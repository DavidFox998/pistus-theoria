import { and, desc, gte } from "drizzle-orm";
import type { Logger } from "pino";
import { db, ledgerCheckpointRerollHistoryTable } from "@workspace/db";
import type { LedgerAlertSink } from "./ledgerAlerts.js";

export interface RerollDigestRow {
  timestamp: string;
  durationMs: number;
  exitCode: number;
  ok: boolean;
  error: string | null;
  refereeName: string | null;
  ip: string | null;
}

export interface RerollDigestPerReferee {
  refereeName: string;
  okCount: number;
  failCount: number;
}

export interface RerollDigestBucket {
  /** ISO-8601 timestamp of the bucket's (inclusive) start. */
  start: string;
  attempts: number;
  okCount: number;
  failCount: number;
}

export interface RerollDigest {
  windowHours: number;
  windowStart: string;
  windowEnd: string;
  totalAttempts: number;
  okCount: number;
  failCount: number;
  perReferee: RerollDigestPerReferee[];
  failures: RerollDigestRow[];
  buckets: RerollDigestBucket[];
  text: string;
}

const ANON_REFEREE = "(unnamed)";

/**
 * Task #224: fixed number of time buckets per digest, regardless of
 * window length, so the dashboard sparkline stays a compact, constant
 * width across 24h/7d/30d. 24 columns keeps each bar readable while
 * still revealing a burst. With 24 buckets a 24h window is hourly, 7d
 * is 7h-wide, 30d is daily.
 */
const DIGEST_BUCKET_COUNT = 24;

/**
 * Task #224: bucket the window into `DIGEST_BUCKET_COUNT` equal slices
 * and tally attempts/ok/fail per slice so the dashboard can draw a
 * volume-over-time chart. Rows are placed by their finish timestamp;
 * anything landing on or before the window start clamps into bucket 0
 * and anything at/after the end clamps into the last bucket (defensive
 * against clock skew between the row time and `now`).
 */
function bucketRerollRows(
  rows: RerollDigestRow[],
  windowStartMs: number,
  windowHours: number,
): RerollDigestBucket[] {
  const windowMs = windowHours * 60 * 60 * 1000;
  const bucketMs = windowMs / DIGEST_BUCKET_COUNT;
  const buckets: RerollDigestBucket[] = Array.from(
    { length: DIGEST_BUCKET_COUNT },
    (_, i) => ({
      start: new Date(windowStartMs + i * bucketMs).toISOString(),
      attempts: 0,
      okCount: 0,
      failCount: 0,
    }),
  );
  for (const r of rows) {
    const t = Date.parse(r.timestamp);
    if (Number.isNaN(t)) continue;
    let idx = Math.floor((t - windowStartMs) / bucketMs);
    if (idx < 0) idx = 0;
    if (idx >= DIGEST_BUCKET_COUNT) idx = DIGEST_BUCKET_COUNT - 1;
    const bucket = buckets[idx];
    bucket.attempts += 1;
    if (r.ok) bucket.okCount += 1;
    else bucket.failCount += 1;
  }
  return buckets;
}

/**
 * Task #176: build the human-readable digest body. Groups by referee
 * (ok/fail counts), then lists every failing row so an unexpected
 * referee or a spike of failed re-rolls jumps out of the email
 * without anyone watching the dashboard live.
 */
export function buildRerollDigest(
  rows: RerollDigestRow[],
  windowHours: number,
  now: Date = new Date(),
): RerollDigest {
  const windowEnd = now.toISOString();
  const windowStartMs = now.getTime() - windowHours * 60 * 60 * 1000;
  const windowStart = new Date(windowStartMs).toISOString();
  const byReferee = new Map<string, RerollDigestPerReferee>();
  let okCount = 0;
  let failCount = 0;
  const failures: RerollDigestRow[] = [];
  for (const r of rows) {
    const ref =
      r.refereeName && r.refereeName.length > 0 ? r.refereeName : ANON_REFEREE;
    let bucket = byReferee.get(ref);
    if (!bucket) {
      bucket = { refereeName: ref, okCount: 0, failCount: 0 };
      byReferee.set(ref, bucket);
    }
    if (r.ok) {
      bucket.okCount += 1;
      okCount += 1;
    } else {
      bucket.failCount += 1;
      failCount += 1;
      failures.push(r);
    }
  }
  const perReferee = Array.from(byReferee.values()).sort((a, b) => {
    if (b.failCount !== a.failCount) return b.failCount - a.failCount;
    if (b.okCount !== a.okCount) return b.okCount - a.okCount;
    return a.refereeName.localeCompare(b.refereeName);
  });

  const lines: string[] = [];
  lines.push(
    `Window: ${windowStart} → ${windowEnd} (${windowHours}h)`,
    `Total attempts: ${rows.length} (ok=${okCount}, fail=${failCount})`,
    "",
    "By referee:",
  );
  if (perReferee.length === 0) {
    lines.push("  (no checkpoint re-roll attempts in this window)");
  } else {
    for (const p of perReferee) {
      lines.push(
        `  - ${p.refereeName}: ok=${p.okCount}, fail=${p.failCount}`,
      );
    }
  }
  lines.push("", "Failures:");
  if (failures.length === 0) {
    lines.push("  (none)");
  } else {
    for (const f of failures) {
      const ref =
        f.refereeName && f.refereeName.length > 0
          ? f.refereeName
          : ANON_REFEREE;
      const ip = f.ip ?? "?";
      const err = f.error ? f.error.replace(/\s+/g, " ").slice(0, 200) : "";
      lines.push(
        `  - ${f.timestamp} referee=${ref} ip=${ip} exit=${f.exitCode}${
          err ? ` err="${err}"` : ""
        }`,
      );
    }
  }

  return {
    windowHours,
    windowStart,
    windowEnd,
    totalAttempts: rows.length,
    okCount,
    failCount,
    perReferee,
    failures,
    buckets: bucketRerollRows(rows, windowStartMs, windowHours),
    text: lines.join("\n"),
  };
}

/**
 * Task #176: fetch every reroll-history row from the last
 * `windowHours` hours (no capacity cap — the digest must reflect the
 * full window, not just the last N kept by the ring buffer).
 */
export async function fetchRerollRowsSince(
  windowHours: number,
  now: Date = new Date(),
): Promise<RerollDigestRow[]> {
  const since = new Date(now.getTime() - windowHours * 60 * 60 * 1000);
  const rows = await db
    .select()
    .from(ledgerCheckpointRerollHistoryTable)
    .where(
      and(gte(ledgerCheckpointRerollHistoryTable.timestamp, since)),
    )
    .orderBy(desc(ledgerCheckpointRerollHistoryTable.id));
  return rows.map((r) => ({
    timestamp: r.timestamp.toISOString(),
    durationMs: r.durationMs,
    exitCode: r.exitCode,
    ok: r.ok,
    error: r.error,
    refereeName: r.refereeName,
    ip: r.ip,
  }));
}

/**
 * Task #198: mirror the kernel transports' env-var gate
 * (`kernel._fire_ledger_alert` reads the exact same two vars). A sink
 * counts as "configured" when either the webhook URL or the email
 * recipient is a non-empty string after trimming. With neither set,
 * `_fire_ledger_alert` would still spawn, write a "not_configured"
 * history row, and return — pure noise on a sink-less deployment, so
 * the digest scheduler short-circuits before dispatching.
 */
export function hasAlertSinkConfigured(
  env: NodeJS.ProcessEnv = process.env,
): boolean {
  const webhook = (env["MORNINGSTAR_ALERT_WEBHOOK_URL"] ?? "").trim();
  const emailTo = (env["MORNINGSTAR_ALERT_EMAIL_TO"] ?? "").trim();
  return webhook.length > 0 || emailTo.length > 0;
}

export interface RerollDigestRunOptions {
  windowHours: number;
  sink: LedgerAlertSink;
  logger: Pick<Logger, "info" | "warn" | "error">;
  fetchRows?: (
    windowHours: number,
    now: Date,
  ) => Promise<RerollDigestRow[]>;
  now?: () => Date;
  skipWhenEmpty?: boolean;
  hasSink?: () => boolean;
}

/**
 * Build and dispatch one digest. Returns the digest object so tests
 * can assert on it; swallows sink failures (best-effort observability,
 * same posture as `_fire_ledger_alert` on the Python side).
 */
export async function runRerollDigestOnce(
  opts: RerollDigestRunOptions,
): Promise<RerollDigest | null> {
  const now = (opts.now ?? (() => new Date()))();
  const hasSink = opts.hasSink ?? hasAlertSinkConfigured;
  if (!hasSink()) {
    opts.logger.info(
      { windowHours: opts.windowHours },
      "reroll digest: no sinks configured, digest disabled",
    );
    return null;
  }
  const fetcher = opts.fetchRows ?? fetchRerollRowsSince;
  let rows: RerollDigestRow[];
  try {
    rows = await fetcher(opts.windowHours, now);
  } catch (err) {
    opts.logger.error(
      { err },
      "reroll digest: failed to read history table",
    );
    return null;
  }
  if (opts.skipWhenEmpty !== false && rows.length === 0) {
    opts.logger.info(
      { windowHours: opts.windowHours },
      "reroll digest: skipped (no attempts in window)",
    );
    return null;
  }
  const digest = buildRerollDigest(rows, opts.windowHours, now);
  const message = `Checkpoint re-roll digest: ${digest.totalAttempts} attempts (ok=${digest.okCount}, fail=${digest.failCount}) over the last ${digest.windowHours}h.`;
  try {
    await opts.sink({
      kind: "alert",
      message,
      context: {
        failure_mode: "reroll_digest",
        checked_at: now.toISOString(),
        source: "rerollDigest",
        window_hours: digest.windowHours,
        window_start: digest.windowStart,
        window_end: digest.windowEnd,
        total_attempts: digest.totalAttempts,
        ok_count: digest.okCount,
        fail_count: digest.failCount,
        per_referee: digest.perReferee,
        failures: digest.failures,
        digest_text: digest.text,
      },
    });
    opts.logger.info(
      {
        windowHours: digest.windowHours,
        totalAttempts: digest.totalAttempts,
        okCount: digest.okCount,
        failCount: digest.failCount,
      },
      "reroll digest: dispatched",
    );
  } catch (err) {
    opts.logger.warn(
      { err },
      "reroll digest: sink dispatch failed (swallowed)",
    );
  }
  return digest;
}

export interface RerollDigestScheduler {
  stop(): void;
  runNow(): Promise<RerollDigest | null>;
}

export interface RerollDigestSchedulerOptions extends RerollDigestRunOptions {
  intervalMs: number;
}

/**
 * Spin up the daily digest timer. Cadence is driven by `intervalMs`
 * and the digest window matches that cadence (so a 24h interval
 * digests the last 24h, a 12h interval digests the last 12h, etc.).
 */
export function startRerollDigestScheduler(
  opts: RerollDigestSchedulerOptions,
): RerollDigestScheduler {
  let stopped = false;
  let running = false;
  const tick = async (): Promise<RerollDigest | null> => {
    if (stopped || running) return null;
    running = true;
    try {
      return await runRerollDigestOnce(opts);
    } finally {
      running = false;
    }
  };
  const handle = setInterval(() => {
    void tick();
  }, opts.intervalMs);
  handle.unref?.();
  return {
    stop() {
      stopped = true;
      clearInterval(handle);
    },
    runNow: tick,
  };
}

const DEFAULT_DIGEST_INTERVAL_SECONDS = 24 * 60 * 60;

/**
 * Parse `MORNINGSTAR_REROLL_DIGEST_INTERVAL_SECONDS`. Default 86400
 * (24h). `off`/`0`/`disabled`/`none` disables the scheduler. Bad
 * values fall back to the default — same posture as the existing
 * `LEDGER_INTEGRITY_CHECK_INTERVAL_SECONDS` parser.
 */
export function resolveRerollDigestIntervalSeconds(
  raw: string | undefined,
): number | null {
  if (raw == null) return DEFAULT_DIGEST_INTERVAL_SECONDS;
  const trimmed = raw.trim();
  if (trimmed === "") return DEFAULT_DIGEST_INTERVAL_SECONDS;
  if (/^(off|disabled?|none|0)$/i.test(trimmed)) return null;
  const n = Number(trimmed);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_DIGEST_INTERVAL_SECONDS;
  return Math.floor(n);
}

/**
 * Convert an interval (whole seconds) into the digest window in whole
 * hours, matching the boot-time wiring: the digest window tracks the
 * cadence, with a 1h floor so a sub-hour interval still digests at
 * least an hour.
 */
export function rerollDigestWindowHours(intervalSeconds: number): number {
  return Math.max(1, Math.round(intervalSeconds / 3600));
}

/**
 * Task #223. The digest scheduler can be live, off-by-interval, or
 * silently off because no alert sink is wired up — three states that
 * are indistinguishable from the dashboard today (all you see is a
 * quiet log line). `state` makes the distinction explicit:
 *  - `enabled`: the timer is running; `intervalSeconds`/`windowHours`
 *    describe the cadence and digest window.
 *  - `disabled_interval_off`: an operator set
 *    `MORNINGSTAR_REROLL_DIGEST_INTERVAL_SECONDS=off` (or 0/none) — a
 *    deliberate opt-out, nothing to fix.
 *  - `disabled_no_sink`: the interval is live but neither
 *    `MORNINGSTAR_ALERT_WEBHOOK_URL` nor `MORNINGSTAR_ALERT_EMAIL_TO`
 *    is set, so the scheduler short-circuits (task #198) — a likely
 *    misconfiguration that an operator can fix by setting a sink.
 */
export type RerollDigestState =
  | "enabled"
  | "disabled_interval_off"
  | "disabled_no_sink";

export interface RerollDigestStatus {
  state: RerollDigestState;
  /** Cadence in whole seconds when enabled; null otherwise. */
  intervalSeconds: number | null;
  /** Digest look-back window in whole hours when enabled; null otherwise. */
  windowHours: number | null;
}

/**
 * Task #223. Resolve the digest's *effective* state from the same two
 * inputs the boot wiring uses — the interval env var and whether an
 * alert sink is configured — so the dashboard can surface exactly why
 * the digest is (or isn't) running.
 */
export function resolveRerollDigestStatus(
  rawInterval: string | undefined,
  hasSink: boolean = hasAlertSinkConfigured(),
): RerollDigestStatus {
  const intervalSeconds = resolveRerollDigestIntervalSeconds(rawInterval);
  if (intervalSeconds == null) {
    return {
      state: "disabled_interval_off",
      intervalSeconds: null,
      windowHours: null,
    };
  }
  if (!hasSink) {
    return {
      state: "disabled_no_sink",
      intervalSeconds: null,
      windowHours: null,
    };
  }
  return {
    state: "enabled",
    intervalSeconds,
    windowHours: rerollDigestWindowHours(intervalSeconds),
  };
}
