/// Smart notification scheduling based on user behavior.
///
/// Respects a daily cap and avoids over-notifying. Pure Dart, deterministic.
library;

import 'package:transformfit/services/notifications/notification_service.dart';

/// User behavior signals used to decide which notifications to schedule.
class UserBehaviorSignals {
  const UserBehaviorSignals({
    this.preferredCheckInHour = 9,
    this.preferredCheckInMinute = 0,
    this.trainingWeekdays = const [1, 3, 5], // Mon, Wed, Fri
    this.workoutHour = 18,
    this.workoutMinute = 0,
    this.moodLoggedToday = false,
    this.currentStreak = 0,
    this.streakAtRisk = false,
    this.lastActiveDate,
  });

  final int preferredCheckInHour;
  final int preferredCheckInMinute;
  final List<int> trainingWeekdays;
  final int workoutHour;
  final int workoutMinute;
  final bool moodLoggedToday;
  final int currentStreak;
  final bool streakAtRisk;
  final DateTime? lastActiveDate;
}

/// Schedules notifications intelligently based on [UserBehaviorSignals].
///
/// Rules:
/// - Max 3 notifications per day
/// - Daily check-in always scheduled
/// - Workout reminders only on training days
/// - Mood check-in only if no mood logged today
/// - Streak risk only if streak is actually at risk
class NotificationScheduler {
  NotificationScheduler(this._service);

  final NotificationService _service;

  /// Maximum notifications allowed per day.
  static const int maxDailyNotifications = 3;

  /// Schedule notifications based on current user signals.
  ///
  /// Returns the number of notifications scheduled.
  Future<int> scheduleForDay(UserBehaviorSignals signals) async {
    // Clear previous schedule to avoid duplicates.
    await _service.cancelAll();

    var scheduled = 0;

    // 1. Daily check-in (always)
    if (scheduled < maxDailyNotifications) {
      await _service.scheduleDaily(
        hour: signals.preferredCheckInHour,
        minute: signals.preferredCheckInMinute,
      );
      scheduled++;
    }

    // 2. Workout reminder (only on training days)
    final today = DateTime.now().weekday;
    if (scheduled < maxDailyNotifications &&
        signals.trainingWeekdays.contains(today)) {
      await _service.scheduleWorkoutReminder(
        hour: signals.workoutHour,
        minute: signals.workoutMinute,
        weekdays: signals.trainingWeekdays,
      );
      scheduled++;
    }

    // 3. Mood check-in (if not logged today, different time from daily)
    if (scheduled < maxDailyNotifications && !signals.moodLoggedToday) {
      final moodHour = (signals.preferredCheckInHour + 8) % 24;
      await _service.scheduleMoodCheckIn(
        hour: moodHour,
        minute: signals.preferredCheckInMinute,
      );
      scheduled++;
    }

    // 4. Streak risk (if at risk and we haven't hit the cap)
    if (scheduled < maxDailyNotifications && signals.streakAtRisk) {
      await _service.scheduleStreakRisk(
        streakDays: signals.currentStreak,
        hour: 20, // Evening nudge
        minute: 0,
      );
      scheduled++;
    }

    return scheduled;
  }

  /// Schedule an immediate achievement notification.
  Future<void> notifyAchievement({
    required String name,
    String? description,
  }) async {
    await _service.scheduleAchievement(
      achievementName: name,
      description: description,
    );
  }

  /// Get the current pending notifications.
  List<ScheduledNotification> get pending => _service.pendingNotifications;
}
