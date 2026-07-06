/// Training + mental health burnout risk assessment.
///
/// Burnout in athletes and fitness enthusiasts is a multifactorial syndrome
/// combining physical overtraining with psychological exhaustion. This
/// module integrates training load metrics with mental health indicators
/// to provide early warning before full burnout develops.
///
/// Evidence base:
/// - Overtraining syndrome: Meeusen et al. (2013), "Prevention, diagnosis
///   and treatment of the overtraining syndrome" — consensus statement
///   from the European College of Sport Science.
/// - ACWR (Acute:Chronic Workload Ratio): Blanch & Gabbett (2016) —
///   ACWR > 1.5 increases injury risk by 2-4x. This is the primary
///   training load indicator.
/// - Athlete burnout: Raedeke (1997), "Is athlete burnout more than
///   just stress?" — three dimensions: emotional/physical exhaustion,
///   reduced accomplishment, sport devaluation.
/// - Mood-performance link: Morgan et al. (1987), "Psychological
///   monitoring of overtraining and staleness" — the POMS-based
///   Iceberg Profile deteriorates before performance declines.
/// - Recovery timeline: Budgett (1998) — full recovery from
///   overtraining syndrome takes 6 weeks to 6 months depending on
///   severity and duration of accumulated overload.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

/// Contributing factor to burnout risk.
///
/// Each factor represents a dimension of the biopsychosocial model
/// applied to training and wellness.
enum BurnoutFactor {
  /// High acute:chronic workload ratio (ACWR > 1.5).
  ///
  /// Indicates the body is experiencing sudden load increases without
  /// adequate chronic preparation. Primary injury and overtraining
  /// risk factor (Blanch & Gabbett, 2016).
  trainingLoad,

  /// Declining mood trend over recent weeks.
  ///
  /// Mood deterioration is an early marker of overtraining, often
  /// preceding performance decline by 2-4 weeks (Morgan et al., 1987).
  moodDecline,

  /// Accumulated sleep debt.
  ///
  /// Chronic sleep restriction impairs recovery, hormonal balance,
  /// and immune function. Sleep debt > 5 hours significantly elevates
  /// burnout risk (Van Dongen et al., 2003).
  sleepDebt,

  /// Elevated stress levels.
  ///
  /// Chronic psychological stress competes for the same recovery
  /// resources as training stress. Combined physical-psychological
  /// stress is additive, not independent (Kellmann, 2010).
  stressAccumulation,

  /// Declining motivation and training enjoyment.
  ///
  /// Motivation drop is the behavioral signature of sport devaluation,
  /// one of Raedeke's three burnout dimensions. Often manifests as
  /// dreading sessions that were previously enjoyable.
  motivationDrop,

  /// Performance plateau despite continued training.
  ///
  /// A plateau in the presence of adequate training stimulus suggests
  /// the body cannot adapt further without recovery. This is the
  /// "staleness" described by Morgan et al. (1987).
  performancePlateau,
}

/// Burnout risk zone classification.
enum BurnoutZone {
  /// Risk level 0-25. All systems healthy. Continue current approach.
  green,

  /// Risk level 26-50. Early warning signs present. Monitor closely
  /// and consider proactive recovery measures.
  yellow,

  /// Risk level 51-75. Significant risk. Reduce training load and
  /// prioritize recovery strategies.
  orange,

  /// Risk level 76-100. Critical risk. Full deload or rest period
  /// required. Potential medical evaluation recommended.
  red,
}

/// A contributing factor with its individual risk score.
class FactorScore {
  const FactorScore({
    required this.factor,
    required this.score,
    required this.description,
  });

  final BurnoutFactor factor;
  final double score;
  final String description;
}

/// Burnout risk assessment result.
///
/// Contains the composite risk level, individual factor contributions,
/// a prioritized recommendation, and estimated recovery timeline.
class BurnoutRisk {
  const BurnoutRisk({
    required this.riskLevel,
    required this.factors,
    required this.recommendation,
    required this.daysToRecovery,
    required this.zone,
  });

  /// Composite risk score 0-100.
  final double riskLevel;

  /// Individual contributing factors with scores and descriptions.
  final List<FactorScore> factors;

  /// Top-level recommendation based on current risk zone.
  final String recommendation;

  /// Estimated days to full recovery if recommendations are followed.
  ///
  /// Based on Budgett (1998) recovery timelines:
  /// - Green: 0 days (no action needed)
  /// - Yellow: 3-7 days (proactive recovery)
  /// - Orange: 14-28 days (structured deload + recovery)
  /// - Red: 42-180 days (potential overtraining syndrome)
  final int daysToRecovery;

  /// Risk zone classification.
  final BurnoutZone zone;
}

/// Deterministic burnout detection engine.
///
/// Integrates multiple data streams (training load, mood, sleep, stress,
/// motivation, performance) into a unified risk assessment. Uses a
/// weighted multi-factor model where each factor contributes independently
/// to the composite risk.
class BurnoutDetector {
  const BurnoutDetector();

  /// Assess burnout risk from current state indicators.
  ///
  /// All inputs are normalized to 0-100 scales before aggregation.
  /// The composite score uses a weighted sum with interaction terms:
  /// high values in multiple factors compound risk non-linearly
  /// (the body's recovery capacity is shared across stressors).
  BurnoutRisk assessRisk({
    /// Acute:Chronic Workload Ratio (0.5-2.0 typical range).
    required double acwr,

    /// Current mood level (1-5 scale from MoodLevel).
    required double moodLevel,

    /// Average mood over last 2 weeks (1-5 scale).
    required double moodTwoWeekAverage,

    /// Current sleep debt in hours.
    required double sleepDebtHours,

    /// Current stress level (0-100 from StressMonitor).
    required double stressLevel,

    /// Current motivation level (1-10 self-report).
    required double motivationLevel,

    /// Performance trend: positive = improving, 0 = plateau, negative declining.
    /// Normalized to roughly -10 to +10 scale.
    required double performanceTrend,
  }) {
    final factors = <FactorScore>[];

    // 1. Training load factor (ACWR-based).
    final trainingScore = _scoreAcwr(acwr);
    factors.add(FactorScore(
      factor: BurnoutFactor.trainingLoad,
      score: trainingScore,
      description: 'ACWR of ${acwr.toStringAsFixed(2)} — '
          '${_acwrLabel(acwr)}',
    ));

    // 2. Mood decline factor.
    final moodDeclineScore = _scoreMoodDecline(moodLevel, moodTwoWeekAverage);
    factors.add(FactorScore(
      factor: BurnoutFactor.moodDecline,
      score: moodDeclineScore,
      description: 'Current mood ${moodLevel.toStringAsFixed(1)} vs '
          '2-week average ${moodTwoWeekAverage.toStringAsFixed(1)}',
    ));

    // 3. Sleep debt factor.
    final sleepScore = _scoreSleepDebt(sleepDebtHours);
    factors.add(FactorScore(
      factor: BurnoutFactor.sleepDebt,
      score: sleepScore,
      description: '${sleepDebtHours.toStringAsFixed(1)} hours of '
          'cumulative sleep debt',
    ));

    // 4. Stress accumulation factor.
    final stressScore = _scoreStress(stressLevel);
    factors.add(FactorScore(
      factor: BurnoutFactor.stressAccumulation,
      score: stressScore,
      description: 'Stress level at ${stressLevel.toStringAsFixed(0)}/100',
    ));

    // 5. Motivation drop factor.
    final motivationScore = _scoreMotivation(motivationLevel);
    factors.add(FactorScore(
      factor: BurnoutFactor.motivationDrop,
      score: motivationScore,
      description: 'Motivation at ${motivationLevel.toStringAsFixed(1)}/10',
    ));

    // 6. Performance plateau factor.
    final plateauScore = _scorePerformancePlateau(performanceTrend);
    factors.add(FactorScore(
      factor: BurnoutFactor.performancePlateau,
      score: plateauScore,
      description: 'Performance trend: ${performanceTrend >= 0 ? "+" : ""}'
          '${performanceTrend.toStringAsFixed(1)}',
    ));

    // Composite risk: weighted sum with interaction amplification.
    //
    // Base weights reflect relative importance from literature:
    // Training load is primary (0.25), mood and sleep are secondary
    // (0.20 each), stress and motivation tertiary (0.15 each),
    // performance plateau supplementary (0.05).
    final baseScore = trainingScore * 0.25 +
        moodDeclineScore * 0.20 +
        sleepScore * 0.20 +
        stressScore * 0.15 +
        motivationScore * 0.15 +
        plateauScore * 0.05;

    // Interaction term: when 3+ factors are elevated (>50), apply
    // an amplification factor. This models the compounding effect
    // of simultaneous stressors on recovery capacity.
    final elevatedCount = factors.where((f) => f.score > 50).length;
    final interactionMultiplier = elevatedCount >= 3
        ? 1.0 + (elevatedCount - 2) * 0.1
        : 1.0;

    final compositeRisk = (baseScore * interactionMultiplier).clamp(0.0, 100.0);
    final zone = _classifyZone(compositeRisk);

    return BurnoutRisk(
      riskLevel: compositeRisk,
      factors: factors,
      recommendation: _getRecommendation(zone, factors),
      daysToRecovery: _estimateRecovery(zone, compositeRisk),
      zone: zone,
    );
  }

  /// Get warning signals based on current inputs.
  ///
  /// Returns a list of human-readable warning messages. Each signal
  /// corresponds to a specific burnout factor exceeding its threshold.
  List<String> getWarningSignals({
    required double acwr,
    required double moodLevel,
    required double moodTwoWeekAverage,
    required double sleepDebtHours,
    required double stressLevel,
    required double motivationLevel,
    required double performanceTrend,
  }) {
    final signals = <String>[];

    if (acwr > 1.5) {
      signals.add(
        'Training load spike: ACWR at ${acwr.toStringAsFixed(2)} — '
        'injury risk is 2-4x higher than normal.',
      );
    }
    if (moodLevel < 3 && moodLevel < moodTwoWeekAverage - 0.5) {
      signals.add(
        'Mood decline detected: current mood (${moodLevel.toStringAsFixed(1)}) '
        'is below your recent average. This is an early overtraining marker.',
      );
    }
    if (sleepDebtHours > 5) {
      signals.add(
        'Significant sleep debt: ${sleepDebtHours.toStringAsFixed(1)} hours '
        'of accumulated deficit. Recovery capacity is impaired.',
      );
    }
    if (stressLevel > 70) {
      signals.add(
        'Elevated stress: ${stressLevel.toStringAsFixed(0)}/100. '
        'Psychological stress shares recovery resources with training.',
      );
    }
    if (motivationLevel < 4) {
      signals.add(
        'Low motivation: ${motivationLevel.toStringAsFixed(1)}/10. '
        'This may indicate sport devaluation — a core burnout dimension.',
      );
    }
    if (performanceTrend < -3) {
      signals.add(
        'Performance declining: trend at ${performanceTrend.toStringAsFixed(1)}. '
        'Continued training without recovery will worsen this.',
      );
    }
    if (performanceTrend.abs() < 1 && acwr > 1.0) {
      signals.add(
        'Performance plateau with elevated load: your body is not adapting. '
        'This is "staleness" — a precursor to overtraining.',
      );
    }

    return signals;
  }

  /// Get a structured prevention plan based on identified risk factors.
  ///
  /// Returns actionable steps prioritized by impact.
  List<PreventionStep> getPreventionPlan(BurnoutRisk risk) {
    final steps = <PreventionStep>[];

    // Always address the highest-scoring factors first.
    final sortedFactors = List<FactorScore>.of(risk.factors)
      ..sort((a, b) => b.score.compareTo(a.score));

    for (final factor in sortedFactors.where((f) => f.score > 30)) {
      steps.addAll(_getStepsForFactor(factor));
    }

    // Ensure at least one recovery step.
    if (steps.isEmpty) {
      steps.add(const PreventionStep(
        priority: 1,
        area: 'Maintenance',
        action: 'Continue your current approach. Monitor weekly.',
        durationDays: 7,
      ));
    }

    return steps;
  }

  // --- Private scoring helpers ---

  double _scoreAcwr(double acwr) {
    // ACWR scoring:
    // 0.8-1.3: sweet spot (low risk, score 0-20)
    // 1.3-1.5: moderate risk (score 20-50)
    // 1.5-2.0: high risk (score 50-85)
    // >2.0: very high risk (score 85-100)
    // <0.8: detraining risk (score 20-40)
    if (acwr >= 0.8 && acwr <= 1.3) {
      return ((acwr - 0.8) / 0.5 * 20).clamp(0.0, 20.0);
    } else if (acwr > 1.3 && acwr <= 1.5) {
      return 20 + (acwr - 1.3) / 0.2 * 30;
    } else if (acwr > 1.5 && acwr <= 2.0) {
      return 50 + (acwr - 1.5) / 0.5 * 35;
    } else if (acwr > 2.0) {
      return 85 + ((acwr - 2.0) * 15).clamp(0.0, 15.0);
    } else {
      // < 0.8: detraining but some risk from inconsistency.
      return ((0.8 - acwr) / 0.3 * 20 + 20).clamp(20.0, 40.0);
    }
  }

  double _scoreMoodDecline(double current, double twoWeekAvg) {
    final decline = twoWeekAvg - current;
    if (decline <= 0) return 0; // Mood is stable or improving.
    // Decline of 1 point = 40 risk, 2+ points = 80+ risk.
    return (decline * 40).clamp(0.0, 100.0);
  }

  double _scoreSleepDebt(double debtHours) {
    // 0h debt = 0 risk, 5h debt = 50 risk, 10+h debt = 100 risk.
    return (debtHours * 10).clamp(0.0, 100.0);
  }

  double _scoreStress(double stressLevel) {
    // Direct mapping from 0-100 stress to 0-100 risk contribution.
    return stressLevel.clamp(0.0, 100.0);
  }

  double _scoreMotivation(double motivation) {
    // Inverse scale: 10 = 0 risk, 1 = 90 risk, 0 = 100 risk.
    if (motivation >= 7) return 0;
    if (motivation >= 4) return (7 - motivation) / 3 * 40;
    return 40 + (4 - motivation) / 4 * 60;
  }

  double _scorePerformancePlateau(double trend) {
    if (trend >= 0) return 0;
    // Negative trend: -1 = 10 risk, -5 = 50 risk, -10 = 100 risk.
    return (-trend * 10).clamp(0.0, 100.0);
  }

  BurnoutZone _classifyZone(double risk) {
    if (risk <= 25) return BurnoutZone.green;
    if (risk <= 50) return BurnoutZone.yellow;
    if (risk <= 75) return BurnoutZone.orange;
    return BurnoutZone.red;
  }

  int _estimateRecovery(BurnoutZone zone, double risk) {
    return switch (zone) {
      BurnoutZone.green => 0,
      BurnoutZone.yellow => 3 + ((risk - 26) / 24 * 4).round(),
      BurnoutZone.orange => 14 + ((risk - 51) / 24 * 14).round(),
      BurnoutZone.red => 42 + ((risk - 76) / 24 * 30).round(),
    };
  }

  String _getRecommendation(BurnoutZone zone, List<FactorScore> factors) {
    return switch (zone) {
      BurnoutZone.green =>
        'You\'re in a healthy training state. Maintain your current '
            'approach and continue monitoring.',
      BurnoutZone.yellow =>
        'Early warning signs present. Consider a deload week (reduce '
            'volume by 30%) and prioritize sleep and stress management.',
      BurnoutZone.orange =>
        'Significant burnout risk. Reduce training volume by 50% for '
            '1-2 weeks. Focus on recovery: sleep, nutrition, low-intensity '
            'movement, and stress reduction activities.',
      BurnoutZone.red =>
        'Critical burnout risk. Stop high-intensity training immediately. '
            'Take a full rest period of 1-2 weeks minimum, then gradually '
            'return at 50% volume. Consider consulting a sports medicine '
            'professional.',
    };
  }

  List<PreventionStep> _getStepsForFactor(FactorScore factor) {
    return switch (factor.factor) {
      BurnoutFactor.trainingLoad => [
          PreventionStep(
            priority: 1,
            area: 'Training Load',
            action: 'Reduce training volume by '
                '${factor.score > 50 ? "50%" : "30%"} this week. '
                'Keep intensity but cut sets/reps.',
            durationDays: 7,
          ),
          const PreventionStep(
            priority: 2,
            area: 'Training Load',
            action: 'Ensure ACWR stays between 0.8-1.3. Build gradually: '
                'no more than 10% volume increase per week.',
            durationDays: 14,
          ),
        ],
      BurnoutFactor.moodDecline => [
          const PreventionStep(
            priority: 1,
            area: 'Mental Health',
            action: 'Add daily mood check-ins and journaling. '
                'Track what\'s working and what\'s not.',
            durationDays: 14,
          ),
          const PreventionStep(
            priority: 2,
            area: 'Mental Health',
            action: 'Consider whether training has become a source of '
                'stress rather than fulfillment. Adjust goals if needed.',
            durationDays: 7,
          ),
        ],
      BurnoutFactor.sleepDebt => [
          const PreventionStep(
            priority: 1,
            area: 'Sleep',
            action: 'Prioritize 8-9 hours of sleep. Set a consistent '
                'bedtime and wake time, even on weekends.',
            durationDays: 7,
          ),
          const PreventionStep(
            priority: 2,
            area: 'Sleep',
            action: 'Reduce evening screen time and caffeine after 14:00. '
                'Create a wind-down routine.',
            durationDays: 14,
          ),
        ],
      BurnoutFactor.stressAccumulation => [
          const PreventionStep(
            priority: 1,
            area: 'Stress Management',
            action: 'Practice 10 minutes of breathing exercises daily. '
                'Add 15-minute outdoor walks.',
            durationDays: 14,
          ),
          const PreventionStep(
            priority: 2,
            area: 'Stress Management',
            action: 'Identify and address the primary stressor. Consider '
                'whether it\'s training-related, work-related, or both.',
            durationDays: 7,
          ),
        ],
      BurnoutFactor.motivationDrop => [
          const PreventionStep(
            priority: 1,
            area: 'Motivation',
            action: 'Switch to activities you enjoy. Try a new sport, '
                'train with a friend, or set a fun challenge.',
            durationDays: 14,
          ),
          const PreventionStep(
            priority: 2,
            area: 'Motivation',
            action: 'Revisit your "why" — the deeper reason you train. '
                'Align your routine with your values.',
            durationDays: 7,
          ),
        ],
      BurnoutFactor.performancePlateau => [
          const PreventionStep(
            priority: 1,
            area: 'Performance',
            action: 'Take a planned deload week. Progress often comes '
                'after rest, not more effort.',
            durationDays: 7,
          ),
          const PreventionStep(
            priority: 2,
            area: 'Performance',
            action: 'Change your training stimulus: new exercises, '
                'rep ranges, or training split.',
            durationDays: 14,
          ),
        ],
    };
  }

  String _acwrLabel(double acwr) {
    if (acwr < 0.8) return 'detraining zone';
    if (acwr <= 1.3) return 'sweet spot';
    if (acwr <= 1.5) return 'moderate risk';
    if (acwr <= 2.0) return 'high risk';
    return 'very high risk';
  }
}

/// A single step in a burnout prevention plan.
class PreventionStep {
  const PreventionStep({
    required this.priority,
    required this.area,
    required this.action,
    required this.durationDays,
  });

  /// Priority order (1 = most important).
  final int priority;

  /// Area of focus (Training, Sleep, Stress, etc.).
  final String area;

  /// Specific action to take.
  final String action;

  /// How many days to maintain this action.
  final int durationDays;
}
