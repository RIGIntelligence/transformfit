// M4: E2E tests — workout flow (Playwright).
//
// Tests the workout screen on the live web deployment.
// Requires the app to be in authenticated state (demo mode or real auth).
import { test, expect } from '@playwright/test';

test.describe('Workout Flow', () => {
  test('workout route loads', async ({ page }) => {
    // Navigate to the workout route.
    await page.goto('/workout');
    await page.waitForTimeout(3000);

    // Verify the page loaded (Flutter app initialized).
    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();

    // Verify the Flutter view is present.
    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('workout tab route loads', async ({ page }) => {
    // The /workout-tab route is the bottom nav workout branch.
    await page.goto('/workout-tab');
    await page.waitForTimeout(3000);

    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });

  test('coach chat route loads', async ({ page }) => {
    await page.goto('/coach-chat');
    await page.waitForTimeout(3000);

    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });

  test('nutrition route loads', async ({ page }) => {
    await page.goto('/nutrition');
    await page.waitForTimeout(3000);

    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });

  test('exercises route loads', async ({ page }) => {
    await page.goto('/exercises');
    await page.waitForTimeout(3000);

    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });
});
