/// Post-session analysis engine — M5 Debrief milestone.
///
/// Computes deterministic post-session analytics from logged exercise data:
/// volume total, estimated 1RM changes (Epley formula), progression corridor
/// status, and readiness impact. Pure, no I/O, no randomness, no time
/// dependence. The Deno mirror at
/// `supabase/functions/_shared/engines/post_session_analysis.ts` must agree.
///
/// Doctrine L6-2 (deterministic-before-agentic): this engine owns every
/// number in the debrief. The LLM may only narrate. A surfaced deterministic
/// fallback is used on LLM failure (never a silent hardcoded template).
library;

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// A single logged set within the session being analysed.
class AnalysisLoggedSet {
  const AnalysisLoggedSet({
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    this.rpe,
  });

  final String exerciseId;
  final double weightKg;
  final int reps;
  final int? rpe;
}

/// Per-exercise previous best, used to compute 1RM delta.
class AnalysisPreviousBest {
  const AnalysisPreviousBest({
    required this.exerciseId,
    required this.estimatedOneRmKg,
  });

  final String exerciseId;
  final double estimatedOneRmKg;
}

/// Inputs to the post-session analysis engine.
class PostSessionAnalysisInputs {
  const PostSessionAnalysisInputs({
    required this.sets,
    this.previousBests = const [],
    this.durationMinutes,
    this.readinessScoreBefore,
    this.corridorRepsMin = 5,
    this.corridorRepsMax = 12,
    this.corridorRpeTarget = 7,
  });

  final List<AnalysisLoggedSet> sets;
  final List<AnalysisPreviousBest> previousBests;
  final int? durationMinutes;
  final int? readinessScoreBefore;

  /// Progression corridor parameters used to judge whether the session
  /// stayed within the intended rep/RPE band.
  final int corridorRepsMin;
  final int corridorRepsMax;
  final int corridorRpeTarget;
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

/// Per-exercise 1RM change summary.
class OneRmChange {
  const OneRmChange({
    required this.exerciseId,
    required this.sessionOneRmKg,
    required this.previousOneRmKg,
    required this.deltaKg,
  });

  final String exerciseId;
  final double sessionOneRmKg;
  final double previousOneRmKg;
  final double deltaKg;
}

/// Result of the post-session analysis.
class PostSessionAnalysisResult {
  const PostSessionAnalysisResult({
    required this.totalVolumeKg,
    required this.totalSets,
    required this.totalReps,
    required this.averageRpe,
    required this.oneRmChanges,
    required this.corridorStatus,
    required this.corridorReason,
    required this.readinessImpact,
    required this.readinessImpactReason,
    required this.durationMinutes,
  });

  final double totalVolumeKg;
  final int totalSets;
  final int totalReps;
  final double averageRpe;
  final List<OneRmChange> oneRmChanges;

  /// 'in_corridor' | 'above_corridor' | 'below_corridor'
  final String corridorStatus;
  final String corridorReason;

  /// Estimated readiness impact in points (negative = more fatigue).
  final int readinessImpact;
  final String readinessImpactReason;

  final int? durationMinutes;

  Map<String, Object?> toJson() => {
        'totalVolumeKg': totalVolumeKg,
        'totalSets': totalSets,
        'totalReps': totalReps,
        'averageRpe': averageRpe,
        'oneRmChanges': oneRmChanges
            .map((c) => {
                  'exerciseId': c.exerciseId,
                  'sessionOneRmKg': c.sessionOneRmKg,
                  'previousOneRmKg': c.previousOneRmKg,
                  'deltaKg': c.deltaKg,
                })
            .toList(),
        'corridorStatus': corridorStatus,
        'corridorReason': corridorReason,
        'readinessImpact': readinessImpact,
        'readinessImpactReason': readinessImpactReason,
        'durationMinutes': durationMinutes,
      };
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

/// Compute deterministic post-session analytics.
///
/// Algorithm:
///   1. Volume = sum(weight × reps) across all sets.
///   2. Per-exercise session 1RM via Epley: 1RM = w × (1 + r/30). Compare
///      against [PostSessionAnalysisInputs.previousBests] for deltas.
///   3. Corridor status from the average RPE and rep range vs the target
///      corridor.
///   4. Readiness impact: heuristic from total volume, average RPE, and
///      duration — higher volume/RPE → larger negative impact.
PostSessionAnalysisResult computePostSessionAnalysis(
  PostSessionAnalysisInputs inputs,
) {
  if (inputs.sets.isEmpty) {
    return const PostSessionAnalysisResult(
      totalVolumeKg: 0.0,
      totalSets: 0,
      totalReps: 0,
      averageRpe: 0.0,
      oneRmChanges: [],
      corridorStatus: 'in_corridor',
      corridorReason: 'No sets logged; corridor is trivially satisfied.',
      readinessImpact: 0,
      readinessImpactReason: 'No training stimulus recorded.',
      durationMinutes: null,
    );
  }

  var totalVolume = 0.0;
  var totalReps = 0;
  var rpeSum = 0;
  var rpeCount = 0;

  // Per-exercise best 1RM within this session.
  final sessionBestOneRm = <String, double>{};
  for (final s in inputs.sets) {
    if (s.weightKg <= 0 || s.reps <= 0) continue;
    final volume = s.weightKg * s.reps;
    totalVolume += volume;
    totalReps += s.reps;
    if (s.rpe != null) {
      rpeSum += s.rpe!;
      rpeCount++;
    }
    final oneRm = _epleyOneRm(s.weightKg, s.reps);
    final prev = sessionBestOneRm[s.exerciseId];
    if (prev == null || oneRm > prev) {
      sessionBestOneRm[s.exerciseId] = oneRm;
    }
  }

  final averageRpe = rpeCount > 0 ? rpeSum / rpeCount : 0.0;

  // 1RM changes vs previous bests.
  final prevMap = <String, double>{
    for (final b in inputs.previousBests) b.exerciseId: b.estimatedOneRmKg,
  };
  final oneRmChanges = <OneRmChange>[];
  for (final entry in sessionBestOneRm.entries) {
    final prev = prevMap[entry.key] ?? entry.value;
    oneRmChanges.add(OneRmChange(
      exerciseId: entry.key,
      sessionOneRmKg: _round(entry.value),
      previousOneRmKg: _round(prev),
      deltaKg: _round(entry.value - prev),
    ));
  }
  // Deterministic ordering.
  oneRmChanges.sort((a, b) => a.exerciseId.compareTo(b.exerciseId));

  // Corridor status.
  final avgReps = inputs.sets.isNotEmpty
      ? inputs.sets.map((s) => s.reps).reduce((a, b) => a + b) /
          inputs.sets.length
      : 0.0;
  final (corridorStatus, corridorReason) = _classifyCorridor(
    avgReps: avgReps,
    averageRpe: averageRpe,
    inputs: inputs,
  );

  // Readiness impact.
  final (readinessImpact, readinessImpactReason) = _readinessImpact(
    totalVolume: totalVolume,
    averageRpe: averageRpe,
    durationMinutes: inputs.durationMinutes,
  );

  return PostSessionAnalysisResult(
    totalVolumeKg: _round(totalVolume),
    totalSets: inputs.sets.length,
    totalReps: totalReps,
    averageRpe: _round(averageRpe),
    oneRmChanges: oneRmChanges,
    corridorStatus: corridorStatus,
    corridorReason: corridorReason,
    readinessImpact: readinessImpact,
    readinessImpactReason: readinessImpactReason,
    durationMinutes: inputs.durationMinutes,
  );
}

/// Epley 1RM estimate: 1RM = w × (1 + reps / 30).
double _epleyOneRm(double weightKg, int reps) {
  if (reps <= 0) return 0.0;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}

/// Classify whether the session stayed in the progression corridor.
(String, String) _classifyCorridor({
  required double avgReps,
  required double averageRpe,
  required PostSessionAnalysisInputs inputs,
}) {
  final min = inputs.corridorRepsMin;
  final max = inputs.corridorRepsMax;
  final targetRpe = inputs.corridorRpeTarget;

  if (avgReps > max + 1 && averageRpe <= targetRpe - 1) {
    return (
      'above_corridor',
      'Average ${avgReps.toStringAsFixed(1)} reps exceeded the corridor max '
          '($max) at low RPE (${averageRpe.toStringAsFixed(1)}); ready for load '
          'progression next session.',
    );
  }
  if (avgReps < min - 1 || averageRpe >= targetRpe + 2) {
    return (
      'below_corridor',
      'Average ${avgReps.toStringAsFixed(1)} reps or RPE '
          '${averageRpe.toStringAsFixed(1)} pushed outside the corridor '
          '($min-$max reps at RPE $targetRpe); hold load and rebuild quality.',
    );
  }
  return (
    'in_corridor',
    'Average ${avgReps.toStringAsFixed(1)} reps at RPE '
        '${averageRpe.toStringAsFixed(1)} stayed within the corridor '
        '($min-$max at RPE $targetRpe).',
  );
}

/// Estimate readiness impact (points subtracted from next readiness score).
(int, String) _readinessImpact({
  required double totalVolume,
  required double averageRpe,
  required int? durationMinutes,
}) {
  // Heuristic: base impact from volume (per 1000 kg → ~1 point), plus RPE
  // pressure (RPE above 7 → +1 each), plus duration (per 15 min → +1).
  var impact = 0.0;
  impact += (totalVolume / 1000.0).clamp(0, 10);
  if (averageRpe > 7) {
    impact += (averageRpe - 7).clamp(0, 3);
  }
  if (durationMinutes != null && durationMinutes > 0) {
    impact += (durationMinutes / 15.0).clamp(0, 4);
  }
  final rounded = impact.round().clamp(0, 20);
  String reason;
  if (rounded == 0) {
    reason = 'Minimal stimulus; negligible readiness impact.';
  } else if (rounded <= 5) {
    reason = 'Moderate session; expect '
        '$rounded-point readiness dip tomorrow.';
  } else if (rounded <= 12) {
    reason = 'Significant session; expect '
        '$rounded-point readiness dip and possible soreness.';
  } else {
    reason = 'Heavy session; expect '
        '$rounded-point readiness dip and elevated soreness risk.';
  }
  return (rounded, reason);
}

double _round(double value) {
  return (value * 100).round() / 100.0;
}

/// Public 1RM helper for testing / cross-runtime parity.
double epleyOneRm(double weightKg, int reps) => _epleyOneRm(weightKg, reps);

/// Round to 2 decimal places (parity helper).
double roundTo2(double value) => _round(value);
