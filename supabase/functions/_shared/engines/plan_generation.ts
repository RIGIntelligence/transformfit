// Deterministic training-plan generator — Deno mirror of the Dart engine.
//
// Single spec (architecture.md "deterministic engine duality", M2
// plan-generation engine, VAL-ONB-056/057). This is a VERBATIM port of
// lib/engine/plan_generation.dart: the two MUST agree for identical inputs.
// The long-run exercise source is the `exercises` Supabase table, but with the
// table unseeded in M2 this embedded catalog stays the pure/engine-file
// deterministic-first contract intact (ported 1:1 from the Dart catalog).
//
// Deterministic: no time, no randomness, no I/O. Identical PlanIntake always
// produces an identical GeneratedPlan. Bodyweight is always in the effective
// equipment set, so no-equipment intakes yield a valid non-empty bodyweight
// plan — never the banned ["full_gym"] fallback.
//
// Test: deno test --allow-all supabase/functions/_shared/engines/plan_generation_test.ts
// Parity: see parity scripts run at the milestone gate.

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface PlanIntake {
  goal: string;
  trainingDaysPerWeek: number;
  equipment: string[];
  experienceLevel?: string | null;
  limitations?: string[];
}

export interface PlanExercise {
  id: string;
  name: string;
  muscleGroup: string;
  equipment: string;
  sets: number;
  repsMin: number;
  repsMax: number;
  rpeTarget: number;
  restSeconds: number;
  isCompound: boolean;
  sortOrder: number;
}

export interface PlanDay {
  dayNumber: number;
  focus: string;
  split: string;
  exercises: PlanExercise[];
}

export interface GeneratedPlan {
  goal: string;
  experienceLevel: string | null;
  effectiveEquipment: string[];
  daysPerWeek: number;
  contraindications: string[];
  days: PlanDay[];
}

// ---------------------------------------------------------------------------
// Catalog
// ---------------------------------------------------------------------------

interface _Ex {
  id: string;
  name: string;
  muscleGroup: string;
  equipment: string;
  isCompound: boolean;
  difficulty: string;
  contraindications: string[];
}

// Catalog: canonical, ported verbatim from lib/engine/plan_generation.dart.
// Stable id order. An empty contraindications array means "no limitation
// makes this exercise unsafe".
const _catalog: readonly _Ex[] = [
  // chest (compound)
  {
    id: "barbell_bench_press",
    name: "Barbell Bench Press",
    muscleGroup: "chest",
    equipment: "barbell",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["shoulder"],
  },
  {
    id: "dumbbell_bench_press",
    name: "Dumbbell Bench Press",
    muscleGroup: "chest",
    equipment: "dumbbells",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["shoulder"],
  },
  {
    id: "pushup",
    name: "Push-Up",
    muscleGroup: "chest",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["shoulder", "wrist"],
  },
  {
    id: "dumbbell_fly",
    name: "Dumbbell Fly",
    muscleGroup: "chest",
    equipment: "dumbbells",
    isCompound: false,
    difficulty: "intermediate",
    contraindications: ["shoulder"],
  },
  {
    id: "cable_fly",
    name: "Cable Fly",
    muscleGroup: "chest",
    equipment: "cables",
    isCompound: false,
    difficulty: "intermediate",
    contraindications: ["shoulder"],
  },
  {
    id: "machine_chest_press",
    name: "Machine Chest Press",
    muscleGroup: "chest",
    equipment: "machines",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["shoulder"],
  },
  {
    id: "banded_chest_press",
    name: "Banded Chest Press",
    muscleGroup: "chest",
    equipment: "resistance_bands",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["shoulder"],
  },
  // back (compound)
  {
    id: "pull_up",
    name: "Pull-Up",
    muscleGroup: "back",
    equipment: "pull_up_bar",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["shoulder"],
  },
  {
    id: "barbell_row",
    name: "Barbell Row",
    muscleGroup: "back",
    equipment: "barbell",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["back", "shoulder"],
  },
  {
    id: "dumbbell_row",
    name: "Dumbbell Row",
    muscleGroup: "back",
    equipment: "dumbbells",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "cable_row",
    name: "Cable Row",
    muscleGroup: "back",
    equipment: "cables",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "lat_pulldown",
    name: "Lat Pulldown",
    muscleGroup: "back",
    equipment: "machines",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["shoulder"],
  },
  {
    id: "resistance_band_row",
    name: "Resistance Band Row",
    muscleGroup: "back",
    equipment: "resistance_bands",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "bodyweight_row",
    name: "Bodyweight Inverted Row",
    muscleGroup: "back",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back", "shoulder"],
  },
  {
    id: "superman",
    name: "Superman Hold",
    muscleGroup: "back",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  // shoulders
  {
    id: "overhead_press_barbell",
    name: "Barbell Overhead Press",
    muscleGroup: "shoulders",
    equipment: "barbell",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["shoulder", "wrist"],
  },
  {
    id: "overhead_press_dumbbell",
    name: "Dumbbell Overhead Press",
    muscleGroup: "shoulders",
    equipment: "dumbbells",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["shoulder"],
  },
  {
    id: "lateral_raise_dumbbell",
    name: "Dumbbell Lateral Raise",
    muscleGroup: "shoulders",
    equipment: "dumbbells",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["shoulder"],
  },
  {
    id: "lateral_raise_band",
    name: "Band Lateral Raise",
    muscleGroup: "shoulders",
    equipment: "resistance_bands",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["shoulder"],
  },
  {
    id: "pike_pushup",
    name: "Pike Push-Up",
    muscleGroup: "shoulders",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["shoulder", "wrist"],
  },
  {
    id: "face_pull",
    name: "Face Pull",
    muscleGroup: "shoulders",
    equipment: "cables",
    isCompound: false,
    difficulty: "beginner",
    contraindications: [],
  },
  // biceps
  {
    id: "barbell_curl",
    name: "Barbell Curl",
    muscleGroup: "biceps",
    equipment: "barbell",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["wrist"],
  },
  {
    id: "dumbbell_curl",
    name: "Dumbbell Curl",
    muscleGroup: "biceps",
    equipment: "dumbbells",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["wrist"],
  },
  {
    id: "resistance_band_curl",
    name: "Band Curl",
    muscleGroup: "biceps",
    equipment: "resistance_bands",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["wrist"],
  },
  {
    id: "bodyweight_curl_iso",
    name: "Isometric Arm Curl",
    muscleGroup: "biceps",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: [],
  },
  // triceps
  {
    id: "tricep_dip",
    name: "Tricep Dip",
    muscleGroup: "triceps",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["shoulder", "wrist"],
  },
  {
    id: "dumbbell_skull_crusher",
    name: "Dumbbell Skull Crusher",
    muscleGroup: "triceps",
    equipment: "dumbbells",
    isCompound: false,
    difficulty: "intermediate",
    contraindications: ["wrist"],
  },
  {
    id: "cable_pushdown",
    name: "Cable Pushdown",
    muscleGroup: "triceps",
    equipment: "cables",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["wrist"],
  },
  {
    id: "band_pushdown",
    name: "Band Pushdown",
    muscleGroup: "triceps",
    equipment: "resistance_bands",
    isCompound: false,
    difficulty: "beginner",
    contraindications: [],
  },
  {
    id: "close_grip_pushup",
    name: "Close-Grip Push-Up",
    muscleGroup: "triceps",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["shoulder", "wrist"],
  },
  // quads
  {
    id: "barbell_back_squat",
    name: "Barbell Back Squat",
    muscleGroup: "quads",
    equipment: "barbell",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["knee", "back"],
  },
  {
    id: "goblet_squat",
    name: "Goblet Squat",
    muscleGroup: "quads",
    equipment: "dumbbells",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["knee"],
  },
  {
    id: "bodyweight_squat",
    name: "Air Squat",
    muscleGroup: "quads",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["knee"],
  },
  {
    id: "leg_press",
    name: "Leg Press",
    muscleGroup: "quads",
    equipment: "machines",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["knee", "back"],
  },
  {
    id: "lunge_dumbbell",
    name: "Dumbbell Lunge",
    muscleGroup: "quads",
    equipment: "dumbbells",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["knee", "hip"],
  },
  {
    id: "bodyweight_lunge",
    name: "Bodyweight Lunge",
    muscleGroup: "quads",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["knee", "hip"],
  },
  {
    id: "band_squat",
    name: "Band Squat",
    muscleGroup: "quads",
    equipment: "resistance_bands",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["knee"],
  },
  // hamstrings
  {
    id: "romanian_deadlift",
    name: "Romanian Deadlift",
    muscleGroup: "hamstrings",
    equipment: "barbell",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["back"],
  },
  {
    id: "dumbbell_rdl",
    name: "Dumbbell RDL",
    muscleGroup: "hamstrings",
    equipment: "dumbbells",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "bodyweight_romanian_deadlift",
    name: "Bodyweight Single-Leg RDL",
    muscleGroup: "hamstrings",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "glute_bridge",
    name: "Glute Bridge",
    muscleGroup: "hamstrings",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "kettlebell_swing",
    name: "Kettlebell Swing",
    muscleGroup: "hamstrings",
    equipment: "kettlebells",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: ["back"],
  },
  {
    id: "resistance_band_good_morning",
    name: "Band Good Morning",
    muscleGroup: "hamstrings",
    equipment: "resistance_bands",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "lying_leg_curl",
    name: "Lying Leg Curl",
    muscleGroup: "hamstrings",
    equipment: "machines",
    isCompound: false,
    difficulty: "beginner",
    contraindications: [],
  },
  // glutes
  {
    id: "hip_thrust",
    name: "Hip Thrust",
    muscleGroup: "glutes",
    equipment: "barbell",
    isCompound: true,
    difficulty: "intermediate",
    contraindications: [],
  },
  {
    id: "dumbbell_hip_thrust",
    name: "Dumbbell Hip Thrust",
    muscleGroup: "glutes",
    equipment: "dumbbells",
    isCompound: true,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "bodyweight_glute_bridge_walkout",
    name: "Glute Bridge Walkout",
    muscleGroup: "glutes",
    equipment: "bodyweight",
    isCompound: true,
    difficulty: "beginner",
    contraindications: [],
  },
  {
    id: "band_clamshell",
    name: "Band Clamshell",
    muscleGroup: "glutes",
    equipment: "resistance_bands",
    isCompound: false,
    difficulty: "beginner",
    contraindications: [],
  },
  // calves
  {
    id: "standing_calf_raise",
    name: "Standing Calf Raise",
    muscleGroup: "calves",
    equipment: "dumbbells",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["ankle"],
  },
  {
    id: "bodyweight_calf_raise",
    name: "Bodyweight Calf Raise",
    muscleGroup: "calves",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["ankle"],
  },
  {
    id: "machine_calf_raise",
    name: "Machine Calf Raise",
    muscleGroup: "calves",
    equipment: "machines",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["ankle"],
  },
  // core
  {
    id: "plank",
    name: "Plank",
    muscleGroup: "core",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["back", "shoulder", "wrist"],
  },
  {
    id: "dead_bug",
    name: "Dead Bug",
    muscleGroup: "core",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: [],
  },
  {
    id: "bird_dog",
    name: "Bird Dog",
    muscleGroup: "core",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: ["back"],
  },
  {
    id: "bodyweight_crunch",
    name: "Crunch",
    muscleGroup: "core",
    equipment: "bodyweight",
    isCompound: false,
    difficulty: "beginner",
    contraindications: [],
  },
] as const;

// Stable, deterministic sort: compounds first, then by id.
function _sortKey(a: _Ex, b: _Ex): number {
  if (a.isCompound !== b.isCompound) return a.isCompound ? -1 : 1;
  return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
}

// ---------------------------------------------------------------------------
// Training-split specs, by training days per week.
// ---------------------------------------------------------------------------

interface _SplitRole {
  code: string;
  focus: string;
  muscleGroups: readonly string[];
}

function _splitFor(trainingDaysPerWeek: number, dayIndex: number): _SplitRole {
  switch (trainingDaysPerWeek) {
    case 2:
      return dayIndex === 0
        ? {
          code: "full",
          focus: "Full Body A",
          muscleGroups: [
            "chest",
            "back",
            "quads",
            "hamstrings",
            "shoulders",
            "biceps",
          ],
        }
        : {
          code: "full",
          focus: "Full Body B",
          muscleGroups: ["quads", "glutes", "chest", "back", "triceps", "core"],
        };
    case 3:
      switch (dayIndex) {
        case 0:
          return {
            code: "full",
            focus: "Full Body A",
            muscleGroups: [
              "chest",
              "back",
              "quads",
              "hamstrings",
              "shoulders",
              "biceps",
            ],
          };
        case 1:
          return {
            code: "full",
            focus: "Full Body B",
            muscleGroups: [
              "quads",
              "glutes",
              "chest",
              "back",
              "triceps",
              "core",
            ],
          };
        default:
          return {
            code: "full",
            focus: "Full Body C",
            muscleGroups: [
              "hamstrings",
              "shoulders",
              "back",
              "chest",
              "calves",
              "core",
            ],
          };
      }
    case 4:
      switch (dayIndex % 4) {
        case 0:
          return {
            code: "upper",
            focus: "Upper A",
            muscleGroups: ["chest", "back", "shoulders", "biceps", "triceps"],
          };
        case 1:
          return {
            code: "lower",
            focus: "Lower A",
            muscleGroups: ["quads", "hamstrings", "glutes", "calves", "core"],
          };
        case 2:
          return {
            code: "upper",
            focus: "Upper B",
            muscleGroups: ["back", "chest", "shoulders", "triceps", "biceps"],
          };
        default:
          return {
            code: "lower",
            focus: "Lower B",
            muscleGroups: ["hamstrings", "quads", "glutes", "core", "calves"],
          };
      }
    case 5:
      switch (dayIndex % 5) {
        case 0:
          return {
            code: "push",
            focus: "Push",
            muscleGroups: ["chest", "shoulders", "triceps", "quads"],
          };
        case 1:
          return {
            code: "pull",
            focus: "Pull",
            muscleGroups: ["back", "biceps", "hamstrings"],
          };
        case 2:
          return {
            code: "legs",
            focus: "Legs",
            muscleGroups: ["quads", "hamstrings", "glutes", "calves"],
          };
        case 3:
          return {
            code: "upper",
            focus: "Upper",
            muscleGroups: ["chest", "back", "shoulders", "biceps", "triceps"],
          };
        default:
          return {
            code: "lower",
            focus: "Lower",
            muscleGroups: ["hamstrings", "quads", "glutes", "core", "calves"],
          };
      }
    case 6:
    default:
      switch (dayIndex % 6) {
        case 0:
          return {
            code: "push",
            focus: "Push A",
            muscleGroups: ["chest", "shoulders", "triceps", "quads"],
          };
        case 1:
          return {
            code: "pull",
            focus: "Pull A",
            muscleGroups: ["back", "biceps", "hamstrings"],
          };
        case 2:
          return {
            code: "legs",
            focus: "Legs A",
            muscleGroups: ["quads", "hamstrings", "glutes", "calves"],
          };
        case 3:
          return {
            code: "push",
            focus: "Push B",
            muscleGroups: ["shoulders", "chest", "triceps", "core"],
          };
        case 4:
          return {
            code: "pull",
            focus: "Pull B",
            muscleGroups: ["back", "biceps", "rear_shoulders"],
          };
        default:
          return {
            code: "legs",
            focus: "Legs B",
            muscleGroups: ["hamstrings", "glutes", "quads", "calves"],
          };
      }
  }
}

// ---------------------------------------------------------------------------
// Volume grid.
// ---------------------------------------------------------------------------

interface _Vol {
  sets: number;
  repsMin: number;
  repsMax: number;
  rpe: number;
}

const _defaultVol: _Vol = { sets: 3, repsMin: 8, repsMax: 12, rpe: 8 };

const _volumeGrid: Record<string, Record<string, _Vol>> = {
  build_muscle: {
    beginner: { sets: 3, repsMin: 10, repsMax: 12, rpe: 7 },
    intermediate: { sets: 3, repsMin: 8, repsMax: 12, rpe: 8 },
    advanced: { sets: 4, repsMin: 6, repsMax: 10, rpe: 9 },
  },
  build_strength: {
    beginner: { sets: 3, repsMin: 5, repsMax: 8, rpe: 7 },
    intermediate: { sets: 4, repsMin: 4, repsMax: 6, rpe: 8 },
    advanced: { sets: 5, repsMin: 3, repsMax: 5, rpe: 9 },
  },
  lose_fat: {
    beginner: { sets: 3, repsMin: 10, repsMax: 15, rpe: 7 },
    intermediate: { sets: 3, repsMin: 10, repsMax: 12, rpe: 8 },
    advanced: { sets: 4, repsMin: 8, repsMax: 12, rpe: 9 },
  },
  get_fitter: {
    beginner: { sets: 3, repsMin: 8, repsMax: 12, rpe: 7 },
    intermediate: { sets: 3, repsMin: 8, repsMax: 10, rpe: 8 },
    advanced: { sets: 4, repsMin: 6, repsMax: 10, rpe: 9 },
  },
  improve_mobility: {
    beginner: { sets: 2, repsMin: 8, repsMax: 12, rpe: 6 },
    intermediate: { sets: 2, repsMin: 8, repsMax: 10, rpe: 7 },
    advanced: { sets: 3, repsMin: 6, repsMax: 10, rpe: 8 },
  },
  train_for_sport: {
    beginner: { sets: 3, repsMin: 8, repsMax: 10, rpe: 7 },
    intermediate: { sets: 3, repsMin: 8, repsMax: 10, rpe: 8 },
    advanced: { sets: 4, repsMin: 6, repsMax: 8, rpe: 9 },
  },
};

function _volumeFor(
  goal: string,
  experienceLevel: string | null | undefined,
): _Vol {
  const exp = (!experienceLevel) ? "intermediate" : experienceLevel;
  const byGoal = _volumeGrid[goal];
  if (byGoal && byGoal[exp]) return byGoal[exp];
  return _defaultVol;
}

function _normalizedExp(
  experienceLevel: string | null | undefined,
): string | null {
  if (experienceLevel === null || experienceLevel === undefined) {
    return "intermediate";
  }
  return experienceLevel.length === 0 ? "intermediate" : experienceLevel;
}

function _targetExercisesPerDay(trainingDaysPerWeek: number): number {
  if (trainingDaysPerWeek <= 3) return 6;
  if (trainingDaysPerWeek === 4) return 5;
  return 4;
}

function _restSeconds(
  isCompound: boolean,
  experienceLevel: string | null | undefined,
): number {
  const base = isCompound ? 120 : 60;
  return experienceLevel === "beginner" ? base + 30 : base;
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

export function generatePlan(intake: PlanIntake): GeneratedPlan {
  // Effective equipment: user + "bodyweight" (base human equipment).
  const eff = new Set<string>(["bodyweight", ...(intake.equipment ?? [])]);
  eff.delete("");

  // Canonical contraindications: strip 'none'/empty.
  const contras: string[] = [];
  for (const l of intake.limitations ?? []) {
    if (l && l !== "none") contras.push(l);
  }

  // Filtered, deterministic catalog.
  const usable: _Ex[] = _catalog
    .filter((e) => eff.has(e.equipment))
    .filter((e) => !e.contraindications.some((c) => contras.includes(c)))
    .slice()
    .sort(_sortKey);

  // Group usable exercises by muscle group (preserves sort order).
  const byGroup = new Map<string, _Ex[]>();
  for (const e of usable) {
    if (!byGroup.has(e.muscleGroup)) byGroup.set(e.muscleGroup, []);
    byGroup.get(e.muscleGroup)!.push(e);
  }

  const target = _targetExercisesPerDay(intake.trainingDaysPerWeek);
  const vol = _volumeFor(intake.goal, intake.experienceLevel);

  const days: PlanDay[] = [];
  for (let d = 0; d < intake.trainingDaysPerWeek; d++) {
    const split = _splitFor(intake.trainingDaysPerWeek, d);

    const exercises: PlanExercise[] = [];
    const seen = new Set<string>();
    const mgOrder = split.muscleGroups;
    for (
      let round = 0;
      exercises.length < target && round < mgOrder.length * 8;
      round++
    ) {
      for (const mg of mgOrder) {
        if (exercises.length >= target) break;
        const candidates = byGroup.get(mg);
        if (!candidates) continue;
        for (const c of candidates) {
          if (!seen.has(c.id)) {
            seen.add(c.id);
            exercises.push({
              id: c.id,
              name: c.name,
              muscleGroup: c.muscleGroup,
              equipment: c.equipment,
              sets: vol.sets,
              repsMin: vol.repsMin,
              repsMax: vol.repsMax,
              rpeTarget: vol.rpe,
              restSeconds: _restSeconds(c.isCompound, intake.experienceLevel),
              isCompound: c.isCompound,
              sortOrder: exercises.length,
            });
            break;
          }
        }
      }
    }

    days.push({
      dayNumber: d + 1,
      focus: split.focus,
      split: split.code,
      exercises,
    });
  }

  const effList = Array.from(eff).sort();

  return {
    goal: intake.goal,
    experienceLevel: _normalizedExp(intake.experienceLevel),
    effectiveEquipment: effList,
    daysPerWeek: intake.trainingDaysPerWeek,
    contraindications: contras,
    days,
  };
}
