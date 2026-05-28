import { test, expect, type Route } from "@playwright/test";

/**
 * Task #128: end-to-end coverage for the "WATCHDOG FIRED — MONITOR STALLED"
 * red badge added to the Ledger Integrity card.
 *
 * Task #113 added an in-process watchdog that pushes a `monitor_stalled`
 * alert when no integrity tick has completed in 2× the configured
 * monitor interval. Task #128 then surfaces that state in the dashboard
 * via two new fields on `GET /api/ledger/integrity` → `monitor`:
 * `watchdogState` (`ok` | `stalled` | null) and `watchdogLastFiredAt`
 * (ISO-8601 | null). This spec mocks the endpoint so we can flip those
 * fields deterministically without driving the real watchdog timer.
 *
 * Selectors / copy under test:
 *   - `[data-testid="text-ledger-monitor-watchdog"]` carries
 *     `data-watchdog-state="ok"|"stalled"` and
 *     `data-watchdog-fired-at` with the ISO timestamp (or "").
 *   - Red badge fires when `watchdogState === "stalled"`; copy starts
 *     with "watchdog fired — monitor stalled".
 *   - Amber recovered-recently badge fires when `watchdogState === "ok"`
 *     but `watchdogLastFiredAt` is set; copy starts with
 *     "watchdog recovered".
 *   - Nothing renders when `watchdogState === "ok"` and
 *     `watchdogLastFiredAt === null` (the steady-state healthy case).
 *
 * Task #184: rewritten to drive `page.clock` instead of `page.reload()`
 * + wall-clock waits. Flipping the mock state and fast-forwarding past
 * the dashboard's 30s `refetchInterval` for `useGetLedgerIntegrity`
 * triggers an in-place React Query refetch, so the test gets the same
 * observable behaviour without paying the Vite SPA cold-start cost
 * twice per test. The "relative-age ticks up" sub-test fast-forwards
 * the 1s `setNowMs` interval virtually instead of sleeping for ~2s.
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
// 31s — just past the 30s `refetchInterval` on
// `useGetLedgerIntegrity` (see dashboard.tsx). One fastForward of
// this size is enough to trigger exactly one refetch.
const INTEGRITY_REFETCH_TICK_MS = 31_000;

type WatchdogOverrides = {
  watchdogState: "ok" | "stalled" | null;
  watchdogLastFiredAt: string | null;
};

function buildLedgerIntegrityBody(
  overrides: WatchdogOverrides,
  nowIso: string,
) {
  return {
    status: "ok",
    failureMode: null,
    reason: null,
    checkpointSize: 1024,
    checkpointSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    liveSize: 1024,
    livePrefixSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    growthBytes: 0,
    checkedAt: nowIso,
    ledgerLastModified: nowIso,
    ledgerPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    lastOkAt: nowIso,
    lastOkAgeSeconds: 5,
    lastCheckedAt: nowIso,
    lastCheckedAgeSeconds: 5,
    staleThresholdSeconds: 1800,
    stale: false,
    checkedStaleThresholdSeconds: 600,
    checkedStale: false,
    checkpointLastModified: nowIso,
    checkpointAgeSeconds: 100,
    checkpointCoverageRatio: 1,
    checkpointStaleThresholdSeconds: 2592000,
    checkpointStale: false,
    lastOkSidecarStatus: "ok",
    lastOkSidecarStatusAcknowledgedAt: null,
    monitor: {
      enabled: true,
      intervalSeconds: 300,
      lastTickAt: nowIso,
      lastAlertedFailureMode: null,
      lastAcknowledgedAlertId: null,
      watchdogState: overrides.watchdogState,
      watchdogLastFiredAt: overrides.watchdogLastFiredAt,
    },
  };
}

async function installLedgerIntegrityMock(
  page: import("@playwright/test").Page,
  overridesRef: { current: WatchdogOverrides },
  nowIso: string,
) {
  await page.route(LEDGER_INTEGRITY_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(
        buildLedgerIntegrityBody(overridesRef.current, nowIso),
      ),
    });
  });
}

test.describe("dashboard: ledger monitor watchdog badge", () => {
  test("renders red 'WATCHDOG FIRED' badge when stalled, amber recovered badge after recovery, and nothing in the steady-state healthy case", async ({
    page,
  }) => {
    // Anchor the page clock so the dashboard's `Date.now()` matches
    // our `firedAt` deterministically and the fastForward we use to
    // trigger the 30s refetchInterval doesn't drift relative to any
    // ages baked into the mock body.
    const anchorMs = Date.now();
    await page.clock.install({ time: anchorMs });
    const anchorIso = new Date(anchorMs).toISOString();
    const firedAt = new Date(anchorMs - 30_000).toISOString();

    const overridesRef: { current: WatchdogOverrides } = {
      current: {
        watchdogState: "stalled",
        watchdogLastFiredAt: firedAt,
      },
    };

    await installLedgerIntegrityMock(page, overridesRef, anchorIso);

    // Stalled path.
    await page.goto("/");

    const watchdogBlock = page.locator(
      '[data-testid="text-ledger-monitor-watchdog"]',
    );
    await expect(watchdogBlock).toBeVisible();
    await expect(watchdogBlock).toHaveAttribute(
      "data-watchdog-state",
      "stalled",
    );
    await expect(watchdogBlock).toHaveAttribute(
      "data-watchdog-fired-at",
      firedAt,
    );
    await expect(watchdogBlock).toContainText(
      "watchdog fired — monitor stalled",
    );

    // Recovered path: state goes back to ok but the last-fired
    // timestamp is sticky, so the amber recovered badge stays up.
    overridesRef.current = {
      watchdogState: "ok",
      watchdogLastFiredAt: firedAt,
    };
    // Trigger the dashboard's 30s integrity refetchInterval without
    // paying for an SPA reload. Same observable result, but the
    // virtual clock means the test does not actually sleep.
    await page.clock.fastForward(INTEGRITY_REFETCH_TICK_MS);

    await expect(watchdogBlock).toBeVisible();
    await expect(watchdogBlock).toHaveAttribute(
      "data-watchdog-state",
      "ok",
    );
    await expect(watchdogBlock).toContainText("watchdog recovered");

    // Steady-state healthy path: never fired in this process — the
    // whole block stays out of the DOM.
    overridesRef.current = {
      watchdogState: "ok",
      watchdogLastFiredAt: null,
    };
    await page.clock.fastForward(INTEGRITY_REFETCH_TICK_MS);

    await expect(
      page.locator('[data-testid="text-ledger-monitor-watchdog"]'),
    ).toHaveCount(0);
  });

  test("the 'last fire' relative-age text ticks up on its own without a reload (task #143)", async ({
    page,
  }) => {
    // Anchor the page clock and fix the watchdog fire 30s in the
    // past relative to it. The dashboard runs a 1s
    // `setNowMs(Date.now())` interval (task #73) that the watchdog
    // badge consumes via `formatRelativeAge(wdFiredAt, nowMs)`, so
    // advancing the page clock should bump the rendered "Ns ago"
    // string deterministically — no real-time sleep required.
    const anchorMs = Date.now();
    await page.clock.install({ time: anchorMs });
    const anchorIso = new Date(anchorMs).toISOString();
    const firedAt = new Date(anchorMs - 30_000).toISOString();
    const overridesRef: { current: WatchdogOverrides } = {
      current: {
        watchdogState: "stalled",
        watchdogLastFiredAt: firedAt,
      },
    };

    await installLedgerIntegrityMock(page, overridesRef, anchorIso);
    await page.goto("/");

    const firedAgo = page.locator(
      '[data-testid="text-ledger-monitor-watchdog-fired"]',
    );
    await expect(firedAgo).toBeVisible();
    // Format under test is "Ns ago" (sub-minute).
    await expect(firedAgo).toHaveText(/^\d+s ago$/);

    const initialText = (await firedAgo.textContent())?.trim() ?? "";
    expect(initialText).toMatch(/^\d+s ago$/);

    // Advance the virtual clock past several 1s ticks; the `setNowMs`
    // setInterval inside the dashboard will fire repeatedly and the
    // displayed seconds must climb. No reload, no refetch — purely
    // the (now faked) `nowMs` ticking through the same DOM node.
    await page.clock.fastForward(5_000);

    await expect(firedAgo).not.toHaveText(initialText);
    const laterText = (await firedAgo.textContent())?.trim() ?? "";
    expect(laterText).toMatch(/^\d+s ago$/);
    const initialSec = Number(initialText.replace(/s ago$/, ""));
    const laterSec = Number(laterText.replace(/s ago$/, ""));
    expect(laterSec).toBeGreaterThan(initialSec);
  });
});
