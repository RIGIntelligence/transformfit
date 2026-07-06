import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/onboarding/welcome_screen.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

Widget _wrap() {
  return const ProviderScope(child: MaterialApp(home: WelcomeScreen()));
}

void main() {
  testWidgets('Welcome opens with the real TransformFitAI brand mark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final brandMark = find.bySemanticsLabel(
      TransformFitBrandMark.defaultSemanticsLabel,
    );
    final heading = find.bySemanticsLabel('Welcome heading');

    expect(brandMark, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                TransformFitBrandMark.assetPath,
      ),
      findsOneWidget,
    );
    expect(
      tester.getCenter(brandMark).dy,
      lessThan(tester.getCenter(heading).dy),
    );
  });

  testWidgets('Welcome screen renders with a heading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Welcome heading'), findsOneWidget);
  });

  testWidgets('Welcome offers exactly one unambiguous primary action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Begin intake'), findsOneWidget);
  });

  testWidgets('Welcome carries no payment / pricing / subscribe nodes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('subscribe', findRichText: true), findsNothing);
    expect(find.textContaining('checkout', findRichText: true), findsNothing);
    expect(find.textContaining('pricing', findRichText: true), findsNothing);
    expect(find.textContaining('\$', findRichText: true), findsNothing);
  });

  testWidgets('Welcome primary action is tappable (no dead-end)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final button = find.bySemanticsLabel('Begin intake');
    expect(button, findsOneWidget);

    // The button must be enabled (onPressed != null).
    final elevatedButton = tester.widget<ElevatedButton>(
      find.descendant(of: button, matching: find.byType(ElevatedButton)),
    );
    expect(elevatedButton.onPressed, isNotNull);
  });
}
