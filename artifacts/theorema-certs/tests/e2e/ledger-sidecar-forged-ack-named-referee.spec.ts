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
import { createLedgerChecker } from "../../../api-server/src/routes/ledger.js";

/**
 * Task #151: end-to-end coverage for the named-referee attribution on
 * the sidecar tamper "acknowledged" badge.
 *
 * Task #139 added the referee name to the dashboard badge tooltip
 * ("Acknowledged by alice at <ISO>") and inlined the name next to
 * the badge text ("acknowledged · alice"). It also surfaces the
 * attribution as a `data-acked-by` attribute on
 * `badge-ledger-sidecar-forged-acknowledged`. A unit test pins the
 * API contract (`lastOkSidecarStatusAcknowledgedBy` field) but the
 * rendered UI had no end-to-end coverage, so a future dashboard
 * refactor could silently drop the attribution surface.
 *
 * Strategy mirrors `ledger-sidecar-forged-ack.spec.ts` (task #138):
 * boot an in-process express server backed by a real
 * `createLedgerChecker`, point the dashboard's `/api/ledger/integrity`
 * and `/api/ledger/sidecar-forged-ack` calls at it via `page.route`.
 *
 * The wrapper around `POST /api/ledger/sidecar-forged-ack` mirrors
 * the production named-token attribution path: a small in-fixture
 * map turns the bearer token into a referee name and passes it to
 * `checker.acknowledgeForgedSidecar(name)` — exactly what the real
 * `lean.ts` route does when `LEAN_REBUILD_TOKENS=alice:...` is set
 * and the named-token branch wins over `X-Referee-Name`. The
 * dashboard's `useAckSidecarForged` hook only sends the
 * `Authorization` header (no `X-Referee-Name` for the ack call), so
 * the named-token map is the realistic mechanism for getting a name
 * on the acknowledged badge through this surface.
 *
 * Assertions:
 *  - inline text after the badge label reads "· alice"
 *  - `data-acked-by` attribute equals "alice"
 *  - `title` attribute reads "Acknowledged by alice at <ISO>" where
 *    the ISO matches the server-issued `acknowledgedAt`
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
const LEDGER_ACK_URL = "**/api/ledger/sidecar-forged-ack";
const FIXTURE_REFEREE_NAME = "alice";
const FIXTURE_NAMED_TOKEN = "alice-named-token-fixture";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";

function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

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

  // In-fixture named-token → referee-name map. Mirrors the production
  // `LEAN_REBUILD_TOKENS=alice:<token>,bob:<token>` parser: a bearer
  // token that matches a named entry resolves to that name and is
  // authoritative — `X-Referee-Name` headers are ignored (and the
  // dashboard's ack mutation doesn't send one in any case).
  const namedTokens = new Map<string, string>([
    [FIXTURE_NAMED_TOKEN, FIXTURE_REFEREE_NAME],
  ]);

  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  app.post("/api/ledger/sidecar-forged-ack", (req, res) => {
    const auth = req.headers["authorization"] ?? "";
    const match = /^Bearer\s+(.+)$/i.exec(
      Array.isArray(auth) ? (auth[0] ?? "") : auth,
    );
    const provided = match ? match[1]?.trim() : "";
    if (!provided) {
      res
        .status(401)
        .json({ ok: false, error: "Unauthorized: bad referee token." });
      return;
    }
    const refereeName = namedTokens.get(provided) ?? null;
    if (refereeName === null) {
      res
        .status(401)
        .json({ ok: false, error: "Unauthorized: bad referee token." });
      return;
    }
    const result = checker.acknowledgeForgedSidecar(refereeName);
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
      ackedBy: result.ackedBy,
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

test.describe("dashboard: sidecar tamper acknowledged badge surfaces the referee name (task #151)", () => {
  test("named-referee Acknowledge renders inline name + tooltip + data-acked-by on the badge", async ({
    page,
  }) => {
    const tmpDir = mkdtempSync(
      path.join(tmpdir(), "ledger-ack-named-referee-e2e-"),
    );
    const hitsPath = path.join(tmpDir, "hits.txt");
    const checkpointPath = path.join(tmpDir, "hits.txt.checkpoint");
    const lastOkPath = path.join(tmpDir, "hits.txt.lastok");
    const secretPath = path.join(tmpDir, "hits.txt.lastok.key");

    const sealed = "line1\nline2\nline3\n";
    const buf = Buffer.from(sealed, "utf-8");
    writeFileSync(hitsPath, buf);
    writeFileSync(checkpointPath, `${buf.length} ${sha256(buf)}\n`);
    writeFileSync(secretPath, "ab".repeat(32) + "\n");
    writeForgedSidecar(lastOkPath, "payload-v1-named");

    let active = await bootFixture({
      hitsPath,
      checkpointPath,
      lastOkPath,
      secretPath,
    });

    try {
      // Task #184: install the Playwright virtual clock for parity
      // with `ledger-sidecar-forged-ack.spec.ts`. This spec doesn't
      // simulate a restart, but the install also stops the
      // dashboard's 1s `setNowMs` interval from waking the page on
      // its own under parallel-worker CPU contention, so the test
      // stays well under 10s even on a hot box.
      await page.clock.install({ time: Date.now() });
      await installForwarders(page, () => active);

      // Seed the bearer token that the in-fixture named-token map
      // resolves to "alice". The dashboard reads this from
      // localStorage and sends it as Authorization: Bearer <token>.
      await page.addInitScript(
        ([key, token]) => {
          window.localStorage.setItem(key as string, token as string);
        },
        [REBUILD_TOKEN_STORAGE_KEY, FIXTURE_NAMED_TOKEN],
      );

      await page.goto("/");

      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-forged"]',
      );
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");

      const ackButton = page.locator(
        '[data-testid="button-ack-ledger-sidecar-forged"]',
      );
      await expect(ackButton).toBeEnabled();
      await ackButton.click();

      await expect(panel).toHaveAttribute("data-acknowledged", "true");

      const badge = page.locator(
        '[data-testid="badge-ledger-sidecar-forged-acknowledged"]',
      );
      await expect(badge).toBeVisible();

      // Inline attribution: the badge's text content is "acknowledged"
      // followed by "· alice" rendered as a normal-case span. We assert
      // both pieces in the visible text.
      await expect(badge).toHaveText(/acknowledged/i);
      await expect(badge).toContainText(`· ${FIXTURE_REFEREE_NAME}`);

      // data-acked-by attribute carries the raw name (task #139).
      await expect(badge).toHaveAttribute(
        "data-acked-by",
        FIXTURE_REFEREE_NAME,
      );

      // title attribute reads "Acknowledged by alice at <ISO>". Pull
      // the ISO from the title and assert the shape so the test
      // doesn't race the server clock.
      const title = await badge.getAttribute("title");
      expect(title).not.toBeNull();
      const expectedPrefix = `Acknowledged by ${FIXTURE_REFEREE_NAME} at `;
      expect(title).toMatch(
        new RegExp(
          `^Acknowledged by ${FIXTURE_REFEREE_NAME} at \\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$`,
        ),
      );
      const iso = title!.slice(expectedPrefix.length);
      expect(() => new Date(iso).toISOString()).not.toThrow();
      expect(new Date(iso).toISOString()).toBe(iso);
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
