import { describe, it, expect, vi } from "vitest";
import {
  buildRerollDigest,
  hasAlertSinkConfigured,
  resolveRerollDigestIntervalSeconds,
  resolveRerollDigestStatus,
  runRerollDigestOnce,
  type RerollDigestRow,
} from "./rerollDigest.js";

const NOW = new Date("2026-05-28T12:00:00Z");

function row(overrides: Partial<RerollDigestRow> = {}): RerollDigestRow {
  return {
    timestamp: "2026-05-28T10:00:00Z",
    durationMs: 1234,
    exitCode: 0,
    ok: true,
    error: null,
    refereeName: "alice",
    ip: "10.0.0.1",
    ...overrides,
  };
}

const stubLogger = {
  info: vi.fn(),
  warn: vi.fn(),
  error: vi.fn(),
};

describe("buildRerollDigest", () => {
  it("groups by referee with ok/fail counts and sorts by fail-desc", () => {
    const rows: RerollDigestRow[] = [
      row({ refereeName: "alice", ok: true }),
      row({ refereeName: "alice", ok: false, exitCode: 1, error: "boom" }),
      row({ refereeName: "bob", ok: false, exitCode: 2, error: "kaboom" }),
      row({ refereeName: "bob", ok: false, exitCode: 2 }),
      row({ refereeName: null, ok: true }),
    ];
    const d = buildRerollDigest(rows, 24, NOW);
    expect(d.totalAttempts).toBe(5);
    expect(d.okCount).toBe(2);
    expect(d.failCount).toBe(3);
    expect(d.perReferee[0]).toEqual({
      refereeName: "bob",
      okCount: 0,
      failCount: 2,
    });
    expect(d.perReferee[1].refereeName).toBe("alice");
    expect(d.perReferee[2].refereeName).toBe("(unnamed)");
    expect(d.failures).toHaveLength(3);
    expect(d.text).toContain("By referee:");
    expect(d.text).toContain("- bob: ok=0, fail=2");
    expect(d.text).toContain('err="boom"');
  });

  it("emits a 'no attempts' line on empty input", () => {
    const d = buildRerollDigest([], 24, NOW);
    expect(d.totalAttempts).toBe(0);
    expect(d.text).toContain("(no checkpoint re-roll attempts in this window)");
    expect(d.text).toContain("Failures:\n  (none)");
  });

  it("buckets the window into fixed-width slices with ok/fail tallies", () => {
    // NOW is 2026-05-28T12:00:00Z; a 24h window => 24 hourly buckets
    // starting at 2026-05-27T12:00:00Z.
    const rows: RerollDigestRow[] = [
      row({ timestamp: "2026-05-27T12:30:00Z", ok: true }), // bucket 0
      row({ timestamp: "2026-05-28T11:30:00Z", ok: true }), // last bucket
      row({ timestamp: "2026-05-28T11:45:00Z", ok: false }), // last bucket
    ];
    const d = buildRerollDigest(rows, 24, NOW);
    expect(d.buckets).toHaveLength(24);
    expect(d.buckets[0]).toEqual({
      start: "2026-05-27T12:00:00.000Z",
      attempts: 1,
      okCount: 1,
      failCount: 0,
    });
    expect(d.buckets[23]).toEqual({
      start: "2026-05-28T11:00:00.000Z",
      attempts: 2,
      okCount: 1,
      failCount: 1,
    });
    const totalAttempts = d.buckets.reduce((s, b) => s + b.attempts, 0);
    expect(totalAttempts).toBe(3);
  });

  it("returns empty (zeroed) buckets when there are no attempts", () => {
    const d = buildRerollDigest([], 24, NOW);
    expect(d.buckets).toHaveLength(24);
    expect(d.buckets.every((b) => b.attempts === 0)).toBe(true);
  });

  it("clamps out-of-window rows into the first/last bucket", () => {
    const rows: RerollDigestRow[] = [
      row({ timestamp: "2026-05-20T00:00:00Z", ok: true }), // way before start
      row({ timestamp: "2026-05-28T12:00:00Z", ok: false }), // at/after end
    ];
    const d = buildRerollDigest(rows, 24, NOW);
    expect(d.buckets[0].attempts).toBe(1);
    expect(d.buckets[23].attempts).toBe(1);
  });

  it("collapses whitespace and caps error length in failure list", () => {
    const huge = "x".repeat(500);
    const d = buildRerollDigest(
      [row({ ok: false, error: `multi\nline   ${huge}` })],
      24,
      NOW,
    );
    const failureLine = d.text.split("\n").find((l) => l.includes("err="))!;
    expect(failureLine).toBeDefined();
    expect(failureLine.length).toBeLessThan(300);
    expect(failureLine).not.toContain("\n");
  });
});

describe("runRerollDigestOnce", () => {
  it("dispatches via the sink with reroll_digest failure_mode", async () => {
    const sink = vi.fn().mockResolvedValue(undefined);
    const rows = [row({ ok: true }), row({ ok: false, refereeName: "mallory" })];
    const result = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => rows,
      hasSink: () => true,
    });
    expect(result).not.toBeNull();
    expect(sink).toHaveBeenCalledTimes(1);
    const inv = sink.mock.calls[0]![0];
    expect(inv.kind).toBe("alert");
    expect(inv.context.failure_mode).toBe("reroll_digest");
    expect(inv.context.window_hours).toBe(24);
    expect(inv.context.total_attempts).toBe(2);
    expect(inv.context.ok_count).toBe(1);
    expect(inv.context.fail_count).toBe(1);
    expect(typeof inv.context.digest_text).toBe("string");
    expect(inv.message).toContain("Checkpoint re-roll digest");
  });

  it("disables the digest when no sinks are configured", async () => {
    const sink = vi.fn();
    const fetchRows = vi.fn(async () => [row({ ok: false })]);
    const logger = { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
    const r = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger,
      now: () => NOW,
      fetchRows,
      hasSink: () => false,
    });
    expect(r).toBeNull();
    expect(sink).not.toHaveBeenCalled();
    expect(fetchRows).not.toHaveBeenCalled();
    expect(logger.info).toHaveBeenCalledWith(
      expect.objectContaining({ windowHours: 24 }),
      "reroll digest: no sinks configured, digest disabled",
    );
  });

  it("dispatches when a sink is configured", async () => {
    const sink = vi.fn().mockResolvedValue(undefined);
    const r = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => [row({ ok: true })],
      hasSink: () => true,
    });
    expect(r).not.toBeNull();
    expect(sink).toHaveBeenCalledTimes(1);
  });

  it("skips dispatch when the window has no attempts (default)", async () => {
    const sink = vi.fn();
    const r = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => [],
    });
    expect(r).toBeNull();
    expect(sink).not.toHaveBeenCalled();
  });

  it("still dispatches an empty digest when skipWhenEmpty=false", async () => {
    const sink = vi.fn().mockResolvedValue(undefined);
    await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => [],
      skipWhenEmpty: false,
      hasSink: () => true,
    });
    expect(sink).toHaveBeenCalledTimes(1);
  });

  it("swallows sink failures so a flaky on-call sink can't crash the timer", async () => {
    const sink = vi.fn().mockRejectedValue(new Error("smtp down"));
    const r = await runRerollDigestOnce({
      windowHours: 24,
      sink,
      logger: stubLogger,
      now: () => NOW,
      fetchRows: async () => [row({ ok: false })],
      hasSink: () => true,
    });
    expect(r).not.toBeNull();
  });
});

describe("hasAlertSinkConfigured", () => {
  it("is false when neither transport env var is set", () => {
    expect(hasAlertSinkConfigured({})).toBe(false);
    expect(
      hasAlertSinkConfigured({
        MORNINGSTAR_ALERT_WEBHOOK_URL: "  ",
        MORNINGSTAR_ALERT_EMAIL_TO: "",
      }),
    ).toBe(false);
  });

  it("is true when the webhook URL is set", () => {
    expect(
      hasAlertSinkConfigured({
        MORNINGSTAR_ALERT_WEBHOOK_URL: "http://example/alert",
      }),
    ).toBe(true);
  });

  it("is true when the email recipient is set", () => {
    expect(
      hasAlertSinkConfigured({ MORNINGSTAR_ALERT_EMAIL_TO: "ops@example.com" }),
    ).toBe(true);
  });
});

describe("resolveRerollDigestIntervalSeconds", () => {
  it("defaults to 86400 seconds (24h) when unset", () => {
    expect(resolveRerollDigestIntervalSeconds(undefined)).toBe(86400);
    expect(resolveRerollDigestIntervalSeconds("")).toBe(86400);
  });

  it("returns null for off/disabled/0/none (case-insensitive)", () => {
    for (const v of ["off", "Off", "DISABLED", "disable", "none", "0"]) {
      expect(resolveRerollDigestIntervalSeconds(v)).toBeNull();
    }
  });

  it("falls back to default on bad input", () => {
    expect(resolveRerollDigestIntervalSeconds("nonsense")).toBe(86400);
    expect(resolveRerollDigestIntervalSeconds("-5")).toBe(86400);
  });

  it("accepts positive numeric values", () => {
    expect(resolveRerollDigestIntervalSeconds("3600")).toBe(3600);
    expect(resolveRerollDigestIntervalSeconds("43200.7")).toBe(43200);
  });
});

describe("resolveRerollDigestStatus", () => {
  it("is enabled with cadence + window when interval is live and a sink exists", () => {
    expect(resolveRerollDigestStatus(undefined, true)).toEqual({
      state: "enabled",
      intervalSeconds: 86400,
      windowHours: 24,
    });
    expect(resolveRerollDigestStatus("43200", true)).toEqual({
      state: "enabled",
      intervalSeconds: 43200,
      windowHours: 12,
    });
  });

  it("floors the window at 1h for sub-hour intervals", () => {
    expect(resolveRerollDigestStatus("60", true)).toEqual({
      state: "enabled",
      intervalSeconds: 60,
      windowHours: 1,
    });
  });

  it("is disabled_interval_off when the interval is off (regardless of sink)", () => {
    expect(resolveRerollDigestStatus("off", true)).toEqual({
      state: "disabled_interval_off",
      intervalSeconds: null,
      windowHours: null,
    });
    expect(resolveRerollDigestStatus("0", false)).toEqual({
      state: "disabled_interval_off",
      intervalSeconds: null,
      windowHours: null,
    });
  });

  it("is disabled_no_sink when the interval is live but no sink is configured", () => {
    expect(resolveRerollDigestStatus(undefined, false)).toEqual({
      state: "disabled_no_sink",
      intervalSeconds: null,
      windowHours: null,
    });
    expect(resolveRerollDigestStatus("3600", false)).toEqual({
      state: "disabled_no_sink",
      intervalSeconds: null,
      windowHours: null,
    });
  });

  it("interval-off wins over a missing sink (deliberate opt-out, not a misconfig)", () => {
    expect(resolveRerollDigestStatus("none", false).state).toBe(
      "disabled_interval_off",
    );
  });
});
