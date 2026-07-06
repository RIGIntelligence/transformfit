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
class Streak {
  const Streak({
    required this.type,
    required this.currentDays,
    required this.longestDays,
    required this.lastActivityDate,
    required this.isActive,
  });

  final StreakType type;
  final int currentDays;
  final int longestDays;
  final DateTime? lastActivityDate;

  /// Whether the streak is currently active (activity logged today or yesterday).
  final bool isActive;

  Streak copyWith({
    int? currentDays,
    int? longestDays,
    DateTime? lastActivityDate,
    bool? isActive,
  }) {
    return Streak(
      type: type,
      currentDays: currentDays ?? this.currentDays,
      longestDays: longestDays ?? this.longestDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Tracks streaks across multiple activity dimensions.
class StreakTracker {
  StreakTracker([Map<StreakType, Streak>? streaks])
      : _streaks = Map.from(streaks ?? {});

  final Map<StreakType, Streak> _streaks;

  /// Update (or create) the streak for [type] given an activity at [date].
  ///
  /// - If the activity is on the same day as [lastActivityDate], no change.
  /// - If it's the next day, the streak increments.
  /// - If it's later than that, the streak resets to 1.
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
        );
        _streaks[type] = updated;
        return updated;
      }
    }

    // First activity or broken streak — start fresh.
    final isActive = activityDay.isAtSameMomentAs(today);
    final streak = Streak(
      type: type,
      currentDays: 1,
      longestDays: existing != null
          ? (1 > existing.longestDays ? 1 : existing.longestDays)
          : 1,
      lastActivityDate: date,
      isActive: isActive,
    );
    _streaks[type] = streak;
    return streak;
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
  ///
  /// Scans from the earliest activity to [now], counting days where every
  /// streak type had activity.
  int getPerfectDays({DateTime? now}) {
    if (_streaks.length < StreakType.values.length) return 0;

    // Find the earliest activity date across all types.
    DateTime? earliest;
    for (final streak in _streaks.values) {
      if (streak.lastActivityDate == null) return 0;
      if (earliest == null || streak.lastActivityDate!.isBefore(earliest)) {
        earliest = streak.lastActivityDate;
      }
    }
    if (earliest == null) return 0;

    // For a lightweight implementation, perfect days = min current streak
    // across all types (conservative estimate based on active streaks).
    // A full calendar scan would require per-day activity records.
    final allActive = _streaks.values.every((s) => s.isActive);
    if (!allActive) return 0;

    // Return the minimum current streak length as a lower bound.
    return _streaks.values
        .map((s) => s.currentDays)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Returns a calendar map for the last [days] days.
  ///
  /// Keys are dates (at midnight), values are the set of streak types
  /// active on that day. Only days with at least one activity are included.
  Map<DateTime, Set<StreakType>> getStreakCalendar({int days = 30, DateTime? now}) {
    final today = _startOfDay(now ?? DateTime.now());
    final calendar = <DateTime, Set<StreakType>>{};

    for (final streak in _streaks.entries) {
      if (streak.value.lastActivityDate == null) continue;
      // Mark the lastActivityDate for each type.
      // For a full calendar we'd need per-day records; here we mark
      // the known active days based on streak length.
      final lastDay = _startOfDay(streak.value.lastActivityDate!);
      for (int i = 0; i < streak.value.currentDays; i++) {
        final day = lastDay.subtract(Duration(days: i));
        if (day.isAfter(today) || day.isBefore(today.subtract(Duration(days: days)))) continue;
        calendar.putIfAbsent(day, () => {}).add(streak.key);
      }
    }

    return calendar;
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
