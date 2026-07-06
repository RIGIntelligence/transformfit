/// M4: Weight trend analysis with exponential smoothing.
///
/// Implements MacroFactor-style exponential smoothing for body weight
/// trend analysis. Single-exponential smoothing (SES) with α=0.1
/// provides a 10-day half-life, meaning the trend line responds
/// primarily to the last ~2 weeks of data while smoothing out daily
/// fluctuations from water, sodium, and glycogen.
///
/// Evidence base:
/// - Exponential smoothing: Holt (1957, 2004). SES is the simplest
///   form of exponential forecasting, appropriate for body weight
///   which has no strong seasonal component within short windows.
/// - α=0.1 (10-day half-life): chosen because body weight fluctuations
///   of 1-3% are normal day-to-day (Trexler et al., 2014). A 10-day
///   window smooths these while still responding to real changes within
///   ~2 weeks.
/// - MacroFactor approach: the trend line is computed forward-only
///   (no future data leakage), making it suitable for real-time
///   decision making about calorie adjustments.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

// ── Weight Entry Source ──────────────────────────────────────────────────

/// How a weight entry was recorded.
enum WeightSource {
  /// Manually entered by the user.
  manual,

  /// From a connected smart scale.
  scale,

  /// From a wearable device (estimated).
  wearable,
}

// ── WeightEntry ──────────────────────────────────────────────────────────

/// A single body weight measurement.
class WeightEntry {
  const WeightEntry({
    required this.weightKg,
    required this.date,
    this.source = WeightSource.manual,
    this.bodyFatPercent,
    this.notes,
  });

  /// Weight in kilograms.
  final double weightKg;

  /// Date of measurement.
  final DateTime date;

  /// How this entry was recorded.
  final WeightSource source;

  /// Optional body fat percentage.
  final double? bodyFatPercent;

  /// Optional notes (e.g., "after fasted cardio", "post-meal").
  final String? notes;

  /// Weight in pounds (for US users).
  double get weightLbs => weightKg * 2.20462;

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'weightKg': weightKg,
        'date': date.toIso8601String(),
        'source': source.name,
        'bodyFatPercent': bodyFatPercent,
        'notes': notes,
      };

  factory WeightEntry.fromJson(Map<String, Object?> json) {
    return WeightEntry(
      weightKg: (json['weightKg'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      source: WeightSource.values.byName(
        json['source'] as String? ?? WeightSource.manual.name,
      ),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() =>
      'WeightEntry(${weightKg.toStringAsFixed(1)}kg, '
      '${date.toIso8601String().substring(0, 10)}, ${source.name})';
}

// ── Trend Data Point ─────────────────────────────────────────────────────

/// A single point on the weight trend line.
class TrendPoint {
  const TrendPoint({
    required this.date,
    required this.rawWeightKg,
    required this.trendWeightKg,
  });

  final DateTime date;
  final double rawWeightKg;
  final double trendWeightKg;

  /// Deviation of raw weight from trend (kg).
  double get deviationKg => rawWeightKg - trendWeightKg;

  /// Whether the raw weight is above the trend.
  bool get isAboveTrend => deviationKg > 0;

  Map<String, Object?> toJson() => {
        'date': date.toIso8601String(),
        'rawWeightKg': rawWeightKg,
        'trendWeightKg': trendWeightKg,
      };

  factory TrendPoint.fromJson(Map<String, Object?> json) {
    return TrendPoint(
      date: DateTime.parse(json['date'] as String),
      rawWeightKg: (json['rawWeightKg'] as num).toDouble(),
      trendWeightKg: (json['trendWeightKg'] as num).toDouble(),
    );
  }
}

// ── Weight Trend ─────────────────────────────────────────────────────────

/// Body weight trend analysis using exponential smoothing.
///
/// Computes a smoothed trend line from a series of weight entries.
/// The trend line filters out daily noise while preserving the
/// direction and magnitude of real weight changes.
class WeightTrend {
  /// Smoothing factor (α). Lower = smoother, higher = more responsive.
  /// α=0.1 gives a ~10-day half-life.
  static const double alpha = 0.1;

  /// Get the full trend line from a sorted list of weight entries.
  ///
  /// [entries] must be sorted by date ascending. Returns one
  /// [TrendPoint] per entry.
  static List<TrendPoint> getTrendLine(List<WeightEntry> entries) {
    if (entries.isEmpty) return const [];

    // Ensure sorted.
    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final points = <TrendPoint>[];
    double trend = sorted.first.weightKg;

    for (final entry in sorted) {
      // Exponential smoothing: trend_t = α * raw_t + (1-α) * trend_{t-1}
      trend = alpha * entry.weightKg + (1 - alpha) * trend;
      points.add(TrendPoint(
        date: entry.date,
        rawWeightKg: entry.weightKg,
        trendWeightKg: _round(trend),
      ));
    }

    return points;
  }

  /// Get the current trend weight (last smoothed value).
  ///
  /// Returns null if no entries are provided.
  static double? getCurrentTrend(List<WeightEntry> entries) {
    final trendLine = getTrendLine(entries);
    return trendLine.isEmpty ? null : trendLine.last.trendWeightKg;
  }

  /// Get the weight change over the last 7 days.
  ///
  /// Returns null if fewer than 7 days of data are available.
  static double? getWeeklyChange(List<WeightEntry> entries) {
    final trendLine = getTrendLine(entries);
    if (trendLine.length < 2) return null;

    final latest = trendLine.last;
    final weekAgo = _findClosestTrendPoint(
      trendLine,
      latest.date.subtract(const Duration(days: 7)),
    );

    if (weekAgo == null) return null;
    return _round(latest.trendWeightKg - weekAgo.trendWeightKg);
  }

  /// Get the weight change over the last 30 days.
  ///
  /// Returns null if fewer than 30 days of data are available.
  static double? getMonthlyChange(List<WeightEntry> entries) {
    final trendLine = getTrendLine(entries);
    if (trendLine.length < 2) return null;

    final latest = trendLine.last;
    final monthAgo = _findClosestTrendPoint(
      trendLine,
      latest.date.subtract(const Duration(days: 30)),
    );

    if (monthAgo == null) return null;
    return _round(latest.trendWeightKg - monthAgo.trendWeightKg);
  }

  /// Whether weight is stable (weekly change < 0.5kg).
  ///
  /// Stability indicates the user is at energy balance (maintenance).
  static bool isStable(List<WeightEntry> entries) {
    final weeklyChange = getWeeklyChange(entries);
    if (weeklyChange == null) return false;
    return weeklyChange.abs() < 0.5;
  }

  /// Get the direction of weight change.
  static WeightDirection getDirection(List<WeightEntry> entries) {
    final weeklyChange = getWeeklyChange(entries);
    if (weeklyChange == null) return WeightDirection.unknown;
    if (weeklyChange.abs() < 0.3) return WeightDirection.stable;
    if (weeklyChange > 0) return WeightDirection.gaining;
    return WeightDirection.losing;
  }

  /// Estimate weekly rate of change (kg/week) from the last 2-4 weeks.
  ///
  /// More robust than single-week change for calorie adjustment decisions.
  static double? getWeeklyRate(List<WeightEntry> entries) {
    final trendLine = getTrendLine(entries);
    if (trendLine.length < 14) return null; // Need at least 2 weeks.

    final latest = trendLine.last;
    // Use up to 4 weeks of data.
    final lookbackDays = (trendLine.length - 1).clamp(14, 28);
    final startDate =
        latest.date.subtract(Duration(days: lookbackDays));
    final start = _findClosestTrendPoint(trendLine, startDate);

    if (start == null) return null;

    final daysDiff = latest.date.difference(start.date).inDays;
    if (daysDiff <= 0) return null;

    final weightDiff = latest.trendWeightKg - start.trendWeightKg;
    final weeklyRate = (weightDiff / daysDiff) * 7;
    return _round(weeklyRate);
  }

  /// Get a summary of the weight trend for display.
  static TrendSummary getSummary(List<WeightEntry> entries) {
    final currentTrend = getCurrentTrend(entries);
    final weeklyChange = getWeeklyChange(entries);
    final monthlyChange = getMonthlyChange(entries);
    final weeklyRate = getWeeklyRate(entries);
    final direction = getDirection(entries);
    final stable = isStable(entries);

    return TrendSummary(
      currentTrendKg: currentTrend,
      weeklyChangeKg: weeklyChange,
      monthlyChangeKg: monthlyChange,
      weeklyRateKg: weeklyRate,
      direction: direction,
      isStable: stable,
      dataPoints: entries.length,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Find the trend point closest to [targetDate].
  static TrendPoint? _findClosestTrendPoint(
    List<TrendPoint> points,
    DateTime targetDate,
  ) {
    if (points.isEmpty) return null;

    TrendPoint? closest;
    Duration? closestDiff;

    for (final point in points) {
      final diff = (point.date.difference(targetDate)).abs();
      if (closestDiff == null || diff < closestDiff) {
        closest = point;
        closestDiff = diff;
      }
    }

    // Only return if within 7 days of the target.
    if (closestDiff != null && closestDiff.inDays <= 7) {
      return closest;
    }
    return null;
  }

  /// Round to 1 decimal place.
  static double _round(double value) {
    return (value * 10).round() / 10;
  }
}

// ── Weight Direction ─────────────────────────────────────────────────────

/// Direction of weight change trend.
enum WeightDirection {
  /// Trend is downward (caloric deficit).
  losing,

  /// Trend is stable (maintenance).
  stable,

  /// Trend is upward (caloric surplus).
  gaining,

  /// Insufficient data to determine direction.
  unknown,
}

// ── Trend Summary ────────────────────────────────────────────────────────

/// Summary of weight trend analysis.
class TrendSummary {
  const TrendSummary({
    required this.currentTrendKg,
    required this.weeklyChangeKg,
    required this.monthlyChangeKg,
    required this.weeklyRateKg,
    required this.direction,
    required this.isStable,
    required this.dataPoints,
  });

  /// Current smoothed trend weight (kg).
  final double? currentTrendKg;

  /// Change in trend over the last 7 days (kg).
  final double? weeklyChangeKg;

  /// Change in trend over the last 30 days (kg).
  final double? monthlyChangeKg;

  /// Estimated weekly rate of change (kg/week).
  final double? weeklyRateKg;

  /// Direction of change.
  final WeightDirection direction;

  /// Whether weight is stable.
  final bool isStable;

  /// Number of data points used.
  final int dataPoints;

  /// Human-readable direction label.
  String get directionLabel => switch (direction) {
        WeightDirection.losing => 'Losing',
        WeightDirection.stable => 'Stable',
        WeightDirection.gaining => 'Gaining',
        WeightDirection.unknown => 'Insufficient data',
      };

  /// Human-readable summary text.
  String get summaryText {
    if (currentTrendKg == null) return 'No weight data available.';
    if (dataPoints < 7) {
      return 'Trend: ${currentTrendKg!.toStringAsFixed(1)} kg '
          '($dataPoints data points — need more for reliable trend).';
    }
    final changeText = weeklyChangeKg != null
        ? '${weeklyChangeKg! > 0 ? "+" : ""}${weeklyChangeKg!.toStringAsFixed(1)} kg/week'
        : '';
    return 'Trend: ${currentTrendKg!.toStringAsFixed(1)} kg. '
        '$directionLabel. $changeText.';
  }

  @override
  String toString() =>
      'TrendSummary(${currentTrendKg?.toStringAsFixed(1)}kg, '
      '${direction.name}, $dataPoints points)';
}
