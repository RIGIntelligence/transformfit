import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/navigation/auth_state.dart';
import 'package:transformfit/screens/auth_screen.dart';
import 'package:transformfit/widgets/transformfit_brand_mark.dart';

class _FakeAuthFacade implements AuthFacade {
  _FakeAuthFacade();

  final StreamController<AuthStateChanged> _controller =
      StreamController<AuthStateChanged>.broadcast();

  List<({bool signUp, String email, String password})> calls = [];
  AuthResult nextResult = const AuthResult.success();
  int signOutCalls = 0;

  @override
  Stream<AuthStateChanged> authStateChanges() => _controller.stream;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    calls.add((signUp: true, email: email, password: password));
    return nextResult;
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    calls.add((signUp: false, email: email, password: password));
    return nextResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  String? currentUserId() => 'u-fake';
}

Widget _wrap(ProviderContainer container, {bool localDemoEntryEnabled = true}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: AuthScreen(localDemoEntryEnabled: localDemoEntryEnabled),
    ),
  );
}

void main() {
  testWidgets(
    'renders Email, Password, and Sign in controls with semantics labels',
    (tester) async {
      final facade = _FakeAuthFacade();
      final container = ProviderContainer(
        overrides: [authFacadeProvider.overrideWithValue(facade)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Password'), findsOneWidget);
      expect(find.bySemanticsLabel('Sign in'), findsOneWidget);
      expect(
        find.bySemanticsLabel("Don't have an account? Sign up"),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Open sample workout'), findsOneWidget);
      expect(find.bySemanticsLabel('TransformFitAI logo'), findsOneWidget);
      expect(
        find.image(const AssetImage(TransformFitBrandMark.assetPath)),
        findsOneWidget,
      );
      expect(find.text('TransformFitAI'), findsOneWidget);
    },
  );

  testWidgets(
    'local demo opens deterministic workout state without auth call',
    (tester) async {
      final facade = _FakeAuthFacade();
      final sessionController = SessionController();
      final authState = AuthGuardState(
        initialStatus: AuthGuardStatus.unauthenticated,
      );
      final container = ProviderContainer(
        overrides: [
          authFacadeProvider.overrideWithValue(facade),
          sessionControllerProvider.overrideWithValue(sessionController),
          authGuardStateProvider.overrideWithValue(authState),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Open sample workout'));
      await tester.pumpAndSettle();

      expect(facade.calls, isEmpty);
      expect(authState.status, AuthGuardStatus.authenticatedWithProfile);
      expect(sessionController.state.readinessEntry, isNotNull);
      expect(sessionController.state.activeSession, isNotNull);
      expect(sessionController.state.activeSessionPlan, hasLength(3));
      expect(sessionController.state.history, hasLength(2));
      expect(
        sessionController.state.lastDebrief?.nextSessionFocus,
        contains('third squat set'),
      );
    },
  );

  testWidgets('local demo entry is hidden when disabled', (tester) async {
    final facade = _FakeAuthFacade();
    final sessionController = SessionController();
    final authState = AuthGuardState(
      initialStatus: AuthGuardStatus.unauthenticated,
    );
    final container = ProviderContainer(
      overrides: [
        authFacadeProvider.overrideWithValue(facade),
        sessionControllerProvider.overrideWithValue(sessionController),
        authGuardStateProvider.overrideWithValue(authState),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container, localDemoEntryEnabled: false));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Open sample workout'), findsNothing);
    expect(find.text('Open sample workout'), findsNothing);
    expect(facade.calls, isEmpty);
    expect(authState.status, AuthGuardStatus.unauthenticated);
    expect(sessionController.state.activeSession, isNull);
  });

  testWidgets('switching to sign-up mode exposes a Sign up button', (
    tester,
  ) async {
    final facade = _FakeAuthFacade();
    final container = ProviderContainer(
      overrides: [authFacadeProvider.overrideWithValue(facade)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel("Don't have an account? Sign up"));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Sign up'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Already have an account? Sign in'),
      findsOneWidget,
    );
  });

  testWidgets('Sign in calls the facade with entered credentials', (
    tester,
  ) async {
    final facade = _FakeAuthFacade();
    final container = ProviderContainer(
      overrides: [authFacadeProvider.overrideWithValue(facade)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Email'),
      'tester@transformfit.test',
    );
    await tester.enterText(find.bySemanticsLabel('Password'), 'supersecret');
    await tester.tap(find.bySemanticsLabel('Sign in'));
    await tester.pumpAndSettle();

    expect(facade.calls.length, 1);
    expect(facade.calls.single.signUp, isFalse);
    expect(facade.calls.single.email, 'tester@transformfit.test');
    expect(facade.calls.single.password, 'supersecret');
  });

  testWidgets('Sign up calls signUp on the facade', (tester) async {
    final facade = _FakeAuthFacade();
    final container = ProviderContainer(
      overrides: [authFacadeProvider.overrideWithValue(facade)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel("Don't have an account? Sign up"));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Email'),
      'new@transformfit.test',
    );
    await tester.enterText(find.bySemanticsLabel('Password'), 'newpassword');
    await tester.tap(find.bySemanticsLabel('Sign up'));
    await tester.pumpAndSettle();

    expect(facade.calls.single.signUp, isTrue);
    expect(facade.calls.single.email, 'new@transformfit.test');
  });

  testWidgets('surfaces an Auth error on failed sign-in', (tester) async {
    final facade = _FakeAuthFacade()
      ..nextResult = const AuthResult.failure('Incorrect email or password.');
    final container = ProviderContainer(
      overrides: [authFacadeProvider.overrideWithValue(facade)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Email'),
      'tester@transformfit.test',
    );
    await tester.enterText(find.bySemanticsLabel('Password'), 'supersecret');
    await tester.tap(find.bySemanticsLabel('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('blocks submit on invalid email', (tester) async {
    final facade = _FakeAuthFacade();
    final container = ProviderContainer(
      overrides: [authFacadeProvider.overrideWithValue(facade)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Email'), 'not-an-email');
    await tester.enterText(find.bySemanticsLabel('Password'), 'supersecret');
    await tester.tap(find.bySemanticsLabel('Sign in'));
    await tester.pumpAndSettle();

    expect(facade.calls, isEmpty);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('blocks submit on sub-minimum password', (tester) async {
    final facade = _FakeAuthFacade();
    final container = ProviderContainer(
      overrides: [authFacadeProvider.overrideWithValue(facade)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Email'),
      'tester@transformfit.test',
    );
    await tester.enterText(find.bySemanticsLabel('Password'), '12345');
    await tester.tap(find.bySemanticsLabel('Sign in'));
    await tester.pumpAndSettle();

    expect(facade.calls, isEmpty);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
  });
}
