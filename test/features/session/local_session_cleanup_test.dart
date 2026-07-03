import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/features/session/local_session_cleanup.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/session/session_snapshot_store.dart';

class _FakeSessionSnapshotStore extends SessionSnapshotStore {
  Completer<void>? saveGate;
  final events = <String>[];
  var hasSnapshot = false;
  var clearCalls = 0;

  @override
  Future<SessionState?> load() async {
    return hasSnapshot ? const SessionState() : null;
  }

  @override
  Future<void> save(SessionState state) async {
    events.add('save-start');
    final gate = saveGate;
    if (gate != null && !gate.isCompleted) {
      await gate.future;
    }
    events.add('save-finish');
    hasSnapshot = true;
  }

  @override
  Future<void> clear() async {
    events.add('clear');
    clearCalls += 1;
    hasSnapshot = false;
  }
}

void main() {
  test('clear wipes controller state and persisted snapshot', () async {
    final store = _FakeSessionSnapshotStore();
    final controller = SessionController(snapshotWriter: store.save);
    final cleaner = LocalSessionCleaner(
      sessionController: controller,
      snapshotStore: store,
    );

    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    controller.startSession();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.readinessEntry, isNotNull);
    expect(controller.state.activeSession, isNotNull);
    expect(store.hasSnapshot, isTrue);

    await cleaner.clear();

    expect(controller.state.readinessEntry, isNull);
    expect(controller.state.activeSession, isNull);
    expect(controller.state.lastDebrief, isNull);
    expect(controller.state.history, isEmpty);
    expect(store.clearCalls, equals(1));
    expect(store.hasSnapshot, isFalse);
  });

  test('clear drains queued snapshot writes before removing storage', () async {
    final store = _FakeSessionSnapshotStore();
    final saveGate = Completer<void>();
    store.saveGate = saveGate;
    final controller = SessionController(snapshotWriter: store.save);
    final cleaner = LocalSessionCleaner(
      sessionController: controller,
      snapshotStore: store,
    );

    controller.submitReadiness(
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: const [],
    );
    await Future<void>.delayed(Duration.zero);

    expect(store.events, equals(['save-start']));

    final cleanup = cleaner.clear();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.readinessEntry, isNull);
    expect(controller.state.activeSession, isNull);
    expect(store.events, equals(['save-start']));

    saveGate.complete();
    await cleanup;
    await controller.snapshotWritesIdle;

    expect(store.clearCalls, equals(1));
    expect(store.events, equals(['save-start', 'save-finish', 'clear']));
    expect(store.hasSnapshot, isFalse);
  });
}
