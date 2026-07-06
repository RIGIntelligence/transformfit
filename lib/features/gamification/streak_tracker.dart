library;

/// The types of activities that can form streaks.
enum StreakType {
  workout,
  mood,
  nutrition,
  sleep,
  mindfulness,
  readiness,
}

/// A single streak record for one activity type.
///
/// Grace days prevent the streak from breaking when a user misses a day due to
/// an irregular schedule. The streak only breaks when consecutive missed days
/// exceed the available grace days for the current week.
class Streak {
  const Streak({
    required this.type,
    required this.currentDays,
    required this.longestDays,
    required this.lastActivityDate,
    required this.isActive,
    this.graceDaysUsedThisWeek = 0,
    this.consecutiveMissedDays = 0,
  });

  final StreakType type;
  final int currentDays;
  final int longestDays;
  final DateTime? lastActivityDate;

  /// Whether the streak is currently active (activity logged today or yesterday
  /// or within grace day window).
  final bool isActive;

  /// How many grace days have been consumed this calendar week.
  final int graceDaysUsedThisWeek;

  /// How many consecutive days have been missed since the last activity.
  final int consecutiveMissedDays;

  Streak copyWith({
    int? currentDays,
    int? longestDays,
    DateTime? lastActivityDate,
    bool? isActive,
    int? graceDaysUsedThisWeek,
    int? consecutiveMissedDays,
  }) {
    return Streak(
      type: type,
      currentDays: currentDays ?? this.currentDays,
      longestDays: longestDays ?? this.longestDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      isActive: isActive ?? this.isActive,
      graceDaysUsedThisWeek:
          graceDaysUsedThisWeek ?? this.graceDaysUsedThisWeek,
      consecutiveMissedDays:
          consecutiveMissedDays ?? this.consecutiveMissedDays,
    );
  }
}

/// Tracks streaks across multiple activity dimensions with grace day support.
///
/// Grace days let users maintain streaks with irregular schedules. A user who
/// trains 3-4x/week (e.g. Mon/Wed/Fri/Sat) would naturally have gaps, and
/// grace days keep their streak alive.
///
/// Default: 2 grace days per week (configurable via [graceDaysPerWeek]).
///
/// Logic:
///   - Consecutive day → streak extends, consecutive missed resets to 0.
///   - Missed 1 day → uses 1 grace day if available, streak continues.
///   - Missed 2 days → uses 2 grace days if available, streak continues.
///   - Missed > grace days remaining → streak resets to 1.
///   - Grace days reset at the start of each calendar week (Monday).
class StreakTracker {
  StreakTracker({
    Map<StreakType, Streak>? streaks,
    this.graceDaysPerWeek = 2,
  }) : _streaks = Map.from(streaks ?? {});

  final Map<StreakType, Streak> _streaks;

  /// Number of grace days allowed per calendar week. Configurable.
  final int graceDaysPerWeek;

  /// Update (or create) the streak for [type] given an activity at [date].
  ///
  /// - If the activity is on the same day as [lastActivityDate], no change.
  /// - If it's the next day, the streak increments.
  /// - If it's within grace days, the streak continues (grace days consumed).
  /// - If it's beyond grace days, the streak resets to 1.
  /// Returns the updated [Streak].
  Streak updateStreak(StreakType type, DateTime date, {DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    final activityDay = _startOfDay(date);
    final existing = _streaks[type];

    if (existing != null && existing.lastActivityDate != null) {
      final lastDay = _startOfDay(existing.lastActivityDate!);

      if (activityDay.isAtSameMomentAs(lastDay)) {
        // Same day — no change needed, just mark active.
        final updated = existing.copyWith(isActive: true);
        _streaks[type] = updated;
        return updated;
      }

      final diff = activityDay.difference(lastDay).inDays;
      if (diff == 1) {
        // Consecutive day — extend streak.
        final newCurrent = existing.currentDays + 1;
        final newLongest =
            newCurrent > existing.longestDays ? newCurrent : existing.longestDays;
        final isActive = activityDay.isAtSameMomentAs(today);
        final updated = existing.copyWith(
          currentDays: newCurrent,
          longestDays: newLongest,
          lastActivityDate: date,
          isActive: isActive,
          consecutiveMissedDays: 0, // reset on activity
        );
        _streaks[type] = updated;
        return updated;
      }

      // Missed 1+ days — check grace days.
      final missedDays = diff - 1; // days between last activity and this one
      final graceUsedThisWeek = _currentWeekGraceDaysUsed(existing, activityDay);
      final graceAvailable = graceDaysPerWeek - graceUsedThisWeek;

      if (missedDays <= graceAvailable) {
        // Grace days cover the gap — streak continues.
        final newCurrent = existing.currentDays + 1;
        final newLongest =
            newCurrent > existing.longestDays ? newCurrent : existing.longestDays;
        final isActive = activityDay.isAtSameMomentAs(today);
        final updated = existing.copyWith(
          currentDays: newCurrent,
          longestDays: newLongest,
          lastActivityDate: date,
          isActive: isActive,
          graceDaysUsedThisWeek: graceUsedThisWeek + missedDays,
          consecutiveMissedDays: 0,
        );
        _streaks[type] = updated;
        return updated;
      }
    }

    // First activity or broken streak (beyond grace days) — start fresh.
    final isActive = activityDay.isAtSameMomentAs(today);
    final streak = Streak(
      type: type,
      currentDays: 1,
      longestDays: existing != null
          ? (1 > existing.longestDays ? 1 : existing.longestDays)
          : 1,
      lastActivityDate: date,
      isActive: isActive,
      graceDaysUsedThisWeek: 0,
      consecutiveMissedDays: 0,
    );
    _streaks[type] = streak;
    return streak;
  }

  /// Check if the streak is still alive (within grace day window) even though
  /// the user hasn't logged today. This lets the UI show "streak at risk" states.
  bool isStreakAlive(StreakType type, {DateTime? now}) {
    final streak = getStreak(type);
    if (!streak.isActive && streak.currentDays == 0) return false;
    if (streak.lastActivityDate == null) return false;

    final today = _startOfDay(now ?? DateTime.now());
    final lastDay = _startOfDay(streak.lastActivityDate!);
    final missedDays = today.difference(lastDay).inDays - 1;
    if (missedDays <= 0) return true; // active today or yesterday

    final graceUsed = _currentWeekGraceDaysUsed(streak, today);
    final graceAvailable = graceDaysPerWeek - graceUsed;
    return missedDays <= graceAvailable;
  }

  /// Get the number of grace days remaining this week for a streak type.
  int getGraceDaysRemaining(StreakType type, {DateTime? now}) {
    final streak = getStreak(type);
    final today = _startOfDay(now ?? DateTime.now());
    final graceUsed = _currentWeekGraceDaysUsed(streak, today);
    return (graceDaysPerWeek - graceUsed).clamp(0, graceDaysPerWeek);
  }

  /// Calculate how many grace days were used in the current calendar week
  /// for the given streak. Accounts for week rollover.
  int _currentWeekGraceDaysUsed(Streak streak, DateTime referenceDate) {
    if (streak.lastActivityDate == null) return 0;

    // If the last activity was in a different week, grace days reset.
    final lastWeek = _weekStart(streak.lastActivityDate!);
    final refWeek = _weekStart(referenceDate);
    if (lastWeek.isBefore(refWeek)) return 0;

    return streak.graceDaysUsedThisWeek;
  }

  /// Get the Monday of the week containing [d].
  static DateTime _weekStart(DateTime d) {
    final start = _startOfDay(d);
    final daysFromMonday = start.weekday - DateTime.monday;
    return start.subtract(Duration(days: daysFromMonday));
  }

  /// Get the streak for a specific type, or a zero-streak if none exists.
  Streak getStreak(StreakType type) {
    return _streaks[type] ??
        Streak(
          type: type,
          currentDays: 0,
          longestDays: 0,
          lastActivityDate: null,
          isActive: false,
        );
  }

  /// All tracked streaks.
  List<Streak> getAllStreaks() {
    return StreakType.values.map(getStreak).toList();
  }

  /// Count of perfect days — days where all 6 streak types were active.
  int getPerfectDays({DateTime? now}) {
    if (_streaks.length < StreakType.values.length) return 0;

    DateTime? earliest;
    for (final streak in _streaks.values) {
      if (streak.lastActivityDate == null) return 0;
      if (earliest == null || streak.lastActivityDate!.isBefore(earliest)) {
        earliest = streak.lastActivityDate;
      }
    }
    if (earliest == null) return 0;

    final allActive = _streaks.values.every((s) => s.isActive);
    if (!allActive) return 0;

    return _streaks.values
        .map((s) => s.currentDays)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Returns a calendar map for the last [days] days.
  Map<DateTime, Set<StreakType>> getStreakCalendar({int days = 30, DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    final calendar = <DateTime, Set<StreakType>>{};

    for (final streak in _streaks.entries) {
      if (streak.value.lastActivityDate == null) continue;
      final lastDay = _startOfDay(streak.value.lastActivityDate!);
      for (int i = 0; i < streak.value.currentDays; i++) {
        final day = lastDay.subtract(Duration(days: i));
        if (day.isAfter(today) ||
            day.isBefore(today.subtract(Duration(days: days)))) continue;
        calendar.putIfAbsent(day, () => {}).add(streak.key);
      }
    }

    return calendar;
  }

  /// Build a grace-day status summary for the UI.
  ///
  /// Returns a map of streak types to their grace day status:
  ///   - graceDaysUsed: how many used this week
  ///   - graceDaysRemaining: how many remain
  ///   - streakAlive: whether the streak is still within grace window
  Map<StreakType, ({int used, int remaining, bool alive})> getGraceDayStatus(
      {DateTime? now}) {
    final result = <StreakType, ({int used, int remaining, bool alive})>{};
    for (final type in StreakType.values) {
      final streak = getStreak(type);
      final today = _startOfDay(now ?? DateTime.now());
      final used = _currentWeekGraceDaysUsed(streak, today);
      final remaining = (graceDaysPerWeek - used).clamp(0, graceDaysPerWeek);
      result[type] = (
        used: used,
        remaining: remaining,
        alive: isStreakAlive(type, now: now),
      );
    }
    return result;
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
