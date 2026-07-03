// Unit tests for the M4 offline sync queue.

import 'package:flutter_test/flutter_test.dart';
import 'package:transformfit/engine/offline_sync.dart';

void main() {
  group('SyncQueue: enqueue', () {
    test('adds operations to the queue', () {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-1'));

      expect(queue.pendingCount, 1);
      expect(queue.isEmpty, isFalse);
    });

    test('is idempotent (duplicate IDs not added)', () {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-1'));
      queue.enqueue(_makeOp('op-1'));

      expect(queue.pendingCount, 1);
    });
  });

  group('SyncQueue: remove', () {
    test('removes by operation ID', () {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-1'));
      queue.enqueue(_makeOp('op-2'));

      queue.remove('op-1');

      expect(queue.pendingCount, 1);
      expect(queue.pending.first.id, 'op-2');
    });
  });

  group('SyncQueue: markFailed', () {
    test('increments attempts and records error', () {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-1'));

      queue.markFailed('op-1', 'network timeout');

      final op = queue.all.first;
      expect(op.attempts, 1);
      expect(op.lastError, 'network timeout');
      expect(op.lastAttemptAt, isNotNull);
    });
  });

  group('SyncQueue: pruneDeadLetters', () {
    test('removes ops that exceed max attempts', () {
      final queue = SyncQueue();
      final op = _makeOp('op-1');
      queue.enqueue(op);

      // Fail it maxAttempts times.
      for (int i = 0; i < SyncOperation.maxAttempts; i++) {
        queue.markFailed('op-1', 'error $i');
      }

      expect(queue.pendingCount, 0); // no longer retryable

      final dead = queue.pruneDeadLetters();
      expect(dead.length, 1);
      expect(dead.first.id, 'op-1');
      expect(queue.all.length, 0);
    });
  });

  group('SyncQueue: flush (online success)', () {
    test('syncs all operations when transport succeeds', () async {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-1'));
      queue.enqueue(_makeOp('op-2'));

      final result = await queue.flush(_OnlineTransport());

      expect(result.synced, 2);
      expect(result.failed, 0);
      expect(result.pending, 0);
      expect(result.allSynced, isTrue);
    });
  });

  group('SyncQueue: flush (offline)', () {
    test('returns pending count when offline', () async {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-1'));
      queue.enqueue(_makeOp('op-2'));

      final result = await queue.flush(_OfflineTransport());

      expect(result.synced, 0);
      expect(result.failed, 0);
      expect(result.pending, 2);
    });
  });

  group('SyncQueue: flush (partial failure)', () {
    test('syncs successful ops and marks failed ones', () async {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-ok'));
      queue.enqueue(_makeOp('op-fail'));

      final result = await queue.flush(_PartialTransport());

      expect(result.synced, 1);
      expect(result.failed, 1);
      expect(result.pending, 1); // the failed one is still retryable
    });
  });

  group('SyncQueue: serialization', () {
    test('round-trips through JSON', () {
      final queue = SyncQueue();
      queue.enqueue(_makeOp('op-1'));
      queue.enqueue(_makeOp('op-2'));

      final json = queue.toJson();
      final restored = SyncQueue.fromJson(json);

      expect(restored.pendingCount, 2);
      expect(restored.pending.map((o) => o.id).toSet(), {'op-1', 'op-2'});
    });
  });

  group('SyncOperation: serialization', () {
    test('round-trips through JSON with all fields', () {
      final op = SyncOperation(
        id: 'test-op',
        type: SyncOperationType.loggedSet,
        table: 'logged_sets',
        payload: {'weightKg': 50.0, 'reps': 10},
        createdAt: DateTime(2026, 7, 3, 10, 0),
        attempts: 2,
        lastError: 'timeout',
        lastAttemptAt: DateTime(2026, 7, 3, 10, 5),
      );

      final json = op.toJson();
      final restored = SyncOperation.fromJson(json);

      expect(restored.id, op.id);
      expect(restored.type, op.type);
      expect(restored.table, op.table);
      expect(restored.payload, op.payload);
      expect(restored.attempts, op.attempts);
      expect(restored.lastError, op.lastError);
    });

    test('handles all operation types', () {
      for (final type in SyncOperationType.values) {
        final op = SyncOperation(
          id: 'op-${type.name}',
          type: type,
          table: 'test',
          payload: {},
          createdAt: DateTime(2026, 7, 3),
        );
        final restored = SyncOperation.fromJson(op.toJson());
        expect(restored.type, type);
      }
    });
  });
}

SyncOperation _makeOp(String id) {
  return SyncOperation(
    id: id,
    type: SyncOperationType.loggedSet,
    table: 'logged_sets',
    payload: {'exerciseId': 'goblet_squat', 'weightKg': 40.0, 'reps': 10},
    createdAt: DateTime(2026, 7, 3, 10, 0),
  );
}

class _OnlineTransport implements SyncTransport {
  @override
  Future<bool> isOnline() async => true;

  @override
  Future<void> send(SyncOperation op) async {
    // Simulate success.
  }
}

class _OfflineTransport implements SyncTransport {
  @override
  Future<bool> isOnline() async => false;

  @override
  Future<void> send(SyncOperation op) async {
    throw Exception('offline');
  }
}

class _PartialTransport implements SyncTransport {
  @override
  Future<bool> isOnline() async => true;

  @override
  Future<void> send(SyncOperation op) async {
    if (op.id == 'op-fail') {
      throw Exception('server error');
    }
  }
}
