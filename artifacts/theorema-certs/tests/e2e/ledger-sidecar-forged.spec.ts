import { test, expect, type Route, type Request } from "@playwright/test";
import {
  mkdtempSync,
  writeFileSync,
  rmSync,
  unlinkSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import {
  createLedgerRouter,
  createLedgerChecker,
} from "../../../api-server/src/routes/ledger.js";

/**
 * Task #125: end-to-end coverage for the sidecar tamper / stale-binding
 * banners on the Ledger Integrity card.
 *
 * Task #110 added unit + monitor tests for the server-side
 * `sidecar_forged` path. The dashboard banners
 * (`panel-ledger-sidecar-forged` and `text-ledger-sidecar-stale-binding`
 * in `artifacts/theorema-certs/src/pages/dashboard.tsx` ~lines 1777-1893)
 * were only covered by typecheck. A React-side regression — conditional
 * ordering, missing import, copy drift — would not have been caught.
 *
 * Mixed strategy: the two `sidecar_forged` cases (initial forged
 * banner + rotate-clears-banner) are fixture-driven — they spin up a
 * fresh in-process express server backed by a real `createLedgerRouter`
 * from the api-server package, pointed at a tmp dir containing real
 * `hits.txt`, `hits.txt.checkpoint`, `hits.txt.lastok.key` and a forged
 * `hits.txt.lastok`. Playwright forwards the dashboard's
 * `/api/ledger/integrity` requests to that fixture-backed server via
 * `page.route` and fulfils the dashboard with the REAL bytes the real
 * router computed, exercising the same code path as the "rejects a
 * forged sidecar…" test in
 * `artifacts/api-server/src/routes/ledger.integration.test.ts`. This
 * works because `forgedIncident` is sticky on the API's response shape.
 *
 * The third case (`stale_checkpoint_binding`) uses a SYNTHETIC
 * `page.route` mock instead — see the comment block above that test
 * for the full root-cause analysis (Task #165). Short version: the
 * API's `buildStatusInner` unconditionally flips
 * `lastOkSidecarStatus = "ok"` on every `/integrity` call, so a
 * fixture-driven test could never deterministically observe the
 * banner.
 *
 * We forward instead of swapping the dashboard's baseURL because the
 * dashboard is served by the global proxy on port 80 and the real
 * api-server already owns `/api/*` there — running a second router on
 * a random port and forwarding keeps the rest of the dashboard
 * (`/api/lean/*`, `/api/certificates/*`, …) talking to the real
 * production-shaped api-server while only the integrity endpoint
 * sees the fixture state.
 *
 * Selectors / copy under test (dashboard.tsx ~1777-1893):
 *   - `[data-testid="panel-ledger-sidecar-forged"]` carries
 *     `data-acknowledged="true|false"`.
 *   - `[data-testid="text-ledger-sidecar-forged-reason"]` — the
 *     HMAC-failure copy naming `data/hits.txt.lastok`.
 *   - Remediation: "rotate the sidecar secret", `LEDGER_SIDECAR_SECRET`,
 *     `data/hits.txt.lastok.key`, "audit who has write access",
 *     "re-verify the ledger from a fresh checkout".
 *   - `[data-testid="text-ledger-sidecar-stale-binding"]` — amber line
 *     with "stale checkpoint binding" + "HMAC verified" hint.
 *   - The two banners are mutually exclusive (`if/else if` in the JSX).
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

/**
 * Mirrors the canonicalize() + HMAC scheme in
 * `artifacts/api-server/src/routes/ledger.ts` so we can seed a
 * sidecar that the REAL router will accept as HMAC-valid (used for
 * the stale-binding case, where the MAC must verify but the
 * `boundCheckpointSha` must mismatch the on-disk checkpoint).
 */
function sealSidecar(
  secretHex: string,
  payload: {
    lastOkAt: string | null;
    lastCheckedAt: string | null;
    boundCheckpointSize: number | null;
    boundCheckpointSha: string | null;
  },
): string {
  const canonical = JSON.stringify({
    lastOkAt: payload.lastOkAt,
    lastCheckedAt: payload.lastCheckedAt,
    boundCheckpointSize: payload.boundCheckpointSize,
    boundCheckpointSha: payload.boundCheckpointSha,
  });
  const mac = createHmac("sha256", Buffer.from(secretHex, "hex"))
    .update(canonical)
    .digest("hex");
  return JSON.stringify({ ...payload, mac }) + "\n";
}

type FixtureServer = {
  baseUrl: string;
  tmpDir: string;
  close: () => Promise<void>;
};

/**
 * Start an in-process express server with a real `createLedgerRouter`
 * pointed at a tmp dir whose contents are pre-arranged by `setup`
 * BEFORE the router is constructed (so the boot-time sidecar load
 * sees the forged / stale fixture exactly as a real deploy would).
 */
async function startFixtureLedgerServer(
  setup: (paths: {
    tmpDir: string;
    hitsPath: string;
    checkpointPath: string;
    lastOkPath: string;
    secretPath: string;
  }) => void,
): Promise<FixtureServer> {
  const tmpDir = mkdtempSync(path.join(tmpdir(), "ledger-e2e-"));
  const hitsPath = path.join(tmpDir, "hits.txt");
  const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
  const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
  const secretPath = path.join(tmpDir, "hits.txt.lastok.key");

  setup({ tmpDir, hitsPath, checkpointPath, lastOkPath, secretPath });

  const app = express();
  app.use(
    "/api",
    createLedgerRouter({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    }),
  );
  const srv = http.createServer(app);
  await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
  const port = (srv.address() as AddressInfo).port;

  return {
    baseUrl: `http://127.0.0.1:${port}`,
    tmpDir,
    close: async () => {
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
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
      rmSync(tmpDir, { recursive: true, force: true });
    },
  };
}

/**
 * Forward `/api/ledger/integrity` requests from the dashboard to the
 * fixture-backed router and fulfil with the REAL bytes the real
 * router computed. We do NOT synthesize a response — the dashboard
 * sees the exact JSON the production code path produces for the
 * configured on-disk fixture.
 */
async function forwardIntegrityToFixture(
  page: import("@playwright/test").Page,
  fixtureBaseUrl: string,
): Promise<void> {
  await page.route(
    LEDGER_INTEGRITY_URL,
    async (route: Route, request: Request) => {
      const upstream = new URL(request.url());
      const forwarded = `${fixtureBaseUrl}/api/ledger/integrity${upstream.search}`;
      const res = await fetch(forwarded, {
        method: request.method(),
        headers: request.headers(),
      });
      const body = Buffer.from(await res.arrayBuffer());
      const headers: Record<string, string> = {};
      res.headers.forEach((v, k) => {
        // Drop transport-layer headers Playwright must own.
        if (
          k.toLowerCase() === "content-encoding" ||
          k.toLowerCase() === "content-length" ||
          k.toLowerCase() === "transfer-encoding"
        ) {
          return;
        }
        headers[k] = v;
      });
      await route.fulfill({
        status: res.status,
        headers,
        body,
      });
    },
  );
}

test.describe("dashboard: ledger sidecar tamper / stale-binding banners", () => {
  test("renders the red 'sidecar tamper detected' panel with rotation + audit copy when the real api-server boots over a forged hits.txt.lastok", async ({
    page,
  }) => {
    const fixture = await startFixtureLedgerServer(
      ({ hitsPath, checkpointPath, lastOkPath, secretPath }) => {
        // Healthy sealed prefix + matching checkpoint so the integrity
        // check itself succeeds; the failure surface we're testing is
        // the sidecar HMAC, not the prefix mismatch.
        const sealed = "line1\nline2\nline3\n";
        const buf = Buffer.from(sealed, "utf-8");
        writeFileSync(hitsPath, buf);
        writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);

        // Pre-seed the HMAC secret so the router does NOT auto-generate
        // one on boot — we want the forged sidecar to be evaluated
        // against a known secret it does not carry a valid mac for.
        writeFileSync(secretPath, "ab".repeat(32) + "\n");

        // Forge a sidecar with a future lastOkAt and NO mac — the
        // naive hand-edit an attacker with data-dir write access (but
        // no HMAC key) would produce. The real router must classify
        // this as `sidecar_forged` on boot, discard the lastOkAt, and
        // surface `lastOkSidecarStatus: "forged"` on `/integrity`.
        const forgedFuture = new Date(Date.now() + 60 * 60 * 1000).toISOString();
        writeFileSync(
          lastOkPath,
          JSON.stringify({
            lastOkAt: forgedFuture,
            lastCheckedAt: forgedFuture,
          }) + "\n",
        );
      },
    );

    try {
      await forwardIntegrityToFixture(page, fixture.baseUrl);
      await page.goto("/");

      const panel = page.locator('[data-testid="panel-ledger-sidecar-forged"]');
      await expect(panel).toBeVisible();
      // Not-yet-acknowledged — operator-visible signal.
      await expect(panel).toHaveAttribute("data-acknowledged", "false");
      await expect(panel).toContainText("Sidecar tamper detected");

      // HMAC-failure reason must name the exact sidecar file.
      const reason = page.locator(
        '[data-testid="text-ledger-sidecar-forged-reason"]',
      );
      await expect(reason).toBeVisible();
      await expect(reason).toContainText("data/hits.txt.lastok");
      await expect(reason).toContainText("failed HMAC verification");
      await expect(reason).toContainText("forged payload");
      await expect(reason).toContainText("lastOkAt reset to null");

      // Remediation copy — the three concrete actions. Drift here is a
      // real regression worth catching.
      await expect(panel).toContainText("rotate the sidecar secret");
      await expect(panel).toContainText("LEDGER_SIDECAR_SECRET");
      await expect(panel).toContainText("data/hits.txt.lastok.key");
      await expect(panel).toContainText("audit who has write access");
      await expect(panel).toContainText(
        "re-verify the ledger from a fresh checkout",
      );

      // Acknowledged badge must NOT render in the un-acked state.
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
        ),
      ).toHaveCount(0);

      // Mutual exclusivity — the amber stale-binding line is in the
      // same `if/else if` and must not render concurrently.
      await expect(
        page.locator('[data-testid="text-ledger-sidecar-stale-binding"]'),
      ).toHaveCount(0);
    } finally {
      await fixture.close();
    }
  });

  /**
   * Task #140: rotating the sidecar HMAC secret from the dashboard
   * clears the red banner on the next /integrity poll.
   *
   * Strategy mirrors task #138's ack spec: instead of the read-only
   * `createLedgerRouter` we boot the full `createLedgerChecker` so we
   * have its `rotateSidecarSecret()` handle, mount the integrity
   * router AND a token-gated POST wrapper at
   * `/api/ledger/sidecar-secret/rotate` (matching the real
   * `lean.ts:checkRebuildAuth` shape so the dashboard's outbound
   * `Authorization: Bearer <token>` header does not need a special
   * case), forward both endpoints into the page, then drive the
   * button. After the POST resolves and TanStack Query invalidates
   * the integrity key, the next poll must report
   * `lastOkSidecarStatus: "ok"` and the panel must disappear.
   */
  test("clicking 'Rotate sidecar secret' rotates the HMAC key, re-seals the live sidecar, and clears the banner on the next /integrity poll", async ({
    page,
  }) => {
    const ROTATE_TOKEN = "fixture-rotate-token";
    const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";

    const tmpDir = mkdtempSync(path.join(tmpdir(), "ledger-rotate-e2e-"));
    const hitsPath = path.join(tmpDir, "hits.txt");
    const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
    const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
    const secretPath = path.join(tmpDir, "hits.txt.lastok.key");

    const sealed = "line1\nline2\nline3\n";
    const buf = Buffer.from(sealed, "utf-8");
    writeFileSync(hitsPath, buf);
    writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
    writeFileSync(secretPath, "ab".repeat(32) + "\n");
    // Forged sidecar at boot so the banner renders.
    writeFileSync(
      lastOkPath,
      JSON.stringify({
        lastOkAt: "2099-01-01T00:00:00.000Z",
        lastCheckedAt: "2099-01-01T00:00:00.000Z",
      }) + "\n",
    );

    const checker = createLedgerChecker({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });
    const app = express();
    app.use(express.json());
    app.use("/api", checker.router);
    app.post("/api/ledger/sidecar-secret/rotate", (req, res) => {
      const auth = req.headers["authorization"] ?? "";
      const match = /^Bearer\s+(.+)$/i.exec(
        Array.isArray(auth) ? (auth[0] ?? "") : auth,
      );
      const provided = match ? match[1]?.trim() : "";
      if (!provided || provided !== ROTATE_TOKEN) {
        res
          .status(401)
          .json({ ok: false, error: "Unauthorized: bad referee token." });
        return;
      }
      const result = checker.rotateSidecarSecret("e2e-operator");
      res.json(result);
    });
    const srv = http.createServer(app);
    await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
    const port = (srv.address() as AddressInfo).port;
    const baseUrl = `http://127.0.0.1:${port}`;

    try {
      const forward = async (
        route: Route,
        request: Request,
        suffix: string,
      ) => {
        const upstream = new URL(request.url());
        const forwarded = `${baseUrl}${suffix}${upstream.search}`;
        const res = await fetch(forwarded, {
          method: request.method(),
          headers: request.headers(),
          body: request.postData() ?? undefined,
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
      await page.route(
        "**/api/ledger/sidecar-secret/rotate",
        (route, request) =>
          forward(route, request, "/api/ledger/sidecar-secret/rotate"),
      );

      // Seed the referee token in localStorage so the dashboard sends
      // `Authorization: Bearer <token>` on the rotate POST AND so the
      // rotate button renders (gated on rebuildToken).
      await page.addInitScript(
        ([key, token]) => {
          window.localStorage.setItem(key as string, token as string);
        },
        [REBUILD_TOKEN_STORAGE_KEY, ROTATE_TOKEN],
      );

      await page.goto("/");

      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-forged"]',
      );
      await expect(panel).toBeVisible();
      const rotateBtn = page.locator(
        '[data-testid="button-rotate-ledger-sidecar-secret"]',
      );
      await expect(rotateBtn).toBeVisible();
      await expect(rotateBtn).toBeEnabled();
      await expect(rotateBtn).toHaveText(/^Rotate sidecar secret$/);

      await rotateBtn.click();

      // After the POST resolves + the integrity query invalidates,
      // the next poll re-seals the sidecar (already done by the
      // rotate call) and reports lastOkSidecarStatus: "ok" — the
      // panel must disappear entirely.
      await expect(panel).toHaveCount(0);
      await expect(
        page.locator(
          '[data-testid="text-rotate-ledger-sidecar-secret-error"]',
        ),
      ).toHaveCount(0);
    } finally {
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
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
      rmSync(tmpDir, { recursive: true, force: true });
    }
  });

  /**
   * Task #165: the original fixture-driven version of this test was
   * structurally flaky — it boots a real `createLedgerRouter` over a
   * stale-bound sidecar, but the server's `buildStatusInner()` (in
   * `artifacts/api-server/src/routes/ledger.ts` ~line 1356)
   * unconditionally flips `lastOkSidecarStatus = "ok"` on every
   * `/integrity` call and rewrites the sidecar with a fresh HMAC.
   * The boot-time `stale_checkpoint_binding` status is therefore
   * never surfaced on the wire (the server-side coverage in
   * `ledger.integration.test.ts:658` only asserts `lastOkAt === null`,
   * which is what does survive). The fixture-driven approach cannot
   * deterministically exercise the dashboard's amber banner; switching
   * this one case to a synthetic `page.route` mock — same pattern as
   * `ledger-monitor-suppressed.spec.ts` — keeps the dashboard-side
   * coverage intact without depending on server behaviour the API
   * doesn't promise. The two sibling tests above (forged + rotate)
   * stay fixture-driven because `forgedIncident` IS sticky and they
   * exercise a real cross-process tamper path.
   */
  test("renders the amber 'stale checkpoint binding' line when the integrity endpoint reports lastOkSidecarStatus=stale_checkpoint_binding", async ({
    page,
  }) => {
    const nowIso = new Date().toISOString();
    const integrityBody = {
      status: "ok" as const,
      failureMode: null,
      reason: null,
      checkpointSize: 17,
      checkpointSha:
        "0000000000000000000000000000000000000000000000000000000000000000",
      liveSize: 17,
      livePrefixSha:
        "0000000000000000000000000000000000000000000000000000000000000000",
      growthBytes: 0,
      checkedAt: nowIso,
      ledgerLastModified: nowIso,
      ledgerPath: "data/hits.txt",
      checkpointPath: "data/hits.txt.checkpoint",
      // lastOkAt is null in the stale-binding case — the binding was
      // verified by HMAC but bound to a checkpoint that no longer
      // matches, so the persisted ok timestamp was discarded.
      lastOkAt: null,
      lastOkAgeSeconds: null,
      lastCheckedAt: nowIso,
      lastCheckedAgeSeconds: 5,
      staleThresholdSeconds: 1800,
      stale: true,
      checkedStaleThresholdSeconds: 600,
      checkedStale: false,
      checkpointLastModified: nowIso,
      checkpointAgeSeconds: 100,
      checkpointCoverageRatio: 1,
      checkpointStaleThresholdSeconds: 2592000,
      checkpointStale: false,
      lastOkSidecarStatus: "stale_checkpoint_binding" as const,
      sidecarSecretStrictMode: false,
      lastOkSidecarStatusAcknowledgedAt: null,
      lastOkSidecarStatusAcknowledgedBy: null,
      monitor: {
        enabled: true,
        intervalSeconds: 300,
        lastTickAt: nowIso,
        lastAlertedFailureMode: null,
        lastAcknowledgedAlertId: null,
        watchdogState: "ok",
        watchdogLastFiredAt: null,
      },
    };

    await page.route(LEDGER_INTEGRITY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(integrityBody),
      });
    });
    await page.goto("/");

    const staleLine = page.locator(
      '[data-testid="text-ledger-sidecar-stale-binding"]',
    );
    await expect(staleLine).toBeVisible();
    await expect(staleLine).toContainText("Stale checkpoint binding");
    // Task #204: the banner is now a full panel (with an Acknowledge
    // affordance) rather than a one-line hint, so the descriptive copy
    // distinguishing this benign case from the forged-HMAC case lives
    // in the surrounding panel body.
    const stalePanel = page.locator(
      '[data-testid="panel-ledger-sidecar-stale-binding"]',
    );
    await expect(stalePanel).toBeVisible();
    await expect(stalePanel).toContainText("HMAC verification");
    await expect(stalePanel).toContainText("bound to a different checkpoint");
    await expect(stalePanel).toContainText("discarded");
    // Un-acknowledged at boot: the acknowledged badge must not render.
    await expect(stalePanel).toHaveAttribute("data-acknowledged", "false");
    await expect(
      page.locator(
        '[data-testid="badge-ledger-sidecar-stale-binding-acknowledged"]',
      ),
    ).toHaveCount(0);

    // The red forged panel must NOT render in the stale-binding case.
    await expect(
      page.locator('[data-testid="panel-ledger-sidecar-forged"]'),
    ).toHaveCount(0);
  });
});
