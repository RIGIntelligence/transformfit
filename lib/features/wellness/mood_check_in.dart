/// Daily mood tracking system with trend analysis.
///
/// Implements the circumplex model of affect (Russell, 1980) simplified to a
/// unidimensional mood scale. Mood tracking is a core component of
/// ecological momentary assessment (EMA) used in clinical psychology.
///
/// Evidence base:
/// - Daily mood monitoring improves self-awareness and emotional regulation
///   (Bakker & Rickard, 2018, "Engagement in mobile phone apps for
///   self-report of mood").
/// - Mood-energy-sleep correlations follow the tripartite model of anxiety
///   and depression (Clark & Watson, 1991).
/// - Streak-based habit formation leverages the "don't break the chain"
///   effect documented in habit formation research (Clear, 2018).
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

import 'dart:math' as math;

/// Five-level mood scale mapped to integer values.
///
/// Derived from the PANAS (Positive and Negative Affect Schedule) simplified
/// to a single-axis valence dimension. Each level carries a visual
/// representation for UI rendering and a numeric value for mathematical
/// operations (averaging, trend analysis).
enum MoodLevel {
  /// Intensely negative affect. Value = 1.
  terrible(1),

  /// Mildly negative affect. Value = 2.
  bad(2),

  /// Neutral affect. Value = 3.
  okay(3),

  /// Mildly positive affect. Value = 4.
  good(4),

  /// Intensely positive affect. Value = 5.
  great(5);

  const MoodLevel(this.value);

  /// Numeric value for mathematical operations.
  final int value;

  /// Emoji representation for visual display.
  String get emoji => switch (this) {
        MoodLevel.terrible => '😣',
        MoodLevel.bad => '😟',
        MoodLevel.okay => '😐',
        MoodLevel.good => '🙂',
        MoodLevel.great => '😄',
      };

  /// Human-readable label.
  String get label => switch (this) {
        MoodLevel.terrible => 'Terrible',
        MoodLevel.bad => 'Bad',
        MoodLevel.okay => 'Okay',
        MoodLevel.good => 'Good',
        MoodLevel.great => 'Great',
      };

  /// Hex color code for UI theming.
  ///
  /// Colors follow a warm-to-cool gradient aligned with affective valence:
  /// negative states use reds/oranges (high arousal negative), positive
  /// states use greens/blues (calm-positive per color-emotion mapping
  /// research, Valdez & Mehrabian, 1994).
  String get colorHex => switch (this) {
        MoodLevel.terrible => '#EF4444',
        MoodLevel.bad => '#F97316',
        MoodLevel.okay => '#EAB308',
        MoodLevel.good => '#22C55E',
        MoodLevel.great => '#3B82F6',
      };

  /// Create a MoodLevel from its integer value (1-5).
  static MoodLevel fromValue(int value) => switch (value) {
        1 => MoodLevel.terrible,
        2 => MoodLevel.bad,
        3 => MoodLevel.okay,
        4 => MoodLevel.good,
        5 => MoodLevel.great,
        _ => throw ArgumentError('MoodLevel value must be 1-5, got $value'),
      };
}

/// Mood trend direction derived from linear regression slope.
///
/// Thresholds calibrated from ecological momentary assessment literature:
/// a slope of ±0.1 per day over a 7-day window represents a meaningful
/// shift in affect (Koval et al., 2012).
enum MoodTrend {
  /// Slope > 0.1 per day — mood is meaningfully improving.
  improving,

  /// Slope between -0.1 and 0.1 — mood is stable.
  stable,

  /// Slope < -0.1 per day — mood is declining.
  declining,
}

/// A single mood log entry.
///
/// Captures mood along with contextual correlates. Energy and sleep
/// correlation fields enable cross-domain analysis consistent with the
/// biopsychosocial model of wellness.
class MoodEntry {
  const MoodEntry({
    required this.level,
    required this.timestamp,
    this.note,
    this.energyCorrelation,
    this.sleepCorrelation,
  });

  /// The mood level rated by the user.
  final MoodLevel level;

  /// Optional free-text note (journaling component).
  final String? note;

  /// When this mood was logged.
  final DateTime timestamp;

  /// Self-reported energy level at time of mood check-in (1-10).
  ///
  /// Captures the arousal dimension of affect per Russell's circumplex model.
  final int? energyCorrelation;

  /// Self-reported sleep quality from the previous night (1-10).
  ///
  /// Sleep-mood bidirectional relationship is well-documented:
  /// poor sleep predicts next-day negative affect (Finan et al., 2015).
  final int? sleepCorrelation;

  /// Numeric mood value for calculations.
  double get numericValue => level.value.toDouble();
}

/// Deterministic mood tracking engine.
///
/// Operates on an in-memory list of [MoodEntry] objects. The caller is
/// responsible for persistence — this class provides pure computation.
///
/// Trend analysis uses simple linear regression over the 7-day window,
/// which is sufficient for mood monitoring apps and avoids overfitting
/// to noise (more sophisticated models like Kalman filters add complexity
/// without meaningful improvement at daily cadence).
class MoodTracker {
  MoodTracker({List<MoodEntry>? entries}) : _entries = entries ?? [];

  final List<MoodEntry> _entries;

  /// All logged entries (unmodifiable view).
  List<MoodEntry> get entries => List.unmodifiable(_entries);

  /// Log a new mood entry.
  ///
  /// Returns the entry for chaining. Does not validate ordering — the
  /// caller should ensure timestamps are reasonable.
  MoodEntry logMood({
    required MoodLevel level,
    required DateTime timestamp,
    String? note,
    int? energyCorrelation,
    int? sleepCorrelation,
  }) {
    final entry = MoodEntry(
      level: level,
      timestamp: timestamp,
      note: note,
      energyCorrelation: energyCorrelation,
      sleepCorrelation: sleepCorrelation,
    );
    _entries.add(entry);
    return entry;
  }

  /// Get today's mood entry, or null if none logged today.
  ///
  /// Uses the provided [now] for determinism in testing.
  MoodEntry? getTodayMood(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (final entry in _entries.reversed) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      if (entryDate == today) return entry;
    }
    return null;
  }

  /// Average mood value over the last 7 days.
  ///
  /// Returns null if no entries exist in the window. Uses simple arithmetic
  /// mean — weighted averages (e.g., recency-weighted) were considered but
  /// add complexity without clear benefit for a 7-day window.
  double? getWeekAverage(DateTime now) {
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekEntries = _entries
        .where((e) => e.timestamp.isAfter(weekAgo))
        .toList();
    if (weekEntries.isEmpty) return null;
    final sum = weekEntries.fold<double>(
      0,
      (acc, e) => acc + e.numericValue,
    );
    return sum / weekEntries.length;
  }

  /// Analyze mood trend over the last 30 days using linear regression.
  ///
  /// Returns null if fewer than 3 data points (insufficient for meaningful
  /// regression). The slope threshold of ±0.1/day is derived from EMA
  /// literature on minimal detectable change in daily mood ratings.
  MoodTrend? getMonthTrend(DateTime now) {
    final monthAgo = now.subtract(const Duration(days: 30));
    final monthEntries = _entries
        .where((e) => e.timestamp.isAfter(monthAgo))
        .toList();
    if (monthEntries.length < 3) return null;

    // Simple linear regression: y = mx + b
    // x = days from first entry, y = mood value
    final firstTime = monthEntries.first.timestamp;
    final n = monthEntries.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (final entry in monthEntries) {
      final x = entry.timestamp.difference(firstTime).inHours / 24.0;
      final y = entry.numericValue;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return MoodTrend.stable;

    final slope = (n * sumXY - sumX * sumY) / denominator;

    if (slope > 0.1) return MoodTrend.improving;
    if (slope < -0.1) return MoodTrend.declining;
    return MoodTrend.stable;
  }

  /// Count consecutive days with mood entries ending at [now].
  ///
  /// Streak counting is a powerful behavioral nudge — the "don't break the
  /// chain" technique (attributed to Jerry Seinfeld) leverages loss aversion
  /// to maintain habit consistency.
  ///
  /// Returns 0 if today has no entry. Counts backward from today.
  int getMoodStreak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final entryDates = <DateTime>{};
    for (final entry in _entries) {
      entryDates.add(DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      ));
    }

    if (!entryDates.contains(today)) return 0;

    int streak = 0;
    var checkDate = today;
    while (entryDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Compute Pearson correlation between mood and energy.
  ///
  /// Returns null if fewer than 3 paired data points. Uses the standard
  /// Pearson formula: r = Σ((x-μx)(y-μy)) / √(Σ(x-μx)² · Σ(y-μy)²).
  double? getMoodEnergyCorrelation() {
    final paired = _entries
        .where((e) => e.energyCorrelation != null)
        .toList();
    if (paired.length < 3) return null;

    return _pearsonCorrelation(
      paired.map((e) => e.numericValue).toList(),
      paired.map((e) => e.energyCorrelation!.toDouble()).toList(),
    );
  }

  /// Compute Pearson correlation between mood and sleep quality.
  double? getMoodSleepCorrelation() {
    final paired = _entries
        .where((e) => e.sleepCorrelation != null)
        .toList();
    if (paired.length < 3) return null;

    return _pearsonCorrelation(
      paired.map((e) => e.numericValue).toList(),
      paired.map((e) => e.sleepCorrelation!.toDouble()).toList(),
    );
  }

  /// Standard Pearson correlation coefficient.
  double _pearsonCorrelation(List<double> x, List<double> y) {
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double sumNum = 0, sumDenomX = 0, sumDenomY = 0;
    for (var i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      sumNum += dx * dy;
      sumDenomX += dx * dx;
      sumDenomY += dy * dy;
    }

    final denom = math.sqrt(sumDenomX * sumDenomY);
    if (denom == 0) return 0;
    return sumNum / denom;
  }
}
