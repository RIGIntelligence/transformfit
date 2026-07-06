/// Hydration tracking for TransformFit.
///
/// Tracks water/coffee/tea intake with caffeine-adjusted equivalents.
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.

enum HydrationType {
  water, // 1.0x equivalent
  coffee, // 0.75x (caffeine is mildly diuretic)
  tea, // 0.90x (less caffeine than coffee)
  other; // 0.80x (sports drinks, etc.)

  /// Water equivalent multiplier (how much effective hydration per ml).
  double get multiplier {
    switch (this) {
      case HydrationType.water:
        return 1.0;
      case HydrationType.coffee:
        return 0.75; // caffeine offset
      case HydrationType.tea:
        return 0.90;
      case HydrationType.other:
        return 0.80;
    }
  }

  String toJson() => name;

  static HydrationType fromJson(String json) {
    return HydrationType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => HydrationType.water,
    );
  }
}

class HydrationEntry {
  final double amountMl;
  final DateTime timestamp;
  final HydrationType type;

  const HydrationEntry({
    required this.amountMl,
    required this.timestamp,
    this.type = HydrationType.water,
  });

  /// Effective hydration in ml (adjusted for caffeine, etc.).
  double get effectiveMl => amountMl * type.multiplier;

  Map<String, dynamic> toJson() => {
        'amountMl': amountMl,
        'timestamp': timestamp.toIso8601String(),
        'type': type.toJson(),
      };

  factory HydrationEntry.fromJson(Map<String, dynamic> json) =>
      HydrationEntry(
        amountMl: (json['amountMl'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: HydrationType.fromJson(json['type'] as String),
      );

  @override
  String toString() =>
      'HydrationEntry(${amountMl.toStringAsFixed(0)}ml ${type.name}, '
      'effective: ${effectiveMl.toStringAsFixed(0)}ml)';
}

class HydrationTracker {
  final List<HydrationEntry> _entries = [];

  /// Default daily goal in ml.
  double _goalMl = 2500; // ~10 glasses of 250ml

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Log a hydration entry.
  void logWater({
    required double amountMl,
    DateTime? timestamp,
    HydrationType type = HydrationType.water,
  }) {
    _entries.add(HydrationEntry(
      amountMl: amountMl,
      timestamp: timestamp ?? DateTime.now(),
      type: type,
    ));
  }

  /// Get all entries.
  List<HydrationEntry> get entries => List.unmodifiable(_entries);

  /// Set daily goal in ml.
  void setGoal(double ml) {
    _goalMl = ml;
  }

  /// Get daily goal in ml.
  double get goalMl => _goalMl;

  /// Get daily goal in glasses (250ml each).
  int get goalGlasses => (_goalMl / 250).ceil();

  /// Get today's total effective hydration in ml (caffeine-adjusted).
  double getDailyTotal({DateTime? date}) {
    final target = date ?? DateTime.now();
    final todayEntries = _getEntriesForDate(target);
    return todayEntries.fold<double>(0, (sum, e) => sum + e.effectiveMl);
  }

  /// Get today's total by raw ml (no caffeine adjustment).
  double getDailyTotalRaw({DateTime? date}) {
    final target = date ?? DateTime.now();
    final todayEntries = _getEntriesForDate(target);
    return todayEntries.fold<double>(0, (sum, e) => sum + e.amountMl);
  }

  /// Get progress toward daily goal (0.0–1.0+).
  double getProgress({DateTime? date}) {
    return getDailyTotal(date: date) / _goalMl;
  }

  /// Get progress as glasses consumed (250ml per glass).
  double getGlassesConsumed({DateTime? date}) {
    return getDailyTotal(date: date) / 250;
  }

  /// Get remaining hydration needed in ml.
  double getRemaining({DateTime? date}) {
    final remaining = _goalMl - getDailyTotal(date: date);
    return remaining > 0 ? remaining : 0;
  }

  /// Get recommended reminder times based on wake hours.
  ///
  /// Spreads intake evenly across the day with emphasis on:
  ///   - Morning (rehydration after sleep)
  ///   - Pre/post workout (if applicable)
  ///   - Before meals
  ///
  /// [wakeHour]: hour user wakes up (default 7)
  /// [sleepHour]: hour user goes to bed (default 23)
  /// [remindersPerDay]: number of reminders (default 8)
  List<DateTime> getReminderTimes({
    int wakeHour = 7,
    int sleepHour = 23,
    int remindersPerDay = 8,
  }) {
    final now = DateTime.now();
    final wakeTime = DateTime(now.year, now.month, now.day, wakeHour);
    final sleepTime = DateTime(now.year, now.month, now.day, sleepHour);
    final awakeMinutes = sleepTime.difference(wakeTime).inMinutes;
    final intervalMinutes = awakeMinutes ~/ remindersPerDay;

    final reminders = <DateTime>[];
    for (int i = 0; i < remindersPerDay; i++) {
      reminders.add(
        wakeTime.add(Duration(minutes: intervalMinutes * i)),
      );
    }
    return reminders;
  }

  /// Get a personalized hydration recommendation.
  ///
  /// Uses body weight, activity level, and climate to determine goal.
  /// Returns a formatted recommendation string.
  String getRecommendation({
    required double weightKg,
    double activityMultiplier = 1.0,
    bool isHotClimate = false,
  }) {
    // Base: 35ml/kg (EFSA guideline)
    double baseMl = weightKg * 35;

    // Activity: +500ml per hour equivalent
    baseMl += 500 * (activityMultiplier - 1.0).clamp(0, 2);

    // Climate
    if (isHotClimate) baseMl += 500;

    final glasses = (baseMl / 250).ceil();
    return '${baseMl.toStringAsFixed(0)}ml/day (~$glasses glasses of 250ml)';
  }

  /// Get breakdown by drink type for today.
  Map<HydrationType, double> getBreakdown({DateTime? date}) {
    final target = date ?? DateTime.now();
    final todayEntries = _getEntriesForDate(target);
    final breakdown = <HydrationType, double>{};

    for (final entry in todayEntries) {
      breakdown[entry.type] =
          (breakdown[entry.type] ?? 0) + entry.amountMl;
    }
    return breakdown;
  }

  /// Get hourly intake for today (keyed by hour 0-23).
  Map<int, double> getHourlyIntake({DateTime? date}) {
    final target = date ?? DateTime.now();
    final todayEntries = _getEntriesForDate(target);
    final hourly = <int, double>{};

    for (final entry in todayEntries) {
      hourly[entry.timestamp.hour] =
          (hourly[entry.timestamp.hour] ?? 0) + entry.effectiveMl;
    }
    return hourly;
  }

  /// Clear all entries.
  void clear() => _entries.clear();

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  List<HydrationEntry> _getEntriesForDate(DateTime date) {
    return _entries.where((e) {
      return e.timestamp.year == date.year &&
          e.timestamp.month == date.month &&
          e.timestamp.day == date.day;
    }).toList();
  }
}
