// M4: Full app integration tests — TransformFit end-to-end flows.
//
// Run with: flutter test integration_test/app_test.dart
// Requires: demo mode enabled or Supabase test env.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:transformfit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TransformFit Integration Tests', () {
    // ── Onboarding Flow ──────────────────────────────────────────────────

    testWidgets('Full onboarding flow — landing to welcome', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // In unauthenticated state, the app should redirect to /onboarding/landing.
      // Wait for the redirect to settle.
      await tester.pump(const Duration(seconds: 2));

      // The landing screen should show the value claim (typewriter text).
      // It contains the word "noticed" in the value claim.
      expect(
        find.textContaining('noticed'),
        findsWidgets,
        reason: 'Landing screen should display the coach value claim',
      );

      // Verify the Begin CTA is present.
      final beginButton = find.bySemanticsLabel('Begin onboarding');
      expect(beginButton, findsOneWidget);

      // Tap Begin to proceed to the welcome screen.
      await tester.tap(beginButton);
      await tester.pumpAndSettle();

      // Welcome screen should show the "Welcome" heading.
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('Landing screen shows feature cards', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Feature cards should be visible.
      expect(find.textContaining('Readiness-adjusted'), findsOneWidget);
      expect(find.textContaining('Coach-voice'), findsOneWidget);
      expect(find.textContaining('Progression'), findsOneWidget);
    });

    testWidgets('Sign in link navigates to auth screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Tap Sign in.
      final signInButton = find.text('Sign in');
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Auth screen should be visible.
      expect(find.textContaining('Sign'), findsWidgets);
    });

    // ── Bottom Navigation (Authenticated) ────────────────────────────────

    testWidgets('Bottom navigation — 5 tabs visible in demo mode', (
      tester,
    ) async {
      // In demo mode the app starts authenticated with a profile.
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // The bottom nav should have 5 tabs: Today, Workout, Coach, Wellness, Profile.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);
      expect(find.text('Wellness'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Bottom navigation — tapping Workout tab', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Tap the Workout tab.
      await tester.tap(find.byIcon(Icons.fitness_center).last);
      await tester.pumpAndSettle();

      // The workout screen should be displayed.
      // ActiveWorkoutScreen shows the TransformFitBrandMark.
      expect(find.bySemanticsLabel('Workout tab, selected'), findsOneWidget);
    });

    testWidgets('Bottom navigation — tapping Coach tab', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Tap the Coach tab.
      await tester.tap(find.byIcon(Icons.chat).last);
      await tester.pumpAndSettle();

      // Coach tab should be selected.
      expect(find.bySemanticsLabel('Coach tab, selected'), findsOneWidget);
    });

    testWidgets('Bottom navigation — tapping Wellness tab', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Tap the Wellness tab.
      await tester.tap(find.byIcon(Icons.favorite).last);
      await tester.pumpAndSettle();

      // Wellness tab should be selected.
      expect(find.bySemanticsLabel('Wellness tab, selected'), findsOneWidget);

      // Wellness dashboard should show wellness modules.
      expect(find.text('Mood'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
    });

    testWidgets('Bottom navigation — tapping Profile tab', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Tap the Profile tab.
      await tester.tap(find.byIcon(Icons.person).last);
      await tester.pumpAndSettle();

      // Profile tab should be selected.
      expect(find.bySemanticsLabel('Profile tab, selected'), findsOneWidget);

      // Profile screen should display.
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Bottom navigation — tapping Today returns to home', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to another tab first.
      await tester.tap(find.byIcon(Icons.favorite).last);
      await tester.pumpAndSettle();

      // Navigate back to Today.
      await tester.tap(find.byIcon(Icons.today).last);
      await tester.pumpAndSettle();

      // Today tab should be selected and home screen visible.
      expect(find.bySemanticsLabel('Today tab, selected'), findsOneWidget);
    });

    // ── Home Screen ──────────────────────────────────────────────────────

    testWidgets('Home screen shows readiness card and quick actions', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Home screen should display the Today heading.
      expect(find.text('Today'), findsOneWidget);

      // Quick actions should be present.
      expect(find.text('Mood'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);

      // Weekly summary should be present.
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
    });
  });
}
