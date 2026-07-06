// M4: Golden tests for WellnessDashboardScreen — snapshot regression testing.
//
// Run with: flutter test test/golden/wellness_dashboard_golden.dart --update-goldens
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/wellness/wellness_dashboard_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// iPhone 11 Pro viewport (414×896 @2x).
const _iphoneSize = Size(414, 896);

/// Helper: build WellnessDashboardScreen wrapped in production theme.
Widget _buildWellnessDashboard() {
  return ProviderScope(
    child: MaterialApp(
      theme: buildDigitalAtelierTheme(),
      home: const WellnessDashboardScreen(),
    ),
  );
}

void main() {
  group('WellnessDashboardScreen Golden Tests', () {
    testWidgets('wellness dashboard — all modules visible', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildWellnessDashboard());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WellnessDashboardScreen),
        matchesGoldenFile('goldens/wellness_dashboard.png'),
      );
    });

    testWidgets('wellness dashboard — scrolled to bottom', (tester) async {
      tester.view.physicalSize = _iphoneSize;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildWellnessDashboard());
      await tester.pumpAndSettle();

      // Scroll down to reveal all modules.
      await tester.drag(
        find.byType(WellnessDashboardScreen),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WellnessDashboardScreen),
        matchesGoldenFile('goldens/wellness_dashboard_scrolled.png'),
      );
    });

    testWidgets('wellness dashboard — wide viewport (tablet)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildWellnessDashboard());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WellnessDashboardScreen),
        matchesGoldenFile('goldens/wellness_dashboard_tablet.png'),
      );
    });
  });
}
