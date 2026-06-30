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
import 'package:transformfit/navigation/auth_state.dart';

/// A minimal fake auth facade for widget tests.
class _FakeAuthFacade implements AuthFacade {
  _FakeAuthFacade(this._userId);
  final String? _userId;

  @override
  Stream<AuthStateChanged> authStateChanges() => const Stream.empty();

  @override
  Future<AuthResult> signUp({required String email, required String password}) async {
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    return const AuthResult.success();
  }

  @override
  Future<void> signOut() async {}

  @override
  String? currentUserId() => _userId;
}

/// A fake profile facade that records completeOnboarding calls.
class _FakeProfileFacade implements ProfileFacade {
  bool onboardingCompleted = false;
  int completeCalls = 0;

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    return ProfileSnapshot(exists: true, onboardingCompleted: onboardingCompleted);
  }

  @override
  Future<void> completeOnboarding(String userId) async {
    completeCalls++;
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
}) async {
  final authState = AuthGuardState(
    initialStatus: AuthGuardStatus.authenticatedNoProfile,
  );
  final profileFacade = _FakeProfileFacade();

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
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGuardStateProvider.overrideWithValue(authState),
        authFacadeProvider.overrideWithValue(_FakeAuthFacade(userId)),
        profileFacadeProvider.overrideWithValue(profileFacade),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _HandoffHarness(
    authState: authState,
    profileFacade: profileFacade,
    router: router,
  );
}

class _HandoffHarness {
  _HandoffHarness({
    required this.authState,
    required this.profileFacade,
    required this.router,
  });
  final AuthGuardState authState;
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

    testWidgets('VAL-ONB-046: handoff renders session 1 details',
        (tester) async {
      await _pumpHandoff(tester, intake: dumbbellsIntake);

      // The handoff screen shows a ready-to-train heading.
      expect(find.text('Ready to train'), findsOneWidget);
      // Session 1 details are rendered.
      expect(find.textContaining('Session 1'), findsWidgets);
      // The first day's focus label is shown.
      final plan = generatePlan(dumbbellsIntake);
      expect(find.textContaining(plan.days.first.focus), findsWidgets);
    });

    testWidgets('VAL-ONB-049: first session exercises use only selected equipment',
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
      expect(find.textContaining(session1.exercises.first.name), findsWidgets);
    });

    testWidgets('VAL-ONB-048: no paywall at the handoff', (tester) async {
      await _pumpHandoff(tester, intake: dumbbellsIntake);

      // No payment-related text anywhere on the handoff.
      expect(find.textContaining('subscribe', findRichText: true), findsNothing);
      expect(find.textContaining('upgrade', findRichText: true), findsNothing);
      expect(find.textContaining('checkout', findRichText: true), findsNothing);
      expect(find.textContaining('payment', findRichText: true), findsNothing);
      expect(find.textContaining('pricing', findRichText: true), findsNothing);
    });

    testWidgets('VAL-ONB-047: handoff CTA leads into the session loop (no dead-end)',
        (tester) async {
      final harness = await _pumpHandoff(tester, intake: dumbbellsIntake);

      // The CTA is present and labeled.
      final cta = find.bySemanticsLabel('Start session');
      expect(cta, findsOneWidget);

      // Before tapping, onboarding is NOT complete (VAL-ONB-060: flag flips
      // only at the handoff CTA, not earlier).
      expect(harness.profileFacade.onboardingCompleted, isFalse);

      // Tapping it flips onboarding-complete and navigates to home.
      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(harness.profileFacade.onboardingCompleted, isTrue);
      expect(harness.profileFacade.completeCalls, equals(1));
      expect(find.text('TODAY_SCREEN'), findsOneWidget);
    });

    testWidgets('VAL-ONB-052: no payment widgets in the handoff tree',
        (tester) async {
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

    testWidgets('bodyweight-only intake yields a valid first session (VAL-ONB-057 boundary)',
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
    });
  });
}
