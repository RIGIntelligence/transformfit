import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The discrete auth lifecycle events the controller reacts to. We model our
/// own enum (instead of re-exporting Supabase's [AuthChangeEvent]) so that
/// pure widget/unit tests can drive the controller without depending on the
/// Supabase SDK at all.
enum AuthEvent {
  initial,
  signedIn,
  signedOut,
  tokenRefreshed,
  passwordRecovery,
  error,
}

/// A single emission from the auth state stream.
///
/// Carries the derived user id (rather than the SDK [Session]) so the
/// controller and its tests never depend on the Supabase SDK types.
class AuthStateChanged {
  const AuthStateChanged({required this.event, this.userId, this.message});

  final AuthEvent event;
  final String? userId;
  final String? message;
}

/// Outcome of a credential operation (sign-up / sign-in).
class AuthResult {
  const AuthResult.success()
    : isSuccess = true,
      userMessage = null,
      rawMessage = null;

  const AuthResult.failure(this.userMessage, {this.rawMessage})
    : isSuccess = false;

  final bool isSuccess;

  /// User-facing, sanitized error message (always non-null on failure).
  final String? userMessage;

  /// The raw upstream message (for diagnostics; never shown raw to users).
  final String? rawMessage;
}

/// A snapshot of the user's profile state relevant to routing.
class ProfileSnapshot {
  const ProfileSnapshot({required this.exists, required this.onboardingCompleted});

  final bool exists;
  final bool onboardingCompleted;
}

/// Abstract auth surface. The real implementation wraps the Supabase GoTrue
/// client; tests inject a fake.
abstract class AuthFacade {
  Stream<AuthStateChanged> authStateChanges();

  Future<AuthResult> signUp({required String email, required String password});

  Future<AuthResult> signIn({required String email, required String password});

  Future<void> signOut();

  /// The current user id, or null when there is no session.
  String? currentUserId();
}

/// Abstract profile surface. The real implementation reads/writes `profiles`
/// via PostgREST (publishable key + RLS owner-scoped); tests inject a fake.
abstract class ProfileFacade {
  /// Fetches the profile snapshot for [userId]. Returns
  /// [ProfileSnapshot(exists: false)] if the row is absent.
  Future<ProfileSnapshot> fetchProfile(String userId);

  /// Marks the user's profile as having completed onboarding.
  Future<void> completeOnboarding(String userId);

  /// Persists the intake-quiz answers to the user's profile. Called only after
  /// the full flow finishes (never mid-intake), so [completeOnboarding] and
  /// [persistIntake] flip together and the onboarding-complete flag is never
  /// set with a half-built profile (VAL-ONB-060).
  Future<void> persistIntake({
    required String userId,
    String? goal,
    int? trainingDaysPerWeek,
    List<String>? equipment,
    String? experienceLevel,
    List<String>? limitations,
    String? whyNow,
  });
}

// ---------------------------------------------------------------------------
// Supabase-backed implementations
// ---------------------------------------------------------------------------

bool _supabaseReady() {
  try {
    // Accessing the client throws a StateError before Supabase.initialize().
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

/// Maps a raw Supabase [AuthException] / error message to a user-facing string.
String _mapAuthError(Object error) {
  final raw = error is AuthException
      ? error.message
      : error.toString();
  final lower = raw.toLowerCase();

  // GoTrue returns the same message for wrong-password and unknown-email to
  // avoid user enumeration; surface a single clear credential error.
  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid credentials')) {
    return 'Incorrect email or password.';
  }
  if (lower.contains('user already registered') ||
      lower.contains('already been registered') ||
      lower.contains('already registered')) {
    return 'An account with this email already exists.';
  }
  if (lower.contains('password') &&
      (lower.contains('short') ||
          lower.contains('weak') ||
          lower.contains('at least') ||
          lower.contains('length'))) {
    return 'Password is too short. Use at least 6 characters.';
  }
  if (lower.contains('email') &&
      (lower.contains('invalid') || lower.contains('not allowed') ||
          lower.contains('signups not allowed'))) {
    return 'This email address is not allowed.';
  }
  if (lower.contains('rate limit') || lower.contains('rate_limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  // Fallback: surface a generic message, never the raw token/internal text.
  return 'Something went wrong. Please try again.';
}

/// Real [AuthFacade] backed by `supabase_flutter`.
///
/// Defensive against Supabase not being initialized (offline / tests): the
/// stream emits a single `initial` event with no session, credential calls
/// return a failure, and `signOut` is a no-op. This preserves the
/// offline-first mandate (L6-4) so the app shell never dead-ends on a missing
/// backend.
class SupabaseAuthFacade implements AuthFacade {
  SupabaseAuthFacade();

  GoTrueClient? get _auth {
    if (!_supabaseReady()) return null;
    try {
      return Supabase.instance.client.auth;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AuthStateChanged> authStateChanges() {
    final auth = _auth;
    if (auth == null) {
      // No backend: emit a single initial empty session so the guard resolves
      // to `unauthenticated` rather than hanging on `loading`.
      return Stream.value(const AuthStateChanged(event: AuthEvent.initial));
    }
    return auth.onAuthStateChange.map((e) {
      final event = switch (e.event) {
        AuthChangeEvent.initialSession => AuthEvent.initial,
        AuthChangeEvent.signedIn => AuthEvent.signedIn,
        AuthChangeEvent.signedOut => AuthEvent.signedOut,
        AuthChangeEvent.tokenRefreshed => AuthEvent.tokenRefreshed,
        AuthChangeEvent.passwordRecovery => AuthEvent.passwordRecovery,
        AuthChangeEvent.userUpdated => AuthEvent.signedIn,
        _ => AuthEvent.tokenRefreshed,
      };
      return AuthStateChanged(event: event, userId: e.session?.user.id);
    });
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const AuthResult.failure(
        'Authentication is unavailable. Please reload the app.',
      );
    }
    try {
      await auth.signUp(email: email, password: password);
      // With email confirmations disabled, signUp establishes a session and
      // the auth stream fires signedIn; the controller routes from there.
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e), rawMessage: e.message);
    } catch (e) {
      return AuthResult.failure(_mapAuthError(e), rawMessage: e.toString());
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const AuthResult.failure(
        'Authentication is unavailable. Please reload the app.',
      );
    }
    try {
      await auth.signInWithPassword(
        email: email,
        password: password,
      );
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e), rawMessage: e.message);
    } catch (e) {
      return AuthResult.failure(_mapAuthError(e), rawMessage: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      // Default scope revokes the refresh token server-side (GoTrue logout)
      // AND clears the persisted local session, satisfying both the local
      // re-guard and server-side invalidation.
      await auth.signOut();
    } catch (e) {
      debugPrint('signOut error (ignored): $e');
    }
  }

  @override
  String? currentUserId() {
    final auth = _auth;
    if (auth == null) return null;
    try {
      return auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
}

/// Real [ProfileFacade] backed by PostgREST (publishable key, owner-scoped RLS).
class SupabaseProfileFacade implements ProfileFacade {
  SupabaseProfileFacade();

  @override
  Future<ProfileSnapshot> fetchProfile(String userId) async {
    if (!_supabaseReady()) {
      // No backend: treat as "needs onboarding" so the shell resolves to the
      // onboarding surface rather than leaking protected content.
      return const ProfileSnapshot(exists: false, onboardingCompleted: false);
    }
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .limit(1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        final done = row['onboarding_completed'] == true;
        return ProfileSnapshot(exists: true, onboardingCompleted: done);
      }
      return const ProfileSnapshot(exists: false, onboardingCompleted: false);
    } catch (e) {
      debugPrint('fetchProfile error: $e');
      // Avoid leaking the authenticated user into the main app when we cannot
      // confirm onboarding state.
      return const ProfileSnapshot(exists: false, onboardingCompleted: false);
    }
  }

  @override
  Future<void> completeOnboarding(String userId) async {
    if (!_supabaseReady()) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'onboarding_completed': true})
          .eq('id', userId);
    } catch (e) {
      debugPrint('completeOnboarding error: $e');
      rethrow;
    }
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
    if (!_supabaseReady()) return;
    try {
      final updates = <String, Object?>{};
      if (goal != null) updates['goal'] = goal;
      if (trainingDaysPerWeek != null) {
        updates['training_days_per_week'] = trainingDaysPerWeek;
      }
      if (equipment != null) updates['equipment'] = equipment;
      if (experienceLevel != null) updates['experience_level'] = experienceLevel;
      if (limitations != null) updates['limitations'] = limitations;
      if (whyNow != null) updates['identity_anchor'] = whyNow;
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      debugPrint('persistIntake error: $e');
      rethrow;
    }
  }
}
