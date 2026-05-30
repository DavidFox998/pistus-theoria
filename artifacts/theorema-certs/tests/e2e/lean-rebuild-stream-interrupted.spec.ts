import { test, expect, type Route, type Request } from "@playwright/test";
import http from "node:http";
import type { AddressInfo, Socket } from "node:net";

/**
 * Task #227: pin the Lean-rebuild live-log panel's behaviour against a
 * *real broken stream*.
 *
 * This is the sibling of `checkpoint-reroll-stream-interrupted.spec.ts`
 * (task #201). The Lean-rebuild streaming path (`streamRebuild()` in
 * `src/pages/dashboard.tsx`) had the exact same bug the re-roll path
 * had: it read the SSE body in a `while (true)` loop with no try/catch
 * around `reader.read()`. If the SSE forwarder in
 * `artifacts/api-server/src/routes/lean.ts` swallows a mid-stream error
 * (proxy drops the connection, the spawned `regenerate.sh` is
 * OOM-killed, the server crashes) the connection is *forcibly
 * terminated* mid-`PROGRESS:` with no `result` frame. `reader.read()`
 * then rejects instead of returning `done`.
 *
 * Before task #227, that rejection escaped `streamRebuild()` entirely;
 * the rebuild button's onClick `finally` cleared the spinner and the
 * rebuild live-log panel froze on the last line with no error — the
 * operator never learned the rebuild had actually failed.
 *
 * Playwright's `route.fulfill` can only deliver a *complete* response
 * (the socket always closes cleanly), so it cannot reproduce a forcible
 * mid-stream termination. Instead we stand up a tiny real HTTP server
 * that writes a couple of SSE `line` frames and then destroys the
 * socket, and 307-redirect the dashboard's rebuild stream POST to it.
 * The browser follows the redirect, renders the progress lines, then
 * sees the connection drop — exactly the production failure mode.
 *
 * Asserts:
 *   1. `panel-rebuild-live-log` becomes visible and shows the streamed
 *      PROGRESS line (so we know lines really were rendered first).
 *   2. After the socket is destroyed, `text-rebuild-message` surfaces a
 *      visible "rebuild stream interrupted" error state.
 *   3. The button leaves the "Rebuilding…" state (no frozen spinner).
 */

const VERIFY_URL = "**/api/lean/verify";
const HISTORY_URL = "**/api/lean/verify/history*";
const STREAM_URL = "**/api/lean/verify/rebuild/stream*";
const ALERTS_URL = "**/api/lean/ledger-alerts*";
const INTEGRITY_URL = "**/api/ledger/integrity*";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";
const REBUILD_REFEREE_STORAGE_KEY = "lean-rebuild-referee-name";
const FIXTURE_TOKEN = "fixture-token";
const FIXTURE_REFEREE = "alice";

function verifyPayload(): Record<string, unknown> {
  return {
    toolchain: "leanprover/lean4:v4.12.0",
    dateVerified: "2026-05-30",
    axiomDebt: [],
    axiomLines: ["'TheoremaAureum.main_theorem' does not depend on any axioms"],
    content: "VERIFY.txt contents",
    lastModified: new Date().toISOString(),
    ageDays: 1,
  };
}

/**
 * Boot a real HTTP server that emits a couple of SSE `line` frames and
 * then holds the connection open until the test calls `cut()`, at which
 * point it forcibly destroys the socket mid-PROGRESS — never sending a
 * `result` frame nor the chunked terminator, so the browser's
 * `reader.read()` rejects with a network error.
 *
 * Driving the cut from the test (rather than a fixed server-side timer)
 * removes the race against a CI browser that may be slow to follow the
 * cross-origin 307 redirect and render the progress lines under
 * full-suite load. CORS is wide open (and OPTIONS is handled) because
 * the dashboard reaches it via a cross-origin 307 redirect from the
 * Vite dev origin.
 */
function bootBrokenStreamServer(): Promise<{
  url: string;
  cut: () => void;
  close: () => Promise<void>;
}> {
  let activeSocket: Socket | null = null;
  const srv = http.createServer((req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "*");
    res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    if (req.method === "OPTIONS") {
      res.writeHead(204);
      res.end();
      return;
    }
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
    });
    const send = (event: string, data: unknown) => {
      res.write(`event: ${event}\n`);
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    };
    send("line", {
      stream: "stdout",
      line: "STEP: rebuilding Lean proof tower",
    });
    send("line", { stream: "stderr", line: "PROGRESS: 50%" });
    // Hold the socket open. The test calls `cut()` only after it has
    // confirmed the browser rendered the PROGRESS line, so the
    // mid-stream termination is deterministic rather than timer-raced.
    activeSocket = res.socket ?? null;
  });
  return new Promise((resolve) => {
    srv.listen(0, "127.0.0.1", () => {
      const port = (srv.address() as AddressInfo).port;
      resolve({
        url: `http://127.0.0.1:${port}/broken-stream`,
        cut: () => {
          activeSocket?.destroy();
        },
        close: () =>
          new Promise<void>((r) => {
            // Destroy any still-open stream socket too, so `srv.close()`
            // resolves even if the test bailed before calling `cut()`.
            activeSocket?.destroy();
            srv.close(() => r());
          }),
      });
    });
  });
}

test.describe("dashboard: lean rebuild live log against a broken stream (task #227)", () => {
  test("a stream forcibly terminated mid-PROGRESS surfaces an interrupted error instead of freezing", async ({
    page,
  }) => {
    const broken = await bootBrokenStreamServer();

    await page.route(VERIFY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(verifyPayload()),
      });
    });
    await page.route(INTEGRITY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ ok: true }),
      });
    });
    await page.route(ALERTS_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          alerts: [],
          fileExists: false,
          totalLines: 0,
          truncated: false,
          rotation: 0,
          availableRotations: [],
          ackGcDropped: 0,
        }),
      });
    });
    await page.route(HISTORY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ capacity: 20, entries: [] }),
      });
    });

    // Redirect the dashboard's rebuild stream POST to the real
    // broken-stream server. 307 preserves the POST method; the browser
    // follows it cross-origin and reads the partial SSE body until the
    // socket dies.
    await page.route(STREAM_URL, async (route: Route, request: Request) => {
      const auth = request.headers()["authorization"] ?? "";
      if (!/^Bearer\s+fixture-token$/i.test(auth)) {
        await route.fulfill({
          status: 401,
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ error: "unauthorized" }),
        });
        return;
      }
      await route.fulfill({
        status: 307,
        headers: { location: broken.url },
        body: "",
      });
    });

    await page.addInitScript(
      ([tokenKey, token, refKey, referee]) => {
        window.localStorage.setItem(tokenKey as string, token as string);
        window.localStorage.setItem(refKey as string, referee as string);
      },
      [
        REBUILD_TOKEN_STORAGE_KEY,
        FIXTURE_TOKEN,
        REBUILD_REFEREE_STORAGE_KEY,
        FIXTURE_REFEREE,
      ],
    );

    try {
      await page.goto("/");

      const rebuildButton = page.locator(
        '[data-testid="button-rebuild-lean-log"]',
      );
      await expect(rebuildButton).toBeVisible();
      await expect(rebuildButton).toBeEnabled();
      await rebuildButton.click();

      // The progress lines really render before the break, so this is a
      // genuine mid-stream interruption, not a connection that never
      // produced output.
      const livePanel = page.locator('[data-testid="panel-rebuild-live-log"]');
      await expect(livePanel).toBeVisible();
      const liveLog = page.locator('[data-testid="text-rebuild-live-log"]');
      await expect(liveLog).toContainText("! PROGRESS: 50%");

      // Now that the progress line has really rendered, force the
      // mid-stream termination. Driving it from the test (rather than a
      // server-side timer) guarantees the frames were read first, so the
      // assertion below isn't racing a slow CI browser.
      broken.cut();

      // The interruption is surfaced as a visible error instead of the
      // panel freezing on the last line.
      const message = page.locator('[data-testid="text-rebuild-message"]');
      await expect(message).toBeVisible();
      await expect(message).toContainText(/interrupted/i);

      // The button is no longer stuck in the "Rebuilding…" spinner state.
      await expect(rebuildButton).not.toHaveText(/Rebuilding/);
      await expect(rebuildButton).toBeEnabled();
    } finally {
      await broken.close();
    }
  });
});
