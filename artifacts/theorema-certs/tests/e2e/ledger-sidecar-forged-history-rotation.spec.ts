import { test, expect, type Route, type Request } from "@playwright/test";
import {
  mkdtempSync,
  writeFileSync,
  rmSync,
  unlinkSync,
  existsSync,
  readFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import { createLedgerChecker } from "../../../api-server/src/routes/ledger.js";

/**
 * Task #185: end-to-end coverage for the rotating-log behavior in
 * `artifacts/api-server/src/routes/ledger.ts` (`rotateForgedAckHistory`,
 * driven by `MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES` /
 * `MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS`).
 *
 * The "Recent dismissals" panel under the forged-sidecar banner is
 * already covered by `ledger-sidecar-forged-history-panel.spec.ts`
 * (task #167), but that spec only exercises two dismissals — well
 * under the rotation byte threshold — so a regression that silently
 * stops rotating, drops the wrong file, or fails to reset the live
 * log would land in production unnoticed (the 20-row panel cap
 * would still look fine on the dashboard).
 *
 * This spec shrinks `MAX_BYTES` to a value that fits exactly 2
 * forged-ack entries (~150 bytes each) and `MAX_ROTATIONS` to 2,
 * then walks the rotator through three full cycles:
 *
 *   - Acks 1–3 (alice, bob, carol): the 3rd append crosses the
 *     byte cap, so the live log is renamed to `.log.jsonl.1` and
 *     the live path is deleted.
 *   - Ack 4 (dave) repopulates the live log with one entry.
 *   - Acks 5–6 (erin, frank) push the live log past the cap again:
 *     the existing `.1` shifts to `.2`, the live log becomes the
 *     new `.1`, and the live path is again deleted.
 *   - Acks 7–9 (grace, heidi, ivan) trigger a third rotation that
 *     deletes the oldest archive — `MAX_ROTATIONS=2` caps the on-
 *     disk window — shifting `.1` to `.2` (dropping the previous
 *     `.2` containing alice/bob/carol) and the live log to `.1`.
 *   - A final ack (judy) repopulates the live log with one entry
 *     so the dashboard panel has something to render.
 *
 * After the cycles we re-write a forged sidecar matching the most
 * recent ack's payload, boot the fixture, and assert:
 *   - the red banner is up + `data-acknowledged=true` (the on-disk
 *     forged-ack file from judy still binds to the in-memory
 *     incident),
 *   - the dismissals panel renders the live log's single newest-
 *     first row (judy),
 *   - the rotations strip surfaces both `.1` and `.2` archives
 *     (alice/bob/carol is gone — proving the oldest was dropped).
 *
 * Hermetic fixture pattern mirrors
 * `ledger-sidecar-forged-history-panel.spec.ts`: a tmp-dir-backed
 * `createLedgerChecker` mounted at `/api` via an in-process express
 * server, plus `page.route` forwarders for the three ledger URLs
 * the dashboard actually reads. The fixture here uses
 * `checker.listForgedAckHistory()` directly for the history GET
 * (rather than re-implementing the JSONL read) so the response
 * also carries the `rotations` array the dashboard renders.
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

/**
 * Drive a single forge → new-checker → ack cycle without going
 * through the dashboard. Each call:
 *   1. writes a fresh forged sidecar with a unique marker so the
 *      checker produces a distinct `payloadSha`,
 *   2. instantiates a new `createLedgerChecker` (the in-memory
 *      `forgedIncident` is set during construction from the on-
 *      disk sidecar bytes),
 *   3. calls `acknowledgeForgedSidecar(refereeName)`, which
 *      appends to the rotating history log and (when size > cap)
 *      synchronously invokes `rotateForgedAckHistory`.
 */
function ackOnce(seeded: SeedPaths, marker: string, refereeName: string): void {
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
  // History GET via the checker's own lister so the response shape
  // (entries + rotations + capacity + rotation) matches what the
  // dashboard's orval hook expects. The lean.ts route does the same
  // delegation in production.
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
  "dismissal log rotation crosses the byte threshold (task #185)",
  () => {
    // The rotator reads `process.env.MORNINGSTAR_FORGED_ACK_HISTORY_*`
    // every append, so set/restore around this spec only — other
    // forged-ack specs running in the same worker must see the
    // default 256 KiB / 3-rotation policy.
    const ENV_BYTES_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_BYTES";
    const ENV_ROTS_KEY = "MORNINGSTAR_FORGED_ACK_HISTORY_MAX_ROTATIONS";
    let prevBytes: string | undefined;
    let prevRots: string | undefined;

    test.beforeAll(() => {
      prevBytes = process.env[ENV_BYTES_KEY];
      prevRots = process.env[ENV_ROTS_KEY];
      // One entry is ~143 bytes. 300 fits exactly 2; the 3rd append
      // tips it over and triggers `rotateForgedAckHistory`.
      process.env[ENV_BYTES_KEY] = "300";
      process.env[ENV_ROTS_KEY] = "2";
    });

    test.afterAll(() => {
      if (prevBytes === undefined) delete process.env[ENV_BYTES_KEY];
      else process.env[ENV_BYTES_KEY] = prevBytes;
      if (prevRots === undefined) delete process.env[ENV_ROTS_KEY];
      else process.env[ENV_ROTS_KEY] = prevRots;
    });

    test("three rotation cycles: .1/.2 created, oldest dropped at MAX_ROTATIONS, live log resets, dashboard panel still renders the newest entry", async ({
      page,
    }) => {
      const tmpDir = mkdtempSync(
        path.join(tmpdir(), "ledger-forged-history-rotation-e2e-"),
      );
      const seeded = seedTmpLedger(tmpDir);
      const { lastOkPath, secretPath, hitsPath, checkpointPath } = seeded;
      const historyPath = `${lastOkPath}.forged-ack.log.jsonl`;
      const rot1 = `${historyPath}.1`;
      const rot2 = `${historyPath}.2`;
      const rot3 = `${historyPath}.3`;

      // Stable, distinct markers — payload shas must all differ so
      // each ack lands a new history row (rather than dedup as
      // alreadyAcknowledged against the prior single-incident sidecar).
      const cycles: Array<{ marker: string; ref: string }> = [
        { marker: "rot-v1", ref: "alice" },
        { marker: "rot-v2", ref: "bob" },
        { marker: "rot-v3", ref: "carol" },
        { marker: "rot-v4", ref: "dave" },
        { marker: "rot-v5", ref: "erin" },
        { marker: "rot-v6", ref: "frank" },
        { marker: "rot-v7", ref: "grace" },
        { marker: "rot-v8", ref: "heidi" },
        { marker: "rot-v9", ref: "ivan" },
      ];
      const finalMarker = "rot-vfinal";
      const finalRef = "judy";

      let active: FixtureServer | null = null;
      try {
        // --- Acks 1–2: live log accumulates, no rotation yet ---
        ackOnce(seeded, cycles[0]!.marker, cycles[0]!.ref);
        ackOnce(seeded, cycles[1]!.marker, cycles[1]!.ref);
        expect(existsSync(historyPath)).toBe(true);
        expect(existsSync(rot1)).toBe(false);

        // --- Ack 3 (carol) tips the live log past MAX_BYTES=300 ---
        ackOnce(seeded, cycles[2]!.marker, cycles[2]!.ref);
        expect(existsSync(rot1)).toBe(true);
        expect(existsSync(historyPath)).toBe(false); // live got renamed away
        expect(existsSync(rot2)).toBe(false);
        const rot1AfterCycle1 = readFileSync(rot1, "utf-8");
        expect(rot1AfterCycle1).toMatch(/"ackedBy":"alice"/);
        expect(rot1AfterCycle1).toMatch(/"ackedBy":"bob"/);
        expect(rot1AfterCycle1).toMatch(/"ackedBy":"carol"/);

        // --- Ack 4 (dave) recreates the live log with one entry ---
        ackOnce(seeded, cycles[3]!.marker, cycles[3]!.ref);
        expect(existsSync(historyPath)).toBe(true);
        const liveAfterDave = readFileSync(historyPath, "utf-8")
          .split("\n")
          .filter((l) => l.length > 0);
        expect(liveAfterDave.length).toBe(1);
        expect(liveAfterDave[0]).toMatch(/"ackedBy":"dave"/);

        // --- Acks 5–6 (erin, frank) trigger the SECOND rotation ---
        ackOnce(seeded, cycles[4]!.marker, cycles[4]!.ref);
        ackOnce(seeded, cycles[5]!.marker, cycles[5]!.ref);
        expect(existsSync(rot1)).toBe(true);
        expect(existsSync(rot2)).toBe(true);
        expect(existsSync(historyPath)).toBe(false);
        // .2 is the previous .1 (alice/bob/carol); .1 is the previous
        // live (dave/erin/frank).
        const rot2AfterCycle2 = readFileSync(rot2, "utf-8");
        expect(rot2AfterCycle2).toMatch(/"ackedBy":"alice"/);
        expect(rot2AfterCycle2).toMatch(/"ackedBy":"carol"/);
        const rot1AfterCycle2 = readFileSync(rot1, "utf-8");
        expect(rot1AfterCycle2).toMatch(/"ackedBy":"dave"/);
        expect(rot1AfterCycle2).toMatch(/"ackedBy":"erin"/);
        expect(rot1AfterCycle2).toMatch(/"ackedBy":"frank"/);

        // --- Acks 7–9 (grace, heidi, ivan) trigger the THIRD
        //     rotation — MAX_ROTATIONS=2 means the oldest archive
        //     (alice/bob/carol, currently at .2) gets DELETED before
        //     the shift, so it must not survive into .3. ---
        ackOnce(seeded, cycles[6]!.marker, cycles[6]!.ref);
        ackOnce(seeded, cycles[7]!.marker, cycles[7]!.ref);
        ackOnce(seeded, cycles[8]!.marker, cycles[8]!.ref);
        expect(existsSync(rot1)).toBe(true);
        expect(existsSync(rot2)).toBe(true);
        // MAX_ROTATIONS=2: anything past .2 must NOT be created — a
        // regression that forgets to delete the oldest would leak a
        // .3 here.
        expect(existsSync(rot3)).toBe(false);
        expect(existsSync(historyPath)).toBe(false);
        const rot2AfterCycle3 = readFileSync(rot2, "utf-8");
        // alice/bob/carol's archive was the oldest; it should be
        // gone from disk entirely.
        expect(rot2AfterCycle3).not.toMatch(/"ackedBy":"alice"/);
        expect(rot2AfterCycle3).not.toMatch(/"ackedBy":"carol"/);
        // .2 is the previous .1 (dave/erin/frank).
        expect(rot2AfterCycle3).toMatch(/"ackedBy":"dave"/);
        expect(rot2AfterCycle3).toMatch(/"ackedBy":"frank"/);
        // .1 is the previous live (grace/heidi/ivan).
        const rot1AfterCycle3 = readFileSync(rot1, "utf-8");
        expect(rot1AfterCycle3).toMatch(/"ackedBy":"grace"/);
        expect(rot1AfterCycle3).toMatch(/"ackedBy":"ivan"/);

        // --- Final ack (judy) repopulates the live log with one
        //     entry so the dashboard panel has something to render
        //     under the banner. ---
        ackOnce(seeded, finalMarker, finalRef);
        expect(existsSync(historyPath)).toBe(true);
        const liveAfterJudy = readFileSync(historyPath, "utf-8")
          .split("\n")
          .filter((l) => l.length > 0);
        expect(liveAfterJudy.length).toBe(1);
        expect(liveAfterJudy[0]).toMatch(/"ackedBy":"judy"/);

        // Re-forge the sidecar bytes with the same final marker so
        // the next checker boot sees a forged incident whose
        // payloadSha matches judy's on-disk single-incident ack file
        // — that's what keeps the banner visible AND already-acked.
        writeForgedSidecar(lastOkPath, finalMarker);

        active = await bootFixture(seeded);
        await installForwarders(page, () => active!);
        await page.goto("/");

        const banner = page.locator(
          '[data-testid="panel-ledger-sidecar-forged"]',
        );
        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("data-acknowledged", "true");

        // Panel renders judy's row from the live log. The rotations
        // strip surfaces .1 and .2 (alice/bob/carol's archive is
        // gone, confirming the MAX_ROTATIONS=2 cap held end-to-end).
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
        // Exactly one row in the live view — the rotated archives
        // are reachable only via the paging buttons asserted below.
        await expect(
          page.locator('[data-testid^="row-ledger-sidecar-forged-history-"]'),
        ).toHaveCount(1);

        // Rotations strip: .1 + .2 buttons present, no .3 (capped).
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
        ).toBeVisible();
        await expect(
          page.locator(
            '[data-testid="btn-ledger-sidecar-forged-history-rotation-3"]',
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
          rot3,
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
