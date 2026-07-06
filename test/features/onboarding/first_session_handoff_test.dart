// RED-then-GREEN widget tests for the first-session handoff (MoT4).
//
// Spec under test: lib/features/onboarding/first_session_handoff_screen.dart.
//
// Assertions covered (VAL-ONB-046..053):
//   VAL-ONB-046: handoff renders session 1 details
//   VAL-ONB-047: handoff CTA leads into the session loop (no dead-end)
//   VAL-ONB-048: no paywall at the handoff
//   VAL-ONB-049: selected equipment carries into the first session's exercises
//   VAL-ONB-052: no payment widgets in the handoff tree

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/engine/plan_generation.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/features/onboarding/first_session_handoff_screen.dart';
import 'package:transformfit/features/onboarding/plan_reveal_controller.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/workout/workout_prefill.dart';
import 'package:transformfit/navigation/auth_state.dart';

/// A minimal fake auth facade for widget tests.
class _FakeAuthFacade implements AuthFacade {
  _FakeAuthFacade(this._userId);
  final String? _userId;

  @override
  Stream<AuthStateChanged> authStateChanges() => const Stream.empty();

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    return const AuthResult.success();
  }

  @override
  Future<void> signOut() async {}

  @override
  String? currentUserId() => _userId;
}

/// A fake profile facade that records completeOnboarding calls.
class _FakeProfileFacade implements ProfileFacade {
  _FakeProfileFacade({this.completeOnboardingGate});

  final Completer<void>? completeOnboardingGate;
  bool onboardingCompleted = false;
  int completeCalls = 0;

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    return ProfileSnapshot(
      exists: true,
      onboardingCompleted: onboardingCompleted,
    );
  }

  @override
  Future<void> completeOnboarding(String userId) async {
    completeCalls++;
    final gate = completeOnboardingGate;
    if (gate != null) {
      await gate.future;
    }
    onboardingCompleted = true;
  }

  @override
  Future<void> persistIntake({
    required String userId,
    String? goal,
    int? trainingDaysPerWeek,
    List<String>? equipment,
    String? experienceLevel,
    List<String>? limitations,
    String? whyNow,
  }) async {}
}

/// Build a handoff screen wrapped in ProviderScope + MaterialApp for testing.
Future<_HandoffHarness> _pumpHandoff(
  WidgetTester tester, {
  required PlanIntake intake,
  String userId = 'user-1',
  Completer<void>? completeOnboardingGate,
  PlanIntake? pendingIntake,
  String? pendingWhyNow,
}) async {
  final authState = AuthGuardState(
    initialStatus: AuthGuardStatus.authenticatedNoProfile,
  );
  final profileFacade = _FakeProfileFacade(
    completeOnboardingGate: completeOnboardingGate,
  );

  final router = GoRouter(
    initialLocation: '/onboarding/handoff',
    routes: [
      GoRoute(
        path: '/onboarding/handoff',
        name: 'onboarding-handoff',
        builder: (context, state) => FirstSessionHandoffScreen(intake: intake),
      ),
      GoRoute(
        path: '/',
        name: 'today',
        builder: (context, state) => const Scaffold(body: Text('TODAY_SCREEN')),
      ),
      GoRoute(
        path: '/workout',
        name: 'workout',
        builder: (context, state) {
          final extra = state.extra;
          return Scaffold(
            body: Column(
              children: [
                const Text('WORKOUT_SCREEN'),
                if (extra is WorkoutPrefill)
                  Column(
                    children: [
                      Text(
                        'PLAN_EXTRA:${extra.exerciseName}:${extra.targetReps}:${extra.targetRpe}:${extra.targetRestSeconds}',
                      ),
                      Text(
                        'PLAN_QUEUE:${extra.sessionExercises.map((exercise) => '${exercise.exerciseName}:${exercise.targetSets}:${exercise.targetReps}:${exercise.targetRpe}:${exercise.targetRestSeconds}').join('|')}',
                      ),
                    ],
                  )
                else
                  const Text('PLAN_EXTRA:none'),
              ],
            ),
          );
        },
      ),
    ],
  );

  final container = ProviderContainer(
    overrides: [
      authGuardStateProvider.overrideWithValue(authState),
      authFacadeProvider.overrideWithValue(_FakeAuthFacade(userId)),
      profileFacadeProvider.overrideWithValue(profileFacade),
    ],
  );
  if (pendingIntake != null) {
    container.read(pendingIntakeProvider.notifier).setIntake(pendingIntake);
  }
  if (pendingWhyNow != null) {
    container.read(userWhyNowProvider.notifier).setPhrase(pendingWhyNow);
  }
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return _HandoffHarness(
    authState: authState,
    container: container,
    profileFacade: profileFacade,
    router: router,
  );
}

class _HandoffHarness {
  _HandoffHarness({
    required this.authState,
    required this.container,
    required this.profileFacade,
    required this.router,
  });
  final AuthGuardState authState;
  final ProviderContainer container;
  final _FakeProfileFacade profileFacade;
  final GoRouter router;
}

void main() {
  group('FirstSessionHandoffScreen (VAL-ONB-046..053)', () {
    const dumbbellsIntake = PlanIntake(
      goal: 'build_muscle',
      trainingDaysPerWeek: 3,
      equipment: ['dumbbells'],
      experienceLevel: 'intermediate',
    );

    testWidgets('VAL-ONB-046: handoff renders session 1 details', (
      tester,
    ) async {
      await _pumpHandoff(tester, intake: dumbbellsIntake);

      // The handoff screen shows a ready-to-train heading.
      expect(find.text('Ready to train'), findsOneWidget);
      // Session 1 details are rendered.
      expect(find.textContaining('Session 1'), findsWidgets);
      // The first day's focus label is shown.
      final plan = generatePlan(dumbbellsIntake);
      expect(find.textContaining(plan.days.first.focus), findsWidgets);
    });

    testWidgets(
      'VAL-ONB-049: first session exercises use only selected equipment',
      (tester) async {
        await _pumpHandoff(tester, intake: dumbbellsIntake);

        final plan = generatePlan(dumbbellsIntake);
        final allowed = {'bodyweight', 'dumbbells'};
        final session1 = plan.days.first;

        // Every exercise in session 1 must be achievable with the selected equipment.
        for (final ex in session1.exercises) {
          expect(
            allowed.contains(ex.equipment),
            isTrue,
            reason: '${ex.name} needs ${ex.equipment}, not in $allowed',
          );
        }

        // At least one exercise name is rendered.
        expect(
          find.textContaining(session1.exercises.first.name),
          findsWidgets,
        );
      },
    );

    testWidgets('VAL-ONB-048: no paywall at the handoff', (tester) async {
      await _pumpHandoff(tester, intake: dumbbellsIntake);

      // No payment-related text anywhere on the handoff.
      expect(
        find.textContaining('subscribe', findRichText: true),
        findsNothing,
      );
      expect(find.textContaining('upgrade', findRichText: true), findsNothing);
      expect(find.textContaining('checkout', findRichText: true), findsNothing);
      expect(find.textContaining('payment', findRichText: true), findsNothing);
      expect(find.textContaining('pricing', findRichText: true), findsNothing);
    });

    testWidgets(
      'VAL-ONB-047: handoff CTA leads into the session loop (no dead-end)',
      (tester) async {
        final harness = await _pumpHandoff(tester, intake: dumbbellsIntake);

        // The CTA is present and labeled.
        final cta = find.bySemanticsLabel('Start session');
        expect(cta, findsOneWidget);

        // Before tapping, onboarding is NOT complete (VAL-ONB-060: flag flips
        // only at the handoff CTA, not earlier).
        expect(harness.profileFacade.onboardingCompleted, isFalse);
        expect(
          harness.container.read(sessionControllerProvider).state.activeSession,
          isNull,
        );

        // Tapping it starts the real session loop, flips onboarding-complete,
        // and navigates to the live workout.
        await tester.tap(cta);
        await tester.pumpAndSettle();

        final sessionState = harness.container
            .read(sessionControllerProvider)
            .state;
        expect(sessionState.readinessEntry, isNotNull);
        expect(sessionState.activeSession, isNotNull);
        expect(
          sessionState.activeSession!.readinessEntryId,
          sessionState.readinessEntry!.id,
        );
        expect(harness.profileFacade.onboardingCompleted, isTrue);
        expect(harness.profileFacade.completeCalls, equals(1));
        expect(find.text('WORKOUT_SCREEN'), findsOneWidget);
        final session1 = generatePlan(dumbbellsIntake).days.first;
        final firstExercise = session1.exercises.first;
        expect(
          find.text(
            'PLAN_EXTRA:${firstExercise.name}:${firstExercise.repsMin}:'
            '${firstExercise.rpeTarget}:${firstExercise.restSeconds}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'PLAN_QUEUE:${session1.exercises.map((exercise) => '${exercise.name}:${exercise.sets}:${exercise.repsMin}:${exercise.rpeTarget}:${exercise.restSeconds}').join('|')}',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'handoff enters workout before remote onboarding completion resolves',
      (tester) async {
        final profileGate = Completer<void>();
        final harness = await _pumpHandoff(
          tester,
          intake: dumbbellsIntake,
          completeOnboardingGate: profileGate,
        );
        final cta = find.bySemanticsLabel('Start session');

        await tester.tap(cta);
        await tester.pumpAndSettle();

        final sessionState = harness.container
            .read(sessionControllerProvider)
            .state;
        final session1 = generatePlan(dumbbellsIntake).days.first;
        expect(sessionState.activeSession, isNotNull);
        expect(
          sessionState.activeSessionPlan,
          hasLength(session1.exercises.length),
        );
        expect(
          sessionState.activeSessionPlan.first.exerciseId,
          session1.exercises.first.id,
        );
        expect(harness.profileFacade.completeCalls, equals(1));
        expect(harness.profileFacade.onboardingCompleted, isFalse);
        expect(
          harness.authState.status,
          AuthGuardStatus.authenticatedWithProfile,
        );
        expect(find.text('WORKOUT_SCREEN'), findsOneWidget);
        expect(
          find.text(
            'PLAN_QUEUE:${session1.exercises.map((exercise) => '${exercise.name}:${exercise.sets}:${exercise.repsMin}:${exercise.rpeTarget}:${exercise.restSeconds}').join('|')}',
          ),
          findsOneWidget,
        );

        profileGate.complete();
        await tester.pumpAndSettle();

        expect(harness.profileFacade.onboardingCompleted, isTrue);
        expect(find.text('WORKOUT_SCREEN'), findsOneWidget);
      },
    );

    testWidgets(
      'handoff clears pending intake and why-now after starting session',
      (tester) async {
        final harness = await _pumpHandoff(
          tester,
          intake: dumbbellsIntake,
          pendingIntake: dumbbellsIntake,
          pendingWhyNow: 'I want this to stick.',
        );
        expect(harness.container.read(pendingIntakeProvider), isNotNull);
        expect(
          harness.container.read(userWhyNowProvider),
          'I want this to stick.',
        );

        await tester.tap(find.bySemanticsLabel('Start session'));
        await tester.pumpAndSettle();

        expect(harness.container.read(pendingIntakeProvider), isNull);
        expect(harness.container.read(userWhyNowProvider), isNull);
        expect(find.text('WORKOUT_SCREEN'), findsOneWidget);
      },
    );

    testWidgets('handoff does not turn limitations into soreness', (
      tester,
    ) async {
      const limitedIntake = PlanIntake(
        goal: 'build_muscle',
        trainingDaysPerWeek: 3,
        equipment: ['dumbbells'],
        experienceLevel: 'intermediate',
        limitations: ['knee', 'shoulder'],
      );
      final harness = await _pumpHandoff(tester, intake: limitedIntake);
      final cta = find.bySemanticsLabel('Start session');

      await tester.tap(cta);
      await tester.pumpAndSettle();

      final sessionState = harness.container
          .read(sessionControllerProvider)
          .state;
      expect(sessionState.readinessEntry, isNotNull);
      expect(sessionState.readinessEntry!.sorenessMap, isEmpty);
      expect(sessionState.activeSession, isNotNull);
      expect(find.text('WORKOUT_SCREEN'), findsOneWidget);
    });

    testWidgets('VAL-ONB-052: no payment widgets in the handoff tree', (
      tester,
    ) async {
      await _pumpHandoff(tester, intake: dumbbellsIntake);

      // Structural: the handoff screen must not contain any widget that
      // could trigger a payment flow. We assert no ElevatedButton has a
      // payment-related label.
      final buttons = find.byType(ElevatedButton);
      for (int i = 0; i < buttons.evaluate().length; i++) {
        final widget = tester.widget<ElevatedButton>(buttons.at(i));
        final child = widget.child;
        if (child is Text) {
          final data = child.data ?? '';
          expect(
            data.toLowerCase().contains('subscribe'),
            isFalse,
            reason: 'payment CTA found: $data',
          );
          expect(
            data.toLowerCase().contains('upgrade'),
            isFalse,
            reason: 'payment CTA found: $data',
          );
        }
      }
    });

    testWidgets(
      'bodyweight-only intake yields a valid first session (VAL-ONB-057 boundary)',
      (tester) async {
        const bodyweightIntake = PlanIntake(
          goal: 'get_fitter',
          trainingDaysPerWeek: 3,
          equipment: <String>[],
          experienceLevel: 'beginner',
        );
        await _pumpHandoff(tester, intake: bodyweightIntake);

        final plan = generatePlan(bodyweightIntake);
        expect(plan.days.first.exercises, isNotEmpty);
        for (final ex in plan.days.first.exercises) {
          expect(ex.equipment, equals('bodyweight'));
        }
        // Handoff still renders.
        expect(find.text('Ready to train'), findsOneWidget);
      },
    );
  });
}
