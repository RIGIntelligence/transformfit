import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transformfit/features/session/session_controller.dart';

class SessionSnapshotStore {
  const SessionSnapshotStore({
    this.preferencesLoader = SharedPreferences.getInstance,
    this.key = defaultKey,
  });

  static const defaultKey = 'transformfit.session_state.v1';

  final Future<SharedPreferences> Function() preferencesLoader;
  final String key;

  Future<SessionState?> load() async {
    final preferences = await preferencesLoader();
    final rawSnapshot = preferences.getString(key);
    if (rawSnapshot == null || rawSnapshot.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawSnapshot);
      return SessionState.fromJson(Map<String, Object?>.from(decoded as Map));
    } catch (_) {
      await preferences.remove(key);
      return null;
    }
  }

  Future<void> save(SessionState state) async {
    final preferences = await preferencesLoader();
    await preferences.setString(key, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final preferences = await preferencesLoader();
    await preferences.remove(key);
  }
}

final sessionSnapshotStoreProvider = Provider<SessionSnapshotStore>((ref) {
  return const SessionSnapshotStore();
});
