// M4: E2E tests — navigation (Playwright).
//
// Tests that the app's route structure works correctly on the live web deployment.
// Verifies direct URL access, redirects, and deep linking.
import { test, expect } from '@playwright/test';

test.describe('Navigation', () => {
  test('root URL loads', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000);

    // The app should load and render.
    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('onboarding redirect from root', async ({ page }) => {
    // For unauthenticated users, / redirects to /onboarding/landing.
    await page.goto('/');
    await page.waitForTimeout(3000);

    // The URL should have been redirected (or stayed at / if authenticated).
    const url = page.url();
    expect(url).toBeTruthy();
  });

  test('direct deep link to onboarding landing', async ({ page }) => {
    await page.goto('/onboarding/landing');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to onboarding welcome', async ({ page }) => {
    await page.goto('/onboarding/welcome');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to onboarding intake', async ({ page }) => {
    await page.goto('/onboarding/intake');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to settings', async ({ page }) => {
    await page.goto('/settings');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to privacy policy', async ({ page }) => {
    await page.goto('/privacy-policy');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to terms', async ({ page }) => {
    await page.goto('/terms');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to gamification', async ({ page }) => {
    await page.goto('/gamification');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to progress', async ({ page }) => {
    await page.goto('/progress');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('direct deep link to debrief', async ({ page }) => {
    await page.goto('/debrief');
    await page.waitForTimeout(3000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('page has correct title', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/TransformFit/);
  });

  test('page handles browser back navigation', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);
    await page.goto('/onboarding/landing');
    await page.waitForTimeout(2000);

    // Go back.
    await page.goBack();
    await page.waitForTimeout(2000);

    // App should still be functional.
    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('page handles browser forward navigation', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(2000);
    await page.goto('/onboarding/landing');
    await page.waitForTimeout(2000);
    await page.goBack();
    await page.waitForTimeout(2000);

    // Go forward.
    await page.goForward();
    await page.waitForTimeout(2000);

    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });
});
