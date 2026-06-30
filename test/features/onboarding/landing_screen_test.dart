import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/onboarding/landing_screen.dart';

Widget _wrap() {
  return const ProviderScope(
    child: MaterialApp(
      home: LandingScreen(),
    ),
  );
}

void main() {
  testWidgets('Landing exposes a coach-specific value claim heading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // MoT1: a coach-specific value claim (not a generic SaaS headline).
    expect(
      find.bySemanticsLabel('Coach value claim'),
      findsOneWidget,
    );
    expect(
      find.textContaining('noticed'),
      findsWidgets,
    );
  });

  testWidgets('Landing shows a readiness preview before the feature stack', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final previewFinder = find.bySemanticsLabel('Readiness preview');
    final featureFinder = find.bySemanticsLabel('Feature stack');

    expect(previewFinder, findsOneWidget);
    expect(featureFinder, findsOneWidget);

    // Readiness preview must precede the feature stack in DOM order.
    final previewCenter = tester.getCenter(previewFinder);
    final featureCenter = tester.getCenter(featureFinder);
    expect(previewCenter.dy, lessThan(featureCenter.dy));
  });

  testWidgets('Landing primary CTA is present with a meaningful label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Begin onboarding'), findsOneWidget);
  });

  testWidgets('Landing carries no payment / pricing / subscribe nodes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('subscribe', findRichText: true), findsNothing);
    expect(find.textContaining('checkout', findRichText: true), findsNothing);
    expect(find.textContaining('pricing', findRichText: true), findsNothing);
    expect(find.textContaining('\$', findRichText: true), findsNothing);
  });
}
