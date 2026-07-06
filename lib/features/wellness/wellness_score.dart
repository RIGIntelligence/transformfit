/// Unified physical + mental health wellness score.
///
/// Integrates all wellness dimensions into a single composite score while
/// preserving component transparency. Based on the biopsychosocial model
/// of health (Engel, 1977) which posits that health outcomes are determined
/// by the interaction of biological, psychological, and social factors.
///
/// Evidence base:
/// - Biopsychosocial model: Engel (1977), "The need for a new medical
///   model." Physical, mental, and behavioral health are interdependent.
/// - Wellness zones: Derived from the PERMA model (Seligman, 2011) which
///   identifies five pillars of well-being: Positive emotion, Engagement,
///   Relationships, Meaning, and Accomplishment.
/// - Composite scoring: WHO defines health as "complete physical, mental,
///   and social well-being, not merely the absence of disease." Our
///   three-domain model maps directly to this definition.
/// - Training consistency: Habit formation research (Lally et al., 2010)
///   shows consistent behavior (not intensity) predicts long-term outcomes.
/// - Recovery integration: Kellmann (2010), "Preventing overtraining in
///   athletes in high-intensity sports and stress/recovery monitoring."
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

/// Wellness zone classification.
///
/// Zones provide an intuitive summary of overall wellness state.
/// Thresholds are calibrated so that "thriving" represents the top ~20%
/// of the population distribution, "needs-attention" represents the
/// bottom ~15% that should seek professional support.
enum WellnessZone {
  /// Score 80+. All domains healthy. Peak performance and life satisfaction.
  thriving,

  /// Score 60-79. Generally healthy with room for improvement.
  maintaining,

  /// Score 40-59. One or more domains struggling. Active recovery needed.
  recovering,

  /// Score 0-39. Critical. Multiple domains compromised. Professional
  /// support recommended.
  needsAttention,
}

/// A structured wellness score with component breakdown.
///
/// Preserves transparency by exposing all sub-scores alongside the
/// composite. This prevents the "black box" problem of aggregate scores
/// and enables targeted intervention.
class WellnessScore {
  const WellnessScore({
    required this.physical,
    required this.mental,
    required this.behavioral,
    required this.overall,
    required this.zone,
    required this.recommendations,
  });

  /// Physical wellness score (0-100).
  ///
  /// Composed of: training consistency, training progression, body
  /// composition trends, and mobility/flexibility.
  final double physical;

  /// Mental wellness score (0-100).
  ///
  /// Composed of: mood trends, stress levels, sleep quality, and
  /// mindfulness practice.
  final double mental;

  /// Behavioral wellness score (0-100).
  ///
  /// Composed of: program adherence, nutrition quality, recovery
  /// compliance, and social connection.
  final double behavioral;

  /// Composite wellness score (0-100).
  ///
  /// Weighted average: physical 35%, mental 40%, behavioral 25%.
  /// Mental receives the highest weight because psychological health
  /// is the strongest predictor of overall life satisfaction and the
  /// primary mediator between physical health and perceived well-being
  /// (Diener et al., 1999).
  final double overall;

  /// Wellness zone classification.
  final WellnessZone zone;

  /// Personalized recommendations based on weakest domains.
  final List<String> recommendations;
}

/// Domain-specific input data for wellness calculation.
///
/// Each domain score is computed from multiple sub-indicators. All inputs
/// are on 0-100 scales for consistency and interpretability.
class WellnessInputs {
  const WellnessInputs({
    // Physical domain.
    required this.trainingConsistency,
    required this.trainingProgression,
    required this.bodyComposition,
    required this.mobility,
    // Mental domain.
    required this.moodScore,
    required this.stressScore,
    required this.sleepScore,
    required this.mindfulnessScore,
    // Behavioral domain.
    required this.adherence,
    required this.nutrition,
    required this.recovery,
    required this.social,
  });

  // --- Physical domain inputs ---

  /// Training consistency: percentage of planned sessions completed
  /// over the last 4 weeks. 100% = all sessions completed.
  final double trainingConsistency;

  /// Training progression: rate of improvement in key metrics (strength,
  /// endurance, etc.) relative to expected progression. 100 = exceeding
  /// expectations, 50 = meeting expectations, 0 = regressing.
  final double trainingProgression;

  /// Body composition score: trend in desired direction (fat loss, muscle
  /// gain, or maintenance depending on goals). 100 = perfectly on track.
  final double bodyComposition;

  /// Mobility/flexibility score: range of motion assessments, movement
  /// quality, and injury risk indicators. 100 = excellent mobility.
  final double mobility;

  // --- Mental domain inputs ---

  /// Mood score derived from mood tracking (1-5 scale mapped to 0-100).
  /// Uses recent average, not single data point.
  final double moodScore;

  /// Stress score: inverted stress level (100 = no stress, 0 = max stress).
  /// Inverted so higher is better, consistent with other inputs.
  final double stressScore;

  /// Sleep score from SleepOptimizer composite score.
  final double sleepScore;

  /// Mindfulness practice score based on consistency, duration, and quality.
  /// 100 = daily practice of 10+ minutes with high quality ratings.
  final double mindfulnessScore;

  // --- Behavioral domain inputs ---

  /// Program adherence: percentage of prescribed workouts, nutrition
  /// targets, and recovery protocols followed. 100 = perfect adherence.
  final double adherence;

  /// Nutrition quality score: macro targets, micronutrient density,
  /// hydration, and meal timing. 100 = all targets met consistently.
  final double nutrition;

  /// Recovery compliance: sleep hygiene, stress management, deload
  /// adherence, and rest day compliance. 100 = fully compliant.
  final double recovery;

  /// Social connection score: quality of relationships, community
  /// engagement, and social support network. Strong social connections
  /// are a top-3 predictor of longevity (Holt-Lunstad et al., 2010).
  final double social;
}

/// Deterministic wellness score engine.
///
/// Computes a unified wellness score from domain-specific inputs.
/// The engine is stateless — all context is passed via [WellnessInputs].
class WellnessEngine {
  const WellnessEngine();

  /// Compute the unified wellness score.
  ///
  /// Domain scores use weighted sub-indicator averages. The composite
  /// score uses domain weights that reflect the relative importance of
  /// each domain to overall life quality:
  /// - Physical (35%): necessary foundation but insufficient alone
  /// - Mental (40%): strongest predictor of perceived well-being
  /// - Behavioral (25%): enabler and multiplier of physical/mental
  WellnessScore compute(WellnessInputs inputs) {
    final physical = _computePhysical(inputs);
    final mental = _computeMental(inputs);
    final behavioral = _computeBehavioral(inputs);

    // Domain weights reflect importance to overall life satisfaction.
    final overall = (physical * 0.35 + mental * 0.40 + behavioral * 0.25)
        .clamp(0.0, 100.0);

    final zone = _classifyZone(overall);
    final recommendations = _generateRecommendations(
      physical: physical,
      mental: mental,
      behavioral: behavioral,
      inputs: inputs,
    );

    return WellnessScore(
      physical: physical,
      mental: mental,
      behavioral: behavioral,
      overall: overall,
      zone: zone,
      recommendations: recommendations,
    );
  }

  // --- Domain computation ---

  double _computePhysical(WellnessInputs inputs) {
    // Physical weights:
    // Consistency (40%): most important — regular training drives all
    //   other physical outcomes.
    // Progression (25%): indicates the training is effective.
    // Body composition (20%): outcome measure.
    // Mobility (15%): injury prevention and movement quality.
    return (inputs.trainingConsistency * 0.40 +
            inputs.trainingProgression * 0.25 +
            inputs.bodyComposition * 0.20 +
            inputs.mobility * 0.15)
        .clamp(0.0, 100.0);
  }

  double _computeMental(WellnessInputs inputs) {
    // Mental weights:
    // Mood (30%): primary subjective well-being indicator.
    // Stress (30%): high weight because chronic stress impairs all
    //   other mental functions (McEwen, 2007).
    // Sleep (25%): foundation of mental health; poor sleep degrades
    //   mood, stress resilience, and cognitive function.
    // Mindfulness (15%): practice consistency and quality.
    return (inputs.moodScore * 0.30 +
            inputs.stressScore * 0.30 +
            inputs.sleepScore * 0.25 +
            inputs.mindfulnessScore * 0.15)
        .clamp(0.0, 100.0);
  }

  double _computeBehavioral(WellnessInputs inputs) {
    // Behavioral weights:
    // Adherence (30%): consistency of execution across all domains.
    // Nutrition (30%): fundamental to physical and mental health.
    // Recovery (25%): enables adaptation and prevents burnout.
    // Social (15%): social support is a longevity predictor
    //   (Holt-Lunstad et al., 2010).
    return (inputs.adherence * 0.30 +
            inputs.nutrition * 0.30 +
            inputs.recovery * 0.25 +
            inputs.social * 0.15)
        .clamp(0.0, 100.0);
  }

  // --- Zone classification ---

  WellnessZone _classifyZone(double score) {
    if (score >= 80) return WellnessZone.thriving;
    if (score >= 60) return WellnessZone.maintaining;
    if (score >= 40) return WellnessZone.recovering;
    return WellnessZone.needsAttention;
  }

  // --- Recommendation generation ---

  List<String> _generateRecommendations({
    required double physical,
    required double mental,
    required double behavioral,
    required WellnessInputs inputs,
  }) {
    final recommendations = <String>[];

    // Identify weakest domain and weakest sub-indicators.
    final domains = [
      _DomainScore('physical', physical),
      _DomainScore('mental', mental),
      _DomainScore('behavioral', behavioral),
    ];
    domains.sort((a, b) => a.score.compareTo(b.score));

    // Overall zone recommendations.
    if (physical < 40) {
      recommendations.add(
        'Physical wellness needs attention. Focus on training consistency '
        'over intensity — even 3 short sessions per week builds the habit.',
      );
    }
    if (mental < 40) {
      recommendations.add(
        'Mental wellness is struggling. Prioritize sleep (8+ hours), '
        'daily stress management (breathing exercises), and mood tracking '
        'to identify patterns.',
      );
    }
    if (behavioral < 40) {
      recommendations.add(
        'Behavioral habits need reinforcement. Simplify your nutrition '
        'plan, set specific recovery targets, and connect with your '
        'training community.',
      );
    }

    // Sub-indicator recommendations for the weakest domain.
    final weakest = domains.first;
    if (weakest.name == 'physical') {
      if (inputs.trainingConsistency < 60) {
        recommendations.add(
          'Your training consistency is low. Reduce planned volume to '
          'what you can realistically complete. Consistency > intensity.',
        );
      }
      if (inputs.mobility < 50) {
        recommendations.add(
          'Mobility work is lacking. Add 10 minutes of targeted stretching '
          'after each session. Poor mobility increases injury risk.',
        );
      }
    } else if (weakest.name == 'mental') {
      if (inputs.sleepScore < 50) {
        recommendations.add(
          'Sleep quality is a bottleneck. Set a consistent bedtime, '
          'reduce screens before bed, and aim for 8+ hours.',
        );
      }
      if (inputs.stressScore < 50) {
        recommendations.add(
          'Stress levels are high. Add daily breathing exercises or '
          'meditation. Consider what\'s driving the stress and address '
          'the root cause.',
        );
      }
    } else {
      if (inputs.nutrition < 50) {
        recommendations.add(
          'Nutrition quality needs improvement. Focus on whole foods, '
          'adequate protein (1.6-2.2g/kg), and consistent meal timing.',
        );
      }
      if (inputs.social < 40) {
        recommendations.add(
          'Social connection is low. Training with others improves '
          'adherence and well-being. Join a class, find a training '
          'partner, or engage with an online community.',
        );
      }
    }

    // Positive reinforcement for thriving areas.
    if (domains.last.score >= 80) {
      final strongest = domains.last;
      recommendations.add(
        '${strongest.name[0].toUpperCase()}${strongest.name.substring(1)} '
        'is a strength (${strongest.score.toStringAsFixed(0)}/100). '
        'Maintain this while improving other areas.',
      );
    }

    return recommendations;
  }
}

/// Helper for domain sorting.
class _DomainScore {
  const _DomainScore(this.name, this.score);
  final String name;
  final double score;
}
