import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/features/onboarding/intake_screen.dart';

/// In-memory fake profile facade so widget tests never touch Supabase.
class _FakeProfileFacade implements ProfileFacade {
  ProfileSnapshot snapshot = const ProfileSnapshot(
    exists: true,
    onboardingCompleted: false,
  );
  String? persistedGoal;
  int? persistedDays;
  List<String>? persistedEquipment;
  String? persistedExperience;
  List<String>? persistedLimitations;
  String? persistedWhyNow;
  bool completeOnboardingCalled = false;

  _FakeProfileFacade();

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async => snapshot;

  @override
  Future<void> completeOnboarding(String userId) async {
    completeOnboardingCalled = true;
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
  }) async {
    persistedGoal = goal;
    persistedDays = trainingDaysPerWeek;
    persistedEquipment = equipment;
    persistedExperience = experienceLevel;
    persistedLimitations = limitations;
    persistedWhyNow = whyNow;
  }
}

/// In-memory fake auth facade returning a deterministic signed-in user.
class _FakeAuthFacade implements AuthFacade {
  _FakeAuthFacade();

  @override
  Stream<AuthStateChanged> authStateChanges() =>
      Stream.value(AuthStateChanged(event: AuthEvent.signedIn, userId: 'user-123'));

  @override
  Future<AuthResult> signUp({required String email, required String password}) async =>
      const AuthResult.success();

  @override
  Future<AuthResult> signIn({required String email, required String password}) async =>
      const AuthResult.success();

  @override
  Future<void> signOut() async {}

  @override
  String? currentUserId() => 'user-123';
}

Widget _wrap({required _FakeProfileFacade profileFacade}) {
  return ProviderScope(
    overrides: [
      profileFacadeProvider.overrideWithValue(profileFacade),
      authFacadeProvider.overrideWithValue(_FakeAuthFacade()),
    ],
    child: const MaterialApp(
      home: IntakeScreen(),
    ),
  );
}

Future<void> _pumpApp(WidgetTester tester, _FakeProfileFacade facade) async {
  await tester.pumpWidget(_wrap(profileFacade: facade));
  await tester.pumpAndSettle();
}

void main() {
  group('IntakeScreen multi-step conversational flow', () {
    testWidgets('Step 1 (goals) renders with a prompt and a Next control', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      expect(find.bySemanticsLabel('Goals step'), findsOneWidget);
      expect(find.bySemanticsLabel('Next'), findsOneWidget);
    });

    testWidgets('progress indicator reflects step position', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      expect(find.bySemanticsLabel('Step 1 of 6'), findsOneWidget);
    });

    testWidgets('selecting a goal records the answer and enables advancing', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Training schedule step'), findsOneWidget);
    });

    testWidgets('Next is disabled on goals step when nothing is selected', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.bySemanticsLabel('Next'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('schedule step accepts a day-per-week selection', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // advance to schedule
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Training schedule step'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.bySemanticsLabel('Next'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('equipment step supports multi-select', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // goals -> schedule -> equipment
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Equipment step'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Equipment: barbell'));
      await tester.pumpAndSettle();

      // both chips should reflect selected state
      expect(find.bySemanticsLabel('Equipment: dumbbells'), findsOneWidget);
      expect(find.bySemanticsLabel('Equipment: barbell'), findsOneWidget);
    });

    testWidgets('experience step captures level', (WidgetTester tester) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // goal -> schedule -> equipment -> experience
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Experience step'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Experience: intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Injury step'), findsOneWidget);
    });

    testWidgets('injury step is optional and advances when empty', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // reach injury step
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Experience: intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      // injury step - advance without selecting anything ("none")
      await tester.tap(find.bySemanticsLabel('Injury: none'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Why now step'), findsOneWidget);
    });

    testWidgets('why-now step accepts free text', (WidgetTester tester) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // reach why-now step (optional, advance injury with 'none')
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Experience: intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Injury: none'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Why now step'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'I want to feel strong again');
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Finish'));
      await tester.pumpAndSettle();

      expect(facade.persistedWhyNow, 'I want to feel strong again');
    });

    testWidgets('forward navigation advances one step at a time', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      expect(find.bySemanticsLabel('Goals step'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Training schedule step'), findsOneWidget);

      // progress indicator advanced
      expect(find.bySemanticsLabel('Step 2 of 6'), findsOneWidget);
    });

    testWidgets('back navigation returns to the prior step', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Training schedule step'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Goals step'), findsOneWidget);
    });

    testWidgets('answers persist across back-then-forward round trips', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // Answer goal, advance, go back, verify retained, then complete.
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      // go back to goals
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      // goal still selected (Next is enabled)
      var nextBtn = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.bySemanticsLabel('Next'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(nextBtn.onPressed, isNotNull);

      // forward again, answer schedule, equipment, experience, injury, why-now
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Experience: intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Injury: none'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'because of my knee rehab',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Finish'));
      await tester.pumpAndSettle();

      expect(facade.persistedGoal, 'build_strength');
      expect(facade.persistedDays, 4);
      expect(facade.persistedWhyNow, 'because of my knee rehab');
      // completeOnboarding is NOT called on Finish (VAL-ONB-060); it is
      // called only when the user proceeds past the plan reveal.
      expect(facade.completeOnboardingCalled, isFalse);
    });

    testWidgets('no paywall nodes appear on any intake step', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      void expectNoPaywall() {
        expect(find.textContaining('subscribe', findRichText: true), findsNothing);
        expect(find.textContaining('checkout', findRichText: true), findsNothing);
        expect(find.textContaining('pricing', findRichText: true), findsNothing);
        expect(find.textContaining('\$', findRichText: true), findsNothing);
        expect(find.textContaining('payment', findRichText: true), findsNothing);
      }

      // step 1
      expectNoPaywall();
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expectNoPaywall();
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expectNoPaywall();
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expectNoPaywall();
      await tester.tap(find.bySemanticsLabel('Experience: intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expectNoPaywall();
      await tester.tap(find.bySemanticsLabel('Injury: none'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expectNoPaywall();
    });

    testWidgets('completeOnboarding is NOT called when Finish is tapped (VAL-ONB-060)', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // walking through must not call completeOnboarding
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      expect(facade.completeOnboardingCalled, isFalse);

      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(facade.completeOnboardingCalled, isFalse);

      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Experience: intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Injury: none'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(facade.completeOnboardingCalled, isFalse);

      // Finish navigates to the plan reveal; completeOnboarding is NOT
      // called until the user proceeds past the reveal (VAL-ONB-060).
      await tester.tap(find.bySemanticsLabel('Finish'));
      await tester.pumpAndSettle();
      expect(facade.completeOnboardingCalled, isFalse);
    });

    testWidgets('Back control is hidden on the first step', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      expect(find.bySemanticsLabel('Back'), findsNothing);
    });

    testWidgets('Last step shows a Finish control instead of Next', (
      WidgetTester tester,
    ) async {
      final facade = _FakeProfileFacade();
      await _pumpApp(tester, facade);

      // advance all the way to the last step without filling optionals much
      await tester.tap(find.bySemanticsLabel('Goal: build_strength'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Schedule: 4 days'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Equipment: dumbbells'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Experience: intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Injury: none'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Why now step'), findsOneWidget);
      expect(find.bySemanticsLabel('Finish'), findsOneWidget);
    });
  });
}
