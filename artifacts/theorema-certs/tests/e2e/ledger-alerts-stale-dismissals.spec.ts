import { test, expect, type Route } from "@playwright/test";

/**
 * Task #135: end-to-end coverage for the "X stale dismissal(s) cleaned up"
 * suffix added by task #119 to the Recent ledger alerts panel header.
 *
 * The suffix is driven by `ackGcDropped` on `GET /api/lean/ledger-alerts`,
 * which counts ack-sidecar entries whose alerts have rolled off the live
 * log and were therefore garbage-collected on read. The API contract is
 * already pinned by `artifacts/api-server/src/routes/lean.integration.test.ts`
 * but the dashboard render path
 * (`artifacts/theorema-certs/src/pages/dashboard.tsx` ~1432–1438) was not
 * covered — a regression in pluralization, missing-when-positive, or
 * leaking-when-zero would ship silently.
 *
 * We mock `/api/lean/ledger-alerts*` via Playwright route interception so
 * the test is deterministic and does not depend on driving the real ack
 * sidecar GC into firing inside the api-server process under test.
 *
 * Selectors / copy under test:
 *   - `[data-testid="panel-ledger-alerts"]`
 *   - `[data-testid="text-ledger-alerts-count"]` should:
 *       * include `N stale dismissals cleaned up` (plural) when N>1
 *       * include `1 stale dismissal cleaned up` (singular) when N==1
 *       * NOT include any "stale dismissal" copy when N==0
 */

const LEDGER_ALERTS_URL = "**/api/lean/ledger-alerts*";

function buildAlertsResponse(ackGcDropped: number) {
  return {
    alerts: [
      {
        id: "stale-dismissals-test-id",
        acknowledgedAt: null,
        timestamp: new Date().toISOString(),
        workflow: "zeta-burst-101-10000",
        message:
          "Ledger checkpoint verification failed: live prefix sha mismatch",
        failureMode: "live_prefix_sha_mismatch",
        recovery: null,
        hitsPath: "data/hits.txt",
        checkpointPath: "data/hits.txt.checkpoint",
        expectedSize: 1024,
        actualSize: 1024,
        expectedSha:
          "0000000000000000000000000000000000000000000000000000000000000000",
        source: "kernel._verify_checkpoint",
        delivery: {
          webhook: { status: "ok", error: null, inflight: 0, cap: 8 },
          email: { status: "ok", error: null, inflight: 0, cap: 8 },
        },
      },
    ],
    limit: 50,
    totalReturned: 1,
    logPath: "data/ledger-alerts.jsonl",
    logExists: true,
    ackGcDropped,
    rotation: 0,
    availableRotations: [],
  };
}

async function installMock(
  page: import("@playwright/test").Page,
  ackGcDropped: number,
) {
  await page.route(LEDGER_ALERTS_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildAlertsResponse(ackGcDropped)),
    });
  });
}

/**
 * Task #184: the dashboard's `useGetLedgerAlerts` query has a 30s
 * `refetchInterval` on the live rotation (see dashboard.tsx). Rather
 * than tearing down + cold-loading the SPA again with `page.reload()`
 * between phases, install Playwright's virtual clock and fast-forward
 * past one refetch tick — same observable result, but the test does
 * not actually sleep and does not pay the Vite SPA boot cost twice.
 * 31s is just past the 30s `refetchInterval`, which guarantees
 * exactly one refetch fires.
 */
const ALERTS_REFETCH_TICK_MS = 31_000;

test.describe("dashboard: ledger alerts 'stale dismissals cleaned up' suffix", () => {
  test("renders the plural suffix when ackGcDropped > 1, and singular when ==1", async ({
    page,
  }) => {
    await page.clock.install({ time: Date.now() });

    // Phase 1: plural (3 stale dismissals cleaned up).
    await installMock(page, 3);
    await page.goto("/");

    const panel = page.locator('[data-testid="panel-ledger-alerts"]');
    await expect(panel).toBeVisible();

    const counter = page.locator('[data-testid="text-ledger-alerts-count"]');
    await expect(counter).toBeVisible();
    await expect(counter).toContainText("1 entry");
    await expect(counter).toContainText("3 stale dismissals cleaned up");

    // Phase 2: singular (exactly 1) — proves the pluralization branch
    // toggles correctly on the next refetch.
    await page.unroute(LEDGER_ALERTS_URL);
    await installMock(page, 1);
    await page.clock.fastForward(ALERTS_REFETCH_TICK_MS);
    await expect(panel).toBeVisible();
    await expect(counter).toContainText("1 stale dismissal cleaned up");
    // Must not also be matching the plural form.
    await expect(counter).not.toContainText("stale dismissals cleaned up");
  });

  test("omits the suffix entirely when ackGcDropped == 0", async ({
    page,
  }) => {
    await page.clock.install({ time: Date.now() });

    // Start with a positive count so we know the suffix branch fires...
    await installMock(page, 2);
    await page.goto("/");

    const counter = page.locator('[data-testid="text-ledger-alerts-count"]');
    await expect(counter).toContainText("2 stale dismissals cleaned up");

    // ...then flip to 0 and confirm the suffix disappears on the next
    // refetch tick (no SPA reload required).
    await page.unroute(LEDGER_ALERTS_URL);
    await installMock(page, 0);
    await page.clock.fastForward(ALERTS_REFETCH_TICK_MS);
    await expect(counter).toBeVisible();
    await expect(counter).toContainText("1 entry");
    await expect(counter).not.toContainText("stale dismissal");
  });
});
