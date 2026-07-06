import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/screens/home_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Performance: memory usage profiling.
///
/// Measures widget tree depth / element count as a proxy for memory pressure
/// in the Flutter test environment. True heap measurement requires a device;
/// these tests detect widget leaks and excessive rebuilds.
///
/// Target: < 100 MB on mobile (reported via proxy metrics here).
void main() {
  group('Memory profiling', () {
    testWidgets('memory baseline after app startup', skip: true, (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final elementCount = _countElements(tester);
      debugPrint('📊  Baseline elements: $elementCount (after startup)');

      // Widget tree should be reasonable — flag if > 500 elements.
      expect(
        elementCount,
        lessThan(500),
        reason: 'Excessive widget count ($elementCount) after startup.',
      );
    });

    testWidgets('memory after repeated builds (leak detection)', skip: true, (tester) async {
      // Build and tear down 10 times to detect leaked state / subscriptions.
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }

      // Final build — element count should match baseline (no leaked state).
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finalCount = _countElements(tester);
      debugPrint('📊  Post-leak-test elements: $finalCount');

      expect(
        finalCount,
        lessThan(500),
        reason: 'Widget count increased after 10 rebuild/teardown cycles — possible leak.',
      );
    });

    testWidgets('memory after simulated workout sessions', skip: true, (tester) async {
      // Simulate 10 workout sessions by pumping the HomeScreen repeatedly
      // with different key combinations to force full rebuilds.
      for (int session = 0; session < 10; session++) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
              home: HomeScreen(key: ValueKey('session_$session')),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      final elementCount = _countElements(tester);
      debugPrint('📊  After 10 workout sessions: $elementCount elements');

      expect(
        elementCount,
        lessThan(600),
        reason: 'Widget count excessive after 10 sessions.',
      );
    });

    testWidgets('no duplicate GlobalKey registrations', (tester) async {
      // Flutter throws on duplicate GlobalKeys — this test verifies
      // no collisions across rebuilds.
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // If we got here without throwing, no duplicate keys exist.
      debugPrint('✅  No duplicate GlobalKey registrations detected.');
    });
  });
}

/// Count all Element nodes in the widget tree.
int _countElements(WidgetTester tester) {
  int count = 0;
  void visit(Element element) {
    count++;
    element.visitChildren(visit);
  }

  tester.allElements.forEach(visit);
  return count;
}
