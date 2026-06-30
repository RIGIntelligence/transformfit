import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthGuardStatus {
  loading,
  unauthenticated,
  authenticatedNoProfile,
  authenticatedWithProfile,
}

class AuthGuardState extends ChangeNotifier {
  /// Defaults to [AuthGuardStatus.loading] so the route guard shows a neutral
  /// loading surface (never protected content) until the real Supabase session
  /// resolves. Callers (tests) may pass an explicit [initialStatus].
  AuthGuardState({
    AuthGuardStatus initialStatus = AuthGuardStatus.loading,
  }) : _status = initialStatus;

  AuthGuardStatus _status;

  AuthGuardStatus get status => _status;

  void setStatus(AuthGuardStatus nextStatus) {
    if (_status == nextStatus) {
      return;
    }
    _status = nextStatus;
    notifyListeners();
  }
}

final authGuardStateProvider = Provider<AuthGuardState>((ref) {
  final state = AuthGuardState();
  ref.onDispose(state.dispose);
  return state;
});
