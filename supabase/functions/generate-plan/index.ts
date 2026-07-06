// generate-plan — the M2 onboarding plan-generation edge function.
//
// Establishes the deterministic-decision -> LLM-narrate pattern (architecture
// §4.2, reused by dai-adapt in M3):
//
//   1. Resolve the acting user FROM THE JWT ONLY (_shared/auth.ts). Any
//      caller-supplied user_id in the body is IGNORED (impersonation guard).
//   2. Validate intake, run the DETERMINISTIC plan-generation engine
//      (_shared/engines/plan_generation.ts) -> immutable GeneratedPlan.
//   3. Narrate via _shared/llm.ts. On LLM failure, return a deterministic
//      narrative flagged is_fallback:true / model_used:"deterministic".
//   4. ALWAYS return 200 with a complete plan packet (never 501/empty).
//
// Invariants:
//   - Numbers/exercises/sets/reps/rpe/equipment come ONLY from the engine.
//   - LLM writes narrative only; deterministic fallback if the LLM fails.
//   - Never 501; never silent; always surfaced.

import { type AuthUser, resolveUser } from "../_shared/auth.ts";
import {
  type GeneratedPlan,
  generatePlan,
  type PlanIntake,
} from "../_shared/engines/plan_generation.ts";
import { narratePlan, type PlanNarrative } from "../_shared/llm.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface GeneratePlanResponse {
  /** Acting user, resolved from the JWT only. */
  user: AuthUser;
  /** "jwt" — the user was resolved from the JWT, never the body. */
  source: "jwt";
  /** True iff a caller-supplied user_id differed from the JWT subject. */
  impersonation_attempt: boolean;
  /** The deterministic plan (engine-only: numbers, exercises, sets, reps). */
  plan: GeneratedPlan;
  /** Narrative — LLM-written on success, deterministic+flagged on fallback. */
  headline: string;
  reasoning: string;
  changes_made: string[];
  coaching_cue: string;
  /** false on LLM success; true whenever the deterministic fallback is used. */
  is_fallback: boolean;
  /** "z-ai/glm-5.1" on LLM success, "deterministic" on fallback. */
  model_used: string;
}

interface GeneratePlanIntake {
  goal?: string;
  daysPerWeek?: number;
  equipment?: string[];
  experienceLevel?: string | null;
  limitations?: string[];
  userPhrase?: string | null;
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

const VALID_GOALS = new Set([
  "build_muscle",
  "build_strength",
  "lose_fat",
  "get_fitter",
  "improve_mobility",
  "train_for_sport",
]);

const VALID_EXPERIENCE = new Set(["beginner", "intermediate", "advanced"]);

/** Validate + normalize intake. Throws on invalid (caller returns 4xx). */
function validateIntake(body: GeneratePlanIntake): PlanIntake {
  if (!body || typeof body !== "object") {
    throw new Error("Request body must be a JSON object.");
  }
  const goal = typeof body.goal === "string" ? body.goal.trim() : "";
  if (!VALID_GOALS.has(goal)) {
    throw new Error(
      `Invalid goal "${goal}". Valid goals: ${[...VALID_GOALS].join(", ")}.`,
    );
  }
  const days = Number(body.daysPerWeek);
  if (!Number.isInteger(days) || days < 1 || days > 6) {
    throw new Error("daysPerWeek must be an integer from 1 to 6.");
  }
  const eq = Array.isArray(body.equipment)
    ? body.equipment.filter((e): e is string => typeof e === "string")
    : [];
  const exp = typeof body.experienceLevel === "string" &&
      VALID_EXPERIENCE.has(body.experienceLevel.trim())
    ? body.experienceLevel.trim()
    : null;
  const limits = Array.isArray(body.limitations)
    ? body.limitations.filter((l): l is string => typeof l === "string").map((
      l,
    ) => l.trim()).filter((l) => l.length > 0)
    : [];
  return {
    goal,
    trainingDaysPerWeek: days,
    equipment: eq,
    experienceLevel: exp,
    limitations: limits,
  };
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

export async function handler(req: Request): Promise<Response> {
  const jsonHeaders = { "content-type": "application/json" };

  // 1. Resolve the user from the JWT ONLY.
  const { user, response } = await resolveUser(req);
  if (response !== null || user === null) {
    return response ??
      new Response(JSON.stringify({ error: "Unauthorized." }), {
        status: 401,
        headers: jsonHeaders,
      });
  }

  // 2. Parse the body (ignoring any caller-supplied user_id).
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Malformed JSON body." }), {
      status: 400,
      headers: jsonHeaders,
    });
  }
  const body = (raw ?? {}) as Record<string, unknown> & GeneratePlanIntake;
  const bodyUserId = typeof body.user_id === "string" ? body.user_id : null;
  const impersonationAttempt = bodyUserId !== null && bodyUserId !== user.id;

  // 3. Validate intake.
  let intake: PlanIntake;
  try {
    intake = validateIntake(body);
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: e instanceof Error ? e.message : "Invalid intake.",
      }),
      {
        status: 400,
        headers: jsonHeaders,
      },
    );
  }

  // 4. Run the deterministic engine.
  const plan: GeneratedPlan = generatePlan(intake);

  // 5. Narrate (LLM or deterministic fallback).
  const userPhrase = typeof body.userPhrase === "string"
    ? body.userPhrase
    : null;
  const narrative: PlanNarrative = await narratePlan({
    goal: plan.goal,
    daysPerWeek: plan.daysPerWeek,
    experienceLevel: plan.experienceLevel,
    effectiveEquipment: plan.effectiveEquipment,
    days: plan.days.map((d) => ({
      dayNumber: d.dayNumber,
      focus: d.focus,
      split: d.split,
      exercises: d.exercises.map((e) => ({
        id: e.id,
        name: e.name,
        muscleGroup: e.muscleGroup,
        equipment: e.equipment,
        sets: e.sets,
        repsMin: e.repsMin,
        repsMax: e.repsMax,
        rpeTarget: e.rpeTarget,
      })),
    })),
    userPhrase,
  });

  const res: GeneratePlanResponse = {
    user,
    source: "jwt",
    impersonation_attempt: impersonationAttempt,
    plan,
    headline: narrative.headline,
    reasoning: narrative.reasoning,
    changes_made: narrative.changes_made,
    coaching_cue: narrative.coaching_cue,
    is_fallback: narrative.is_fallback,
    model_used: narrative.model_used,
  };

  // ALWAYS 200 with a complete packet (never 501/empty).
  return new Response(JSON.stringify(res), {
    status: 200,
    headers: jsonHeaders,
  });
}

Deno.serve(handler);
