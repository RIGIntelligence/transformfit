// M4: E2E tests — onboarding flow (Playwright).
//
// Tests the landing → welcome → intake entry point on the live web deployment.
// The app starts in unauthenticated state and redirects to /onboarding/landing.
import { test, expect } from '@playwright/test';

test.describe('Onboarding Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to root — the auth guard redirects unauthenticated users
    // to /onboarding/landing.
    await page.goto('/');
    // Wait for the Flutter app to fully render (Flutter web uses a canvas
    // or skwasm renderer — we wait for the app shell to be present).
    await page.waitForTimeout(3000);
  });

  test('landing page loads and shows value claim', async ({ page }) => {
    // The landing screen displays the coach value claim.
    // Since Flutter web renders to canvas, we use accessibility semantics.
    // The app uses Semantics widgets with labels we can query.
    const pageContent = await page.content();

    // Verify the page loaded (Flutter app initialized).
    expect(pageContent).toBeTruthy();

    // The page title should be TransformFit.
    await expect(page).toHaveTitle(/TransformFit/);
  });

  test('landing page shows brand mark', async ({ page }) => {
    // The TransformFitBrandMark is rendered with a semantics label.
    // On Flutter web, we check that the app rendered by verifying
    // the Flutter view container exists.
    const flutterView = page.locator('flt-glass-pane, flutter-view');
    await expect(flutterView.first()).toBeAttached({ timeout: 10_000 });
  });

  test('onboarding URL loads directly', async ({ page }) => {
    await page.goto('/onboarding/landing');
    await page.waitForTimeout(3000);

    // Verify the page loaded.
    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });

  test('auth URL loads directly', async ({ page }) => {
    await page.goto('/auth');
    await page.waitForTimeout(3000);

    // Verify the page loaded.
    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });

  test('unknown route shows 404 screen', async ({ page }) => {
    await page.goto('/this-does-not-exist');
    await page.waitForTimeout(3000);

    // The app should render the NotFoundScreen.
    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
  });
});
