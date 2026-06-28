import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthGuardStatus {
  loading,
  unauthenticated,
  authenticatedNoProfile,
  authenticatedWithProfile,
}

class AuthGuardState extends ChangeNotifier {
  AuthGuardState({AuthGuardStatus initialStatus = AuthGuardStatus.unauthenticated})
    : _status = initialStatus;

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
