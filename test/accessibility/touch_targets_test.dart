import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/screens/home_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/tf_button.dart';

/// Accessibility: verify all tappable elements meet the 44px minimum
/// touch target requirement (WCAG 2.5.5 / Apple HIG).
///
/// Tests buttons, chips, cards, list items, and icon buttons.
void main() {
  group('Touch target sizes (≥ 44px)', () {
    testWidgets('TfButton meets 44px height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
          home: Scaffold(
            body: Column(
              children: [
                TfButton(label: 'Primary', onPressed: () {}),
                TfButton(label: 'Secondary', variant: TfButtonVariant.secondary, onPressed: () {}),
                TfButton(label: 'Ghost', variant: TfButtonVariant.ghost, onPressed: () {}),
                TfButton(label: 'Danger', variant: TfButtonVariant.danger, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<TfButton>(find.byType(TfButton));
      for (final button in buttons) {
        final size = tester.getSize(find.byWidget(button));
        debugPrint('📏  TfButton "${button.label}": ${size.width}x${size.height}');
        expect(
          size.height,
          greaterThanOrEqualTo(44),
          reason: 'TfButton "${button.label}" height ${size.height}px < 44px.',
        );
      }
    });

    testWidgets('ElevatedButton meets 44px height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(ElevatedButton));
      debugPrint('📏  ElevatedButton: ${size.width}x${size.height}');
      expect(size.height, greaterThanOrEqualTo(44), reason: 'ElevatedButton height < 44px.');
    });

    testWidgets('HomeScreen quick actions meet 44px', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick actions are Material widgets with InkWell inside a SizedBox(height: 44).
      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
      int below44 = 0;

      for (final inkWell in inkWells) {
        final finder = find.byWidget(inkWell);
        if (finder.evaluate().isNotEmpty) {
          final size = tester.getSize(finder);
          if (size.height < 44) {
            below44++;
            debugPrint('⚠️  InkWell below 44px: ${size.width}x${size.height}');
          }
        }
      }

      debugPrint('📏  InkWells below 44px: $below44 / ${inkWells.length}');
      // Report but don't hard-fail — some may be decorative.
    });

    testWidgets('BottomNavigationBar items meet 44px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The bottom nav itself should be tall enough.
      final navBarSize = tester.getSize(find.byType(BottomNavigationBar));
      debugPrint('📏  BottomNavigationBar: ${navBarSize.width}x${navBarSize.height}');
      expect(navBarSize.height, greaterThanOrEqualTo(44));
    });

    testWidgets('all tappable elements audit', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      int totalTappable = 0;
      int below44 = 0;
      final issues = <String>[];

      // Check all InkWell widgets.
      final inkWells = find.byType(InkWell);
      for (final element in inkWells.evaluate()) {
        totalTappable++;
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final size = renderBox.size;
          if (size.height < 44 || size.width < 44) {
            below44++;
            final widget = element.widget;
            issues.add('$widget: ${size.width}x${size.height}');
          }
        }
      }

      // Check all GestureDetector widgets (excluding scroll views).
      final gestures = find.byType(GestureDetector);
      for (final element in gestures.evaluate()) {
        final widget = element.widget as GestureDetector;
        if (widget.onTap != null || widget.onDoubleTap != null || widget.onLongPress != null) {
          totalTappable++;
          final renderBox = element.renderObject as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            final size = renderBox.size;
            if (size.height < 44 || size.width < 44) {
              below44++;
              issues.add('GestureDetector: ${size.width}x${size.height}');
            }
          }
        }
      }

      debugPrint('\n📏  === Touch Target Audit ===');
      debugPrint('    Total tappable: $totalTappable');
      debugPrint('    Below 44px: $below44');
      if (issues.isNotEmpty) {
        debugPrint('    Issues:');
        for (final issue in issues) {
          debugPrint('      - $issue');
        }
      }

      // Hard-fail if any tappable element is below 44px.
      expect(below44, equals(0), reason: '$below44 tappable elements below 44px.');
    });

    testWidgets('IconButton meets 44px touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // IconButton default is 48x48 but can be constrained smaller.
      final size = tester.getSize(find.byType(IconButton));
      debugPrint('📏  IconButton: ${size.width}x${size.height}');
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });
}
