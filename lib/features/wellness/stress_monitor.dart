/// HRV-based stress detection and intervention recommendation.
///
/// Heart Rate Variability (HRV) is the gold-standard non-invasive biomarker
/// for autonomic nervous system (ANS) balance. Higher HRV indicates greater
/// parasympathetic (vagal) tone and lower stress; lower HRV indicates
/// sympathetic dominance and elevated stress.
///
/// Evidence base:
/// - HRV as stress biomarker: Task Force of ESC/NASPE (1996), "Heart rate
///   variability: standards of measurement, physiological interpretation."
/// - HRV-guided training: Plews et al. (2013), "Training adaptation and
///   heart rate variability in elite endurance athletes."
/// - Stress zones from HRV deviation: Nuuttila et al. (2017), "Effects of
///   HRV-guided training on load and recovery."
/// - Recovery recommendations align with the polyvagal theory (Porges, 2011):
///   activities that promote vagal tone (breathing, walking) shift ANS
///   balance from sympathetic to parasympathetic dominance.
///
/// Stress level calculation: maps HRV deviation from personal resting
/// baseline onto a 0-100 scale. A 50% drop from resting HRV corresponds
/// to maximal stress (100). No deviation = 0 stress.
///
/// Pure Dart, deterministic — no I/O, no Flutter dependencies.
library;

/// Data source for stress reading.
enum StressSource {
  /// Reading from a wearable device (e.g., Whoop, Oura, Apple Watch).
  wearable,

  /// Manual self-report or estimate.
  manual,
}

/// A single stress measurement.
///
/// Captures both raw HRV and derived stress level for flexibility. The
/// raw HRV value enables future analysis; the pre-computed stress level
/// simplifies UI consumption.
class StressReading {
  const StressReading({
    required this.hrvValue,
    required this.restingHrv,
    required this.stressLevel,
    required this.timestamp,
    required this.source,
  });

  /// Raw HRV value in milliseconds (RMSSD or SDNN depending on device).
  ///
  /// RMSSD (root mean square of successive differences) is preferred for
  /// short-term recordings and reflects parasympathetic activity.
  final double hrvValue;

  /// The user's personal resting HRV baseline in milliseconds.
  ///
  /// Individual baselines vary enormously (20-150ms). Comparing to personal
  /// baseline rather than population norms is essential for meaningful
  /// stress assessment (Plews et al., 2013).
  final double restingHrv;

  /// Derived stress level on a 0-100 scale.
  ///
  /// 0 = no stress (HRV at or above resting), 100 = maximal stress
  /// (HRV at 50% or below of resting baseline).
  final double stressLevel;

  /// When the reading was taken.
  final DateTime timestamp;

  /// How the reading was obtained.
  final StressSource source;
}

/// Stress classification zones.
///
/// Zones map to the sympathetic-parasympathetic balance continuum. Thresholds
/// are calibrated from HRV-guided training literature where a 20% deviation
/// from baseline is considered meaningful (Plews et al., 2013).
enum StressZone {
  /// Stress level 0-30. Parasympathetic dominance. Good recovery state.
  low,

  /// Stress level 31-60. Mixed ANS state. Manageable but worth monitoring.
  moderate,

  /// Stress level 61-80. Sympathetic dominance. Intervention recommended.
  high,

  /// Stress level 81-100. Severe sympathetic dominance. Immediate action.
  veryHigh,
}

/// Intervention type for stress recovery.
enum Intervention {
  /// Structured breathing exercise. Directly stimulates vagus nerve via
  /// slow diaphragmatic breathing (Lehrer & Gevirtz, 2014).
  breathingExercise,

  /// Guided meditation. Reduces cortisol and improves HRV over time
  /// (Pascoe et al., 2017, meta-analysis of 45 studies).
  meditation,

  /// Low-intensity walking. Combines gentle movement with nature exposure;
  /// 10-min walk reduces cortisol by ~15% (Park et al., 2010).
  walk,

  /// Expressive writing / journaling. Pennebaker's paradigm: 15-20 min
  /// of writing about stressors reduces stress markers (Pennebaker, 1997).
  journal,

  /// Reduce training load. High stress impairs recovery and increases
  /// injury risk; HRV-guided deloading prevents overtraining (Kiviniemi
  /// et al., 2007).
  reduceTrainingIntensity,
}

/// Deterministic stress monitoring engine.
///
/// Operates on in-memory data. The caller provides HRV readings and the
/// engine classifies stress, recommends interventions, and detects trends.
class StressMonitor {
  const StressMonitor();

  /// Classify a stress reading into a zone.
  ///
  /// Stress level is pre-computed in the reading. This method maps the
  /// level to a zone using clinically-motivated thresholds.
  StressZone classifyStress(StressReading reading) {
    if (reading.stressLevel <= 30) return StressZone.low;
    if (reading.stressLevel <= 60) return StressZone.moderate;
    if (reading.stressLevel <= 80) return StressZone.high;
    return StressZone.veryHigh;
  }

  /// Get recovery recommendation based on current stress level.
  ///
  /// Escalating interventions: low stress needs no action, moderate
  /// stress gets breathing exercises, high stress gets meditation + walk,
  /// very high stress gets all interventions plus training reduction.
  ///
  /// The escalation is based on the principle that acute interventions
  /// (breathing) work for moderate stress, but chronic/severe stress
  /// requires behavioral changes (training load reduction).
  List<Intervention> getRecoveryRecommendation(StressReading reading) {
    final zone = classifyStress(reading);
    return switch (zone) {
      StressZone.low => [],
      StressZone.moderate => [Intervention.breathingExercise],
      StressZone.high => [
          Intervention.breathingExercise,
          Intervention.meditation,
          Intervention.walk,
        ],
      StressZone.veryHigh => [
          Intervention.breathingExercise,
          Intervention.meditation,
          Intervention.walk,
          Intervention.journal,
          Intervention.reduceTrainingIntensity,
        ],
    };
  }

  /// Analyze stress trend over a series of readings.
  ///
  /// Uses linear regression slope over the reading timestamps. Returns:
  /// - positive slope: stress is increasing
  /// - near-zero slope: stress is stable
  /// - negative slope: stress is decreasing
  ///
  /// Requires at least 3 readings for meaningful trend detection.
  StressTrend getStressTrend(List<StressReading> readings) {
    if (readings.length < 3) return StressTrend.stable;

    // Sort by timestamp to ensure temporal ordering.
    final sorted = List<StressReading>.of(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstTime = sorted.first.timestamp;
    final n = sorted.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (final reading in sorted) {
      final x = reading.timestamp.difference(firstTime).inHours / 24.0;
      final y = reading.stressLevel;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return StressTrend.stable;

    final slope = (n * sumXY - sumX * sumY) / denominator;

    // Threshold: 5 points per day is a meaningful change in stress.
    if (slope > 5) return StressTrend.increasing;
    if (slope < -5) return StressTrend.decreasing;
    return StressTrend.stable;
  }

  /// Determine if an intervention should be triggered.
  ///
  /// Triggers when:
  /// 1. Current stress is high or very-high, OR
  /// 2. Stress has been increasing for 3+ consecutive readings AND current
  ///    level exceeds the user's recent average by 15+ points.
  ///
  /// This dual criterion prevents both false negatives (missing high stress)
  /// and false positives (triggering on a single spike that resolves).
  bool shouldTriggerIntervention(
    StressReading current,
    List<StressReading> recentReadings,
  ) {
    // Criterion 1: immediate high stress.
    if (current.stressLevel > 60) return true;

    // Criterion 2: sustained increase pattern.
    if (recentReadings.length < 3) return false;

    final sorted = List<StressReading>.of(recentReadings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Check last 3 readings are all increasing.
    bool increasing = true;
    for (var i = sorted.length - 3; i < sorted.length - 1; i++) {
      if (sorted[i + 1].stressLevel <= sorted[i].stressLevel) {
        increasing = false;
        break;
      }
    }

    if (!increasing) return false;

    // Check current exceeds recent average by 15+ points.
    final avg = sorted.fold<double>(0, (acc, r) => acc + r.stressLevel) /
        sorted.length;
    return current.stressLevel - avg >= 15;
  }

  /// Create a StressReading with computed stress level from raw HRV.
  ///
  /// Stress level formula:
  ///   stressLevel = max(0, min(100, (1 - hrvValue / restingHrv) * 200))
  ///
  /// At resting HRV (hrvValue == restingHrv): stress = 0.
  /// At 50% of resting HRV: stress = 100.
  /// Above resting HRV: stress = 0 (clamped).
  ///
  /// The 200 multiplier maps the 0-0.5 HRV ratio range to 0-100 stress.
  static StressReading createReading({
    required double hrvValue,
    required double restingHrv,
    required DateTime timestamp,
    required StressSource source,
  }) {
    final ratio = hrvValue / restingHrv;
    final rawStress = (1 - ratio) * 200;
    final stressLevel = rawStress.clamp(0.0, 100.0);

    return StressReading(
      hrvValue: hrvValue,
      restingHrv: restingHrv,
      stressLevel: stressLevel,
      timestamp: timestamp,
      source: source,
    );
  }
}

/// Stress trend direction.
enum StressTrend {
  /// Stress levels are rising over time.
  increasing,

  /// Stress levels are stable.
  stable,

  /// Stress levels are declining over time.
  decreasing,
}

/// Human-readable intervention descriptions.
extension InterventionLabel on Intervention {
  String get label => switch (this) {
        Intervention.breathingExercise => 'Breathing Exercise',
        Intervention.meditation => 'Meditation',
        Intervention.walk => 'Walk',
        Intervention.journal => 'Journal',
        Intervention.reduceTrainingIntensity =>
          'Reduce Training Intensity',
      };

  /// Detailed guidance for the intervention.
  String get guidance => switch (this) {
        Intervention.breathingExercise =>
          'Try box breathing: inhale 4s, hold 4s, exhale 4s, hold 4s. '
              'Repeat for 5 minutes. Slow exhalation activates the vagus '
              'nerve, shifting your autonomic nervous system toward '
              'parasympathetic dominance.',
        Intervention.meditation =>
          'Sit comfortably and focus on your breath for 10 minutes. '
              'When thoughts arise, acknowledge them and return to breath. '
              'Regular practice reduces baseline cortisol levels.',
        Intervention.walk =>
          'Take a 10-15 minute walk, preferably outdoors. Low-intensity '
              'movement combined with nature exposure reduces cortisol '
              'by approximately 15%.',
        Intervention.journal =>
          'Write freely about your stressors for 15-20 minutes. '
              'Pennebaker\'s research shows expressive writing reduces '
              'stress markers and improves immune function.',
        Intervention.reduceTrainingIntensity =>
          'Your stress levels indicate impaired recovery capacity. '
              'Reduce training volume by 40-50% for 3-5 days to allow '
              'your autonomic nervous system to recover.',
      };
}
