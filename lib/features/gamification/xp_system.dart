library;

/// Actions that award XP, each with a base point value.
enum XpAction {
  workoutCompleted(50),
  setLogged(5),
  prAchieved(100),
  readinessChecked(10),
  moodLogged(15),
  mindfulnessCompleted(20),
  nutritionLogged(10),
  socialInteraction(5),
  streakMaintained(25),
  perfectWeek(200);

  const XpAction(this.basePoints);

  /// Base XP awarded for this action.
  final int basePoints;
}

/// A single XP award record.
class XpEntry {
  const XpEntry({
    required this.action,
    required this.points,
    required this.timestamp,
    this.multiplier = 1.0,
    this.bonusReason,
  });

  final XpAction action;
  final int points;
  final DateTime timestamp;
  final double multiplier;
  final String? bonusReason;

  /// Effective points after multiplier, rounded down.
  int get effectivePoints => (points * multiplier).floor();
}

/// Tracks all XP entries and computes levels, totals, and time-windowed sums.
class XpTracker {
  XpTracker([List<XpEntry>? entries]) : _entries = entries ?? [];

  final List<XpEntry> _entries;

  /// Immutable view of all entries, ordered chronologically.
  List<XpEntry> get entries => List.unmodifiable(_entries);

  /// Add XP for [action] at [timestamp] with optional [multiplier] and [bonusReason].
  ///
  /// Returns the created [XpEntry].
  XpEntry addXp(
    XpAction action, {
    DateTime? timestamp,
    double multiplier = 1.0,
    String? bonusReason,
  }) {
    final entry = XpEntry(
      action: action,
      points: action.basePoints,
      timestamp: timestamp ?? DateTime.now(),
      multiplier: multiplier,
      bonusReason: bonusReason,
    );
    _entries.add(entry);
    return entry;
  }

  /// Total effective XP across all entries.
  int getTotalXp() {
    return _entries.fold<int>(0, (sum, e) => sum + e.effectivePoints);
  }

  /// Current level based on cumulative XP.
  ///
  /// Level formula: level N requires N × 100 cumulative XP.
  ///   - Level 1: 100 XP
  ///   - Level 2: 300 XP (100 + 200)
  ///   - Level 3: 600 XP (100 + 200 + 300)
  ///   - Level N: N*(N+1)/2 * 100 XP
  ///
  /// Returns 0 if no XP earned yet.
  int getLevel() {
    final total = getTotalXp();
    int level = 0;
    int cumulative = 0;
    while (true) {
      final needed = (level + 1) * 100;
      if (cumulative + needed > total) break;
      cumulative += needed;
      level++;
    }
    return level;
  }

  /// XP still needed to reach the next level.
  int getXpToNextLevel() {
    final total = getTotalXp();
    final level = getLevel();
    int cumulative = 0;
    for (int i = 1; i <= level; i++) {
      cumulative += i * 100;
    }
    final nextLevelReq = (level + 1) * 100;
    return (cumulative + nextLevelReq) - total;
  }

  /// XP earned within the last 7 days from [now].
  int getWeeklyXp({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 7));
    return _entries
        .where((e) => e.timestamp.isAfter(cutoff))
        .fold<int>(0, (sum, e) => sum + e.effectivePoints);
  }

  /// XP earned today (same calendar date as [now]).
  int getDailyXp({DateTime? now}) {
    final today = now ?? DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _entries
        .where((e) =>
            !e.timestamp.isBefore(startOfDay) &&
            e.timestamp.isBefore(endOfDay))
        .fold<int>(0, (sum, e) => sum + e.effectivePoints);
  }
}
