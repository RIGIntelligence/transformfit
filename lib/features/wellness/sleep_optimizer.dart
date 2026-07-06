/// Sleep quality analysis, scoring, and optimization.
///
/// Sleep is the single most important recovery variable for athletes and
/// general wellness. The National Sleep Foundation recommends 7-9 hours
/// for adults, but individual needs vary based on training load, stress,
/// and chronotype.
///
/// Evidence base:
/// - Sleep quality vs. quantity: Buysse et al. (1989), PSQI — quality
///   matters as much as duration. Our composite score weights both.
/// - Sleep debt: Van Dongen et al. (2003) — cumulative sleep restriction
///   produces dose-dependent cognitive impairment. A 7-day rolling window
///   captures chronic debt before it becomes pathological.
/// - Training load interaction: Mah et al. (2011) — extended sleep (10h)
///   improves sprint times, shooting accuracy, and reaction time in
///   athletes. Training load increases sleep need.
/// - Chronotype-based bedtime: Roenneberg et al. (2007) — chronotype
///   (morningness-eveningness) determines optimal sleep timing, not
///   just duration.
/// - Sleep disturbances: Ohayon et al. (2004) — even 1 disturbance per
///   night reduces restorative deep sleep proportion by ~15%.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

/// Chronotype classification based on Horne-Östberg Morningness-Eveningness
/// Questionnaire (MEQ) simplified to three categories.
enum Chronotype {
  /// Naturally early riser. Optimal bedtime ~21:00-22:00.
  earlyBird,

  /// Neither strongly morning nor evening. Optimal bedtime ~22:00-23:00.
  intermediate,

  /// Naturally late riser. Optimal bedtime ~23:00-00:00.
  nightOwl,
}

/// A single sleep log entry.
///
/// Captures both objective (duration) and subjective (quality, dreams)
/// dimensions. The sleep literature emphasizes that perceived quality
/// is a meaningful predictor of daytime functioning independent of
/// duration (Pilcher et al., 1997).
class SleepEntry {
  const SleepEntry({
    required this.bedtime,
    required this.wakeTime,
    required this.quality,
    required this.hoursSlept,
    required this.sleepDebt,
    this.disturbances = 0,
    this.dreamQuality,
  });

  /// When the user went to bed.
  final DateTime bedtime;

  /// When the user woke up.
  final DateTime wakeTime;

  /// Self-reported sleep quality (1-10).
  ///
  /// Based on a simplified PSQI subjective quality component.
  /// 1-3: very poor, 4-5: poor, 6-7: fair, 8-9: good, 10: excellent.
  final int quality;

  /// Actual hours of sleep (may differ from time in bed).
  final double hoursSlept;

  /// Cumulative sleep debt in hours (negative = surplus).
  ///
  /// Sleep debt = sum of (7.5 - actual hours) over the 7-day window.
  /// 7.5 hours is the midpoint of the NSF recommendation (7-9h).
  final double sleepDebt;

  /// Number of nighttime awakenings.
  ///
  /// Each awakening fragments sleep architecture and reduces the
  /// proportion of restorative deep sleep (N3) and REM stages.
  final int disturbances;

  /// Self-reported dream vividness/quality (1-10), optional.
  ///
  /// Dream recall and quality correlate with REM sleep completeness.
  /// REM is critical for emotional regulation (Walker, 2017).
  final int? dreamQuality;

  /// Composite sleep score combining duration, quality, and disturbances.
  ///
  /// Formula:
  ///   durationScore = min(100, hoursSlept / 8 * 100)
  ///   disturbancePenalty = disturbances * 8
  ///   qualityBonus = quality * 5
  ///   score = (durationScore * 0.4 + qualityBonus * 0.5) - disturbancePenalty
  ///   score = score.clamp(0, 100)
  ///
  /// Weights derived from PSQI component loadings (Buysse et al., 1989).
  double get compositeScore {
    final durationScore = (hoursSlept / 8.0 * 100).clamp(0.0, 100.0);
    final disturbancePenalty = disturbances * 8.0;
    final qualityBonus = quality * 5.0;
    final raw = durationScore * 0.4 + qualityBonus * 0.5 - disturbancePenalty;
    return raw.clamp(0.0, 100.0);
  }
}

/// Sleep optimization engine.
///
/// Analyzes sleep patterns and provides actionable recommendations based
/// on training context, stress, and individual chronotype.
class SleepOptimizer {
  const SleepOptimizer();

  /// Analyze a sleep entry and return a quality assessment.
  ///
  /// Returns a structured analysis with component scores and flags for
  /// areas needing improvement.
  SleepAnalysis analyzeSleep(SleepEntry entry) {
    final durationScore = _scoreDuration(entry.hoursSlept);
    final qualityScore = entry.quality * 10.0;
    final efficiencyScore = _scoreEfficiency(entry);
    final recoveryScore = _scoreRecovery(entry);

    final overallScore =
        (durationScore * 0.3 + qualityScore * 0.3 +
         efficiencyScore * 0.2 + recoveryScore * 0.2);

    return SleepAnalysis(
      durationScore: durationScore,
      qualityScore: qualityScore,
      efficiencyScore: efficiencyScore,
      recoveryScore: recoveryScore,
      overallScore: overallScore.clamp(0.0, 100.0),
      flags: _getFlags(entry),
    );
  }

  /// Get the composite sleep score for an entry.
  ///
  /// Convenience wrapper around [analyzeSleep] that returns only the
  /// overall score.
  double getSleepScore(SleepEntry entry) {
    return analyzeSleep(entry).overallScore;
  }

  /// Get personalized sleep recommendations.
  ///
  /// Combines training load, stress level, season, and chronotype to
  /// generate actionable advice. Each recommendation includes a priority
  /// level and specific action.
  List<SleepRecommendation> getRecommendations({
    required SleepEntry latestEntry,
    required List<SleepEntry> recentEntries,
    required double trainingLoad,
    required double stressLevel,
    required Chronotype chronotype,
    required DateTime now,
  }) {
    final recommendations = <SleepRecommendation>[];

    // 1. Duration recommendation.
    final avgHours = _averageHours(recentEntries);
    if (avgHours < 7.0) {
      recommendations.add(SleepRecommendation(
        priority: RecommendationPriority.high,
        area: 'Duration',
        message: 'You\'re averaging ${avgHours.toStringAsFixed(1)} hours. '
            'Aim for 7-9 hours, especially with your current training load.',
      ));
    }

    // 2. Training load interaction.
    if (trainingLoad > 0.7) {
      // High training load (>70% of max) increases sleep need by ~1 hour.
      recommendations.add(SleepRecommendation(
        priority: RecommendationPriority.high,
        area: 'Training Recovery',
        message: 'Your training load is high. Add 30-60 minutes to your '
            'sleep target. Athletes in heavy training benefit from '
            '9-10 hours (Mah et al., 2011).',
      ));
    }

    // 3. Stress interaction.
    if (stressLevel > 60) {
      recommendations.add(SleepRecommendation(
        priority: RecommendationPriority.medium,
        area: 'Stress Management',
        message: 'High stress impairs sleep onset and quality. Practice '
            'a wind-down routine: no screens 30min before bed, try '
            'progressive muscle relaxation or breathing exercises.',
      ));
    }

    // 4. Disturbance reduction.
    final avgDisturbances = recentEntries.isEmpty
        ? 0.0
        : recentEntries.fold<int>(0, (acc, e) => acc + e.disturbances) /
            recentEntries.length;
    if (avgDisturbances > 1.5) {
      recommendations.add(SleepRecommendation(
        priority: RecommendationPriority.medium,
        area: 'Sleep Continuity',
        message: 'You average ${avgDisturbances.toStringAsFixed(1)} '
            'awakenings per night. Keep your room cool (18-20°C), dark, '
            'and quiet. Avoid caffeine after 14:00.',
      ));
    }

    // 5. Chronotype-aligned bedtime.
    final optimalBedtime = _getOptimalBedtimeHour(chronotype, trainingLoad);
    final currentBedtimeHour = latestEntry.bedtime.hour +
        latestEntry.bedtime.minute / 60.0;
    final bedtimeDiff = (currentBedtimeHour - optimalBedtime).abs();
    // Account for crossing midnight.
    final adjustedDiff = bedtimeDiff > 12 ? 24 - bedtimeDiff : bedtimeDiff;
    if (adjustedDiff > 1.0) {
      recommendations.add(SleepRecommendation(
        priority: RecommendationPriority.low,
        area: 'Timing',
        message: 'Your bedtime doesn\'t match your chronotype. '
            'Aim for ~${optimalBedtime.toInt()}:00 for optimal '
            'circadian alignment.',
      ));
    }

    // 6. Dream quality / REM.
    final avgDreamQuality = _averageDreamQuality(recentEntries);
    if (avgDreamQuality != null && avgDreamQuality < 4.0) {
      recommendations.add(SleepRecommendation(
        priority: RecommendationPriority.low,
        area: 'REM Sleep',
        message: 'Low dream recall may indicate insufficient REM sleep. '
            'Alcohol and late caffeine suppress REM. Ensure consistent '
            'wake times to protect REM cycles.',
      ));
    }

    // Seasonal adjustment.
    final month = now.month;
    if (month >= 11 || month <= 2) {
      recommendations.add(SleepRecommendation(
        priority: RecommendationPriority.low,
        area: 'Seasonal',
        message: 'Winter months reduce daylight exposure, affecting '
            'circadian rhythm. Get 15-30 min of morning sunlight and '
            'consider a light therapy lamp.',
      ));
    }

    return recommendations;
  }

  /// Calculate current sleep debt over a 7-day window.
  ///
  /// Sleep debt = Σ(max(0, 7.5 - hoursSlept)) for each night in the window.
  /// Uses 7.5h as baseline (midpoint of NSF 7-9h recommendation).
  ///
  /// Positive value = debt (hours of sleep deficit).
  /// Zero or negative = no debt (surplus is not tracked, clamped to 0).
  double getSleepDebt(List<SleepEntry> entries, DateTime now) {
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = entries.where((e) => e.bedtime.isAfter(weekAgo)).toList();
    double debt = 0;
    for (final entry in recent) {
      final deficit = 7.5 - entry.hoursSlept;
      if (deficit > 0) debt += deficit;
    }
    return debt;
  }

  /// Calculate optimal bedtime based on chronotype and training load.
  ///
  /// Returns a DateTime on the given [referenceDate] with the optimal
  /// bedtime hour and minute.
  ///
  /// Base bedtimes by chronotype (from Roenneberg et al., 2007):
  /// - Early bird: 21:30
  /// - Intermediate: 22:30
  /// - Night owl: 23:30
  ///
  /// High training load shifts bedtime 30 minutes earlier to accommodate
  /// increased sleep need.
  DateTime getOptimalBedtime({
    required Chronotype chronotype,
    required double trainingLoad,
    required DateTime referenceDate,
    int? targetWakeTimeHour,
  }) {
    double baseHour = _getOptimalBedtimeHour(chronotype, trainingLoad);

    // If target wake time is specified, work backward to ensure 8h sleep.
    if (targetWakeTimeHour != null) {
      final neededHours = trainingLoad > 0.7 ? 9.0 : 8.0;
      final calculatedBedtime = targetWakeTimeHour - neededHours;
      if (calculatedBedtime < 0) {
        baseHour = 24 + calculatedBedtime;
      } else {
        baseHour = calculatedBedtime;
      }
    }

    final hour = baseHour.floor();
    final minute = ((baseHour - hour) * 60).round();

    // Handle bedtime crossing midnight.
    if (hour >= 24) {
      return DateTime(
        referenceDate.year, referenceDate.month, referenceDate.day + 1,
        hour - 24, minute,
      );
    }
    return DateTime(
      referenceDate.year, referenceDate.month, referenceDate.day,
      hour, minute,
    );
  }

  // --- Private helpers ---

  double _getOptimalBedtimeHour(Chronotype chronotype, double trainingLoad) {
    final baseBedtime = switch (chronotype) {
      Chronotype.earlyBird => 21.5, // 21:30
      Chronotype.intermediate => 22.5, // 22:30
      Chronotype.nightOwl => 23.5, // 23:30
    };

    // High training load shifts bedtime earlier by 30 min.
    final shift = trainingLoad > 0.7 ? 0.5 : 0.0;
    return baseBedtime - shift;
  }

  double _scoreDuration(double hours) {
    // Optimal: 7.5-9 hours. Linear penalty outside range.
    if (hours >= 7.5 && hours <= 9.0) return 100.0;
    if (hours < 7.5) return (hours / 7.5 * 100).clamp(0.0, 100.0);
    // Over 9 hours: slight penalty (oversleeping correlates with
    // depression and illness; Kronholm et al., 2009).
    return (100 - (hours - 9) * 10).clamp(0.0, 100.0);
  }

  double _scoreEfficiency(SleepEntry entry) {
    // Sleep efficiency = hours slept / time in bed.
    final timeInBed = entry.wakeTime.difference(entry.bedtime).inMinutes / 60.0;
    if (timeInBed <= 0) return 0;
    final efficiency = entry.hoursSlept / timeInBed;
    // Optimal efficiency: 85-95% (Ohayon et al., 2004).
    return (efficiency * 100).clamp(0.0, 100.0);
  }

  double _scoreRecovery(SleepEntry entry) {
    // Recovery based on quality, disturbances, and dream quality.
    double score = entry.quality * 10.0;
    score -= entry.disturbances * 10.0;
    if (entry.dreamQuality != null) {
      score += entry.dreamQuality! * 3.0;
    }
    return score.clamp(0.0, 100.0);
  }

  List<String> _getFlags(SleepEntry entry) {
    final flags = <String>[];
    if (entry.hoursSlept < 6) flags.add('critically_low_duration');
    if (entry.hoursSlept < 7) flags.add('low_duration');
    if (entry.quality <= 4) flags.add('poor_quality');
    if (entry.disturbances >= 3) flags.add('high_disturbances');
    if (entry.sleepDebt > 5) flags.add('significant_debt');
    return flags;
  }

  double _averageHours(List<SleepEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.fold<double>(0, (acc, e) => acc + e.hoursSlept) /
        entries.length;
  }

  double? _averageDreamQuality(List<SleepEntry> entries) {
    final withDreams = entries.where((e) => e.dreamQuality != null).toList();
    if (withDreams.isEmpty) return null;
    return withDreams.fold<double>(
      0, (acc, e) => acc + e.dreamQuality!,
    ) / withDreams.length;
  }
}

/// Structured sleep analysis result.
class SleepAnalysis {
  const SleepAnalysis({
    required this.durationScore,
    required this.qualityScore,
    required this.efficiencyScore,
    required this.recoveryScore,
    required this.overallScore,
    required this.flags,
  });

  final double durationScore;
  final double qualityScore;
  final double efficiencyScore;
  final double recoveryScore;
  final double overallScore;
  final List<String> flags;
}

/// A personalized sleep recommendation.
class SleepRecommendation {
  const SleepRecommendation({
    required this.priority,
    required this.area,
    required this.message,
  });

  final RecommendationPriority priority;
  final String area;
  final String message;
}

/// Recommendation priority level.
enum RecommendationPriority {
  low,
  medium,
  high,
}
