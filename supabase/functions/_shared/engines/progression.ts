// Deterministic progression engine — Deno mirror of
// lib/engine/progression.dart.
// No time, randomness, network, or database access belongs in this file.
// The two runtimes MUST agree for identical inputs (doctrine L6-2,
// deterministic-before-agentic).

export interface ProgressionAnchor {
  weightKg: number;
  reps: number;
  rpe: number;
  completedAt: string; // ISO 8601
}

export interface ProgressionParams {
  repsMin: number;
  repsMax: number;
  rpeTarget: number;
  restSeconds: number;
}

export interface ProgressionInputs {
  exerciseId: string;
  params: ProgressionParams;
  lastAnchor: ProgressionAnchor | null;
  recentAnchors: ProgressionAnchor[];
  readinessScore: number | null;
  deloadRecommended: boolean;
}

export interface ProgressionResult {
  exerciseId: string;
  prescribedWeightKg: number;
  prescribedReps: number;
  prescribedRpe: number;
  prescribedSets: number;
  prescribedRestSeconds: number;
  progressionType:
    | "baseline"
    | "rep_progression"
    | "load_progression"
    | "deload"
    | "rebuild"
    | "hold";
  progressionReason: string;
  volumeMultiplier: number;
  acwr: number;
  fatigueState: "safe" | "caution" | "high";
  isDeload: boolean;
}

// Constants — must match the Dart side exactly.
const MIN_LOAD_INCREMENT = 2.5;
const DEFAULT_SETS = 3;
const ACWR_SAFE_MAX = 1.3;
const ACWR_DANGER_MIN = 1.5;

export function computeProgression(
  inputs: ProgressionInputs,
): ProgressionResult {
  if (!inputs.exerciseId || inputs.exerciseId.trim().length === 0) {
    throw new Error("exerciseId must be non-empty");
  }

  const acwr = computeAcwr(inputs.recentAnchors);
  const fatigueState = classifyFatigue(acwr);

  const isDeload = inputs.deloadRecommended || acwr >= ACWR_DANGER_MIN;

  const volumeMultiplier = _volumeMultiplier(
    acwr,
    isDeload,
    inputs.readinessScore,
  );

  let prescribedSets = DEFAULT_SETS;
  if (inputs.readinessScore !== null && inputs.readinessScore !== undefined) {
    if (inputs.readinessScore >= 75) {
      prescribedSets = DEFAULT_SETS + 1;
    } else if (inputs.readinessScore < 50) {
      prescribedSets = DEFAULT_SETS - 1;
    }
  }
  if (fatigueState === "high") prescribedSets -= 1;
  prescribedSets = Math.max(2, prescribedSets);

  if (isDeload) {
    prescribedSets = Math.max(2, prescribedSets - 1);
  }

  const last = inputs.lastAnchor;
  if (last === null) {
    return {
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: 0.0,
      prescribedReps: inputs.params.repsMin,
      prescribedRpe: inputs.params.rpeTarget,
      prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: "baseline",
      progressionReason:
        "No prior logged sets for this exercise; starting at the prescribed rep minimum with bodyweight or a conservative entry load.",
      volumeMultiplier,
      acwr,
      fatigueState,
      isDeload,
    };
  }

  if (isDeload) {
    const deloadWeight = fatigueState === "high"
      ? roundLoad(last.weightKg * 0.90)
      : last.weightKg;
    return {
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: deloadWeight,
      prescribedReps: Math.max(inputs.params.repsMin, last.reps - 2),
      prescribedRpe: Math.max(5, inputs.params.rpeTarget - 2),
      prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds + 30,
      progressionType: "deload",
      progressionReason: acwr >= ACWR_DANGER_MIN
        ? `ACWR ${acwr.toFixed(2)} exceeds the danger threshold (${ACWR_DANGER_MIN.toFixed(1)}); prescribing a deload to reduce accumulated fatigue.`
        : "Deload recommended; reducing volume and intensity for recovery.",
      volumeMultiplier,
      acwr,
      fatigueState,
      isDeload: true,
    };
  }

  const targetMax = inputs.params.repsMax;
  const targetMin = inputs.params.repsMin;

  if (last.reps >= targetMax && last.rpe <= inputs.params.rpeTarget - 1) {
    const newWeight = roundLoad(last.weightKg + MIN_LOAD_INCREMENT);
    return {
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: newWeight,
      prescribedReps: targetMin,
      prescribedRpe: inputs.params.rpeTarget,
      prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: "load_progression",
      progressionReason:
        `Last set hit ${last.reps} reps at RPE ${last.rpe} (target max ${targetMax} at RPE ${inputs.params.rpeTarget}); load increased by ${MIN_LOAD_INCREMENT.toFixed(1)} kg and reps reset to ${targetMin}.`,
      volumeMultiplier,
      acwr,
      fatigueState,
      isDeload: false,
    };
  }

  if (last.reps >= targetMax && last.rpe >= inputs.params.rpeTarget) {
    return {
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: last.weightKg,
      prescribedReps: targetMax,
      prescribedRpe: inputs.params.rpeTarget,
      prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: "hold",
      progressionReason:
        `Last set hit ${last.reps} reps but at RPE ${last.rpe} (target ${inputs.params.rpeTarget}); holding load until RPE drops.`,
      volumeMultiplier,
      acwr,
      fatigueState,
      isDeload: false,
    };
  }

  if (last.reps < targetMin) {
    return {
      exerciseId: inputs.exerciseId,
      prescribedWeightKg: roundLoad(last.weightKg * 0.90),
      prescribedReps: targetMin,
      prescribedRpe: Math.max(5, inputs.params.rpeTarget - 1),
      prescribedSets,
      prescribedRestSeconds: inputs.params.restSeconds,
      progressionType: "rebuild",
      progressionReason:
        `Last set was ${last.reps} reps (below corridor min ${targetMin}); reducing load 10% to rebuild quality reps.`,
      volumeMultiplier,
      acwr,
      fatigueState,
      isDeload: false,
    };
  }

  const newReps = Math.min(targetMax, last.reps + 1);
  return {
    exerciseId: inputs.exerciseId,
    prescribedWeightKg: last.weightKg,
    prescribedReps: newReps,
    prescribedRpe: inputs.params.rpeTarget,
    prescribedSets,
    prescribedRestSeconds: inputs.params.restSeconds,
    progressionType: newReps > last.reps ? "rep_progression" : "hold",
    progressionReason: newReps > last.reps
      ? `Last set was ${last.reps} reps at RPE ${last.rpe} (within corridor ${targetMin}-${targetMax}); adding one rep to ${newReps}.`
      : `At the top of the rep corridor; holding at ${newReps} reps.`,
    volumeMultiplier,
    acwr,
    fatigueState,
    isDeload: false,
  };
}

// --- ACWR ---

export function computeAcwr(
  anchors: ProgressionAnchor[],
): number {
  if (anchors.length === 0) return 0.0;

  const now = new Date(anchors[0].completedAt);
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const twentyEightDaysAgo = new Date(
    now.getTime() - 28 * 24 * 60 * 60 * 1000,
  );

  let acuteVolume = 0.0;
  let chronicVolume = 0.0;
  let chronicDays = 0;

  for (const a of anchors) {
    const volume = a.weightKg * a.reps;
    const d = new Date(a.completedAt);
    if (d >= sevenDaysAgo) {
      acuteVolume += volume;
    } else if (d >= twentyEightDaysAgo) {
      chronicVolume += volume;
    }
  }

  for (const a of anchors) {
    const d = new Date(a.completedAt);
    if (d < sevenDaysAgo && d >= twentyEightDaysAgo) {
      chronicDays++;
    }
  }

  if (chronicVolume === 0.0 || chronicDays === 0) return 0.0;

  const chronicDaily = chronicVolume / 21.0;
  if (chronicDaily === 0.0) return 0.0;

  const acuteDaily = acuteVolume / 7.0;
  return acuteDaily / chronicDaily;
}

export function classifyFatigue(acwr: number): "safe" | "caution" | "high" {
  if (acwr === 0.0) return "safe";
  if (acwr < ACWR_SAFE_MAX) return "safe";
  if (acwr < ACWR_DANGER_MIN) return "caution";
  return "high";
}

export function roundLoad(kg: number): number {
  if (kg <= 0) return 0.0;
  return Math.round(kg / MIN_LOAD_INCREMENT) * MIN_LOAD_INCREMENT;
}

function _volumeMultiplier(
  acwr: number,
  deload: boolean,
  readinessScore: number | null,
): number {
  if (deload) return 0.60;

  let base = 1.0;
  if (acwr >= ACWR_DANGER_MIN) {
    base = 0.70;
  } else if (acwr >= ACWR_SAFE_MAX) {
    base = 0.85;
  }

  if (readinessScore !== null && readinessScore !== undefined) {
    if (readinessScore >= 75) {
      base = Math.min(1.10, base + 0.10);
    } else if (readinessScore < 50) {
      base = Math.max(0.50, base - 0.15);
    }
  }

  return base;
}
