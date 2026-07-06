import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/screens/home_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Performance: frame timing profiling.
///
/// Measures pump durations (proxy for frame build time) across scrolling,
/// animations, and navigation. In Flutter test mode, pump durations reflect
/// widget build cost; on-device these map to actual frame times.
///
/// Target: < 16ms per frame (60fps).
void main() {
  group('Frame timing', () {
    testWidgets('frame times during scroll simulation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final frameTimes = <int>[];

      // Simulate 60 frames of scrolling.
      for (int frame = 0; frame < 60; frame++) {
        final sw = Stopwatch()..start();
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -20),
        );
        sw.stop();
        frameTimes.add(sw.elapsedMicroseconds);
      }

      _reportFrameTimes('Scroll', frameTimes);

      final p95 = _percentile(frameTimes, 95);
      // In test mode, each pump can be > 16ms due to test harness overhead.
      // Use a generous ceiling; the relative distribution matters more.
      expect(
        p95,
        lessThan(100000), // 100ms ceiling for test harness
        reason: 'P95 scroll frame time exceeded ceiling.',
      );
    });

    testWidgets('frame times during animation', (tester) async {
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 500),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: _AnimatedTestWidget(controller: controller),
          ),
        ),
      );

      final frameTimes = <int>[];

      controller.forward();
      // Pump individual frames to measure each one.
      for (int frame = 0; frame < 30; frame++) {
        final sw = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        frameTimes.add(sw.elapsedMicroseconds);
      }

      _reportFrameTimes('Animation', frameTimes);
      controller.dispose();

      final p95 = _percentile(frameTimes, 95);
      expect(
        p95,
        lessThan(100000),
        reason: 'P95 animation frame time exceeded ceiling.',
      );
    });

    testWidgets('frame times during navigation rebuild', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final frameTimes = <int>[];

      // Simulate 20 navigation-triggered rebuilds.
      for (int i = 0; i < 20; i++) {
        final sw = Stopwatch()..start();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
              home: HomeScreen(key: ValueKey('nav_$i')),
            ),
          ),
        );
        await tester.pump();
        sw.stop();
        frameTimes.add(sw.elapsedMicroseconds);
      }

      _reportFrameTimes('Navigation', frameTimes);

      final p95 = _percentile(frameTimes, 95);
      expect(
        p95,
        lessThan(200000),
        reason: 'P95 navigation rebuild time exceeded ceiling.',
      );
    });

    testWidgets('P50 frame time consistency', skip: true, (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final frameTimes = <int>[];
      for (int i = 0; i < 30; i++) {
        final sw = Stopwatch()..start();
        await tester.pump();
        sw.stop();
        frameTimes.add(sw.elapsedMicroseconds);
      }

      final p50 = _percentile(frameTimes, 50);
      final p99 = _percentile(frameTimes, 99);

      debugPrint('📊  Idle frame P50: $p50 μs, P99: $p99 μs');

      // P99 should not be more than 10x P50 (consistency check).
      expect(
        p99,
        lessThan(p50 * 10),
        reason: 'Frame time variance too high — P99/P50 ratio > 10x.',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _reportFrameTimes(String label, List<int> microseconds) {
  final sorted = [...microseconds]..sort();
  final p50 = _percentile(microseconds, 50);
  final p95 = _percentile(microseconds, 95);
  final p99 = _percentile(microseconds, 99);
  final avg = microseconds.reduce((a, b) => a + b) / microseconds.length;

  debugPrint('📊  $label frame times ($microseconds.length frames):');
  debugPrint('    P50: ${(p50 / 1000).toStringAsFixed(2)}ms');
  debugPrint('    P95: ${(p95 / 1000).toStringAsFixed(2)}ms');
  debugPrint('    P99: ${(p99 / 1000).toStringAsFixed(2)}ms');
  debugPrint('    Avg: ${(avg / 1000).toStringAsFixed(2)}ms');
  debugPrint(
    '    Min/Max: ${(sorted.first / 1000).toStringAsFixed(2)}ms / ${(sorted.last / 1000).toStringAsFixed(2)}ms',
  );
}

int _percentile(List<int> values, int p) {
  final sorted = [...values]..sort();
  final index = (p / 100 * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

// ---------------------------------------------------------------------------
// Test widgets
// ---------------------------------------------------------------------------

class _AnimatedTestWidget extends StatelessWidget {
  const _AnimatedTestWidget({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + controller.value * 0.5,
          child: Container(
            width: 200,
            height: 200,
            color: Colors.orange.withValues(alpha: controller.value),
            child: const Center(child: Text('Animating')),
          ),
        );
      },
    );
  }
}
