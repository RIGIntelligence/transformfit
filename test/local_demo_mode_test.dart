import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/config/runtime_flags.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/main.dart';
import 'package:transformfit/navigation/auth_state.dart';

void main() {
  test('startup helpers seed a contained local demo state', () {
    final state = initialSessionStateForStartup(
      demoMode: true,
      storedState: const SessionState(),
    );
    final guard = authGuardStateForStartup(demoMode: true);
    addTearDown(guard.dispose);

    expect(state.readinessEntry, isNotNull);
    expect(state.activeSession, isNotNull);
    expect(state.activeSessionPlan, hasLength(3));
    expect(state.history, hasLength(2));
    expect(state.lastDebrief?.painNotes, isNull);
    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);

    final normalGuard = authGuardStateForStartup(demoMode: false);
    addTearDown(normalGuard.dispose);
    expect(normalGuard.status, AuthGuardStatus.loading);
  });

  testWidgets(
    'local demo build boots into Today and sign out reseeds the sample state',
    (tester) async {
      final sessionController = SessionController(
        initialState: initialSessionStateForStartup(
          demoMode: transformfitDemoMode,
        ),
      );
      final authState = authGuardStateForStartup(
        demoMode: transformfitDemoMode,
      );
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWithValue(sessionController),
          authGuardStateProvider.overrideWithValue(authState),
          authControllerProvider.overrideWithValue(AuthController.noop()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TransformFitApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
      expect(sessionController.state.activeSession, isNotNull);
      expect(find.text('Sample workout'), findsOneWidget);
      expect(find.bySemanticsLabel('Apply sample next set'), findsOneWidget);
      expect(find.bySemanticsLabel('Log sample set'), findsOneWidget);

      final initialSetCount =
          sessionController.state.activeSession!.loggedSets.length;

      await tester.ensureVisible(
        find.bySemanticsLabel('Apply sample next set'),
      );
      await tester.tap(find.bySemanticsLabel('Apply sample next set'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Loaded:'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Log sample set'));
      await tester.pumpAndSettle();

      expect(
        sessionController.state.activeSession!.loggedSets,
        hasLength(initialSetCount + 1),
      );

      sessionController.clear();
      await tester.pumpAndSettle();
      expect(sessionController.state.activeSession, isNull);

      await tester.ensureVisible(find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(authState.status, AuthGuardStatus.authenticatedWithProfile);
      expect(sessionController.state.activeSession, isNotNull);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    },
    skip: !transformfitDemoMode,
  );
}
