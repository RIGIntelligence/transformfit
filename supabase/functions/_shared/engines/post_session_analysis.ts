// Deterministic post-session analysis engine — Deno mirror of
// lib/engine/post_session_analysis.dart.
// No time, randomness, network, or database access belongs in this file.
// The two runtimes MUST agree for identical inputs (doctrine L6-2,
// deterministic-before-agentic).

export interface AnalysisLoggedSet {
  exerciseId: string;
  weightKg: number;
  reps: number;
  rpe?: number | null;
}

export interface AnalysisPreviousBest {
  exerciseId: string;
  estimatedOneRmKg: number;
}

export interface PostSessionAnalysisInputs {
  sets: AnalysisLoggedSet[];
  previousBests?: AnalysisPreviousBest[];
  durationMinutes?: number | null;
  readinessScoreBefore?: number | null;
  corridorRepsMin?: number;
  corridorRepsMax?: number;
  corridorRpeTarget?: number;
}

export interface OneRmChange {
  exerciseId: string;
  sessionOneRmKg: number;
  previousOneRmKg: number;
  deltaKg: number;
}

export interface PostSessionAnalysisResult {
  totalVolumeKg: number;
  totalSets: number;
  totalReps: number;
  averageRpe: number;
  oneRmChanges: OneRmChange[];
  corridorStatus: "in_corridor" | "above_corridor" | "below_corridor";
  corridorReason: string;
  readinessImpact: number;
  readinessImpactReason: string;
  durationMinutes: number | null;
}

function epleyOneRm(weightKg: number, reps: number): number {
  if (reps <= 0) return 0.0;
  if (reps === 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}

function round2(value: number): number {
  return Math.round(value * 100) / 100.0;
}

export function computePostSessionAnalysis(
  inputs: PostSessionAnalysisInputs,
): PostSessionAnalysisResult {
  const sets = inputs.sets ?? [];
  if (sets.length === 0) {
    return {
      totalVolumeKg: 0.0,
      totalSets: 0,
      totalReps: 0,
      averageRpe: 0.0,
      oneRmChanges: [],
      corridorStatus: "in_corridor",
      corridorReason:
        "No sets logged; corridor is trivially satisfied.",
      readinessImpact: 0,
      readinessImpactReason: "No training stimulus recorded.",
      durationMinutes: inputs.durationMinutes ?? null,
    };
  }

  let totalVolume = 0.0;
  let totalReps = 0;
  let rpeSum = 0;
  let rpeCount = 0;
  const sessionBestOneRm = new Map<string, number>();

  for (const s of sets) {
    if (s.weightKg <= 0 || s.reps <= 0) continue;
    const volume = s.weightKg * s.reps;
    totalVolume += volume;
    totalReps += s.reps;
    if (s.rpe != null) {
      rpeSum += s.rpe;
      rpeCount += 1;
    }
    const oneRm = epleyOneRm(s.weightKg, s.reps);
    const prev = sessionBestOneRm.get(s.exerciseId);
    if (prev === undefined || oneRm > prev) {
      sessionBestOneRm.set(s.exerciseId, oneRm);
    }
  }

  const averageRpe = rpeCount > 0 ? rpeSum / rpeCount : 0.0;

  const prevMap = new Map<string, number>();
  for (const b of inputs.previousBests ?? []) {
    prevMap.set(b.exerciseId, b.estimatedOneRmKg);
  }
  const oneRmChanges: OneRmChange[] = [];
  for (const [exerciseId, oneRm] of sessionBestOneRm) {
    const prev = prevMap.get(exerciseId) ?? oneRm;
    oneRmChanges.push({
      exerciseId,
      sessionOneRmKg: round2(oneRm),
      previousOneRmKg: round2(prev),
      deltaKg: round2(oneRm - prev),
    });
  }
  oneRmChanges.sort((a, b) => a.exerciseId.localeCompare(b.exerciseId));

  const avgReps = sets.reduce((sum, s) => sum + s.reps, 0) / sets.length;
  const min = inputs.corridorRepsMin ?? 5;
  const max = inputs.corridorRepsMax ?? 12;
  const targetRpe = inputs.corridorRpeTarget ?? 7;

  let corridorStatus: PostSessionAnalysisResult["corridorStatus"];
  let corridorReason: string;
  if (avgReps > max + 1 && averageRpe <= targetRpe - 1) {
    corridorStatus = "above_corridor";
    corridorReason =
      `Average ${avgReps.toFixed(1)} reps exceeded the corridor max (${max}) at low RPE (${averageRpe.toFixed(1)}); ready for load progression next session.`;
  } else if (avgReps < min - 1 || averageRpe >= targetRpe + 2) {
    corridorStatus = "below_corridor";
    corridorReason =
      `Average ${avgReps.toFixed(1)} reps or RPE ${averageRpe.toFixed(1)} pushed outside the corridor (${min}-${max} reps at RPE ${targetRpe}); hold load and rebuild quality.`;
  } else {
    corridorStatus = "in_corridor";
    corridorReason =
      `Average ${avgReps.toFixed(1)} reps at RPE ${averageRpe.toFixed(1)} stayed within the corridor (${min}-${max} at RPE ${targetRpe}).`;
  }

  let impact = 0.0;
  impact += Math.min(10, Math.max(0, totalVolume / 1000.0));
  if (averageRpe > 7) {
    impact += Math.min(3, Math.max(0, averageRpe - 7));
  }
  if (inputs.durationMinutes != null && inputs.durationMinutes > 0) {
    impact += Math.min(4, inputs.durationMinutes / 15.0);
  }
  const readinessImpact = Math.min(20, Math.max(0, Math.round(impact)));
  let readinessImpactReason: string;
  if (readinessImpact === 0) {
    readinessImpactReason = "Minimal stimulus; negligible readiness impact.";
  } else if (readinessImpact <= 5) {
    readinessImpactReason =
      `Moderate session; expect ${readinessImpact}-point readiness dip tomorrow.`;
  } else if (readinessImpact <= 12) {
    readinessImpactReason =
      `Significant session; expect ${readinessImpact}-point readiness dip and possible soreness.`;
  } else {
    readinessImpactReason =
      `Heavy session; expect ${readinessImpact}-point readiness dip and elevated soreness risk.`;
  }

  return {
    totalVolumeKg: round2(totalVolume),
    totalSets: sets.length,
    totalReps,
    averageRpe: round2(averageRpe),
    oneRmChanges,
    corridorStatus,
    corridorReason,
    readinessImpact,
    readinessImpactReason,
    durationMinutes: inputs.durationMinutes ?? null,
  };
}
