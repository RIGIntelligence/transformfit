/// Local analytics event tracking service.
///
/// Logs events to an in-memory ring buffer. No external SDK dependency is
/// required — events can later be flushed to Supabase or a dedicated backend.
/// Pure Dart, no Flutter dependency.
library;

/// A single analytics event.
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.eventName,
    required this.timestamp,
    this.parameters = const {},
  });

  /// Well-known event names used throughout the app.
  static const String appOpen = 'app_open';
  static const String onboardingStart = 'onboarding_start';
  static const String onboardingComplete = 'onboarding_complete';
  static const String firstWorkout = 'first_workout';
  static const String workoutComplete = 'workout_complete';
  static const String coachInteraction = 'coach_interaction';
  static const String moodLogged = 'mood_logged';
  static const String nutritionLogged = 'nutrition_logged';
  static const String achievementUnlocked = 'achievement_unlocked';
  static const String screenView = 'screen_view';

  final String eventName;
  final DateTime timestamp;
  final Map<String, Object?> parameters;

  Map<String, Object?> toJson() => {
        'eventName': eventName,
        'timestamp': timestamp.toIso8601String(),
        'parameters': parameters,
      };
}

/// In-memory analytics service backed by a fixed-size ring buffer.
///
/// Thread-safe for single-isolate Flutter usage (Riverpod).
class AnalyticsService {
  AnalyticsService({this.maxEvents = 500});

  /// Maximum events retained in memory before oldest are dropped.
  final int maxEvents;

  final List<AnalyticsEvent> _buffer = [];

  /// Current number of buffered events.
  int get eventCount => _buffer.length;

  /// Unmodifiable view of all buffered events (oldest first).
  List<AnalyticsEvent> get events => List.unmodifiable(_buffer);

  /// Log an event with [eventName] and optional [parameters].
  void log(String eventName, [Map<String, Object?> parameters = const {}]) {
    _buffer.add(
      AnalyticsEvent(
        eventName: eventName,
        timestamp: DateTime.now(),
        parameters: Map.unmodifiable(parameters),
      ),
    );
    // Evict oldest when over capacity.
    if (_buffer.length > maxEvents) {
      _buffer.removeRange(0, _buffer.length - maxEvents);
    }
  }

  /// Log a screen view.
  void logScreenView(String screenName) {
    log(AnalyticsEvent.screenView, {'screen': screenName});
  }

  /// Export all buffered events as a JSON-serializable list.
  List<Map<String, Object?>> exportJson() =>
      _buffer.map((e) => e.toJson()).toList();

  /// Clear all buffered events.
  void clear() => _buffer.clear();
}
