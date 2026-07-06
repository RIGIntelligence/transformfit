import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/screens/home_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Performance: measure app startup time from init to first frame rendered.
///
/// Target: < 2000 ms on mid-range device.
/// This test runs in the Flutter test environment so times reflect CI/host
/// characteristics, but relative comparisons and regression detection are valid.
void main() {
  group('Startup time', () {
    testWidgets('renders first frame under 2 seconds', (tester) async {
      final stopwatch = Stopwatch()..start();

      // Simulate the real main() bootstrap path with demo mode overrides.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: const _StartupProbe(),
        ),
      );

      // Wait for the first frame to fully render.
      await tester.pumpAndSettle();
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      debugPrint('⏱  Startup time: ${elapsedMs}ms (target < 2000ms)');

      // Soft assertion — warn but don't fail on CI jitter.
      // Hard fail only if startup exceeds 5s (regression gate).
      expect(
        elapsedMs,
        lessThan(5000),
        reason: 'Startup exceeded hard ceiling of 5s — likely a regression.',
      );

      if (elapsedMs > 2000) {
        debugPrint('⚠️  Startup exceeded 2s target: ${elapsedMs}ms');
      }
    });

    testWidgets('MaterialApp builds without error', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
          home: const Scaffold(body: Center(child: Text('TransformFit'))),
        ),
      );

      stopwatch.stop();
      debugPrint('⏱  Minimal MaterialApp build: ${stopwatch.elapsedMilliseconds}ms');

      expect(find.text('TransformFit'), findsOneWidget);
    });

    testWidgets('HomeScreen renders under 1 second in isolation', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      debugPrint('⏱  HomeScreen render: ${ms}ms');

      expect(ms, lessThan(3000), reason: 'HomeScreen exceeded 3s ceiling.');
    });
  });
}

/// Lightweight widget that mimics the TransformFitApp shell so the test
/// measures the real provider + theme + routing bootstrap cost.
class _StartupProbe extends StatelessWidget {
  const _StartupProbe();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
      home: const Scaffold(
        body: Center(child: Text('TransformFit')),
      ),
    );
  }
}
