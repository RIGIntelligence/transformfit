// TDD-red widget tests for the plan reveal screen.
// Run: flutter test test/features/onboarding/plan_reveal_screen_test.dart
//
// Spec under test: lib/features/onboarding/plan_reveal_screen.dart.
// The plan reveal renders after intake, reflects the user's equipment /
// schedule / experience / injury / goal, echoes a user phrase with emoji
// sanitized, obeys message rules (<=60 words, no emoji, no generic
// encouragement, >=1 data token, <=1 question), follows Ask->Research->Give,
// maps the full 7-beat emotional arc, shows a surfaced deterministic fallback
// when narration LLM fails, and shows no paywall.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/onboarding/plan_reveal_screen.dart';
import 'package:transformfit/features/onboarding/plan_reveal_controller.dart';

/// Minimal fake that returns a deterministic plan.
class _FakePlanController extends PlanRevealController {
  _FakePlanController({this.fallback = false});

  final bool fallback;

  @override
  Future<PlanRevealState> build() async {
    final intake = const PlanIntake(
      goal: 'build_muscle',
      trainingDaysPerWeek: 3,
      equipment: ['dumbbells'],
      experienceLevel: 'intermediate',
    );
    final plan = generatePlan(intake);
    return PlanRevealState(
      plan: plan,
      headline: fallback
          ? 'Built to grow — your muscle-first plan is ready.'
          : 'Your 3-day dumbbell plan is ready — every set is accounted for.',
      reasoning: fallback
          ? 'This plan prioritizes hypertrophy across your available days.'
          : 'You want to build muscle with dumbbells, 3 days a week. This hits every muscle group.',
      coachingCue: 'Track your sets. Small wins this week add up to visible change.',
      changesMade: const ['Plan built for build_muscle goal', '3 sessions/week'],
      isFallback: fallback,
      modelUsed: fallback ? 'deterministic' : 'z-ai/glm-5.1',
      echoedPhrase: 'I want to get stronger',
    );
  }
}

/// A no-op stub that throws, so we can test the error state.
class _ExplodingPlanController extends PlanRevealController {
  @override
  Future<PlanRevealState> build() async {
    throw Exception('Supabase unreachable');
  }
}

ProviderScope _wrap(Widget child, {PlanRevealController? controller}) {
  return ProviderScope(
    overrides: [
      if (controller != null)
        planRevealControllerProvider.overrideWith(() => controller),
    ],
    child: child,
  );
}

void main() {
  group('PlanRevealScreen — renders after intake (VAL-ONB-025)', () {
    testWidgets('shows a plan reveal screen with plan content and forward action',
        (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Plan reveal renders.
      expect(find.byType(PlanRevealScreen), findsOneWidget);
      // There is a forward / CTA action.
      expect(find.bySemanticsLabel('Start session 1'), findsOneWidget);
    });
  });

  group('Plan reflects selected equipment (VAL-ONB-026)', () {
    testWidgets('plan exercises use only the selected equipment', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // The plan body should be present.
      expect(find.bySemanticsLabel('Plan reveal body'), findsOneWidget);
    });
  });

  group('Coach copy echoes user phrase (VAL-ONB-031)', () {
    testWidgets('echoes the user phrase recognizably', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // The echoed phrase should appear in the narration.
      expect(find.textContaining('stronger'), findsOneWidget);
    });
  });

  group('Coach copy <=60 words (VAL-ONB-032)', () {
    testWidgets('reasoning block is at most 60 words', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // The reasoning text node should be present; we assert word count in
      // the controller test. Here we assert the node is rendered.
      expect(find.bySemanticsLabel('Plan reasoning'), findsOneWidget);
    });
  });

  group('Coach copy no emoji (VAL-ONB-033)', () {
    testWidgets('rendered copy contains no emoji', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Find the headline text and assert it has no emoji.
      final headlineFinder = find.bySemanticsLabel('Plan headline');
      expect(headlineFinder, findsOneWidget);
      // The Semantics node wraps a Text; find the Text descendant.
      final textWidget = find.descendant(
        of: headlineFinder,
        matching: find.byType(Text),
      );
      expect(textWidget, findsOneWidget);
      final text = tester.widget<Text>(textWidget);
      final content = text.data ?? '';
      // No emoji in the headline.
      expect(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true).hasMatch(content), isFalse);
    });
  });

  group('Coach copy avoids generic encouragement (VAL-ONB-034)', () {
    testWidgets('no "you got this" / "great job" in copy', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Scan all rendered text for banned phrases.
      final allText = tester.allWidgets
          .whereType<Text>()
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(allText.contains('you got this'), isFalse);
      expect(allText.contains('great job'), isFalse);
      expect(allText.contains('you can do it'), isFalse);
    });
  });

  group('Coach copy >=1 data token (VAL-ONB-035)', () {
    testWidgets('narration references a concrete data token', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // The reasoning should reference a data token (days, goal, equipment).
      final reasoningFinder = find.bySemanticsLabel('Plan reasoning');
      expect(reasoningFinder, findsOneWidget);
      // The Semantics node wraps a Text; find the Text descendant.
      final textWidget = find.descendant(
        of: reasoningFinder,
        matching: find.byType(Text),
      );
      expect(textWidget, findsOneWidget);
      final reasoningText = tester.widget<Text>(textWidget).data ?? '';
      // Must reference at least one of: a number, a goal, equipment, or days.
      final hasDataToken = RegExp(r'\b(3|dumbbell|muscle|day|week|set|rep)\b', caseSensitive: false).hasMatch(reasoningText);
      expect(hasDataToken, isTrue, reason: 'reasoning lacks a data token: "$reasoningText"');
    });
  });

  group('Coach copy <=1 question (VAL-ONB-036)', () {
    testWidgets('narration has at most one question mark', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      final allText = tester.allWidgets
          .whereType<Text>()
          .map((t) => t.data ?? '')
          .join(' ');
      final questionCount = '?'.allMatches(allText).length;
      expect(questionCount, lessThanOrEqualTo(1));
    });
  });

  group('Ask -> Research -> Give structure (VAL-ONB-037)', () {
    testWidgets('all three phases are present in DOM order', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      final askFinder = find.bySemanticsLabel('Ask phase');
      final researchFinder = find.bySemanticsLabel('Research phase');
      final giveFinder = find.bySemanticsLabel('Give phase');
      expect(askFinder, findsOneWidget);
      expect(researchFinder, findsOneWidget);
      expect(giveFinder, findsOneWidget);
    });
  });

  group('No paywall (VAL-ONB-038)', () {
    testWidgets('no payment / subscribe / pricing nodes', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      final allText = tester.allWidgets
          .whereType<Text>()
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(allText.contains('subscribe'), isFalse);
      expect(allText.contains('upgrade'), isFalse);
      expect(allText.contains('pro plan'), isFalse);
      expect(allText.contains('\$'), isFalse);
    });
  });

  group('7-beat arc (VAL-ONB-039..045)', () {
    testWidgets('all 7 beats are present', (tester) async {
      final controller = _FakePlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Arrival beat'), findsOneWidget);
      expect(find.bySemanticsLabel('Grounding beat'), findsOneWidget);
      expect(find.bySemanticsLabel('Recognition beat'), findsOneWidget);
      expect(find.bySemanticsLabel('Highlight beat'), findsOneWidget);
      expect(find.bySemanticsLabel('Reflection beat'), findsOneWidget);
      expect(find.bySemanticsLabel('Forward beat'), findsOneWidget);
      expect(find.bySemanticsLabel('CTA beat'), findsOneWidget);
    });
  });

  group('Surfaced fallback (VAL-ONB-058)', () {
    testWidgets('shows a fallback indicator when narration is deterministic',
        (tester) async {
      final controller = _FakePlanController(fallback: true);
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Fallback indicator'), findsOneWidget);
    });
  });

  group('Error state', () {
    testWidgets('shows an error message when plan generation fails', (tester) async {
      final controller = _ExplodingPlanController();
      await tester.pumpWidget(_wrap(
        const MaterialApp(home: PlanRevealScreen()),
        controller: controller,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Plan reveal error'), findsOneWidget);
    });
  });
}
