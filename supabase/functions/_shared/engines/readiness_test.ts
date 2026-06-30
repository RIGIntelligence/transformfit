import { computeReadinessScore, computeReadinessZone } from "./readiness.ts";

function assertEquals(actual: unknown, expected: unknown, label?: string) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `${label ?? "assertEquals"}\nactual: ${
        JSON.stringify(actual)
      }\nexpected: ${JSON.stringify(expected)}`,
    );
  }
}

Deno.test("VAL-RDY-011: with-HRV worked example scores 71", () => {
  const result = computeReadinessScore({
    energyLevel: 10,
    sleepQuality: 10,
    sorenessMap: [],
    hrv: 120,
  });
  assertEquals(result.readinessScore, 71);
  assertEquals(result.readinessVariant, "with_hrv");
});

Deno.test("VAL-RDY-012: with-HRV ceiling is 71 before soreness penalty", () => {
  const result = computeReadinessScore({
    energyLevel: 10,
    sleepQuality: 10,
    sorenessMap: [],
    hrv: 300,
  });
  assertEquals(result.readinessScore, 71);
  assertEquals(result.hrvScore, 100);
});

Deno.test("VAL-RDY-013: with-HRV mid-range worked example scores 38", () => {
  assertEquals(
    computeReadinessScore({
      energyLevel: 6,
      sleepQuality: 8,
      sorenessMap: ["legs"],
      hrv: 60,
    }).readinessScore,
    38,
  );
});

Deno.test("VAL-RDY-014/015: no-HRV examples match the contract", () => {
  assertEquals(
    computeReadinessScore({
      energyLevel: 10,
      sleepQuality: 10,
      sorenessMap: [],
    }).readinessScore,
    100,
  );
  assertEquals(
    computeReadinessScore({
      energyLevel: 6,
      sleepQuality: 8,
      sorenessMap: ["legs", "back"],
    }).readinessScore,
    61,
  );
});

Deno.test("VAL-RDY-016/017/018/019: soreness penalty clamps and scales", () => {
  assertEquals(
    computeReadinessScore({
      energyLevel: 1,
      sleepQuality: 1,
      sorenessMap: ["legs", "back", "shoulders", "wrist"],
    }).readinessScore,
    0,
  );

  const four = computeReadinessScore({
    energyLevel: 8,
    sleepQuality: 8,
    sorenessMap: ["a", "b", "c", "d"],
  });
  const eight = computeReadinessScore({
    energyLevel: 8,
    sleepQuality: 8,
    sorenessMap: ["a", "b", "c", "d", "e", "f", "g", "h"],
  });
  assertEquals(eight.readinessScore, four.readinessScore);
  assertEquals(eight.sorenessPenalty, 20);
});

Deno.test("VAL-RDY-028/029/030: zone boundaries and deload override", () => {
  assertEquals(computeReadinessZone(75), "push");
  assertEquals(computeReadinessZone(50), "maintain");
  assertEquals(computeReadinessZone(90, { deloadRecommended: true }), "deload");
});

Deno.test("VAL-RDY-053: zero or negative HRV is rejected deterministically", () => {
  for (const hrv of [0, -10]) {
    let rejected = false;
    try {
      computeReadinessScore({
        energyLevel: 8,
        sleepQuality: 8,
        sorenessMap: [],
        hrv,
      });
    } catch {
      rejected = true;
    }
    assertEquals(rejected, true, `hrv=${hrv}`);
  }
});

Deno.test("VAL-RDY-056/057: strain capture does not move score and half boundary rounds to 86", () => {
  const baseline = computeReadinessScore({
    energyLevel: 10,
    sleepQuality: 10,
    sorenessMap: [],
  });
  const withStrain = computeReadinessScore({
    energyLevel: 10,
    sleepQuality: 10,
    sorenessMap: [],
    strain: 9,
  });
  assertEquals(withStrain.readinessScore, baseline.readinessScore);
  assertEquals(withStrain.readinessZone, baseline.readinessZone);
  assertEquals(withStrain.readinessInputs.strain, 9);

  assertEquals(
    computeReadinessScore({
      energyLevel: 8,
      sleepQuality: 9,
      sorenessMap: [],
    }).readinessScore,
    86,
  );
});
