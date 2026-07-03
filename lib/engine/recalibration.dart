/// Recalibration engine — M6 trends milestone.
///
/// Weekly recalibration of training maxes based on actual performance.
/// Pure and deterministic; the Deno mirror must agree.
///
/// Doctrine L6-2: this engine owns the recalibrated numbers. The LLM may
/// only narrate. A surfaced deterministic fallback is used on LLM failure.
library;

import 'package:meta/meta.dart';

/// A single exercise's recent performance record.
@immutable
class ExercisePerformance {
  final String exerciseId;
  final double lastTrainingMaxKg;
  final double topWeightThisWeekKg;
  final int topRepsAtTopWeight;
  final int totalSetsThisWeek;
  final double averageRpe;

  const ExercisePerformance({
    required this.exerciseId,
    required this.lastTrainingMaxKg,
    required this.topWeightThisWeekKg,
    required this.topRepsAtTopWeight,
    required this.totalSetsThisWeek,
    required this.averageRpe,
  });
}

/// Result of recalibrating one exercise.
@immutable
class RecalibrationResult {
  final String exerciseId;
  final double oldTrainingMaxKg;
  final double newTrainingMaxKg;
  final double estimatedOneRmKg;
  final String direction; // 'up' | 'down' | 'hold'
  final String reason;

  const RecalibrationResult({
    required this.exerciseId,
    required this.oldTrainingMaxKg,
    required this.newTrainingMaxKg,
    required this.estimatedOneRmKg,
    required this.direction,
    required this.reason,
  });

  Map<String, Object?> toJson() => {
        'exerciseId': exerciseId,
        'oldTrainingMaxKg': oldTrainingMaxKg,
        'newTrainingMaxKg': newTrainingMaxKg,
        'estimatedOneRmKg': estimatedOneRmKg,
        'direction': direction,
        'reason': reason,
      };
}

/// Epley 1RM formula: weight * (1 + reps/30).
double epleyOneRm(double weightKg, int reps) {
  if (weightKg <= 0 || reps <= 0) return 0;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}

/// Recalibrate training maxes from weekly performance.
///
/// For each exercise:
/// - Compute estimated 1RM from the best set this week (Epley).
/// - If estimated 1RM > current training max by >2.5%, bump training max to
///   90% of estimated 1RM (leaves headroom for daily readiness).
/// - If estimated 1RM < current training max by >5%, drop training max to
///   estimated 1RM's 90% (signals detraining or fatigue).
/// - Otherwise hold.
/// - Rounding: snap to nearest 2.5kg.
List<RecalibrationResult> recalibrateTrainingMaxes(
  List<ExercisePerformance> performances,
) {
  return performances.map((p) => _recalibrateOne(p)).toList();
}

RecalibrationResult _recalibrateOne(ExercisePerformance p) {
  final est1Rm = epleyOneRm(p.topWeightThisWeekKg, p.topRepsAtTopWeight);
  final ninetyPct = est1Rm * 0.90;

  // No work sets this week → hold.
  if (p.totalSetsThisWeek == 0) {
    return RecalibrationResult(
      exerciseId: p.exerciseId,
      oldTrainingMaxKg: p.lastTrainingMaxKg,
      newTrainingMaxKg: p.lastTrainingMaxKg,
      estimatedOneRmKg: roundLoad(est1Rm),
      direction: 'hold',
      reason: 'No working sets logged this week.',
    );
  }

  final gainThreshold = p.lastTrainingMaxKg * 1.025;
  final lossThreshold = p.lastTrainingMaxKg * 0.95;

  if (ninetyPct > gainThreshold) {
    final newMax = roundLoad(ninetyPct);
    return RecalibrationResult(
      exerciseId: p.exerciseId,
      oldTrainingMaxKg: p.lastTrainingMaxKg,
      newTrainingMaxKg: newMax,
      estimatedOneRmKg: roundLoad(est1Rm),
      direction: 'up',
      reason:
          'Estimated 1RM (${roundLoad(est1Rm).toStringAsFixed(1)}kg) exceeded '
          'training max by >2.5%. Bumped to 90% of estimated 1RM.',
    );
  } else if (est1Rm < lossThreshold && p.averageRpe > 8.5) {
    // High RPE + lower performance → likely fatigue. Drop.
    final newMax = roundLoad(ninetyPct);
    return RecalibrationResult(
      exerciseId: p.exerciseId,
      oldTrainingMaxKg: p.lastTrainingMaxKg,
      newTrainingMaxKg: newMax,
      estimatedOneRmKg: roundLoad(est1Rm),
      direction: 'down',
      reason:
          'Estimated 1RM (${roundLoad(est1Rm).toStringAsFixed(1)}kg) below '
          '95% of training max with avg RPE ${p.averageRpe.toStringAsFixed(1)}. '
          'Reduced to 90% of estimated 1RM.',
    );
  } else if (est1Rm < lossThreshold) {
    // Lower performance but low RPE → easy week, hold the max.
    return RecalibrationResult(
      exerciseId: p.exerciseId,
      oldTrainingMaxKg: p.lastTrainingMaxKg,
      newTrainingMaxKg: p.lastTrainingMaxKg,
      estimatedOneRmKg: roundLoad(est1Rm),
      direction: 'hold',
      reason:
          'Lower output but low RPE (${p.averageRpe.toStringAsFixed(1)}) '
          'suggests a planned easy week. Holding training max.',
    );
  } else {
    return RecalibrationResult(
      exerciseId: p.exerciseId,
      oldTrainingMaxKg: p.lastTrainingMaxKg,
      newTrainingMaxKg: p.lastTrainingMaxKg,
      estimatedOneRmKg: roundLoad(est1Rm),
      direction: 'hold',
      reason: 'Performance within ±2.5% of training max. No change.',
    );
  }
}

/// Round load to nearest 2.5kg (mirrors progression.dart).
double roundLoad(double loadKg) {
  return (loadKg / 2.5).round() * 2.5;
}
