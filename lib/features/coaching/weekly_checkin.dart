/// M4: Weekly check-in model for coach progress review.
///
/// Generates a structured weekly summary from training data, readiness
/// scores, and mood tracking. Provides a progress grade and actionable
/// recommendations for the following week.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

// ── Progress Grade ───────────────────────────────────────────────────────

/// Progress grade for the week.
///
/// Based on adherence to the planned training program:
/// - A (exceeded): completed more than planned or hit all targets with
///   progression.
/// - B (met): completed the planned work as prescribed.
/// - C (below): missed 1-2 sessions or fell short on volume/intensity.
/// - D (significantly below): missed 3+ sessions or major deviation from plan.
enum ProgressGrade {
  /// Exceeded targets — extra sessions, PRs, or above-plan volume.
  a('A', 'Exceeded'),

  /// Met all planned targets.
  b('B', 'Met'),

  /// Below plan — minor shortfall.
  c('C', 'Below'),

  /// Significantly below plan — major deviation.
  d('D', 'Significantly Below');

  const ProgressGrade(this.letter, this.label);
  final String letter;
  final String label;
}

// ── Weekly Check-In ──────────────────────────────────────────────────────

/// A weekly check-in record combining training, recovery, and coaching data.
class WeeklyCheckIn {
  const WeeklyCheckIn({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.workoutsCompleted,
    required this.workoutsPlanned,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.readinessAverage,
    required this.moodAverage,
    required this.sleepAverage,
    required this.grade,
    required this.achievements,
    required this.coachSummary,
    required this.nextWeekFocus,
    required this.recommendations,
    this.personalRecords = const [],
    this.missedSessionReasons = const [],
  });

  /// Week number in the current training block (1-indexed).
  final int weekNumber;

  /// Week start date (Monday).
  final DateTime startDate;

  /// Week end date (Sunday).
  final DateTime endDate;

  /// Number of workouts completed.
  final int workoutsCompleted;

  /// Number of workouts planned.
  final int workoutsPlanned;

  /// Total training volume (sets × reps × weight) in kg.
  final double totalVolumeKg;

  /// Total working sets completed.
  final int totalSets;

  /// Average readiness score for the week (0-100).
  final double readinessAverage;

  /// Average mood score for the week (1-5).
  final double moodAverage;

  /// Average sleep quality for the week (1-10).
  final double sleepAverage;

  /// Progress grade.
  final ProgressGrade grade;

  /// Notable achievements this week.
  final List<String> achievements;

  /// Coach-generated summary of the week.
  final String coachSummary;

  /// Suggested focus for the next week.
  final String nextWeekFocus;

  /// Actionable recommendations.
  final List<String> recommendations;

  /// Personal records set this week.
  final List<String> personalRecords;

  /// Reasons for any missed sessions.
  final List<String> missedSessionReasons;

  /// Adherence percentage (workouts completed / planned).
  double get adherencePercent {
    if (workoutsPlanned == 0) return 1.0;
    return (workoutsCompleted / workoutsPlanned).clamp(0.0, 1.0);
  }

  /// Whether this was a deload week (low volume, low intensity).
  bool get isDeloadWeek =>
      totalSets < 20 && adherencePercent >= 0.8 && readinessAverage > 60;

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, Object?> toJson() => {
        'weekNumber': weekNumber,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'workoutsCompleted': workoutsCompleted,
        'workoutsPlanned': workoutsPlanned,
        'totalVolumeKg': totalVolumeKg,
        'totalSets': totalSets,
        'readinessAverage': readinessAverage,
        'moodAverage': moodAverage,
        'sleepAverage': sleepAverage,
        'grade': grade.letter,
        'achievements': achievements,
        'coachSummary': coachSummary,
        'nextWeekFocus': nextWeekFocus,
        'recommendations': recommendations,
        'personalRecords': personalRecords,
        'missedSessionReasons': missedSessionReasons,
      };

  factory WeeklyCheckIn.fromJson(Map<String, Object?> json) {
    return WeeklyCheckIn(
      weekNumber: json['weekNumber'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      workoutsCompleted: json['workoutsCompleted'] as int,
      workoutsPlanned: json['workoutsPlanned'] as int,
      totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
      totalSets: json['totalSets'] as int,
      readinessAverage: (json['readinessAverage'] as num).toDouble(),
      moodAverage: (json['moodAverage'] as num).toDouble(),
      sleepAverage: (json['sleepAverage'] as num).toDouble(),
      grade: gradeFromLetter(json['grade'] as String),
      achievements:
          (json['achievements'] as List).map((a) => a as String).toList(),
      coachSummary: json['coachSummary'] as String,
      nextWeekFocus: json['nextWeekFocus'] as String,
      recommendations: (json['recommendations'] as List)
          .map((r) => r as String)
          .toList(),
      personalRecords: (json['personalRecords'] as List?)
              ?.map((p) => p as String)
              .toList() ??
          const [],
      missedSessionReasons: (json['missedSessionReasons'] as List?)
              ?.map((m) => m as String)
              .toList() ??
          const [],
    );
  }

  @override
  String toString() =>
      'WeeklyCheckIn(week $weekNumber, ${grade.letter} grade, '
      '$workoutsCompleted/$workoutsPlanned workouts)';
}

// ── Check-In Engine ──────────────────────────────────────────────────────

/// Input data for generating a weekly check-in.
class CheckInInputs {
  const CheckInInputs({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.workoutsCompleted,
    required this.workoutsPlanned,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.readinessScores,
    required this.moodScores,
    required this.sleepScores,
    required this.personalRecords,
    this.missedSessionReasons = const [],
    this.previousWeekVolumeKg,
    this.previousWeekSets,
  });

  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int workoutsCompleted;
  final int workoutsPlanned;
  final double totalVolumeKg;
  final int totalSets;
  final List<double> readinessScores; // 0-100 scale
  final List<double> moodScores; // 1-5 scale
  final List<double> sleepScores; // 1-10 scale
  final List<String> personalRecords;
  final List<String> missedSessionReasons;
  final double? previousWeekVolumeKg;
  final int? previousWeekSets;
}

/// Deterministic engine for generating weekly check-ins.
class CheckInEngine {
  const CheckInEngine();

  /// Generate a complete weekly check-in from raw inputs.
  WeeklyCheckIn generateCheckIn(CheckInInputs inputs) {
    final readinessAvg = _average(inputs.readinessScores);
    final moodAvg = _average(inputs.moodScores);
    final sleepAvg = _average(inputs.sleepScores);
    final grade = getProgressGrade(inputs);
    final achievements = _buildAchievements(inputs, grade);
    final coachSummary = _buildCoachSummary(inputs, grade);
    final nextWeekFocus = _buildNextWeekFocus(inputs, grade);
    final recommendations = getRecommendations(inputs, grade);

    return WeeklyCheckIn(
      weekNumber: inputs.weekNumber,
      startDate: inputs.startDate,
      endDate: inputs.endDate,
      workoutsCompleted: inputs.workoutsCompleted,
      workoutsPlanned: inputs.workoutsPlanned,
      totalVolumeKg: inputs.totalVolumeKg,
      totalSets: inputs.totalSets,
      readinessAverage: readinessAvg,
      moodAverage: moodAvg,
      sleepAverage: sleepAvg,
      grade: grade,
      achievements: achievements,
      coachSummary: coachSummary,
      nextWeekFocus: nextWeekFocus,
      recommendations: recommendations,
      personalRecords: inputs.personalRecords,
      missedSessionReasons: inputs.missedSessionReasons,
    );
  }

  /// Grade the week's progress based on adherence and performance.
  ProgressGrade getProgressGrade(CheckInInputs inputs) {
    final adherence = inputs.workoutsPlanned > 0
        ? inputs.workoutsCompleted / inputs.workoutsPlanned
        : 0.0;

    // Check for progressive overload vs previous week.
    final volumeIncreased = inputs.previousWeekVolumeKg != null &&
        inputs.totalVolumeKg > inputs.previousWeekVolumeKg! * 1.05;

    // PRs count as exceeding.
    final hasPrs = inputs.personalRecords.isNotEmpty;

    if (adherence >= 1.0 && (volumeIncreased || hasPrs)) {
      return ProgressGrade.a; // Exceeded
    }
    if (adherence >= 0.9) {
      return ProgressGrade.b; // Met
    }
    if (adherence >= 0.6) {
      return ProgressGrade.c; // Below
    }
    return ProgressGrade.d; // Significantly below
  }

  /// Get actionable recommendations for the next week.
  List<String> getRecommendations(
    CheckInInputs inputs,
    ProgressGrade grade,
  ) {
    final recommendations = <String>[];
    final readinessAvg = _average(inputs.readinessScores);
    final moodAvg = _average(inputs.moodScores);
    final sleepAvg = _average(inputs.sleepScores);

    // Grade-specific recommendations.
    switch (grade) {
      case ProgressGrade.a:
        recommendations.add(
          'Excellent week. Maintain this intensity but watch for '
          'accumulating fatigue. A deload may be due in 2-3 weeks.',
        );
      case ProgressGrade.b:
        recommendations.add(
          'Solid week. Focus on progressive overload — small increases '
          'in weight or reps compound over time.',
        );
      case ProgressGrade.c:
        if (inputs.missedSessionReasons.isNotEmpty) {
          recommendations.add(
            'Sessions were missed. Identify the barrier and adjust the '
            'plan to be more sustainable. Consistency beats intensity.',
          );
        } else {
          recommendations.add(
            'Volume was below plan. Prioritize completing the prescribed '
            'work — reduce weight if needed to finish all sets.',
          );
        }
      case ProgressGrade.d:
        recommendations.add(
          'Significant deviation from plan this week. Consider reducing '
          'training days to match your current schedule capacity. '
          'Three consistent sessions beat five planned but missed ones.',
        );
    }

    // Readiness recommendations.
    if (readinessAvg < 45) {
      recommendations.add(
        'Average readiness was low (${readinessAvg.toStringAsFixed(0)}/100). '
        'Prioritize sleep, hydration, and stress management this week.',
      );
    }

    // Sleep recommendations.
    if (sleepAvg < 6) {
      recommendations.add(
        'Sleep quality averaged ${sleepAvg.toStringAsFixed(1)}/10. '
        'Sleep is the #1 recovery tool. Set a consistent bedtime and '
        'reduce screens 1 hour before bed.',
      );
    }

    // Mood recommendations.
    if (moodAvg < 3.0) {
      recommendations.add(
        'Mood was below average (${moodAvg.toStringAsFixed(1)}/5). '
        'Training can improve mood, but also check for overtraining. '
        'Consider lighter sessions or a rest day if needed.',
      );
    }

    // Positive reinforcement.
    if (inputs.personalRecords.isNotEmpty) {
      recommendations.add(
        '${inputs.personalRecords.length} personal record(s) set this '
        'week. Document what worked and repeat the approach.',
      );
    }

    return recommendations;
  }

  // ── Private Helpers ────────────────────────────────────────────────────

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  List<String> _buildAchievements(CheckInInputs inputs, ProgressGrade grade) {
    final achievements = <String>[];

    if (grade == ProgressGrade.a) {
      achievements.add('Exceeded weekly training targets');
    }

    if (inputs.personalRecords.isNotEmpty) {
      achievements.add('${inputs.personalRecords.length} new PR(s)');
      achievements.addAll(inputs.personalRecords);
    }

    if (inputs.workoutsCompleted >= inputs.workoutsPlanned) {
      achievements.add('Completed all planned sessions');
    }

    final readinessAvg = _average(inputs.readinessScores);
    if (readinessAvg >= 75) {
      achievements.add('Maintained high readiness all week');
    }

    final moodAvg = _average(inputs.moodScores);
    if (moodAvg >= 4.0) {
      achievements.add('Consistently positive mood');
    }

    return achievements;
  }

  String _buildCoachSummary(CheckInInputs inputs, ProgressGrade grade) {
    final adherence = inputs.workoutsPlanned > 0
        ? (inputs.workoutsCompleted / inputs.workoutsPlanned * 100).round()
        : 0;
    final readinessAvg = _average(inputs.readinessScores);

    final parts = <String>[
      'Week ${inputs.weekNumber}: ${grade.label} (${grade.letter}).',
      '$adherence% adherence (${inputs.workoutsCompleted}/'
          '${inputs.workoutsPlanned} sessions).',
      '${inputs.totalSets} total sets, '
          '${inputs.totalVolumeKg.toStringAsFixed(0)} kg volume.',
    ];

    if (readinessAvg >= 70) {
      parts.add('Readiness was strong — good foundation for progression.');
    } else if (readinessAvg >= 50) {
      parts.add('Readiness was moderate — monitor recovery closely.');
    } else {
      parts.add('Readiness was low — recovery should be the priority.');
    }

    return parts.join(' ');
  }

  String _buildNextWeekFocus(
    CheckInInputs inputs,
    ProgressGrade grade,
  ) {
    switch (grade) {
      case ProgressGrade.a:
        return 'Continue progressive overload. Add 2.5% load or 1 rep '
            'per exercise where RPE allows.';
      case ProgressGrade.b:
        return 'Maintain current approach. Focus on technique quality '
            'and controlled tempo.';
      case ProgressGrade.c:
        return 'Prioritize session completion. Reduce planned volume '
            'by 10-15% to rebuild consistency.';
      case ProgressGrade.d:
        return 'Reset to a sustainable baseline. Cut training days to '
            '3 per week and rebuild the habit first.';
    }
  }

}

/// Parse a progress grade letter to its enum value.
ProgressGrade gradeFromLetter(String letter) {
  return ProgressGrade.values.firstWhere(
    (g) => g.letter == letter,
    orElse: () => ProgressGrade.c,
  );
}
