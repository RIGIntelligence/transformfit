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
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
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
  _FakeProfileFacade({
    this.exists = true,
    this.onboardingCompleted = false,
    Map<String, ProfileSnapshot>? snapshotsByUserId,
    Map<String, Duration>? delaysByUserId,
    Set<String>? throwingUserIds,
  }) : snapshotsByUserId = snapshotsByUserId ?? const {},
       delaysByUserId = delaysByUserId ?? const {},
       throwingUserIds = throwingUserIds ?? const {};

  bool exists;
  bool onboardingCompleted;
  final Map<String, ProfileSnapshot> snapshotsByUserId;
  final Map<String, Duration> delaysByUserId;
  final Set<String> throwingUserIds;
  final fetchedUserIds = <String>[];

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    fetchedUserIds.add(userId);
    final delay = delaysByUserId[userId];
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    if (throwingUserIds.contains(userId)) {
      throw StateError('profile unavailable');
    }
    final snapshot = snapshotsByUserId[userId];
    if (snapshot != null) {
      return snapshot;
    }
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

Future<void> _waitForGuardStatus(
  AuthGuardState guard,
  AuthGuardStatus status, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (guard.status != status && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
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

  test('start is idempotent and does not duplicate auth listeners', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade(exists: true, onboardingCompleted: true);
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    );
    controller.start();
    controller.start();
    addTearDown(controller.dispose);

    facade.emit(
      const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-once'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
    expect(profile.fetchedUserIds, equals(['u-once']));
  });

  test(
    'initial null-session event resolves guard to unauthenticated',
    () async {
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
    },
  );

  test(
    'signedIn with onboarding-incomplete profile routes to onboarding',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: false,
      );
      final guard = AuthGuardState();
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-123'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(guard.status, AuthGuardStatus.authenticatedNoProfile);
    },
  );

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

    facade.emit(
      const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-123'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
  });

  test(
    'signedIn with a blank user id fails closed and clears local session',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: true,
      );
      final guard = AuthGuardState();
      var cleanupCalls = 0;
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
        localSessionCleaner: () async {
          cleanupCalls += 1;
        },
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: '   '),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cleanupCalls, equals(1));
      expect(guard.status, AuthGuardStatus.unauthenticated);
      expect(profile.fetchedUserIds, isEmpty);
    },
  );

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

    facade.emit(
      const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-123'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);

    facade.emit(const AuthStateChanged(event: AuthEvent.signedOut));
    await Future<void>.delayed(Duration.zero);

    expect(guard.status, AuthGuardStatus.unauthenticated);
  });

  test(
    'signedOut clears local session state before leaving authenticated route',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: true,
      );
      final guard = AuthGuardState();
      var cleanupCalls = 0;
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
        localSessionCleaner: () async {
          cleanupCalls += 1;
        },
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-123'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);

      facade.emit(const AuthStateChanged(event: AuthEvent.signedOut));
      await Future<void>.delayed(Duration.zero);

      expect(cleanupCalls, equals(1));
      expect(guard.status, AuthGuardStatus.unauthenticated);
    },
  );

  test('refresh with no current user clears local session state', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade();
    final guard = AuthGuardState();
    var cleanupCalls = 0;
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
      localSessionCleaner: () async {
        cleanupCalls += 1;
      },
    )..start();
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(cleanupCalls, equals(1));
    expect(guard.status, AuthGuardStatus.unauthenticated);
  });

  test(
    'signedIn as a different user clears prior local session state',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: true,
      );
      final guard = AuthGuardState();
      var cleanupCalls = 0;
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
        localSessionCleaner: () async {
          cleanupCalls += 1;
        },
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-first'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cleanupCalls, equals(0));
      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-second'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cleanupCalls, equals(1));
      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
    },
  );

  test(
    'stale profile response from a prior user cannot override newer user',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        snapshotsByUserId: const {
          'u-old': ProfileSnapshot(exists: true, onboardingCompleted: false),
          'u-new': ProfileSnapshot(exists: true, onboardingCompleted: true),
        },
        delaysByUserId: const {'u-old': Duration(milliseconds: 80)},
      );
      final guard = AuthGuardState();
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-old'),
      );
      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-new'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);

      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
      expect(profile.fetchedUserIds, equals(['u-old', 'u-new']));
    },
  );

  test('profile fetch failures resolve to onboarding fallback', () async {
    final facade = _FakeAuthFacade();
    final profile = _FakeProfileFacade(
      throwingUserIds: const {'u-failing-profile'},
    );
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(
      const AuthStateChanged(
        event: AuthEvent.signedIn,
        userId: 'u-failing-profile',
      ),
    );
    await _waitForGuardStatus(guard, AuthGuardStatus.authenticatedNoProfile);

    expect(guard.status, AuthGuardStatus.authenticatedNoProfile);
    expect(profile.fetchedUserIds, [
      'u-failing-profile',
      'u-failing-profile',
      'u-failing-profile',
    ]);
  });

  test(
    'repeated signedIn for the same user preserves local session state',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: true,
      );
      final guard = AuthGuardState();
      var cleanupCalls = 0;
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
        localSessionCleaner: () async {
          cleanupCalls += 1;
        },
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-same'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-same'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cleanupCalls, equals(0));
      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
    },
  );

  test('refresh re-resolves profile after onboarding completion', () async {
    final facade = _FakeAuthFacade(initialUserId: 'u-abc');
    final profile = _FakeProfileFacade(
      exists: true,
      onboardingCompleted: false,
    );
    final guard = AuthGuardState();
    final controller = AuthController(
      authFacade: facade,
      profileFacade: profile,
      guard: guard,
    )..start();
    addTearDown(controller.dispose);

    facade.emit(
      const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-abc'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(guard.status, AuthGuardStatus.authenticatedNoProfile);

    await profile.completeOnboarding('u-abc');
    await controller.refresh();
    expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
  });

  test(
    'refresh after auth error stays unauthenticated instead of using stale user',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: true,
      );
      final guard = AuthGuardState();
      var cleanupCalls = 0;
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
        localSessionCleaner: () async {
          cleanupCalls += 1;
        },
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-stale'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
      expect(profile.fetchedUserIds, equals(['u-stale']));

      facade.emit(const AuthStateChanged(event: AuthEvent.error));
      await Future<void>.delayed(Duration.zero);
      expect(guard.status, AuthGuardStatus.unauthenticated);
      expect(cleanupCalls, equals(1));

      await controller.refresh();

      expect(guard.status, AuthGuardStatus.unauthenticated);
      expect(cleanupCalls, equals(2));
      expect(profile.fetchedUserIds, equals(['u-stale']));
    },
  );

  test(
    'tokenRefreshed reaffirms profile when guard is still loading',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: true,
      );
      final guard = AuthGuardState();
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(
          event: AuthEvent.tokenRefreshed,
          userId: 'u-refresh',
        ),
      );
      await _waitForGuardStatus(
        guard,
        AuthGuardStatus.authenticatedWithProfile,
      );

      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
    },
  );

  test(
    'tokenRefreshed without a user fails closed and clears local session',
    () async {
      final facade = _FakeAuthFacade();
      final profile = _FakeProfileFacade(
        exists: true,
        onboardingCompleted: true,
      );
      final guard = AuthGuardState();
      var cleanupCalls = 0;
      final controller = AuthController(
        authFacade: facade,
        profileFacade: profile,
        guard: guard,
        localSessionCleaner: () async {
          cleanupCalls += 1;
        },
      )..start();
      addTearDown(controller.dispose);

      facade.emit(
        const AuthStateChanged(event: AuthEvent.signedIn, userId: 'u-token'),
      );
      await _waitForGuardStatus(
        guard,
        AuthGuardStatus.authenticatedWithProfile,
      );
      expect(guard.status, AuthGuardStatus.authenticatedWithProfile);
      expect(profile.fetchedUserIds, equals(['u-token']));

      facade.emit(const AuthStateChanged(event: AuthEvent.tokenRefreshed));
      await _waitForGuardStatus(guard, AuthGuardStatus.unauthenticated);

      expect(cleanupCalls, equals(1));
      expect(guard.status, AuthGuardStatus.unauthenticated);

      await controller.refresh();

      expect(cleanupCalls, equals(2));
      expect(guard.status, AuthGuardStatus.unauthenticated);
      expect(profile.fetchedUserIds, equals(['u-token']));
    },
  );
}
