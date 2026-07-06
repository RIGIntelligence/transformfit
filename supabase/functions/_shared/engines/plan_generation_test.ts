// Deno unit tests for the Deno plan-generation engine — mirror of the Dart
// tests (test/engine/plan_generation_test.dart). Run:
//   deno test --allow-all supabase/functions/_shared/engines/plan_generation_test.ts
//
// Single spec with the Dart engine (deterministic training-plan generator,
// VAL-ONB-056/057). Identical intake -> Identical plan. Bodyweight/no-equipment
// intake yields a non-empty plan with no full_gym fallback. Contraindicated
// exercises excluded.
import { assert, assertEquals, assertNotEquals } from "@std/assert";
import { generatePlan, type PlanIntake } from "./plan_generation.ts";

const _gen = (i: PlanIntake) => generatePlan(i);
const _json = (p: ReturnType<typeof generatePlan>) => JSON.stringify(p);

Deno.test("determinism: identical intake -> byte-equal JSON", () => {
  const intake: PlanIntake = {
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells", "pull_up_bar"],
    experienceLevel: "intermediate",
  };
  assertEquals(_json(_gen(intake)), _json(_gen(intake)));
  assertEquals(_json(_gen(intake)), _json(_gen(intake)));
});

Deno.test("determinism: repeated runs on a more complex intake agree", () => {
  const intake: PlanIntake = {
    goal: "lose_fat",
    trainingDaysPerWeek: 4,
    equipment: ["kettlebells"],
    experienceLevel: "beginner",
    limitations: ["knee"],
  };
  const r1 = _json(_gen(intake));
  const r2 = _json(_gen(intake));
  const r3 = _json(_gen(intake));
  assertEquals(r2, r1);
  assertEquals(r3, r1);
});

Deno.test("deterministic sort order and unique ids per day", () => {
  const intake: PlanIntake = {
    goal: "get_fitter",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells", "pull_up_bar"],
  };
  const p = _gen(intake);
  assertEquals(p.days.length, 3);
  for (const d of p.days) {
    for (let i = 0; i < d.exercises.length; i++) {
      assertEquals(d.exercises[i].sortOrder, i);
    }
    const ids = d.exercises.map((e) => e.id);
    assertEquals(new Set(ids).size, ids.length);
  }
});

Deno.test("equipment filter: uses only selected + bodyweight, never full_gym", () => {
  const intake: PlanIntake = {
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
  };
  const p = _gen(intake);
  const eq = new Set<string>(["bodyweight", ...intake.equipment]);
  for (const d of p.days) {
    for (const e of d.exercises) {
      assert(
        eq.has(e.equipment),
        `${e.id} needs ${e.equipment}, not in ${[...eq]}`,
      );
    }
  }
});

Deno.test("no-equipment intake -> non-empty bodyweight-only plan (no full_gym fallback)", () => {
  const intake: PlanIntake = {
    goal: "get_fitter",
    trainingDaysPerWeek: 3,
    equipment: [],
    experienceLevel: "beginner",
  };
  const p = _gen(intake);
  assertEquals(p.days.length, 3);
  let total = 0;
  for (const d of p.days) {
    assert(d.exercises.length > 0);
    total += d.exercises.length;
    for (const e of d.exercises) {
      assertEquals(
        e.equipment,
        "bodyweight",
        `bodyweight-only intake must not fall back to "${e.id}" using ${e.equipment}`,
      );
    }
  }
  assert(total > 0);
});

Deno.test("effectiveEquipment includes bodyweight, sorted unique", () => {
  const intake: PlanIntake = {
    goal: "build_strength",
    trainingDaysPerWeek: 4,
    equipment: ["kettlebells", "dumbbells"],
  };
  const p = _gen(intake);
  assert(p.effectiveEquipment.includes("bodyweight"));
  assert(p.effectiveEquipment.includes("kettlebells"));
  assert(p.effectiveEquipment.includes("dumbbells"));
  assertEquals([...p.effectiveEquipment].sort(), p.effectiveEquipment);
});

Deno.test("knee limitation excludes squatting movements", () => {
  const intake: PlanIntake = {
    goal: "get_fitter",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
    limitations: ["knee"],
  };
  const p = _gen(intake);
  const ids = new Set(p.days.flatMap((d) => d.exercises.map((e) => e.id)));
  assert(!ids.has("bodyweight_squat"));
  assert(!ids.has("bodyweight_lunge"));
  assert(!ids.has("goblet_squat"));
  assert(p.days.reduce((s, d) => s + d.exercises.length, 0) > 0);
});

Deno.test("shoulder+wrist limitations remove push-up & OH press family", () => {
  const intake: PlanIntake = {
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells", "barbell", "bodyweight"],
    experienceLevel: "intermediate",
    limitations: ["shoulder", "wrist"],
  };
  const p = _gen(intake);
  const ids = new Set(p.days.flatMap((d) => d.exercises.map((e) => e.id)));
  assert(!ids.has("pushup"));
  assert(!ids.has("overhead_press_dumbbell"));
  assert(!ids.has("barbell_bench_press"));
  assert(!ids.has("dumbbell_bench_press"));
  assert(!ids.has("pike_pushup"));
  assert(!ids.has("close_grip_pushup"));
  assert(!ids.has("tricep_dip"));
  assert(p.days.reduce((s, d) => s + d.exercises.length, 0) > 0);
});

Deno.test('"none" limitation means no exclusions', () => {
  const withNone: PlanIntake = {
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
    limitations: ["none"],
  };
  const without: PlanIntake = {
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
  };
  assertEquals(_json(_gen(withNone)), _json(_gen(without)));
});

Deno.test("volume grid: build_muscle/intermediate -> 3x8-12@8", () => {
  const p = _gen({
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
  });
  for (const d of p.days) {
    for (const e of d.exercises) {
      assertEquals(e.sets, 3);
      assertEquals(e.repsMin, 8);
      assertEquals(e.repsMax, 12);
      assertEquals(e.rpeTarget, 8);
    }
  }
});

Deno.test("volume grid: build_strength/advanced -> 5x3-5@9", () => {
  const p = _gen({
    goal: "build_strength",
    trainingDaysPerWeek: 4,
    equipment: ["barbell"],
    experienceLevel: "advanced",
  });
  for (const d of p.days) {
    for (const e of d.exercises) {
      assertEquals(e.sets, 5);
      assertEquals(e.repsMin, 3);
      assertEquals(e.repsMax, 5);
      assertEquals(e.rpeTarget, 9);
    }
  }
});

Deno.test("null experienceLevel falls back to intermediate row (plan equals explicit intermediate)", () => {
  const a: PlanIntake = {
    goal: "lose_fat",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: null,
  };
  const b: PlanIntake = {
    goal: "lose_fat",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
  };
  assertEquals(_json(_gen(a)), _json(_gen(b)));
});

Deno.test("rest seconds: compound=120, isolation=60 (non-beginner)", () => {
  const p = _gen({
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
  });
  for (const d of p.days) {
    for (const e of d.exercises) {
      assertEquals(e.restSeconds, e.isCompound ? 120 : 60);
    }
  }
});

Deno.test("split: 3 days -> 3 full-body days", () => {
  const p = _gen({
    goal: "get_fitter",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
  });
  assertEquals(p.days.length, 3);
  assertEquals(new Set(p.days.map((d) => d.split)), new Set(["full"]));
});

Deno.test("split: 4 days -> upper/lower/upper/lower", () => {
  const p = _gen({
    goal: "build_muscle",
    trainingDaysPerWeek: 4,
    equipment: ["dumbbells"],
  });
  assertEquals(p.days.length, 4);
  assertEquals(p.days[0].split, "upper");
  assertEquals(p.days[1].split, "lower");
  assertEquals(p.days[2].split, "upper");
  assertEquals(p.days[3].split, "lower");
});

Deno.test("split: 5 days -> push/pull/legs/upper/lower", () => {
  const p = _gen({
    goal: "get_fitter",
    trainingDaysPerWeek: 5,
    equipment: ["dumbbells", "barbell"],
  });
  assertEquals(p.days.length, 5);
  assertEquals(p.days[0].split, "push");
  assertEquals(p.days[1].split, "pull");
  assertEquals(p.days[2].split, "legs");
  assertEquals(p.days[3].split, "upper");
  assertEquals(p.days[4].split, "lower");
  for (const d of p.days) assert(d.exercises.length <= 4);
});

Deno.test("split: 2 days -> 2 full-body days", () => {
  const p = _gen({
    goal: "build_strength",
    trainingDaysPerWeek: 2,
    equipment: ["barbell"],
  });
  assertEquals(p.days.length, 2);
  for (const d of p.days) assert(d.exercises.length <= 6);
});

Deno.test("consequential: changing equipment changes the plan", () => {
  const a: PlanIntake = {
    goal: "get_fitter",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
  };
  const b: PlanIntake = {
    goal: "get_fitter",
    trainingDaysPerWeek: 3,
    equipment: ["barbell"],
  };
  assertNotEquals(_json(_gen(a)), _json(_gen(b)));
});

Deno.test("consequential: changing goal changes sets/reps/rpe", () => {
  const a: PlanIntake = {
    goal: "build_muscle",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
  };
  const b: PlanIntake = {
    goal: "build_strength",
    trainingDaysPerWeek: 3,
    equipment: ["dumbbells"],
    experienceLevel: "intermediate",
  };
  assertNotEquals(_json(_gen(a)), _json(_gen(b)));
});

Deno.test("output contract: positive sets, repsMax>=repsMin, rpe 1..10", () => {
  const p = _gen({
    goal: "build_muscle",
    trainingDaysPerWeek: 5,
    equipment: ["dumbbells", "pull_up_bar"],
    experienceLevel: "advanced",
  });
  for (const d of p.days) {
    for (const e of d.exercises) {
      assert(e.name.length > 0);
      assert(e.sets > 0);
      assert(e.repsMax >= e.repsMin);
      assert(e.rpeTarget >= 1 && e.rpeTarget <= 10);
      assert(e.restSeconds > 0);
    }
  }
});
