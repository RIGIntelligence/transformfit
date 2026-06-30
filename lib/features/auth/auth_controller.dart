// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/auth/auth_service.dart';
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
  final controller = AuthController(
    authFacade: facade,
    profileFacade: profileFacade,
    guard: guard,
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
  }) : _authFacade = authFacade,
       _profileFacade = profileFacade,
       _guard = guard;

  final AuthFacade _authFacade;
  final ProfileFacade _profileFacade;
  final AuthGuardState _guard;

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
      _guard = AuthGuardState();

  void start() {
    _guard.setStatus(AuthGuardStatus.loading);
    _sub = _authFacade.authStateChanges().listen(_handle, onError: _onError);
  }

  Future<void> refresh() async {
    final userId = _authFacade.currentUserId() ?? _lastUserId;
    if (userId == null) {
      _guard.setStatus(AuthGuardStatus.unauthenticated);
      return;
    }
    await _resolveProfile(userId);
  }

  void _onError(Object error, StackTrace stack) {
    debugPrint('auth stream error: $error');
    _guard.setStatus(AuthGuardStatus.unauthenticated);
  }

  Future<void> _handle(AuthStateChanged change) async {
    if (_disposed) return;
    switch (change.event) {
      case AuthEvent.initial:
      case AuthEvent.signedIn:
        final userId = change.userId;
        if (userId == null) {
          _guard.setStatus(AuthGuardStatus.unauthenticated);
          return;
        }
        _lastUserId = userId;
        await _resolveProfile(userId);
      case AuthEvent.tokenRefreshed:
        // Session remains valid; keep current status but reaffirm if we have
        // a session and are somehow still in loading/unauthenticated.
        if (change.userId != null) {
          _lastUserId = change.userId;
          if (_guard.status == AuthGuardStatus.loading ||
              _guard.status == AuthGuardStatus.unauthenticated) {
            await _resolveProfile(change.userId!);
          }
        }
      case AuthEvent.signedOut:
        _lastUserId = null;
        _guard.setStatus(AuthGuardStatus.unauthenticated);
      case AuthEvent.error:
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
      snapshot = await _profileFacade.fetchProfile(userId);
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
    // Profile row genuinely absent (or unreadable): route to onboarding rather
    // than leaking the authenticated user into the main app.
    _guard.setStatus(AuthGuardStatus.authenticatedNoProfile);
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _sub = null;
  }
}

class _NoopAuthFacade implements AuthFacade {
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
  String? currentUserId() => null;
}

class _NoopProfileFacade implements ProfileFacade {
  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    return const ProfileSnapshot(exists: false, onboardingCompleted: false);
  }

  @override
  Future<void> completeOnboarding(String userId) async {}
}
