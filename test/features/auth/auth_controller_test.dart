import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/auth/auth_controller.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/navigation/auth_state.dart';

/// A controllable [AuthFacade] for tests.
class _FakeAuthFacade implements AuthFacade {
  _FakeAuthFacade({String? initialUserId}) : _userId = initialUserId;

  final StreamController<AuthStateChanged> _controller =
      StreamController<AuthStateChanged>.broadcast();
  String? _userId;
  int signOutCalls = 0;

  void emit(AuthStateChanged change) => _controller.add(change);
  void setUserId(String? id) => _userId = id;

  @override
  Stream<AuthStateChanged> authStateChanges() => _controller.stream;

  @override
  Future<AuthResult> signUp({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _userId = null;
    _controller.add(const AuthStateChanged(event: AuthEvent.signedOut));
  }

  @override
  String? currentUserId() => _userId;
}

class _FakeProfileFacade implements ProfileFacade {
  _FakeProfileFacade({this.exists = true, this.onboardingCompleted = false});
  bool exists;
  bool onboardingCompleted;

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    return ProfileSnapshot(
      exists: exists,
      onboardingCompleted: onboardingCompleted,
    );
  }

  @override
  Future<void> completeOnboarding(String userId) async {
    onboardingCompleted = true;
    exists = true;
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

void main() {
  test('guard starts in loading before the first event resolves', () {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade();
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    expect(guard.status, AuthGuardStatus.loading);
  });

  test('initial null-session event resolves guard to unauthenticated', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade();
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(const AuthStateChanged(event: AuthEvent.initial));
    await Future<void>.delayed(Duration.zero);

    expect(guard.status, AuthGuardStatus.unauthenticated);
  });

  test('signedIn with onboarding-incomplete profile routes to onboarding', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade(exists: true, onboardingCompleted: false);
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(const AuthStateChanged(
      event: AuthEvent.signedIn,
      userId: 'u-123',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(guard.status, AuthGuardStatus.authenticatedNoProfile);
  });

  test('signedIn with completed profile routes to main app', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade(exists: true, onboardingCompleted: true);
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(const AuthStateChanged(
      event: AuthEvent.signedIn,
      userId: 'u-123',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
  });

  test('signedOut resolves guard to unauthenticated', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade(exists: true, onboardingCompleted: true);
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(const AuthStateChanged(
      event: AuthEvent.signedIn,
      userId: 'u-123',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);

    facade.emit(const AuthStateChanged(event: AuthEvent.signedOut));
    await Future<void>.delayed(Duration.zero);

    expect(guard.status, AuthGuardStatus.unauthenticated);
  });

  test('refresh re-resolves profile after onboarding completion', () async {
    final facade = _FakeAuthFacade(initialUserId: 'u-abc');
    final profile = _FakeProfileFacade(exists: true, onboardingCompleted: false);
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(const AuthStateChanged(
      event: AuthEvent.signedIn,
      userId: 'u-abc',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(guard.status, AuthGuardStatus.authenticatedNoProfile);

    await profile.completeOnboarding('u-abc');
    await controller.refresh();
    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
  });

  test('tokenRefreshed reaffirms profile when guard is still loading', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade(exists: true, onboardingCompleted: true);
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(const AuthStateChanged(
      event: AuthEvent.tokenRefreshed,
      userId: 'u-refresh',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
  });
}
