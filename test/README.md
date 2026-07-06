# TransformFit Test Suites

## Integration Tests (`integration_test/`)

Full Flutter integration tests that run on a real device or emulator.

```bash
# Run all integration tests
flutter test integration_test/

# Run specific test
flutter test integration_test/app_test.dart
flutter test integration_test/workout_flow_test.dart
```

**Prerequisites:**
- `integration_test` package (added to `pubspec.yaml`)
- For web: Chrome with `--web-renderer html`
- For Android: emulator or connected device
- The app uses demo mode by default (no Supabase needed)

## Golden Tests (`test/golden/`)

Snapshot regression tests that capture screenshots and compare against baselines.

```bash
# Run golden tests
flutter test test/golden/

# Update golden files (after intentional UI changes)
flutter test test/golden/ --update-goldens

# Run specific golden test
flutter test test/golden/home_screen_golden.dart
flutter test test/golden/workout_screen_golden.dart
flutter test test/golden/coach_chat_golden.dart
flutter test test/golden/wellness_dashboard_golden.dart
flutter test test/golden/onboarding_golden.dart
```

**Golden files** are stored in `test/golden/goldens/`. Commit updated goldens
after intentional UI changes. CI will fail if goldens don't match.

**Viewport sizes tested:**
- iPhone 11 Pro: 414×896 @2x (primary)
- iPad: 1024×768 @2x (tablet)
- iPhone SE: 320×568 @2x (compact)

## E2E Tests (`e2e/`)

Playwright tests that run against the live web deployment.

```bash
cd e2e/

# Install dependencies (first time)
npm install

# Install Chromium browser
npm run install:browsers

# Run all E2E tests
npm test

# Run with headed browser
npm run test:headed

# Run with Playwright UI
npm run test:ui

# Run specific suite
npm run test:onboarding
npm run test:workout
npm run test:navigation

# Override base URL (e.g., staging)
BASE_URL=https://staging.example.com npm test
```

**Prerequisites:**
- Node.js 18+
- Playwright Chromium browser
- Network access to the Firebase deployment URL
