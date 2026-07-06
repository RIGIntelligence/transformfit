import { defineConfig } from '@playwright/test';

/**
 * Playwright config for TransformFit E2E tests.
 *
 * The web app is deployed to Firebase Hosting. Tests run against the
 * live deployment URL. Override baseURL via env var for staging:
 *
 *   BASE_URL=https://staging.example.com npx playwright test
 */
export default defineConfig({
  testDir: '.',
  fullyParallel: false,
  forbidOnly: true,
  retries: 1,
  workers: 1,
  reporter: [['html', { open: 'never' }], ['list']],
  timeout: 30_000,

  use: {
    baseURL:
      process.env.BASE_URL ??
      'https://captainamericafitnes-613a4a99--transformfit-v70-s63xro1x.web.app',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10_000,
    navigationTimeout: 15_000,
  },

  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
