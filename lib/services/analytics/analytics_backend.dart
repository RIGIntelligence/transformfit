/// Analytics backend — event schema, batching, and offline queue.
///
/// Pure Dart, no external dependency. Events are typed, batched in groups
/// of 50, and stored locally when offline.
library;

import 'dart:collection';

// ---------------------------------------------------------------------------
// Event categories
// ---------------------------------------------------------------------------

/// High-level analytics event categories.
enum EventCategory {
  engagement,
  conversion,
  retention,
  error,
  performance,
}

// ---------------------------------------------------------------------------
// Typed analytics event
// ---------------------------------------------------------------------------

/// A strongly-typed analytics event with required metadata.
class AnalyticsEvent {
  AnalyticsEvent({
    required this.name,
    required this.category,
    required this.properties,
    DateTime? timestamp,
    this.userId,
    this.sessionId,
    this.platform,
    this.appVersion,
  }) : timestamp = timestamp ?? DateTime.now();

  final String name;
  final EventCategory category;
  final DateTime timestamp;
  final Map<String, Object?> properties;
  final String? userId;
  final String? sessionId;
  final String? platform;
  final String? appVersion;

  Map<String, Object?> toJson() => {
        'name': name,
        'category': category.name,
        'timestamp': timestamp.toIso8601String(),
        'properties': properties,
        if (userId != null) 'userId': userId,
        if (sessionId != null) 'sessionId': sessionId,
        if (platform != null) 'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
      };
}

// ---------------------------------------------------------------------------
// Batch send model
// ---------------------------------------------------------------------------

/// Result of a batch send attempt.
enum BatchSendResult { success, failure, offline }

/// Contract for sending event batches to a remote backend.
abstract class AnalyticsTransport {
  Future<BatchSendResult> sendBatch(List<AnalyticsEvent> events);
}

/// No-op transport — drops events. Useful for dev/testing.
class NoopAnalyticsTransport implements AnalyticsTransport {
  const NoopAnalyticsTransport();

  @override
  Future<BatchSendResult> sendBatch(List<AnalyticsEvent> events) async =>
      BatchSendResult.success;
}

// ---------------------------------------------------------------------------
// Offline store (in-memory, bounded)
// ---------------------------------------------------------------------------

/// In-memory offline event store. In production this would persist to disk.
class OfflineEventStore {
  OfflineEventStore({this.maxEvents = 5000});

  final int maxEvents;
  final List<AnalyticsEvent> _store = [];

  int get count => _store.length;
  bool get isEmpty => _store.isEmpty;

  void add(AnalyticsEvent event) {
    _store.add(event);
    if (_store.length > maxEvents) {
      _store.removeRange(0, _store.length - maxEvents);
    }
  }

  void addAll(Iterable<AnalyticsEvent> events) {
    for (final e in events) {
      add(e);
    }
  }

  /// Drain up to [count] events from the store (FIFO).
  List<AnalyticsEvent> drain(int count) {
    final n = count.clamp(0, _store.length);
    final drained = _store.sublist(0, n);
    _store.removeRange(0, n);
    return drained;
  }

  void clear() => _store.clear();
}

// ---------------------------------------------------------------------------
// Analytics backend
// ---------------------------------------------------------------------------

/// Core analytics backend with batching and offline support.
class AnalyticsBackend {
  AnalyticsBackend({
    AnalyticsTransport? transport,
    OfflineEventStore? offlineStore,
    this.batchSize = 50,
    this.sessionId,
    this.platform,
    this.appVersion,
  })  : transport = transport ?? const NoopAnalyticsTransport(),
        offlineStore = offlineStore ?? OfflineEventStore();

  final AnalyticsTransport transport;
  final OfflineEventStore offlineStore;
  final int batchSize;
  final String? sessionId;
  final String? platform;
  final String? appVersion;

  String? _userId;
  final Queue<AnalyticsEvent> _queue = Queue();

  /// Set the current user ID for subsequent events.
  void setUserId(String? userId) => _userId = userId;

  /// Enqueue an event for delivery.
  void track(AnalyticsEvent event) {
    _queue.add(AnalyticsEvent(
      name: event.name,
      category: event.category,
      timestamp: event.timestamp,
      properties: event.properties,
      userId: event.userId ?? _userId,
      sessionId: event.sessionId ?? sessionId,
      platform: event.platform ?? platform,
      appVersion: event.appVersion ?? appVersion,
    ));
  }

  /// Enqueue a simple named event.
  void trackSimple(
    String name,
    EventCategory category, [
    Map<String, Object?> properties = const {},
  ]) {
    track(AnalyticsEvent(
      name: name,
      category: category,
      properties: properties,
    ));
  }

  /// Flush queued events — sends in batches of [batchSize].
  ///
  /// If the transport fails, events are moved to the offline store.
  Future<void> flush() async {
    while (_queue.length >= batchSize) {
      final batch = <AnalyticsEvent>[];
      for (var i = 0; i < batchSize && _queue.isNotEmpty; i++) {
        batch.add(_queue.removeFirst());
      }
      final result = await transport.sendBatch(batch);
      if (result == BatchSendResult.offline) {
        offlineStore.addAll(batch);
      } else if (result == BatchSendResult.failure) {
        offlineStore.addAll(batch);
      }
    }
  }

  /// Retry sending any offline-stored events.
  Future<void> retryOffline() async {
    while (offlineStore.count > 0) {
      final batch = offlineStore.drain(batchSize);
      final result = await transport.sendBatch(batch);
      if (result != BatchSendResult.success) {
        // Put them back.
        offlineStore.addAll(batch);
        break;
      }
    }
  }

  /// Number of events waiting in the queue.
  int get queueLength => _queue.length;

  /// Number of events stored offline.
  int get offlineCount => offlineStore.count;

  /// Drain all queued events as JSON (for debugging / testing).
  List<Map<String, Object?>> drainQueueAsJson() {
    final list = _queue.map((e) => e.toJson()).toList();
    _queue.clear();
    return list;
  }
}
