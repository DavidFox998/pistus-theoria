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
import { createLedgerChecker } from "../../../api-server/src/routes/ledger.js";

/**
 * Task #138: end-to-end coverage for the sidecar tamper banner's
 * Acknowledge button (`button-ack-ledger-sidecar-forged`) and its
 * sticky acknowledged-state across server restarts.
 *
 * Task #124 made the red "Sidecar tamper detected" banner
 * (`panel-ledger-sidecar-forged`) sticky: clicking Acknowledge
 * persists an `acknowledgedAt` to a sibling ack file
 * (`data/hits.txt.lastok.forged-ack`) bound to the sha256 of the
 * forged payload. The banner stays visible (with an "acknowledged"
 * badge) until a non-forged sidecar is read on the next boot, OR a
 * fresh tamper attempt with DIFFERENT bytes lands — in which case
 * the stale ack is dropped and the banner re-fires un-acked.
 *
 * Only `routes/ledger.monitor.test.ts` covered this server-side; the
 * dashboard flow (set token → click → poll re-render → restart →
 * poll re-render → different payload → restart → re-render) had no
 * end-to-end coverage. This file closes that gap.
 *
 * Fixture-driven strategy (matches `ledger-sidecar-forged.spec.ts`,
 * task #125): we boot an in-process express server backed by a REAL
 * `createLedgerChecker` from the api-server package, pointed at a
 * tmp dir whose contents are pre-arranged so the boot-time sidecar
 * read classifies the payload as `forged`. We expose:
 *
 *   - GET  /api/ledger/integrity         → real router from checker
 *   - POST /api/ledger/sidecar-forged-ack → tiny wrapper around the
 *       checker's `acknowledgeForgedSidecar()` with a bearer-token
 *       check that mirrors `lean.ts:checkRebuildAuth` for a single
 *       shared token. We do NOT import `lean.ts` because it pulls in
 *       env vars (LEAN_REBUILD_TOKEN, lockout map, …) we don't want
 *       to mutate from a parallel-safe test fixture.
 *
 * "Restart" is modeled by closing the express server, tearing down
 * the checker, and constructing a fresh `createLedgerChecker` over
 * the SAME tmp dir — exactly what a real process restart does: the
 * forged sidecar + ack file are re-read from disk.
 *
 * The dashboard authenticates the ack POST with the token it pulls
 * from `localStorage["lean-rebuild-token"]`, so we seed that via
 * `page.addInitScript` before navigating.
 *
 * Task #184: the two "simulated restart" phases used to call
 * `page.reload()` to make the dashboard pick up the rebooted fixture
 * server. That paid the Vite SPA cold-start cost twice per test on
 * top of the real express restart, which pushed the spec into the
 * 30s default per-test timeout under parallel-worker CPU contention.
 * Replaced with `page.clock.fastForward("31s")` so the dashboard's
 * 30s integrity `refetchInterval` fires inside the SAME page session
 * — the `installForwarders` route reads `getActive()` on every
 * request, so the refetch lands on the rebooted fixture without any
 * reload, and the assertions hold against the same observable state.
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
const LEDGER_ACK_URL = "**/api/ledger/sidecar-forged-ack";
const FIXTURE_TOKEN = "fixture-referee-token";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";
// 31s — just past the 30s `refetchInterval` on
// `useGetLedgerIntegrity`, so a single fastForward triggers exactly
// one /integrity refetch through the page.route forwarder.
const INTEGRITY_REFETCH_TICK_MS = 31_000;

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

/**
 * Build an express app that mounts the real `createLedgerChecker`
 * router AND a minimal POST /api/ledger/sidecar-forged-ack wrapper
 * that calls the checker's `acknowledgeForgedSidecar()`. The token
 * check is the same Authorization: Bearer <token> shape the real
 * lean.ts route uses, so the dashboard's outbound headers don't need
 * a special case for the test.
 */
async function bootFixture(paths: {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath: string;
  secretPath: string;
}): Promise<FixtureServer> {
  const checker = createLedgerChecker({
    hitsPath: paths.hitsPath,
    checkpointPath: paths.checkpointPath,
    lastOkPath: paths.lastOkPath,
    secretPath: paths.secretPath,
  });

  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  app.post("/api/ledger/sidecar-forged-ack", (req, res) => {
    const auth = req.headers["authorization"] ?? "";
    const match = /^Bearer\s+(.+)$/i.exec(
      Array.isArray(auth) ? (auth[0] ?? "") : auth,
    );
    const provided = match ? match[1]?.trim() : "";
    if (!provided || provided !== FIXTURE_TOKEN) {
      res
        .status(401)
        .json({ ok: false, error: "Unauthorized: bad referee token." });
      return;
    }
    const result = checker.acknowledgeForgedSidecar();
    if (!result.ok) {
      res.status(409).json({
        ok: false,
        error: "No forged-sidecar incident to acknowledge.",
      });
      return;
    }
    res.json({
      ok: true,
      acknowledgedAt: result.acknowledgedAt,
      alreadyAcknowledged: result.alreadyAcknowledged,
      payloadSha: result.payloadSha,
    });
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

/**
 * Forward both /api/ledger/integrity (GET) and
 * /api/ledger/sidecar-forged-ack (POST) requests from the dashboard
 * to whichever fixture server is currently active. The forwarder
 * reads `getActive()` on every request, so flipping the fixture
 * pointer mid-test (to simulate a server restart) takes effect on
 * the next dashboard poll without re-installing routes.
 */
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
}

/**
 * Build the bytes of a forged hits.txt.lastok payload. `marker`
 * lets the caller vary the bytes so a second "tamper attempt" lands
 * a DIFFERENT sha256 (the ack file is bound to the prior payload's
 * sha and must be discarded when the bytes change). No HMAC field
 * → the real router's sidecar verify will classify this as `forged`.
 *
 * Note (task #138): the first call to /api/ledger/integrity after
 * boot writes a valid HMAC'd sidecar back to disk, so a restart
 * test has to *re-forge* (re-write the same bytes) right before
 * tearing down the old fixture. Otherwise boot 2 would see a valid
 * sidecar and clear the acked banner.
 */
function forgedSidecarBytes(marker: string): Buffer {
  // Frozen timestamp baked into the marker keeps the bytes (and
  // therefore the sha) deterministic across the re-forge calls
  // that bracket a simulated restart.
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

test.describe("dashboard: sidecar tamper banner Acknowledge button (task #138)", () => {
  test("clicking Acknowledge persists across restart, and a fresh tamper attempt re-fires un-acked", async ({
    page,
  }) => {
    const tmpDir = mkdtempSync(path.join(tmpdir(), "ledger-ack-e2e-"));
    const hitsPath = path.join(tmpDir, "hits.txt");
    const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
    const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
    const secretPath = path.join(tmpDir, "hits.txt.lastok.key");

    // Healthy sealed prefix + matching checkpoint so the integrity
    // check itself is `ok` — the failure surface under test is the
    // sidecar HMAC, not the prefix mismatch.
    const sealed = "line1\nline2\nline3\n";
    const buf = Buffer.from(sealed, "utf-8");
    writeFileSync(hitsPath, buf);
    writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
    // Pre-seed the HMAC secret so the router does NOT auto-generate
    // one — the forged sidecar must be evaluated against a known
    // secret it carries no valid mac for.
    writeFileSync(secretPath, "ab".repeat(32) + "\n");

    // Initial forged payload — boot 1.
    writeForgedSidecar(lastOkPath, "payload-v1");

    let active = await bootFixture({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });

    try {
      // Install Playwright's virtual clock so the two simulated
      // restart phases below can advance past the dashboard's 30s
      // integrity refetchInterval without sleeping. Anchor at real
      // `Date.now()` so any baked-in age math in the rendered card
      // stays sensible.
      await page.clock.install({ time: Date.now() });
      await installForwarders(page, () => active);

      // Seed the referee token in localStorage so the dashboard
      // sends Authorization: Bearer <token> on the ack POST and so
      // the Acknowledge button renders (it's gated on rebuildToken).
      await page.addInitScript(
        ([key, token]) => {
          window.localStorage.setItem(key as string, token as string);
        },
        [REBUILD_TOKEN_STORAGE_KEY, FIXTURE_TOKEN],
      );

      // --- Boot 1: banner visible, un-acked ---
      await page.goto("/");
      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-forged"]',
      );
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");
      const ackButton = page.locator(
        '[data-testid="button-ack-ledger-sidecar-forged"]',
      );
      await expect(ackButton).toBeVisible();
      await expect(ackButton).toBeEnabled();
      await expect(ackButton).toHaveText(/^Acknowledge$/);
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
        ),
      ).toHaveCount(0);

      // --- Click Acknowledge ---
      await ackButton.click();

      // After the POST resolves + the query is invalidated, the
      // panel must flip to data-acknowledged="true", the badge must
      // render, and the button must read "Acknowledged" and be
      // disabled (gated on lastOkSidecarStatusAcknowledgedAt).
      await expect(panel).toHaveAttribute("data-acknowledged", "true");
      const badge = page.locator(
        '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
      );
      await expect(badge).toBeVisible();
      await expect(badge).toHaveText(/acknowledged/i);
      await expect(ackButton).toBeDisabled();
      await expect(ackButton).toHaveText(/^Acknowledged$/);

      // The ack file must have been persisted to disk — that's the
      // mechanism that survives the restart.
      const ackPath = `${lastOkPath}.forged-ack`;
      expect(existsSync(ackPath)).toBe(true);

      // --- Restart: same forged file, same ack file → still acked ---
      // The first /integrity poll after boot writes a valid HMAC'd
      // sidecar back to disk (task #110), so we must re-write the
      // SAME forged bytes before tearing down to model the realistic
      // "attacker writes the forged payload again, operator reboots"
      // scenario. Same bytes → same sha → ack file still applies.
      await active.close();
      writeForgedSidecar(lastOkPath, "payload-v1");
      active = await bootFixture({
        hitsPath,
        checkpointPath,
        lastOkPath,
        secretPath,
      });

      // Trigger the dashboard's 30s integrity refetch — the
      // forwarder reads `getActive()` per request, so the refetch
      // lands on the newly-rebooted fixture without any SPA reload.
      await page.clock.fastForward(INTEGRITY_REFETCH_TICK_MS);
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "true");
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
        ),
      ).toBeVisible();
      await expect(ackButton).toBeDisabled();
      await expect(ackButton).toHaveText(/^Acknowledged$/);

      // --- Fresh tamper attempt: different bytes → new payload sha
      // → stale ack discarded → banner re-fires un-acked ---
      await active.close();
      writeForgedSidecar(lastOkPath, "payload-v2-different-bytes");
      active = await bootFixture({
        hitsPath,
        checkpointPath,
        lastOkPath,
        secretPath,
      });

      // Same trick: advance the page clock past the integrity
      // refetchInterval so the dashboard re-polls the (now-fresh)
      // fixture and the changed payload sha drops the stale ack.
      await page.clock.fastForward(INTEGRITY_REFETCH_TICK_MS);
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
        ),
      ).toHaveCount(0);
      await expect(ackButton).toBeEnabled();
      await expect(ackButton).toHaveText(/^Acknowledge$/);
    } finally {
      await active.close();
      try {
        unlinkSync(lastOkPath);
      } catch {
        /* ignore */
      }
      try {
        unlinkSync(secretPath);
      } catch {
        /* ignore */
      }
      try {
        unlinkSync(`${lastOkPath}.forged-ack`);
      } catch {
        /* ignore */
      }
      rmSync(tmpDir, { recursive: true, force: true });
    }
  });
});
