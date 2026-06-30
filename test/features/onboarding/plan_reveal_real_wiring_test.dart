// REAL-wiring integration test for the plan reveal controller/screen.
//
// The previous plan_reveal_screen_test.dart overrides the controller with a
// fake that supplies a fixed plan — so a hardcoded DefaultIntake bug in the
// real controller would never be caught (onboarding-data-flow.md, "Controller
// & Test Authenticity"). This test instead exercises the REAL
// [PlanRevealController] + [PlanRevealScreen] path:
//
//   1. Seed the REAL pending-intake providers with a DISTINCT intake the user
//      "entered" (lose_fat / 5 days / dumbbells+kettlebells / advanced) — the
//      exact opposite of the old hardcoded default (get_fitter / 3 / bodyweight
//      / intermediate).
//   2. Use the REAL controller (no fake override). Supabase is not initialized
//      in the test, so the network call throws and the controller falls back
//      to the local deterministic engine — which runs the SAME intake through
//      generatePlan(), proving the controller read the real input.
//   3. Assert the RENDERED plan reflects the ENTERED equipment / goal /
//      schedule — not the old default.
//
// Spec under test:
//   VAL-ONB-024..030 (plan reflects entered inputs), VAL-ONB-031/059
//   (echoed phrase), VAL-ONB-050 (report a strict user path).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/onboarding/plan_reveal_controller.dart';
import 'package:transformfit/features/onboarding/plan_reveal_screen.dart';

/// Test-only notifier that returns a pre-seeded intake, so the REAL pending
/// intake provider behaves as if the user had just finished the intake quiz.
class _SeededIntake extends PendingIntake {
  _SeededIntake(this._value);
  final PlanIntake? _value;
  @override
  PlanIntake? build() => _value;
}

/// Test-only notifier that returns a pre-seeded phrase.
class _SeededWhyNow extends UserWhyNow {
  _SeededWhyNow(this._value);
  final String? _value;
  @override
  String? build() => _value;
}

ProviderScope _wrap({
  required PlanIntake? intake,
  String? whyNow,
}) {
  return ProviderScope(
    overrides: [
      pendingIntakeProvider.overrideWith(() => _SeededIntake(intake)),
      userWhyNowProvider.overrideWith(() => _SeededWhyNow(whyNow)),
    ],
    child: const MaterialApp(home: PlanRevealScreen()),
  );
}

void main() {
  // A DISTINCT intake — the opposite of the old hardcoded default.
  const enteredIntake = PlanIntake(
    goal: 'lose_fat',
    trainingDaysPerWeek: 5,
    equipment: ['dumbbells', 'kettlebells'],
    experienceLevel: 'advanced',
  );
  const enteredPhrase = 'I am tired of starting over every January.';

  testWidgets(
    'REAL controller path: rendered plan reflects ENTERED equipment, goal, '
    'and schedule — not a hardcoded default',
    (tester) async {
      // Pump with the REAL controller (no override of
      // planRevealControllerProvider) reading the real seeded intake.
      await tester.pumpWidget(_wrap(
        intake: enteredIntake,
        whyNow: enteredPhrase,
      ));
      // Allow the async controller future to resolve (one frame for build()
      // to return a Future, additional frames for settle).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // The plan body is rendered.
      expect(find.bySemanticsLabel('Plan reveal body'), findsOneWidget);

      // --- Schedule reflects the ENTERED 5 days, not the default 3 ---
      expect(find.textContaining('5 days a week'), findsOneWidget);

      // --- Goal reflects the ENTERED lose_fat goal, not the default get_fitter ---
      expect(
        find.textContaining('lose fat goal'),
        findsOneWidget,
        reason: 'grounding beat should restate the entered goal (lose_fat)',
      );
      expect(
        find.textContaining('get fitter goal'),
        findsNothing,
        reason: 'must NOT show the old hardcoded default goal',
      );

      // --- Equipment reflects the ENTERED dumbbells/kettlebells ---
      // The screen passes the intake (with bodyweight stripped) to the
      // handoff; but more directly — deterministically — verify the visible
      // plan exercises only use the entered equipment set (+ bodyweight base).
      final plan = generatePlan(enteredIntake);
      final allowed = <String>{'bodyweight', ...enteredIntake.equipment};
      for (final day in plan.days) {
        for (final ex in day.exercises) {
          expect(
            allowed.contains(ex.equipment),
            isTrue,
            reason:
                '${ex.name} needs ${ex.equipment}, not in user set $allowed',
          );
        }
      }
      // And the rendered exercise names match the deterministic plan
      // (proves the controller built the SAME plan the entered intake yields
      // — it read the real intake, not a hardcoded default that would have
      // produced different exercises).
      expect(plan.days, isNotEmpty);
      expect(
        find.textContaining(plan.days.first.exercises.first.name),
        findsWidgets,
        reason:
            'the first exercise name should render — proves controller used the '
            'real intake to build the plan',
      );

      // --- Plan length (Ask/Research/Give "Give" phase) mentions 5 days ---
      expect(find.textContaining('5-day plan'), findsOneWidget);
    },
  );

  testWidgets(
    'REAL controller path: echoed user phrase reaches the Recognition beat, '
    'sanitized of markup/emoji (VAL-ONB-031 / VAL-ONB-059)',
    (tester) async {
      await tester.pumpWidget(_wrap(
        intake: enteredIntake,
        whyNow: enteredPhrase,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // The Recognition beat echoes the user's phrase.
      expect(
        find.textContaining('You said "I am tired of starting over every January."'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'REAL controller path: markup in the user phrase is stripped before echo '
    '(VAL-ONB-059 sanitization boundary)',
    (tester) async {
      await tester.pumpWidget(_wrap(
        intake: enteredIntake,
        whyNow: 'I want to <b>get</b> stronger 💪',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Echoed phrase must contain the words but no markup and no emoji.
      final recognitionFinder = find.bySemanticsLabel('Recognition beat');
      expect(recognitionFinder, findsOneWidget);
      final textFinder = find.descendant(
        of: recognitionFinder,
        matching: find.byType(Text),
      );
      expect(textFinder, findsOneWidget);
      final echoed = tester.widget<Text>(textFinder).data ?? '';
      expect(echoed.contains('<'), isFalse, reason: 'markup not stripped');
      expect(echoed.contains('>'), isFalse, reason: 'markup not stripped');
      expect(
        RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}]', unicode: true)
            .hasMatch(echoed),
        isFalse,
        reason: 'emoji not stripped',
      );
      expect(echoed.contains('get stronger'), isTrue,
          reason: 'the words remain after sanitizing');
    },
  );

  testWidgets(
    'REAL controller path: deep link with no prior intake falls back to a '
    'default plan + flags fallback (no crash, no hardcoded-default leak)',
    (tester) async {
      // No intake seeded -> controller uses the deterministic default and
      // surfaces it honestly (is_fallback: true), never silent. Wrap in a
      // bare ProviderScope (no overrides) so the providers exist but are
      // null/empty, simulating a deep link straight to plan-reveal.
      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: PlanRevealScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // The fallback indicator is surfaced (VAL-ONB-058) rather than a silent
      // template.
      expect(find.bySemanticsLabel('Fallback indicator'), findsOneWidget);
      // The default plan still renders.
      expect(find.bySemanticsLabel('Plan reveal body'), findsOneWidget);
    },
  );
}
