/// Offline sync queue for M4 logging.
///
/// Doctrine L6-4 (offline-first): critical loop actions degrade safely
/// without network and sync deterministically later. This queue stores
/// pending mutations (logged sets, readiness check-ins, session completions)
/// locally and replays them to Supabase when connectivity is restored.
///
/// The queue is FIFO, idempotent (each operation has a client-generated
/// UUID), and surfaces sync failures honestly (never silently swallows).
library;

/// The type of mutation queued for sync.
enum SyncOperationType {
  readinessCheckIn,
  workoutSessionStart,
  loggedSet,
  workoutSessionComplete,
  sessionDebrief,
}

/// A pending sync operation.
class SyncOperation {
  SyncOperation({
    required this.id,
    required this.type,
    required this.table,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
    this.lastAttemptAt,
  });

  /// Client-generated UUID — idempotency key.
  final String id;
  final SyncOperationType type;
  final String table;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  int attempts;
  String? lastError;
  DateTime? lastAttemptAt;

  bool get isRetryable => attempts < maxAttempts;

  static const int maxAttempts = 5;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'table': table,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      };

  factory SyncOperation.fromJson(Map<String, Object?> json) {
    return SyncOperation(
      id: json['id']! as String,
      type: SyncOperationType.values.byName(json['type']! as String),
      table: json['table']! as String,
      payload: Map<String, Object?>.from(json['payload']! as Map),
      createdAt: DateTime.parse(json['createdAt']! as String),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt']! as String)
          : null,
    );
  }
}

/// Result of a sync flush attempt.
class SyncFlushResult {
  const SyncFlushResult({
    required this.synced,
    required this.failed,
    required this.pending,
  });

  final int synced;
  final int failed;
  final int pending;

  bool get allSynced => pending == 0 && failed == 0;
}

/// The offline sync queue. Pure data structure; the actual network calls
/// are injected via [SyncTransport].
class SyncQueue {
  SyncQueue() : _operations = [];

  final List<SyncOperation> _operations;

  List<SyncOperation> get pending =>
      _operations.where((op) => op.isRetryable).toList(growable: false);

  List<SyncOperation> get all =>
      List.unmodifiable(_operations);

  int get pendingCount => pending.length;

  bool get isEmpty => _operations.isEmpty;

  void enqueue(SyncOperation op) {
    // Idempotency: don't enqueue a duplicate ID.
    if (_operations.any((o) => o.id == op.id)) return;
    _operations.add(op);
  }

  /// Remove an operation after successful sync.
  void remove(String operationId) {
    _operations.removeWhere((op) => op.id == operationId);
  }

  /// Mark an operation as failed (incrementing attempts).
  void markFailed(String operationId, String error) {
    for (final op in _operations) {
      if (op.id == operationId) {
        op.attempts++;
        op.lastError = error;
        op.lastAttemptAt = DateTime.now();
        break;
      }
    }
  }

  /// Prune operations that have exceeded max attempts (dead-letter).
  List<SyncOperation> pruneDeadLetters() {
    final dead = _operations.where((op) => !op.isRetryable).toList();
    _operations.removeWhere((op) => !op.isRetryable);
    return dead;
  }

  /// Flush the queue through [transport]. Returns counts.
  Future<SyncFlushResult> flush(SyncTransport transport) async {
    if (!await transport.isOnline()) {
      return SyncFlushResult(synced: 0, failed: 0, pending: pendingCount);
    }

    int synced = 0;
    int failed = 0;

    for (final op in pending) {
      try {
        await transport.send(op);
        remove(op.id);
        synced++;
      } catch (e) {
        markFailed(op.id, e.toString());
        failed++;
      }
    }

    pruneDeadLetters();

    return SyncFlushResult(
      synced: synced,
      failed: failed,
      pending: pendingCount,
    );
  }

  /// Serialize for local persistence.
  List<Map<String, Object?>> toJson() =>
      _operations.map((op) => op.toJson()).toList();

  /// Deserialize from local persistence.
  static SyncQueue fromJson(List<dynamic> json) {
    final queue = SyncQueue();
    for (final entry in json) {
      queue.enqueue(
        SyncOperation.fromJson(Map<String, Object?>.from(entry! as Map)),
      );
    }
    return queue;
  }
}

/// Transport interface for sending operations to the backend.
/// Implemented by the real Supabase client or a test fake.
abstract class SyncTransport {
  Future<bool> isOnline();
  Future<void> send(SyncOperation op);
}
