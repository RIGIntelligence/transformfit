import { computeReadinessScore, type ReadinessInputs } from "./readiness.ts";

const vectors: { name: string; inputs: ReadinessInputs }[] = [
  {
    name: "with_hrv_ceiling",
    inputs: { energyLevel: 10, sleepQuality: 10, sorenessMap: [], hrv: 120 },
  },
  {
    name: "with_hrv_capped_high",
    inputs: { energyLevel: 10, sleepQuality: 10, sorenessMap: [], hrv: 300 },
  },
  {
    name: "with_hrv_mid_range",
    inputs: { energyLevel: 6, sleepQuality: 8, sorenessMap: ["legs"], hrv: 60 },
  },
  {
    name: "no_hrv_ceiling",
    inputs: { energyLevel: 10, sleepQuality: 10, sorenessMap: [] },
  },
  {
    name: "no_hrv_mid_range",
    inputs: { energyLevel: 6, sleepQuality: 8, sorenessMap: ["legs", "back"] },
  },
  {
    name: "floor_clamp",
    inputs: {
      energyLevel: 1,
      sleepQuality: 1,
      sorenessMap: ["legs", "back", "shoulders", "wrist"],
    },
  },
  {
    name: "soreness_cap",
    inputs: {
      energyLevel: 8,
      sleepQuality: 8,
      sorenessMap: ["a", "b", "c", "d", "e", "f", "g", "h"],
    },
  },
  {
    name: "strain_captured_score_unchanged",
    inputs: { energyLevel: 10, sleepQuality: 10, sorenessMap: [], strain: 9 },
  },
  {
    name: "half_rounding_boundary",
    inputs: { energyLevel: 8, sleepQuality: 9, sorenessMap: [] },
  },
];

const output = vectors.map((vector) => ({
  name: vector.name,
  inputs: vector.inputs,
  result: computeReadinessScore(vector.inputs),
}));

if (import.meta.main) {
  console.log(JSON.stringify(output, null, 2));
}
