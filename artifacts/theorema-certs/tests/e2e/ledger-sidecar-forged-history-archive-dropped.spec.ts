import { test, expect, type Route, type Request } from "@playwright/test";
import {
  mkdtempSync,
  writeFileSync,
  rmSync,
  unlinkSync,
  existsSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import {
  createLedgerChecker,
  startLedgerMonitor,
  type LedgerMonitorHandle,
} from "../../../api-server/src/routes/ledger.js";
import type {
  LedgerAlertInvocation,
  LedgerAlertSink,
} from "../../../api-server/src/lib/ledgerAlerts.js";

/**
 * Task #235: end-to-end coverage for the one-shot info-level
 * "dismissal history archive got full" alert
 * (`forged_ack_history_archive_dropped`) that fires when the
 * forged-ack rotation cap deletes the oldest archive.
 *
 * Task #206 added the alert and is covered by a focused unit test in
 * `artifacts/api-server/src/routes/ledger.monitor.test.ts`, but that
 * test pokes `startLedgerMonitor` in isolation. There was no spec that
 * drives the WHOLE wiring the way operators actually exercise it: the
 * real forged-ack acknowledge flow (re-forge sidecar → fresh checker →
 * `acknowledgeForgedSidecar` → rotating-history append → rotation
 * drop), the env-var plumbing
 * (`MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES` /
 * `MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS`), the monitor
 * construction with `consumeForgedAckHistoryDropAlert` wired to the
 * checker, and the sink delivery — plus the running dashboard server
 * still rendering the post-drop forged banner + history panel. A
 * regression in any of those seams (env not read at append time, the
 * drop latch not threaded onto the checker, the monitor not draining
 * it, the sink never invoked, or it re-firing on later ticks) would
 * slip past the unit test's hand-rolled checker wiring.
 *
 * Hermetic fixture pattern mirrors
 * `ledger-sidecar-forged-history-rotation.spec.ts`: a tmp-dir-backed
 * `createLedgerChecker` per ack (so each forged incident latches a
 * fresh un-acked payloadSha), `MAX_BYTES` shrunk to fit exactly two
 * entries and `MAX_ROTATIONS=1` so the SECOND rotation deletes the
 * oldest archive (the drop we assert on), and an in-process express
 * server mounted at `/api` with `page.route` forwarders so the
 * dashboard can render the running server's post-drop state.
 *
 * Sequence (`MAX_BYTES=300` fits 2 entries; `MAX_ROTATIONS=1`):
 *   - Acks 1–3 (alice, bob, carol): the 3rd append crosses the cap,
 *     so the live log rotates to `.1`. `.1` did not exist beforehand,
 *     so NO archive is dropped yet.
 *   - Acks 4–5 (dave, erin): the live log is recreated and grows back
 *     under the cap.
 *   - Ack 6 (frank): the live log crosses the cap again → SECOND
 *     rotation. With only one rotation slot, the oldest archive
 *     (`.1` = alice/bob/carol, 3 entries) is summarized then DELETED
 *     before the shift — this is the drop. The frank checker carries
 *     the one-shot latch the monitor consumes.
 *   - Final ack (judy) repopulates the live log so the dashboard
 *     panel has a row to render under the banner.
 *
 * Assertions:
 *   - The monitor (wired to the frank checker's
 *     `consumeForgedAckHistoryDropAlert`) delivers EXACTLY ONE
 *     info-level `forged_ack_history_archive_dropped` alert to the
 *     sink, naming the dropped entry count (3), the oldest→newest
 *     acknowledgedAt span and the archive mtime.
 *   - It does NOT re-fire on subsequent ticks (one-shot latch).
 *   - The running dashboard server still renders the forged banner
 *     (acknowledged) and the history panel's newest live row.
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
const LEDGER_ACK_URL = "**/api/ledger/sidecar-forged-ack";
const LEDGER_ACK_HISTORY_URL = "**/api/ledger/sidecar-forged-ack/history*";

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

function forgedSidecarBytes(marker: string): Buffer {
  return Buffer.from(
    JSON.stringify({
      lastOkAt: "2099-01-01T00:00:00.000Z",
      lastCheckedAt: "2099-01-01T00:00:00.000Z",
      marker,
    }) + "\n",
  );
}

function writeForgedSidecar(lastOkPath: string, marker: string): void {
  writeFileSync(lastOkPath, forgedSidecarBytes(marker));
}

function payloadShaFor(marker: string): string {
  return sha256(forgedSidecarBytes(marker));
}

function seedTmpLedger(tmpDir: string): {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath: string;
  secretPath: string;
} {
  const hitsPath = path.join(tmpDir, "hits.txt");
  const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
  const secretPath = path.join(tmpDir, "hits.txt.lastok.key");
  const sealed = "line1\nline2\nline3\n";
  const buf = Buffer.from(sealed, "utf-8");
  writeFileSync(hitsPath, buf);
  writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
  writeFileSync(secretPath, "ab".repeat(32) + "\n");
  return { hitsPath, checkpointPath, lastOkPath, secretPath };
}

type SeedPaths = ReturnType<typeof seedTmpLedger>;
type Checker = ReturnType<typeof createLedgerChecker>;

/**
 * Drive a single forge → new-checker → ack cycle (mirrors the
 * rotation spec / the #206 unit test). Returns the constructed
 * checker so the caller can grab the one that performed the dropping
 * rotation and wire its `consumeForgedAckHistoryDropAlert` to the
 * monitor.
 */
function ackOnce(
  seeded: SeedPaths,
  marker: string,
  refereeName: string,
): Checker {
  writeForgedSidecar(seeded.lastOkPath, marker);
  const checker = createLedgerChecker(seeded);
  const r = checker.acknowledgeForgedSidecar(refereeName);
  if (!r.ok) {
    throw new Error(`ackOnce failed for marker=${marker}: no_incident`);
  }
  if (r.alreadyAcknowledged) {
    throw new Error(
      `ackOnce produced alreadyAcknowledged for marker=${marker} — ` +
        `prior ack file must have collided on payloadSha`,
    );
  }
  return checker;
}

function makeRecordingSink(): {
  sink: LedgerAlertSink;
  calls: LedgerAlertInvocation[];
} {
  const calls: LedgerAlertInvocation[] = [];
  const sink: LedgerAlertSink = (inv) => {
    calls.push(inv);
    return Promise.resolve();
  };
  return { sink, calls };
}

function silentLogger() {
  return { info: () => {}, warn: () => {}, error: () => {} };
}

type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

async function bootFixture(seeded: SeedPaths): Promise<FixtureServer> {
  const checker = createLedgerChecker(seeded);
  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  app.get("/api/ledger/sidecar-forged-ack/history", (req, res) => {
    const rawLimit = req.query["limit"];
    let limit: number | undefined;
    if (typeof rawLimit === "string" && rawLimit.trim() !== "") {
      const parsed = Number(rawLimit);
      if (Number.isFinite(parsed) && parsed > 0) limit = Math.floor(parsed);
    }
    const rawRotation = req.query["rotation"];
    let rotation: number | undefined;
    if (typeof rawRotation === "string" && rawRotation.trim() !== "") {
      const parsed = Number(rawRotation);
      if (Number.isFinite(parsed) && parsed >= 0) {
        rotation = Math.floor(parsed);
      }
    }
    res.json(checker.listForgedAckHistory(limit, rotation));
  });
  const srv = http.createServer(app);
  await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
  const port = (srv.address() as AddressInfo).port;
  return {
    baseUrl: `http://127.0.0.1:${port}`,
    close: async () => {
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
    },
  };
}

async function installForwarders(
  page: import("@playwright/test").Page,
  getActive: () => FixtureServer,
): Promise<void> {
  const forward = async (route: Route, request: Request, suffix: string) => {
    const upstream = new URL(request.url());
    const forwarded = `${getActive().baseUrl}${suffix}${upstream.search}`;
    const postData = request.postData();
    const res = await fetch(forwarded, {
      method: request.method(),
      headers: request.headers(),
      body: postData ?? undefined,
    });
    const body = Buffer.from(await res.arrayBuffer());
    const headers: Record<string, string> = {};
    res.headers.forEach((v, k) => {
      const lk = k.toLowerCase();
      if (
        lk === "content-encoding" ||
        lk === "content-length" ||
        lk === "transfer-encoding"
      ) {
        return;
      }
      headers[k] = v;
    });
    await route.fulfill({ status: res.status, headers, body });
  };
  await page.route(LEDGER_INTEGRITY_URL, (route, request) =>
    forward(route, request, "/api/ledger/integrity"),
  );
  await page.route(LEDGER_ACK_URL, (route, request) =>
    forward(route, request, "/api/ledger/sidecar-forged-ack"),
  );
  await page.route(LEDGER_ACK_HISTORY_URL, (route, request) =>
    forward(route, request, "/api/ledger/sidecar-forged-ack/history"),
  );
}

test.describe(
  "dismissal-archive-full alert fires once end-to-end (task #235)",
  () => {
    // The rotator + the alert producer read
    // `process.env.MORNINGSTAR_FORGED_ACK_HISTORY_*` on every append,
    // so set/restore around this spec only — other forged-ack specs
    // in the same worker must see the default 256 KiB / 3-rotation
    // policy.
    const ENV_BYTES_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES";
    const ENV_ROTS_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS";
    let prevBytes: string | undefined;
    let prevRots: string | undefined;
    let monitor: LedgerMonitorHandle | null = null;

    test.beforeAll(() => {
      prevBytes = process.env[ENV_BYTES_KEY];
      prevRots = process.env[ENV_ROTS_KEY];
      // One entry is ~143 bytes. 300 fits exactly 2; the 3rd append
      // tips it over and triggers `rotateForgedAckHistory`. With a
      // SINGLE rotation slot the second rotation must delete the
      // oldest archive (.1), which is the drop we assert on.
      process.env[ENV_BYTES_KEY] = "300";
      process.env[ENV_ROTS_KEY] = "1";
    });

    test.afterAll(() => {
      if (prevBytes === undefined) delete process.env[ENV_BYTES_KEY];
      else process.env[ENV_BYTES_KEY] = prevBytes;
      if (prevRots === undefined) delete process.env[ENV_ROTS_KEY];
      else process.env[ENV_ROTS_KEY] = prevRots;
    });

    test.afterEach(() => {
      monitor?.stop();
      monitor = null;
    });

    test("drives the real ack flow to a rotation drop; monitor delivers exactly one info-level forged_ack_history_archive_dropped alert (entry count + mtime range), never re-fires, and the dashboard still renders the post-drop state", async ({
      page,
    }) => {
      const tmpDir = mkdtempSync(
        path.join(tmpdir(), "ledger-forged-history-drop-e2e-"),
      );
      const seeded = seedTmpLedger(tmpDir);
      const { lastOkPath, secretPath, hitsPath, checkpointPath } = seeded;
      const historyPath = `${lastOkPath}.forged-ack.log.jsonl`;
      const rot1 = `${historyPath}.1`;
      const rot2 = `${historyPath}.2`;
      const droppedPath = rot1;

      // Stable, distinct markers — payload shas must all differ so
      // each ack lands a new history row (rather than dedup as
      // alreadyAcknowledged against the prior single-incident sidecar).
      const cycles: Array<{ marker: string; ref: string }> = [
        { marker: "drop-v1", ref: "alice" },
        { marker: "drop-v2", ref: "bob" },
        { marker: "drop-v3", ref: "carol" },
        { marker: "drop-v4", ref: "dave" },
        { marker: "drop-v5", ref: "erin" },
        { marker: "drop-v6", ref: "frank" },
      ];
      const finalMarker = "drop-vfinal";
      const finalRef = "judy";

      let active: FixtureServer | null = null;
      try {
        // --- Acks 1–3: ack3 (carol) crosses the cap → FIRST rotation.
        //     `.1` did not exist before, so NOTHING is dropped yet. ---
        ackOnce(seeded, cycles[0]!.marker, cycles[0]!.ref);
        ackOnce(seeded, cycles[1]!.marker, cycles[1]!.ref);
        ackOnce(seeded, cycles[2]!.marker, cycles[2]!.ref);
        expect(existsSync(rot1)).toBe(true);
        expect(existsSync(historyPath)).toBe(false);

        // --- Acks 4–5: live log recreated, grows back under the cap. ---
        ackOnce(seeded, cycles[3]!.marker, cycles[3]!.ref);
        ackOnce(seeded, cycles[4]!.marker, cycles[4]!.ref);
        expect(existsSync(historyPath)).toBe(true);

        // --- Ack 6 (frank): live crosses the cap again → SECOND
        //     rotation. MAX_ROTATIONS=1 means the oldest archive
        //     (`.1` = alice/bob/carol) is deleted. This checker holds
        //     the one-shot drop latch the monitor will consume. ---
        const dropChecker = ackOnce(seeded, cycles[5]!.marker, cycles[5]!.ref);
        expect(existsSync(rot1)).toBe(true); // re-created from the live log
        expect(existsSync(rot2)).toBe(false); // never created — single slot

        // --- Drive the alert through the monitor + sink, exactly the
        //     way the production wiring does (env plumbing already set,
        //     consumer threaded onto the checker). ---
        const { sink, calls } = makeRecordingSink();
        monitor = startLedgerMonitor({
          buildStatus: dropChecker.buildStatus,
          sink,
          intervalMs: 60_000,
          hitsPath: dropChecker.hitsPath,
          checkpointPath: dropChecker.checkpointPath,
          sidecarPath: lastOkPath,
          consumeForgedAckHistoryDropAlert:
            dropChecker.consumeForgedAckHistoryDropAlert,
          logger: silentLogger(),
        });

        await monitor.tick();

        // Exactly one info-level drop alert reaches the sink. The
        // ledger itself is healthy (the forged sidecar is a sidecar-
        // status concern, not an integrity failure), so no integrity
        // alert follows.
        const drops = calls.filter(
          (c) =>
            c.context.failure_mode === "forged_ack_history_archive_dropped",
        );
        expect(drops).toHaveLength(1);
        const drop = drops[0]!;
        expect(drop.kind).toBe("alert");
        expect(drop.context.severity).toBe("info");
        expect(drop.context.source).toBe("api-server-monitor");
        // The dropped archive (alice/bob/carol) held 3 dismissals.
        expect(drop.context.dropped_entry_count).toBe(3);
        expect(drop.context.dropped_path).toBe(droppedPath);
        // mtime range: the acknowledgedAt span of the discarded
        // dismissals plus the archive's file mtime, all present and
        // well-ordered.
        const oldest = drop.context.dropped_oldest_acknowledged_at;
        const newest = drop.context.dropped_newest_acknowledged_at;
        expect(typeof oldest).toBe("string");
        expect(typeof newest).toBe("string");
        expect(Date.parse(oldest as string)).not.toBeNaN();
        expect(Date.parse(newest as string)).not.toBeNaN();
        expect(Date.parse(oldest as string)).toBeLessThanOrEqual(
          Date.parse(newest as string),
        );
        expect(typeof drop.context.dropped_archive_mtime).toBe("string");
        expect(Date.parse(drop.context.dropped_archive_mtime as string)).not.toBeNaN();
        expect(drop.message).toMatch(/dismissal history archive dropped/i);
        expect(drop.message).toMatch(/MAX_ROTATIONS/);

        // One-shot: subsequent ticks must NOT re-fire even though the
        // archive stays dropped.
        await monitor.tick();
        await monitor.tick();
        expect(
          calls.filter(
            (c) =>
              c.context.failure_mode === "forged_ack_history_archive_dropped",
          ),
        ).toHaveLength(1);

        // --- Final ack (judy) repopulates the live log with one entry
        //     so the dashboard panel has something to render under the
        //     banner. This is a fresh checker, so the frank checker's
        //     already-consumed latch is untouched. ---
        ackOnce(seeded, finalMarker, finalRef);
        expect(existsSync(historyPath)).toBe(true);

        // Re-forge the sidecar bytes with judy's marker so the boot
        // checker sees a forged incident whose payloadSha matches
        // judy's on-disk single-incident ack file — that keeps the
        // banner visible AND already-acked.
        writeForgedSidecar(lastOkPath, finalMarker);

        active = await bootFixture(seeded);
        await installForwarders(page, () => active!);
        await page.goto("/");

        const banner = page.locator(
          '[data-testid="panel-ledger-sidecar-forged"]',
        );
        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");

        // The running dashboard server renders judy's live row.
        const historyPanel = page.locator(
          '[data-testid="panel-ledger-sidecar-forged-history"]',
        );
        await expect(historyPanel).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="text-ledger-sidecar-forged-history-count"]',
          ),
        ).toHaveText("1 of last 20");
        const row0 = page.locator(
          '[data-testid="row-ledger-sidecar-forged-history-0"]',
        );
        await expect(row0).toHaveAttribute("data-acked-by", finalRef);
        await expect(row0).toHaveAttribute(
          "data-payload-sha",
          payloadShaFor(finalMarker),
        );
        await expect(row0).toContainText(finalRef);
        await expect(
          page.locator('[data-testid^="row-ledger-sidecar-forged-history-"]'),
        ).toHaveCount(1);

        // Rotations strip: exactly one archive survives (`.1`); the
        // MAX_ROTATIONS=1 cap means there is no `.2`.
        const rotationsStrip = page.locator(
          '[data-testid="panel-ledger-sidecar-forged-history-rotations"]',
        );
        await expect(rotationsStrip).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-1"]',
          ),
        ).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-2"]',
          ),
        ).toHaveCount(0);
      } finally {
        if (active) await active.close();
        for (const p of [
          lastOkPath,
          secretPath,
          `${lastOkPath}.forged-ack`,
          historyPath,
          rot1,
          rot2,
          hitsPath,
          checkpointPath,
        ]) {
          try {
            if (existsSync(p)) unlinkSync(p);
          } catch {
            /* ignore */
          }
        }
        rmSync(tmpDir, { recursive: true, force: true });
      }
    });
  },
);
