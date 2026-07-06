import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/onboarding/landing_screen.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

Widget _wrap() {
  return const ProviderScope(child: MaterialApp(home: LandingScreen()));
}

/// Pump enough frames for all staggered animations to complete.
/// The landing screen has looping animations (gradient, particles) so
/// we cannot use pumpAndSettle — it would time out.
Future<void> _pumpAnimations(WidgetTester tester) async {
  // Give the ticker provider time to start.
  await tester.pump(const Duration(milliseconds: 100));
  // Staggered cards + typewriter + ring animation durations.
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('Landing opens with the real TransformFitAI brand mark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    final brandMark = find.bySemanticsLabel(
      TransformFitBrandMark.defaultSemanticsLabel,
    );

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
  });

  testWidgets('Landing exposes a coach-specific value claim heading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    // MoT1: a coach-specific value claim (not a generic SaaS headline).
    expect(find.bySemanticsLabel('Coach value claim'), findsOneWidget);
    expect(find.textContaining('noticed'), findsWidgets);
  });

  testWidgets('Landing shows a readiness preview before the feature stack', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

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
    await _pumpAnimations(tester);

    expect(find.bySemanticsLabel('Begin onboarding'), findsOneWidget);
  });

  testWidgets(
    'Landing keeps sign-in available without making it the first ask',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrap());
      await _pumpAnimations(tester);

      final valueClaim = find.bySemanticsLabel('Coach value claim');
      final begin = find.bySemanticsLabel('Begin onboarding');
      final signIn = find.bySemanticsLabel('Sign in to existing account');

      expect(valueClaim, findsOneWidget);
      expect(begin, findsOneWidget);
      expect(signIn, findsOneWidget);
      expect(
        tester.getCenter(valueClaim).dy,
        lessThan(tester.getCenter(signIn).dy),
      );
      expect(tester.getCenter(begin).dy, lessThan(tester.getCenter(signIn).dy));
    },
  );

  testWidgets('Landing carries no payment / pricing / subscribe nodes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    expect(find.textContaining('subscribe', findRichText: true), findsNothing);
    expect(find.textContaining('checkout', findRichText: true), findsNothing);
    expect(find.textContaining('pricing', findRichText: true), findsNothing);
    expect(find.textContaining(r'$', findRichText: true), findsNothing);
  });

  testWidgets('Landing has a coach preview bubble', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    expect(find.bySemanticsLabel('Coach preview'), findsOneWidget);
  });
}
