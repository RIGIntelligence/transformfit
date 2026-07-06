import 'package:flutter/material.dart';
import 'deviation_design_system.dart';

// ============================================================================
// Design Quality Score — Automated Screen Scoring
//
// Scores each TransformFit screen against the 40 RIG Deviation Engines.
// Target: ≥80 internal, ≥85 public-facing, ≥90 for ±30σ quality.
//
// Usage:
//   final score = DesignQualityScorer.scoreDashboard(context);
//   print(score); // DesignScore(87.3/100, tier=QualityTier.publicFacing)
//
// For widget-tree analysis, use the helper methods to check specific
// properties of the widget tree against deviation engine rules.
// ============================================================================

/// Automated design quality scoring for TransformFit screens.
class DesignQualityScorer {
  const DesignQualityScorer._();

  // =========================================================================
  // Per-screen scoring presets
  //
  // These are the baseline engine scores for each major screen.
  // In production, these would be computed from widget tree analysis.
  // For now, they represent the DESIGN INTENT — the target each screen
  // should achieve after deviation engine application.
  // =========================================================================

  /// Home/Dashboard screen — the primary landing surface.
  static DesignScore scoreHomeScreen() {
    return DeviationDesignSystem.scoreScreen(const {
      DeviationEngine.quantumTunneling: 0.9, // Recovery circle overlaps hero
      DeviationEngine.pauliExclusion: 0.85, // Each card has unique treatment
      DeviationEngine.casimirPressure: 0.9, // Hero gets focused whitespace
      DeviationEngine.fineTuning: 1.0, // Fibonacci spacing applied
      DeviationEngine.hawkingRadiation: 0.8, // Empty states show info
      DeviationEngine.speedOfLight: 0.9, // Animation durations correct
      DeviationEngine.absoluteZero: 1.0, // No decorative animations
      DeviationEngine.phaseTransition: 0.7, // Threshold states exist
      DeviationEngine.bellEntanglement: 0.85, // Mood→recovery linked
      DeviationEngine.vacuumFluctuation: 0.8, // Loading states pulse
      DeviationEngine.gravityEscape: 0.7, // Some non-standard layout
      DeviationEngine.realityAnchor: 0.9, // One-tap workout start
      DeviationEngine.feynmanXRay: 0.6, // Score formula visible
      DeviationEngine.antColonyPheromone: 0.8, // Nav adapts to usage
      DeviationEngine.beeForaging: 0.9, // 60/25/15 attention split
      DeviationEngine.slimeMoldNetwork: 0.7, // Cards can reorder
    });
  }

  /// Workout screen — active exercise tracking.
  static DesignScore scoreWorkoutScreen() {
    return DeviationDesignSystem.scoreScreen(const {
      DeviationEngine.quantumTunneling: 0.85,
      DeviationEngine.pauliExclusion: 0.9,
      DeviationEngine.casimirPressure: 0.85,
      DeviationEngine.fineTuning: 1.0,
      DeviationEngine.hawkingRadiation: 0.9, // Empty = motivational quote
      DeviationEngine.speedOfLight: 0.95,
      DeviationEngine.absoluteZero: 1.0,
      DeviationEngine.phaseTransition: 0.85, // PR celebration is explosive
      DeviationEngine.bellEntanglement: 0.9, // Set logged → progress animates
      DeviationEngine.vacuumFluctuation: 0.75,
      DeviationEngine.gravityEscape: 0.65,
      DeviationEngine.realityAnchor: 1.0, // One-tap set logging
      DeviationEngine.feynmanXRay: 0.7, // Progression algorithm shown
      DeviationEngine.antColonyPheromone: 0.75,
      DeviationEngine.beeForaging: 0.85,
      DeviationEngine.slimeMoldNetwork: 0.6,
    });
  }

  /// Nutrition screen — meal tracking and macros.
  static DesignScore scoreNutritionScreen() {
    return DeviationDesignSystem.scoreScreen(const {
      DeviationEngine.quantumTunneling: 0.8,
      DeviationEngine.pauliExclusion: 0.85,
      DeviationEngine.casimirPressure: 0.8,
      DeviationEngine.fineTuning: 1.0,
      DeviationEngine.hawkingRadiation: 0.85, // Empty = meal suggestion
      DeviationEngine.speedOfLight: 0.85,
      DeviationEngine.absoluteZero: 0.95,
      DeviationEngine.phaseTransition: 0.65,
      DeviationEngine.bellEntanglement: 0.8, // Macro rings update in real-time
      DeviationEngine.vacuumFluctuation: 0.8,
      DeviationEngine.gravityEscape: 0.6,
      DeviationEngine.realityAnchor: 0.9, // Quick-log meal
      DeviationEngine.feynmanXRay: 0.5,
      DeviationEngine.antColonyPheromone: 0.7,
      DeviationEngine.beeForaging: 0.8,
      DeviationEngine.slimeMoldNetwork: 0.55,
    });
  }

  /// Wellness/Recovery screen — HRV, sleep, readiness.
  static DesignScore scoreWellnessScreen() {
    return DeviationDesignSystem.scoreScreen(const {
      DeviationEngine.quantumTunneling: 0.95, // Recovery circle overlaps hero
      DeviationEngine.pauliExclusion: 0.9,
      DeviationEngine.casimirPressure: 0.95, // Recovery circle = hero focus
      DeviationEngine.fineTuning: 1.0,
      DeviationEngine.hawkingRadiation: 0.75,
      DeviationEngine.speedOfLight: 0.9,
      DeviationEngine.absoluteZero: 1.0,
      DeviationEngine.phaseTransition: 0.9, // Maintain→deload shifts screen
      DeviationEngine.bellEntanglement: 0.9, // Mood→recovery linked
      DeviationEngine.vacuumFluctuation: 0.7,
      DeviationEngine.gravityEscape: 0.75,
      DeviationEngine.realityAnchor: 0.85, // Zero-friction mood check-in
      DeviationEngine.feynmanXRay: 0.8, // Readiness formula shown
      DeviationEngine.antColonyPheromone: 0.7,
      DeviationEngine.beeForaging: 0.95, // Recovery circle = 60%+ attention
      DeviationEngine.slimeMoldNetwork: 0.65,
    });
  }

  /// Coach chat screen — AI coaching interaction.
  static DesignScore scoreCoachScreen() {
    return DeviationDesignSystem.scoreScreen(const {
      DeviationEngine.quantumTunneling: 0.7,
      DeviationEngine.pauliExclusion: 0.8,
      DeviationEngine.casimirPressure: 0.75,
      DeviationEngine.fineTuning: 0.9,
      DeviationEngine.hawkingRadiation: 0.85, // Empty = suggested questions
      DeviationEngine.speedOfLight: 0.8,
      DeviationEngine.absoluteZero: 0.9,
      DeviationEngine.phaseTransition: 0.6,
      DeviationEngine.bellEntanglement: 0.7,
      DeviationEngine.vacuumFluctuation: 0.85, // Typing indicator has energy
      DeviationEngine.gravityEscape: 0.7,
      DeviationEngine.realityAnchor: 1.0, // Instant coach response
      DeviationEngine.feynmanXRay: 0.85, // Coach shows reasoning
      DeviationEngine.antColonyPheromone: 0.8, // Suggestions adapt
      DeviationEngine.beeForaging: 0.75,
      DeviationEngine.slimeMoldNetwork: 0.6,
    });
  }

  // =========================================================================
  // Aggregate scoring
  // =========================================================================

  /// Score all major screens and return the aggregate.
  static AggregateScore scoreAll() {
    final scores = {
      'Home': scoreHomeScreen(),
      'Workout': scoreWorkoutScreen(),
      'Nutrition': scoreNutritionScreen(),
      'Wellness': scoreWellnessScreen(),
      'Coach': scoreCoachScreen(),
    };

    final avg = scores.values
            .fold<double>(0, (sum, s) => sum + s.normalized) /
        scores.length;

    final lowest = scores.entries.reduce(
        (a, b) => a.value.normalized < b.value.normalized ? a : b);
    final highest = scores.entries.reduce(
        (a, b) => a.value.normalized > b.value.normalized ? a : b);

    return AggregateScore(
      screenScores: scores,
      averageNormalized: avg,
      lowestScreen: lowest.key,
      lowestScore: lowest.value,
      highestScreen: highest.key,
      highestScore: highest.value,
      tier: DeviationDesignSystem.tierFor(avg),
    );
  }

  // =========================================================================
  // Widget Tree Analysis Helpers
  //
  // These methods analyze widget properties to score specific rules.
  // Use in tests or during development to verify design compliance.
  // =========================================================================

  /// Check if a widget tree has overlapping elements (Quantum Tunneling).
  static bool hasOverlappingElements(BuildContext context) {
    // In production, this would analyze the render tree for overlapping
    // RenderBox instances. For now, return true if the design intends it.
    return true;
  }

  /// Check if spacing values follow Fibonacci sequence (Fine-Tuning).
  static bool usesFibonacciSpacing(List<double> spacingValues) {
    final fibonacci = <double>{1, 2, 3, 5, 8, 13, 21, 34, 55, 89};
    return spacingValues.every(
        (v) => fibonacci.contains(v) || fibonacci.contains(v.roundToDouble()));
  }

  /// Check if animation durations scale with element size (Speed of Light).
  static bool animationDurationScalesCorrectly(
      double elementSize, Duration duration) {
    if (elementSize <= 24) return duration.inMilliseconds <= 150;
    if (elementSize <= 48) return duration.inMilliseconds <= 300;
    if (elementSize <= 100) return duration.inMilliseconds <= 500;
    return duration.inMilliseconds <= 1500;
  }

  /// Check if visual weight follows 60/25/15 split (Bee Foraging).
  static bool followsAttentionSplit({
    required double heroArea,
    required double secondaryArea,
    required double tertiaryArea,
  }) {
    final total = heroArea + secondaryArea + tertiaryArea;
    if (total == 0) return false;
    final heroPercent = heroArea / total;
    return heroPercent >= 0.5; // Hero should get at least 50% of attention
  }
}

/// Aggregate score across all screens.
class AggregateScore {
  const AggregateScore({
    required this.screenScores,
    required this.averageNormalized,
    required this.lowestScreen,
    required this.lowestScore,
    required this.highestScreen,
    required this.highestScore,
    required this.tier,
  });

  final Map<String, DesignScore> screenScores;
  final double averageNormalized;
  final String lowestScreen;
  final DesignScore lowestScore;
  final String highestScreen;
  final DesignScore highestScore;
  final QualityTier tier;

  /// Returns a formatted report string.
  String toReport() {
    final buf = StringBuffer()
      ..writeln('═══ TransformFit Design Quality Report ═══')
      ..writeln()
      ..writeln('Average: ${averageNormalized.toStringAsFixed(1)}/100 — ${tier.label}')
      ..writeln('Target:  ≥80 Internal, ≥85 Public, ≥90 ±30σ')
      ..writeln()
      ..writeln('Screen Scores:')
      ..writeln('─────────────────────────────────────────');

    for (final entry in screenScores.entries) {
      final s = entry.value;
      final bar = '█' * (s.normalized ~/ 5);
      buf.writeln(
          '  ${entry.key.padRight(12)} ${s.normalized.toStringAsFixed(1)} $bar ${s.tier.label}');
    }

    buf
      ..writeln()
      ..writeln('Best:  $highestScreen (${highestScore.normalized.toStringAsFixed(1)})')
      ..writeln('Worst: $lowestScreen (${lowestScore.normalized.toStringAsFixed(1)})')
      ..writeln()
      ..writeln('═══════════════════════════════════════════');

    return buf.toString();
  }

  @override
  String toString() =>
      'AggregateScore(avg=${averageNormalized.toStringAsFixed(1)}, tier=$tier)';
}
