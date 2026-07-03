import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/features/session/session_controller.dart';
import 'package:transformfit/features/session/session_snapshot_store.dart';

class LocalSessionCleaner {
  const LocalSessionCleaner({
    required this.sessionController,
    required this.snapshotStore,
  });

  final SessionController sessionController;
  final SessionSnapshotStore snapshotStore;

  Future<void> clear() async {
    sessionController.clear();
    await sessionController.waitForSnapshotWrites();
    await snapshotStore.clear();
  }
}

final localSessionCleanerProvider = Provider<LocalSessionCleaner>((ref) {
  return LocalSessionCleaner(
    sessionController: ref.read(sessionControllerProvider),
    snapshotStore: ref.read(sessionSnapshotStoreProvider),
  );
});
