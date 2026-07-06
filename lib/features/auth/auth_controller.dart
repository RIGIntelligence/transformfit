// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/auth/auth_service.dart';
import 'package:transformfit/features/session/local_session_cleanup.dart';
import 'package:transformfit/navigation/auth_state.dart';

/// Riverpod providers for the auth feature.
///
/// `authFacadeProvider` / `profileFacadeProvider` default to the Supabase-backed
/// implementations and are overridable in tests. `authControllerProvider` wires
/// the auth state stream into the route guard ([AuthGuardState]) so routing is
/// driven by the real Supabase session + profile onboarding state.
final authFacadeProvider = Provider<AuthFacade>((ref) {
  return SupabaseAuthFacade();
});

final profileFacadeProvider = Provider<ProfileFacade>((ref) {
  return SupabaseProfileFacade();
});

/// Drives [AuthGuardState] from the Supabase auth stream + profile onboarding
/// state. Created (and kept alive) by the app widget watching it.
final authControllerProvider = Provider<AuthController>((ref) {
  final facade = ref.watch(authFacadeProvider);
  final profileFacade = ref.watch(profileFacadeProvider);
  final guard = ref.read(authGuardStateProvider);
  final localSessionCleaner = ref.read(localSessionCleanerProvider);
  final controller = AuthController(
    authFacade: facade,
    profileFacade: profileFacade,
    guard: guard,
    localSessionCleaner: localSessionCleaner.clear,
  );
  controller.start();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Maps auth lifecycle events onto the route guard status.
///
/// On a session (initial/signedIn/tokenRefreshed) it fetches the profile and
/// resolves to `authenticatedNoProfile` (onboarding incomplete) or
/// `authenticatedWithProfile`. On `signedOut`/`error` it resolves to
/// `unauthenticated`. The guard starts in `loading` so no protected content is
/// painted before the initial session resolves (VAL-FND-025 / VAL-FND-019).
class AuthController {
  AuthController({
    required AuthFacade authFacade,
    required ProfileFacade profileFacade,
    required AuthGuardState guard,
    Future<void> Function()? localSessionCleaner,
  }) : _authFacade = authFacade,
       _profileFacade = profileFacade,
       _guard = guard,
       _localSessionCleaner = localSessionCleaner;

  final AuthFacade _authFacade;
  final ProfileFacade _profileFacade;
  final AuthGuardState _guard;
  final Future<void> Function()? _localSessionCleaner;

  StreamSubscription<AuthStateChanged>? _sub;
  bool _disposed = false;

  /// The user id of the most recently observed session (for refresh).
  String? _lastUserId;

  /// A no-op controller for test overrides: it is NOT started, so it never
  /// touches the guard. Lets router/guard tests drive [AuthGuardState]
  /// directly while still satisfying [authControllerProvider].
  AuthController.noop()
    : _authFacade = _NoopAuthFacade(),
      _profileFacade = _NoopProfileFacade(),
      _guard = AuthGuardState(),
      _localSessionCleaner = null;

  void start() {
    if (_disposed || _sub != null) return;
    _guard.setStatus(AuthGuardStatus.loading);
    _sub = _authFacade.authStateChanges().listen(_handle, onError: _onError);
  }

  Future<void> refresh() async {
    final currentUserId = _authFacade.currentUserId();
    final userId = currentUserId == null
        ? _lastUserId
        : _normalizedUserId(currentUserId);
    if (userId == null) {
      _lastUserId = null;
      await _clearLocalSession();
      _guard.setStatus(AuthGuardStatus.unauthenticated);
      return;
    }
    await _rememberActiveUser(userId);
    await _resolveProfile(userId);
  }

  void _onError(Object error, StackTrace stack) {
    debugPrint('auth stream error: $error');
    _lastUserId = null;
    unawaited(_clearLocalSession());
    _guard.setStatus(AuthGuardStatus.unauthenticated);
  }

  Future<void> _handle(AuthStateChanged change) async {
    if (_disposed) return;
    switch (change.event) {
      case AuthEvent.initial:
      case AuthEvent.signedIn:
        final userId = _normalizedUserId(change.userId);
        if (userId == null) {
          _lastUserId = null;
          await _clearLocalSession();
          _guard.setStatus(AuthGuardStatus.unauthenticated);
          return;
        }
        await _rememberActiveUser(userId);
        await _resolveProfile(userId);
      case AuthEvent.tokenRefreshed:
        // Session remains valid; keep current status but reaffirm if we have
        // a session and are somehow still in loading/unauthenticated.
        final userId = _normalizedUserId(change.userId);
        if (userId == null) {
          _lastUserId = null;
          await _clearLocalSession();
          _guard.setStatus(AuthGuardStatus.unauthenticated);
          return;
        }
        await _rememberActiveUser(userId);
        if (_guard.status == AuthGuardStatus.loading ||
            _guard.status == AuthGuardStatus.unauthenticated) {
          await _resolveProfile(userId);
        }
      case AuthEvent.signedOut:
        _lastUserId = null;
        await _clearLocalSession();
        _guard.setStatus(AuthGuardStatus.unauthenticated);
      case AuthEvent.error:
        _lastUserId = null;
        await _clearLocalSession();
        _guard.setStatus(AuthGuardStatus.unauthenticated);
      case AuthEvent.passwordRecovery:
        // Not handled in M1; leave current status.
        break;
    }
  }

  Future<void> _resolveProfile(String userId) async {
    // The handle_new_user trigger runs in the same transaction as the auth
    // insert, so the profile exists by the time the session arrives. Retry a
    // few times to absorb any replication/transport latency.
    ProfileSnapshot snapshot;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (!_isCurrentUser(userId)) return;
      try {
        snapshot = await _profileFacade.fetchProfile(userId);
      } catch (error) {
        debugPrint('profile fetch failed: ${error.runtimeType}');
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          continue;
        }
        break;
      }
      if (!_isCurrentUser(userId)) return;
      if (snapshot.exists) {
        _guard.setStatus(
          snapshot.onboardingCompleted
              ? AuthGuardStatus.authenticatedWithProfile
              : AuthGuardStatus.authenticatedNoProfile,
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (!_isCurrentUser(userId)) return;
    // Profile row genuinely absent (or unreadable): route to onboarding rather
    // than leaking the authenticated user into the main app.
    _guard.setStatus(AuthGuardStatus.authenticatedNoProfile);
  }

  Future<void> _clearLocalSession() async {
    final cleaner = _localSessionCleaner;
    if (cleaner == null) return;
    try {
      await cleaner();
    } catch (error) {
      debugPrint('local session cleanup failed: ${error.runtimeType}');
    }
  }

  Future<void> _rememberActiveUser(String userId) async {
    final previousUserId = _lastUserId;
    if (previousUserId != null && previousUserId != userId) {
      await _clearLocalSession();
    }
    _lastUserId = userId;
  }

  bool _isCurrentUser(String userId) {
    return !_disposed && _lastUserId == userId;
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _sub = null;
  }
}

String? _normalizedUserId(String? userId) {
  final normalized = userId?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

class _NoopAuthFacade implements AuthFacade {
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
  String? currentUserId() => null;
}

class _NoopProfileFacade implements ProfileFacade {
  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    return const ProfileSnapshot(exists: false, onboardingCompleted: false);
  }

  @override
  Future<void> completeOnboarding(String userId) async {}

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
