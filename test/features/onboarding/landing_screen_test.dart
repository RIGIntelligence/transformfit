import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/onboarding/landing_screen.dart';

Widget _wrap() {
  return const ProviderScope(child: MaterialApp(home: LandingScreen()));
}

/// Pump enough frames for all staggered animations to complete.
Future<void> _pumpAnimations(WidgetTester tester) async {
  // Give the ticker provider time to start.
  await tester.pump(const Duration(milliseconds: 100));
  // Staggered fade-in durations: title 300ms, subtitle 600ms, CTA 900ms.
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('Landing renders a full-screen Scaffold with hero background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    // Scaffold exists and has a Stack body (hero + overlay + content)
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Stack), findsWidgets);
    // The hero image is present somewhere in the widget tree
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('Landing shows the headline text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    expect(find.text('A coach who already noticed.'), findsOneWidget);
  });

  testWidgets('Landing shows the subtitle text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    expect(
      find.text('Before you log a single rep, we built your plan.'),
      findsOneWidget,
    );
  });

  testWidgets('Landing primary CTA is present with Begin text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    expect(find.text('Begin'), findsOneWidget);
    // The button should be an ElevatedButton
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets(
    'Landing shows sign-in button below the CTA',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrap());
      await _pumpAnimations(tester);

      final signIn = find.text('Sign in to existing account');
      final begin = find.text('Begin');

      expect(signIn, findsOneWidget);
      expect(begin, findsOneWidget);
      // Sign in should be below Begin
      expect(
        tester.getCenter(begin).dy,
        lessThan(tester.getCenter(signIn).dy),
      );
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

  testWidgets('Landing has no navigation bar (immersive)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await _pumpAnimations(tester);

    // No AppBar or BottomNavigationBar
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
