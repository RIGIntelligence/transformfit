/// Deterministic progression engine — M4 logging milestone.
///
/// Computes the next-session weight/reps/RPE prescription from logged
/// history using a double-progression corridor. Pure, no I/O, no
/// randomness, no time dependence (uses the timestamps from inputs, never
/// `DateTime.now()`). Same spec as
/// `supabase/functions/_shared/engines/progression.ts`; the two runtimes
/// must agree for identical inputs.
///
/// Doctrine L6-2 (deterministic-before-agentic): this engine owns every
/// weight/reps/RPE decision. The LLM may only narrate. If the LLM fails,
/// a deterministic narrative is surfaced (never a silent hardcoded
/// template).
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/// One previously-logged set for the same exercise, used as a progression
/// anchor. Only the most recent N are needed; the caller selects which.
class ProgressionAnchor {
  const ProgressionAnchor({
    required this.weightKg,
    required this.reps,
    required this.rpe,
    required this.completedAt,
  });

  final double weightKg;
  final int reps;
  final int rpe;
  final DateTime completedAt;
}

/// Per-exercise prescription parameters (from the plan engine).
class ProgressionParams {
  const ProgressionParams({
    required this.repsMin,
    required this.repsMax,
    required this.rpeTarget,
    required this.restSeconds,
  });

  final int repsMin;
  final int repsMax;
  final int rpeTarget;
  final int restSeconds;
}

/// Inputs to the progression engine.
class ProgressionInputs {
  const ProgressionInputs({
    required this.exerciseId,
    required this.params,
    this.lastAnchor,
    this.recentAnchors = const [],
    this.readinessScore,
    this.deloadRecommended = false,
  });

  final String exerciseId;
  final ProgressionParams params;
  final ProgressionAnchor? lastAnchor;

  /// Most-recent-first recent sets for the exercise (for fatigue/volume
  /// calculation). Caller should pass up to 7 sessions.
  final List<ProgressionAnchor> recentAnchors;
  final int? readinessScore;
  final bool deloadRecommended;
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

class ProgressionResult {
  const ProgressionResult({
    required this.exerciseId,
    required this.prescribedWeightKg,
    required this.prescribedReps,
    required this.prescribedRpe,
    required this.prescribedSets,
    required this.prescribedRestSeconds,
    required this.progressionType,
    required this.progressionReason,
    required this.volumeMultiplier,
    required this.acwr,
    required this.fatigueState,
    required this.isDeload,
  });

  final String exerciseId;
  final double prescribedWeightKg;
  final int prescribedReps;
  final int prescribedRpe;
  final int prescribedSets;
  final int prescribedRestSeconds;

  /// 'baseline' | 'rep_progression' | 'load_progression' | 'deload' |
  /// 'rebuild' | 'hold'
  final String progressionType;
  final String progressionReason;
  final double volumeMultiplier;

  /// Acute:chronic workload ratio (0.0 if insufficient data).
  final double acwr;

  /// 'safe' | 'caution' | 'high'
  final String fatigueState;

  final bool isDeload;

  Map<String, Object?> toJson() => {
        'exerciseId': exerciseId,
        'prescribedWeightKg': prescribedWeightKg,
        'prescribedReps': prescribedReps,
        'prescribedRpe': prescribedRpe,
        'prescribedSets': prescribedSets,
        'prescribedRestSeconds': prescribedRestSeconds,
        'progressionType': progressionType,
        'progressionReason': progressionReason,
        'volumeMultiplier': volumeMultiplier,
        'acwr': acwr,
        'fatigueState': fatigueState,
        'isDeload': isDeload,
      };
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Minimum weight increment for load progression (kg).
const double minLoadIncrement = 2.5;

/// Default sets when no fatigue-based adjustment.
const int defaultSets = 3;

/// ACWR thresholds (Gabbett 2016, widely cited).
const double acwrSafeMax = 1.3;
const double acwrDangerMin = 1.5;

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

/// Compute the next-session prescription for [inputs], deterministically.
///
/// Algorithm:
///   1. Compute ACWR from recent volume (7-day acute vs 28-day chronic).
///   2. If deload recommended or ACWR >= danger, prescribe a deload week
///      (60% volume, same weight or slightly reduced).
///   3. If no prior anchor, return baseline (weight=0 for bodyweight, or
///      a conservative starting weight derived from first-set heuristics).
///   4. Double progression: if the last set hit repsMax at or below
///      rpeTarget-1, progress load by minLoadIncrement and reset reps to
///      repsMin. Otherwise, if reps < repsMax, add one rep. If reps ==
///      repsMax but RPE > rpeTarget, hold.
///   5. Readiness modulates volume (not the core load decision): push
///      zone = +1 set, maintain = 0, deload = -1 set (floor 2).
ProgressionResult computeProgression(ProgressionInputs inputs) {
  if (inputs.exerciseId.isEmpty) {
    throw ArgumentError.value(
      inputs.exerciseId,
      'exerciseId',
      'must be non-empty',
    );
  }

  final acwr = _computeAcwr(inputs.recentAnchors);
  final fatigueState = _fatigueState(acwr);

  // Deload override: explicit flag OR dangerous ACWR.
  final isDeload = inputs.deloadRecommended || acwr >= acwrDangerMin;

  // Volume multiplier from fatigue (independent of the load decision).
  final volumeMultiplier = _volumeMultiplier(
    acwr: acwr,
    deload: isDeload,
    readinessScore: inputs.readinessScore,
  );

  // Sets: base 3, adjusted by readiness, floored at 2.
  var prescribedSets = defaultSets;
  if (inputs.readinessScore != null) {
    if (inputs.readinessScore! >= 75) {
      prescribedSets = defaultSets + 1;
    } else if (inputs.readinessScore! < 50) {
      prescribedSets = defaultSets - 1;
    }
  }
  // Fatigue haircut.
  if (fatigueState == 'high') prescribedSets -= 1;
  prescribedSets = math.max(2, prescribedSets);

  if (isDeload) {
    prescribedSets = math.max(2, prescribedSets - 1);
  }

  // --- Load / reps decision ---
  final last = inputs.lastAnchor;
  if (last == null) {
    // Baseline: no prior data. Conservative entry.
    return ProgressionResult(
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: 0.0,
      prescribedReps: inputs.params.repsMin,
      prescribedRpe: inputs.params.rpeTarget,
      prescribedSets: prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: 'baseline',
      progressionReason:
          'No prior logged sets for this exercise; starting at the '
          'prescribed rep minimum with bodyweight or a conservative entry load.',
      volumeMultiplier: volumeMultiplier,
      acwr: acwr,
      fatigueState: fatigueState,
      isDeload: isDeload,
    );
  }

  // Deload path: same weight (or 90% if high fatigue), reduced volume.
  if (isDeload) {
    final deloadWeight = fatigueState == 'high'
        ? _roundLoad(last.weightKg * 0.90)
        : last.weightKg;
    return ProgressionResult(
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: deloadWeight,
      prescribedReps: math.max(inputs.params.repsMin, last.reps - 2),
      prescribedRpe: math.max(5, inputs.params.rpeTarget - 2),
      prescribedSets: prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds + 30,
      progressionType: 'deload',
      progressionReason: acwr >= acwrDangerMin
          ? 'ACWR ${acwr.toStringAsFixed(2)} exceeds the danger threshold '
              '(${acwrDangerMin.toStringAsFixed(1)}); prescribing a deload to '
              'reduce accumulated fatigue.'
          : 'Deload recommended; reducing volume and intensity for recovery.',
      volumeMultiplier: volumeMultiplier,
      acwr: acwr,
      fatigueState: fatigueState,
      isDeload: true,
    );
  }

  // Double progression corridor:
  //   - If last set hit repsMax AND rpe <= rpeTarget - 1 → add load.
  //   - If last set hit repsMax but rpe >= rpeTarget → hold.
  //   - If last reps < repsMax → add one rep.
  //   - If last reps < repsMin (regressed) → rebuild.
  final targetMax = inputs.params.repsMax;
  final targetMin = inputs.params.repsMin;

  if (last.reps >= targetMax && last.rpe <= inputs.params.rpeTarget - 1) {
    // Load progression.
    final newWeight = _roundLoad(last.weightKg + minLoadIncrement);
    return ProgressionResult(
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: newWeight,
      prescribedReps: targetMin,
      prescribedRpe: inputs.params.rpeTarget,
      prescribedSets: prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: 'load_progression',
      progressionReason:
          'Last set hit ${last.reps} reps at RPE ${last.rpe} (target max '
          '$targetMax at RPE ${inputs.params.rpeTarget}); load increased by '
          '${minLoadIncrement.toStringAsFixed(1)} kg and reps reset to '
          '$targetMin.',
      volumeMultiplier: volumeMultiplier,
      acwr: acwr,
      fatigueState: fatigueState,
      isDeload: false,
    );
  }

  if (last.reps >= targetMax && last.rpe >= inputs.params.rpeTarget) {
    // Hold at max reps — RPE too high to add load.
    return ProgressionResult(
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: last.weightKg,
      prescribedReps: targetMax,
      prescribedRpe: inputs.params.rpeTarget,
      prescribedSets: prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: 'hold',
      progressionReason:
          'Last set hit ${last.reps} reps but at RPE ${last.rpe} (target '
          '${inputs.params.rpeTarget}); holding load until RPE drops.',
      volumeMultiplier: volumeMultiplier,
      acwr: acwr,
      fatigueState: fatigueState,
      isDeload: false,
    );
  }

  if (last.reps < targetMin) {
    // Rebuild — regressed below the corridor.
    return ProgressionResult(
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: _roundLoad(last.weightKg * 0.90),
      prescribedReps: targetMin,
      prescribedRpe: math.max(5, inputs.params.rpeTarget - 1),
      prescribedSets: prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: 'rebuild',
      progressionReason:
          'Last set was ${last.reps} reps (below corridor min $targetMin); '
          'reducing load 10% to rebuild quality reps.',
      volumeMultiplier: volumeMultiplier,
      acwr: acwr,
      fatigueState: fatigueState,
      isDeload: false,
    );
  }

  // Rep progression: add one rep within the corridor.
  final newReps = math.min(targetMax, last.reps + 1);
  return ProgressionResult(
    exerciseId: inputs.exerciseId,
    prescribedWeightKg: last.weightKg,
    prescribedReps: newReps,
    prescribedRpe: inputs.params.rpeTarget,
    prescribedSets: prescribedSets,
    prescribedRestSeconds: inputs.params.restSeconds,
    progressionType: newReps > last.reps ? 'rep_progression' : 'hold',
    progressionReason: newReps > last.reps
        ? 'Last set was ${last.reps} reps at RPE ${last.rpe} (within corridor '
            '$targetMin-$targetMax); adding one rep to $newReps.'
        : 'At the top of the rep corridor; holding at $newReps reps.',
    volumeMultiplier: volumeMultiplier,
    acwr: acwr,
    fatigueState: fatigueState,
    isDeload: false,
  );
}

// ---------------------------------------------------------------------------
// Fatigue / ACWR
// ---------------------------------------------------------------------------

/// Compute the acute:chronic workload ratio from recent anchors.
///
/// Volume = weight * reps per set. Acute = sum of last 7 days; chronic =
/// average of the preceding 21 days (28-day window total). Returns 0.0
/// when there is insufficient data (< 7 days of history or chronic == 0).
double _computeAcwr(List<ProgressionAnchor> anchors) {
  if (anchors.isEmpty) return 0.0;

  final now = anchors.first.completedAt;
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final twentyEightDaysAgo = now.subtract(const Duration(days: 28));

  double acuteVolume = 0.0;
  double chronicVolume = 0.0;
  int chronicDays = 0;

  for (final a in anchors) {
    final volume = a.weightKg * a.reps;
    if (!a.completedAt.isBefore(sevenDaysAgo)) {
      acuteVolume += volume;
    } else if (!a.completedAt.isBefore(twentyEightDaysAgo)) {
      chronicVolume += volume;
    }
  }

  // Estimate chronic days from the window.
  for (final a in anchors) {
    if (a.completedAt.isBefore(sevenDaysAgo) &&
        !a.completedAt.isBefore(twentyEightDaysAgo)) {
      chronicDays++;
    }
  }

  if (chronicVolume == 0.0 || chronicDays == 0) return 0.0;

  // Chronic load = average daily load over the 21-day chronic window.
  final chronicDaily = chronicVolume / 21.0;
  if (chronicDaily == 0.0) return 0.0;

  // Acute load = average daily over 7 days.
  final acuteDaily = acuteVolume / 7.0;

  return acuteDaily / chronicDaily;
}

/// Classify fatigue from ACWR.
String _fatigueState(double acwr) {
  if (acwr == 0.0) return 'safe';
  if (acwr < acwrSafeMax) return 'safe';
  if (acwr < acwrDangerMin) return 'caution';
  return 'high';
}

/// Volume multiplier: combines fatigue and readiness.
double _volumeMultiplier({
  required double acwr,
  required bool deload,
  required int? readinessScore,
}) {
  if (deload) return 0.60;

  double base = 1.0;
  if (acwr >= acwrDangerMin) {
    base = 0.70;
  } else if (acwr >= acwrSafeMax) {
    base = 0.85;
  }

  if (readinessScore != null) {
    if (readinessScore >= 75) {
      base = math.min(1.10, base + 0.10);
    } else if (readinessScore < 50) {
      base = math.max(0.50, base - 0.15);
    }
  }

  return base;
}

/// Round to the nearest 2.5 kg increment (standard plate denomination).
double _roundLoad(double kg) {
  if (kg <= 0) return 0.0;
  return (kg / minLoadIncrement).round() * minLoadIncrement;
}

// ---------------------------------------------------------------------------
// Public helpers (also used by tests and the Deno parity layer)
// ---------------------------------------------------------------------------

/// Public ACWR computation for testing / cross-runtime parity.
double computeAcwr(List<ProgressionAnchor> anchors) =>
    _computeAcwr(anchors);

/// Public fatigue classification for testing / cross-runtime parity.
String classifyFatigue(double acwr) => _fatigueState(acwr);

/// Round a load to the nearest valid plate increment.
double roundLoad(double kg) => _roundLoad(kg);
