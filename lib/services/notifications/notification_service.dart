/// Push notification service — abstract interface + local scheduling model.
///
/// Pure Dart, no external dependency. When ready for real push notifications,
/// implement with `flutter_local_notifications` + FCM/APNs.
library;

import 'dart:collection';

// ---------------------------------------------------------------------------
// Notification types
// ---------------------------------------------------------------------------

/// Categories of notifications the app can send.
enum NotificationType {
  dailyCheckin,
  workoutReminder,
  moodPrompt,
  streakRisk,
  achievement,
}

/// A scheduled notification.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.payload,
    this.recurring = false,
    this.recurrenceDays = const [],
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String? payload;

  /// If true, repeat on [recurrenceDays] (1 = Monday … 7 = Sunday).
  final bool recurring;
  final List<int> recurrenceDays;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toIso8601String(),
        'payload': payload,
        'recurring': recurring,
        'recurrenceDays': recurrenceDays,
      };
}

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

/// Notification scheduling contract.
abstract class NotificationService {
  /// Request permission to send notifications. Returns `true` if granted.
  Future<bool> requestPermission();

  /// Schedule a daily check-in notification at [hour]:[minute].
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    String title = 'Daily Check-in',
    String body = 'How are you feeling today? Log your mood and progress.',
  });

  /// Schedule a workout reminder on specific weekday(s).
  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required List<int> weekdays,
    String? workoutName,
  });

  /// Schedule a mood check-in prompt.
  Future<void> scheduleMoodCheckIn({
    required int hour,
    required int minute,
  });

  /// Schedule a streak-risk warning.
  Future<void> scheduleStreakRisk({
    required int streakDays,
    required int hour,
    required int minute,
  });

  /// Schedule an achievement celebration.
  Future<void> scheduleAchievement({
    required String achievementName,
    String? description,
  });

  /// Cancel all pending notifications.
  Future<void> cancelAll();

  /// Cancel a specific notification by [id].
  Future<void> cancel(String id);

  /// All currently scheduled notifications.
  List<ScheduledNotification> get pendingNotifications;
}

// ---------------------------------------------------------------------------
// Local implementation (in-memory scheduling model)
// ---------------------------------------------------------------------------

/// In-memory notification scheduler. Stores scheduled notifications and
/// exposes them for testing or for a platform adapter to consume.
class LocalNotificationService implements NotificationService {
  final Map<String, ScheduledNotification> _notifications = {};
  bool _permissionGranted = false;

  int _nextId = 1;
  String _generateId() => 'notif_${_nextId++}';

  @override
  Future<bool> requestPermission() async {
    // In a real implementation this would call the platform API.
    _permissionGranted = true;
    return _permissionGranted;
  }

  bool get isPermissionGranted => _permissionGranted;

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    String title = 'Daily Check-in',
    String body = 'How are you feeling today? Log your mood and progress.',
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    _notifications[id] = ScheduledNotification(
      id: id,
      type: NotificationType.dailyCheckin,
      title: title,
      body: body,
      scheduledAt: scheduled,
      recurring: true,
      recurrenceDays: [1, 2, 3, 4, 5, 6, 7], // Every day
    );
  }

  @override
  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required List<int> weekdays,
    String? workoutName,
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    _notifications[id] = ScheduledNotification(
      id: id,
      type: NotificationType.workoutReminder,
      title: 'Workout Time!',
      body: workoutName != null
          ? 'Time for your $workoutName workout. Let\'s crush it!'
          : 'Time for your scheduled workout. Let\'s go!',
      scheduledAt: scheduled,
      recurring: true,
      recurrenceDays: weekdays,
      payload: workoutName,
    );
  }

  @override
  Future<void> scheduleMoodCheckIn({
    required int hour,
    required int minute,
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    _notifications[id] = ScheduledNotification(
      id: id,
      type: NotificationType.moodPrompt,
      title: 'How Are You Feeling?',
      body: 'A quick mood check helps your coach personalize your plan.',
      scheduledAt: scheduled,
    );
  }

  @override
  Future<void> scheduleStreakRisk({
    required int streakDays,
    required int hour,
    required int minute,
  }) async {
    final id = _generateId();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    _notifications[id] = ScheduledNotification(
      id: id,
      type: NotificationType.streakRisk,
      title: 'Don\'t Break Your Streak!',
      body: 'You have a $streakDays-day streak going. Log in today to keep it alive!',
      scheduledAt: scheduled,
    );
  }

  @override
  Future<void> scheduleAchievement({
    required String achievementName,
    String? description,
  }) async {
    final id = _generateId();
    _notifications[id] = ScheduledNotification(
      id: id,
      type: NotificationType.achievement,
      title: '🏆 Achievement Unlocked!',
      body: description ?? 'You earned: $achievementName',
      scheduledAt: DateTime.now(), // Immediate
      payload: achievementName,
    );
  }

  @override
  Future<void> cancelAll() async {
    _notifications.clear();
  }

  @override
  Future<void> cancel(String id) async {
    _notifications.remove(id);
  }

  @override
  List<ScheduledNotification> get pendingNotifications =>
      UnmodifiableListView(_notifications.values.toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));

  /// Number of notifications currently scheduled.
  int get pendingCount => _notifications.length;
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

/// Create the default [NotificationService] instance.
NotificationService createNotificationService() => LocalNotificationService();
