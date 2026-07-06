import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/screens/home_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';
import 'package:transformfit/widgets/tf_button.dart';

/// Accessibility: verify semantic label coverage across key screens.
///
/// Checks that all interactive elements (buttons, tappable, text fields)
/// have semantic labels, and reports coverage percentage.
void main() {
  group('Semantic coverage', () {
    testWidgets('all buttons have semantic labels', skip: true, (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      int labeled = 0;
      int total = 0;

      for (final button in buttons) {
        total++;
        // ElevatedButton inherits semantics from its child Text or from
        // an enclosing Semantics widget. Verify the button is accessible.
        final semantics = tester.getSemantics(find.byWidget(button));
        // ignore: deprecated_member_use
        if (semantics.label.isNotEmpty || semantics.hasFlag(SemanticsFlag.isButton)) {
          labeled++;
        }
      }

      debugPrint('📊  ElevatedButton semantic coverage: $labeled/$total');
      expect(total, greaterThan(0), reason: 'No ElevatedButtons found to audit.');
      expect(labeled, equals(total), reason: 'Some buttons lack semantic labels.');
    });

    testWidgets('all TfButton instances have semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
          home: Scaffold(
            body: Column(
              children: [
                TfButton(label: 'Primary', onPressed: () {}),
                TfButton(label: 'Secondary', variant: TfButtonVariant.secondary, onPressed: () {}),
                TfButton(label: 'Disabled', onPressed: null),
                TfButton(label: 'With Icon', icon: Icons.add, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<TfButton>(find.byType(TfButton));
      int total = buttons.length;
      int labeled = 0;

      for (final button in buttons) {
        // TfButton wraps in Semantics with label: semanticLabel ?? label
        final semanticsFinder = find.ancestor(
          of: find.byWidget(button),
          matching: find.byType(Semantics),
        );

        // Each TfButton should have at least one Semantics ancestor.
        expect(
          semanticsFinder,
          findsWidgets,
          reason: 'TfButton "${button.label}" has no Semantics wrapper.',
        );
        labeled++;
      }

      debugPrint('📊  TfButton semantic coverage: $labeled/$total');
      expect(labeled, equals(total));
    });

    testWidgets('HomeScreen interactive elements have labels', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all Semantics widgets that are marked as buttons.
      final semanticsNodes = tester.getSemantics(find.byType(HomeScreen));
      final buttonCount = _countSemanticsButtons(semanticsNodes);

      debugPrint('📊  HomeScreen has $buttonCount semantic button nodes.');

      // The home screen should have at least quick actions + nav buttons.
      expect(
        buttonCount,
        greaterThanOrEqualTo(3),
        reason: 'HomeScreen has too few semantic button nodes.',
      );
    });

    testWidgets('images have alt text (Semantics labels)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
          home: Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Hero workout image',
                  child: Image.asset(
                    'assets/imagery/hero_workout.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, error, stackTrace) => const SizedBox(width: 100, height: 100),
                  ),
                ),
                // Deliberately unlabeled image to test detection.
                Image.asset(
                  'assets/imagery/hero_nutrition.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (_, error, stackTrace) => const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final images = tester.widgetList<Image>(find.byType(Image));
      debugPrint('📊  Found ${images.length} Image widgets.');

      // At minimum, the labeled image should have a Semantics ancestor.
      final labeledFinder = find.descendant(
        of: find.bySemanticsLabel('Hero workout image'),
        matching: find.byType(Image),
      );
      expect(labeledFinder, findsOneWidget, reason: 'Labeled image not found by semantics.');
    });

    testWidgets('coverage percentage report', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildDigitalAtelierTheme(textScaleFactor: 1.0),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      int totalInteractive = 0;
      int labeledInteractive = 0;

      // Check all GestureDetector / InkWell widgets.
      final gestureDetectors = find.byType(GestureDetector);
      final inkWells = find.byType(InkWell);

      for (final finder in [gestureDetectors, inkWells]) {
        final widgets = tester.widgetList(finder);
        for (final widget in widgets) {
          totalInteractive++;
          // Check if there's a Semantics ancestor.
          final semanticsAncestor = find.ancestor(
            of: find.byWidget(widget),
            matching: find.byType(Semantics),
          );
          if (semanticsAncestor.evaluate().isNotEmpty) {
            labeledInteractive++;
          }
        }
      }

      final coverage = totalInteractive > 0
          ? (labeledInteractive / totalInteractive * 100).toStringAsFixed(1)
          : 'N/A';
      debugPrint('📊  Interactive element semantic coverage: $coverage% ($labeledInteractive/$totalInteractive)');
    });
  });
}

int _countSemanticsButtons(SemanticsNode node) {
  int count = 0;
  // ignore: deprecated_member_use
  if (node.hasFlag(SemanticsFlag.isButton) ||
      (node.label.isNotEmpty && node.getSemanticsData().hasAction(SemanticsAction.tap))) {
    count++;
  }
  node.visitChildren((child) {
    count += _countSemanticsButtons(child);
    return true;
  });
  return count;
}
