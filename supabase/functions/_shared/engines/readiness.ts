// Deterministic daily-readiness engine, Deno mirror of lib/engine/readiness.dart.
// No time, randomness, network, or database access belongs in this file.

export interface ReadinessInputs {
  energyLevel: number;
  sleepQuality: number;
  sorenessMap: string[];
  hrv?: number;
  strain?: number;
}

export interface ReadinessResult {
  readinessScore: number;
  readinessZone: "push" | "maintain" | "deload" | "rest";
  readinessVariant: "with_hrv" | "no_hrv";
  hrvScore: number | null;
  sleepScore: number;
  energyScore: number;
  sorenessPenalty: number;
  deloadRecommended: boolean;
  volumeMultiplier: number;
  readinessInputs: ReadinessInputs;
}

export function computeReadinessScore(
  inputs: ReadinessInputs,
): ReadinessResult {
  validate(inputs);

  const sorenessPenalty = Math.min(20, inputs.sorenessMap.length * 5);
  const deloadRecommended = false;

  if (inputs.hrv !== undefined && inputs.hrv !== null) {
    const hrvScore = Math.min(100, (inputs.hrv / 120) * 100);
    const sleepScore = (inputs.sleepQuality / 10) * 60;
    const energyScore = (inputs.energyLevel / 10) * 40;
    const raw = hrvScore * 0.40 + sleepScore * 0.35 + energyScore * 0.25 -
      sorenessPenalty;
    return result({
      score: Math.max(0, Math.round(raw)),
      variant: "with_hrv",
      hrvScore: Math.round(hrvScore),
      sleepScore: Math.round(sleepScore),
      energyScore: Math.round(energyScore),
      sorenessPenalty,
      deloadRecommended,
      inputs,
    });
  }

  const sleepScore = (inputs.sleepQuality / 10) * 100;
  const energyScore = (inputs.energyLevel / 10) * 100;
  const raw = sleepScore * 0.55 + energyScore * 0.45 - sorenessPenalty;
  return result({
    score: Math.max(0, Math.round(raw)),
    variant: "no_hrv",
    hrvScore: null,
    sleepScore: Math.round(sleepScore),
    energyScore: Math.round(energyScore),
    sorenessPenalty,
    deloadRecommended,
    inputs,
  });
}

export function computeReadinessZone(
  score: number,
  options: { deloadRecommended?: boolean } = {},
): ReadinessResult["readinessZone"] {
  if (!Number.isInteger(score) || score < 0 || score > 100) {
    throw new RangeError("score must be an integer between 0 and 100");
  }
  if (options.deloadRecommended === true) return "deload";
  if (score >= 75) return "push";
  if (score >= 50) return "maintain";
  return "deload";
}

export function volumeMultiplierForZone(
  zone: ReadinessResult["readinessZone"],
): number {
  switch (zone) {
    case "push":
      return 1.10;
    case "maintain":
      return 1.00;
    case "deload":
      return 0.65;
    case "rest":
      return 0.00;
  }
}

function result(args: {
  score: number;
  variant: ReadinessResult["readinessVariant"];
  hrvScore: number | null;
  sleepScore: number;
  energyScore: number;
  sorenessPenalty: number;
  deloadRecommended: boolean;
  inputs: ReadinessInputs;
}): ReadinessResult {
  const zone = computeReadinessZone(args.score, {
    deloadRecommended: args.deloadRecommended,
  });
  return {
    readinessScore: args.score,
    readinessZone: zone,
    readinessVariant: args.variant,
    hrvScore: args.hrvScore,
    sleepScore: args.sleepScore,
    energyScore: args.energyScore,
    sorenessPenalty: args.sorenessPenalty,
    deloadRecommended: args.deloadRecommended,
    volumeMultiplier: volumeMultiplierForZone(zone),
    readinessInputs: args.inputs,
  };
}

function validate(inputs: ReadinessInputs): void {
  if (
    !Number.isInteger(inputs.energyLevel) || inputs.energyLevel < 1 ||
    inputs.energyLevel > 10
  ) {
    throw new RangeError("energyLevel must be an integer from 1 to 10");
  }
  if (
    !Number.isInteger(inputs.sleepQuality) || inputs.sleepQuality < 1 ||
    inputs.sleepQuality > 10
  ) {
    throw new RangeError("sleepQuality must be an integer from 1 to 10");
  }
  if (!Array.isArray(inputs.sorenessMap)) {
    throw new TypeError("sorenessMap must be an array");
  }
  if (
    inputs.hrv !== undefined &&
    (!Number.isInteger(inputs.hrv) || inputs.hrv <= 0)
  ) {
    throw new RangeError("hrv must be a positive integer when supplied");
  }
  if (
    inputs.strain !== undefined &&
    (!Number.isInteger(inputs.strain) || inputs.strain < 1 ||
      inputs.strain > 10)
  ) {
    throw new RangeError(
      "strain must be an integer from 1 to 10 when supplied",
    );
  }
}
