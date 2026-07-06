// M4: Golden tests for onboarding screens — snapshot regression testing.
//
// Covers LandingScreen and WelcomeScreen golden snapshots.
//
// Run with: flutter test test/golden/onboarding_golden.dart --update-goldens
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/onboarding/landing_screen.dart';
import 'package:transformfit/features/onboarding/welcome_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// iPhone 11 Pro viewport (414×896 @2x).
const _iphoneSize = Size(414, 896);

/// Pump enough frames for all staggered animations to complete.
/// The landing screen has looping animations (gradient, particles) so
/// we cannot use pumpAndSettle — it would time out.
Future<void> _pumpLandingAnimations(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  group('LandingScreen Golden Tests', () {
    testWidgets('landing screen — full viewport', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LandingScreen()),
        ),
      );
      await _pumpLandingAnimations(tester);

      await expectLater(
        find.byType(LandingScreen),
        matchesGoldenFile('goldens/landing_screen.png'),
      );
    });

    testWidgets('landing screen — wide viewport (tablet)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LandingScreen()),
        ),
      );
      await _pumpLandingAnimations(tester);

      await expectLater(
        find.byType(LandingScreen),
        matchesGoldenFile('goldens/landing_screen_tablet.png'),
      );
    });

    testWidgets('landing screen — narrow viewport (SE)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LandingScreen()),
        ),
      );
      await _pumpLandingAnimations(tester);

      await expectLater(
        find.byType(LandingScreen),
        matchesGoldenFile('goldens/landing_screen_se.png'),
      );
    });
  });

  group('WelcomeScreen Golden Tests', () {
    testWidgets('welcome screen — full viewport', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(),
          home: const WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WelcomeScreen),
        matchesGoldenFile('goldens/welcome_screen.png'),
      );
    });

    testWidgets('welcome screen — wide viewport (tablet)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(),
          home: const WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WelcomeScreen),
        matchesGoldenFile('goldens/welcome_screen_tablet.png'),
      );
    });
  });
}
