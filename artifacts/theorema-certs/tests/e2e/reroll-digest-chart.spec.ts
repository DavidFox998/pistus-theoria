import { test, expect, type Route, type Page } from "@playwright/test";

/**
 * Task #224: end-to-end coverage for the re-roll digest volume chart.
 *
 * The digest panel (task #199) gained a compact bucketed bar chart of
 * attempts/failures over the chosen window so an unusual burst jumps out
 * visually. The bucketing itself is unit-tested in
 * `artifacts/api-server/src/lib/rerollDigest.test.ts`; this spec covers
 * the dashboard rendering path by mocking
 * `GET /api/ledger/checkpoint/reroll/digest` with a known `buckets`
 * array and asserting the chart reflects it, including across windows.
 *
 * Selectors under test (see `src/pages/dashboard.tsx`):
 *   - `[data-testid="chart-reroll-digest"]` carries `data-bucket-count`
 *     and `data-max-attempts`
 *   - `[data-testid="chart-reroll-digest-bucket-<i>"]` one per bucket
 */

const DIGEST_URL = "**/api/ledger/checkpoint/reroll/digest*";

type Bucket = {
  start: string;
  attempts: number;
  okCount: number;
  failCount: number;
};

function makeBuckets(
  spec: Array<{ ok: number; fail: number }>,
  windowHours: number,
): Bucket[] {
  const now = Date.now();
  const windowMs = windowHours * 60 * 60 * 1000;
  const bucketMs = windowMs / spec.length;
  return spec.map((s, i) => ({
    start: new Date(now - windowMs + i * bucketMs).toISOString(),
    attempts: s.ok + s.fail,
    okCount: s.ok,
    failCount: s.fail,
  }));
}

function buildDigestBody(window: string, windowHours: number, buckets: Bucket[]) {
  const okCount = buckets.reduce((s, b) => s + b.okCount, 0);
  const failCount = buckets.reduce((s, b) => s + b.failCount, 0);
  const totalAttempts = okCount + failCount;
  const now = Date.now();
  return {
    window,
    windowHours,
    windowStart: new Date(now - windowHours * 3600 * 1000).toISOString(),
    windowEnd: new Date(now).toISOString(),
    totalAttempts,
    okCount,
    failCount,
    perReferee:
      totalAttempts > 0
        ? [{ refereeName: "alice", okCount, failCount }]
        : [],
    failures: [],
    buckets,
    text: "stub digest text",
  };
}

async function routeDigest(
  page: Page,
  resolver: (window: string) => {
    windowHours: number;
    buckets: Bucket[];
  },
) {
  await page.route(DIGEST_URL, async (route: Route) => {
    const url = new URL(route.request().url());
    const window = url.searchParams.get("window") ?? "24h";
    const { windowHours, buckets } = resolver(window);
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildDigestBody(window, windowHours, buckets)),
    });
  });
}

test.describe("dashboard: re-roll digest volume chart", () => {
  test("renders one column per bucket with the peak attempt count", async ({
    page,
  }) => {
    const buckets = makeBuckets(
      [
        { ok: 1, fail: 0 },
        { ok: 2, fail: 0 },
        { ok: 0, fail: 0 },
        { ok: 3, fail: 4 }, // burst: 7 attempts is the peak
        { ok: 1, fail: 0 },
      ],
      24,
    );
    await routeDigest(page, () => ({ windowHours: 24, buckets }));
    await page.goto("/");

    const chart = page.locator('[data-testid="chart-reroll-digest"]');
    await expect(chart).toBeVisible();
    await expect(chart).toHaveAttribute("data-bucket-count", "5");
    await expect(chart).toHaveAttribute("data-max-attempts", "7");
    await expect(chart).toContainText("peak 7/bucket");

    // One <g> per bucket.
    await expect(
      page.locator('[data-testid^="chart-reroll-digest-bucket-"]'),
    ).toHaveCount(5);

    // The burst bucket's tooltip exposes its ok/fail split.
    await expect(
      page.locator('[data-testid="chart-reroll-digest-bucket-3"] title'),
    ).toHaveText(/7 attempts \(ok=3, fail=4\)/);
  });

  test("redraws when the window changes", async ({ page }) => {
    await routeDigest(page, (window) => {
      if (window === "7d") {
        return {
          windowHours: 24 * 7,
          buckets: makeBuckets(
            [
              { ok: 5, fail: 0 },
              { ok: 9, fail: 1 }, // peak 10
              { ok: 2, fail: 0 },
            ],
            24 * 7,
          ),
        };
      }
      return {
        windowHours: 24,
        buckets: makeBuckets([{ ok: 1, fail: 0 }], 24),
      };
    });
    await page.goto("/");

    const chart = page.locator('[data-testid="chart-reroll-digest"]');
    await expect(chart).toHaveAttribute("data-bucket-count", "1");
    await expect(chart).toHaveAttribute("data-max-attempts", "1");

    await page.locator('[data-testid="button-reroll-digest-window-7d"]').click();

    await expect(chart).toHaveAttribute("data-bucket-count", "3");
    await expect(chart).toHaveAttribute("data-max-attempts", "10");
  });

  test("draws a flat (zeroed) chart on an empty window", async ({ page }) => {
    await routeDigest(page, () => ({
      windowHours: 24,
      buckets: makeBuckets(
        Array.from({ length: 4 }, () => ({ ok: 0, fail: 0 })),
        24,
      ),
    }));
    await page.goto("/");

    const chart = page.locator('[data-testid="chart-reroll-digest"]');
    await expect(chart).toBeVisible();
    await expect(chart).toHaveAttribute("data-bucket-count", "4");
    await expect(chart).toHaveAttribute("data-max-attempts", "0");
    await expect(chart).toContainText("peak 0/bucket");
  });
});
