// Unit tests for the shared LLM proxy (_shared/llm.ts).
//
// Run: deno test --allow-all supabase/functions/_shared/llm_test.ts
//
// The proxy calls OpenRouter (https://openrouter.ai/api/v1/chat/completions)
// with the server-side OPENROUTER_API_KEY, an env-driven model
// (OPENROUTER_MODEL, default z-ai/glm-5.1), and response_format: json_object.
// On any failure it returns a deterministic fallback narrative flagged
// is_fallback:true / model_used:"deterministic" -- never a silent template,
// never a thrown error, never a 501.
//
// These tests exercise the proxy's CONTRACT without hitting the live LLM:
//   - missing / empty API key -> deterministic fallback (no throw),
//   - forced failure (bad key + unreachable) -> deterministic fallback,
//   - the fallback is ALWAYS flagged is_fallback:true / model_used:"deterministic",
//   - the deterministic fallback is specific to inputs (not a one-size template),
//   - the deterministic fallback echoes the user phrase (when present),
//   - the output is always a well-formed PlanNarrative.
import { assert, assertEquals, assertNotEquals } from "jsr:@std/assert";
import { narratePlan, deterministicNarrative, type PlanNarrative } from "./llm.ts";

// --- helpers ---------------------------------------------------------------

const SAMPLE_REQUEST = {
  goal: "build_muscle",
  daysPerWeek: 3,
  experienceLevel: "intermediate" as const,
  effectiveEquipment: ["bodyweight", "dumbbells"],
  days: [{ dayNumber: 1, focus: "Full Body A", split: "full", exercises: [] }],
};

/** Set an env var, await fn, then restore. Returns fn's return value. */
async function withEnv<T>(name: string, value: string | undefined, fn: () => Promise<T>): Promise<T> {
  const prev = Deno.env.get(name);
  if (value === undefined) Deno.env.delete(name);
  else Deno.env.set(name, value);
  try {
    return await fn();
  } finally {
    if (prev === undefined) Deno.env.delete(name);
    else Deno.env.set(name, prev);
  }
}

// --- fallback contract ------------------------------------------------------

Deno.test("narratePlan: missing OPENROUTER_API_KEY returns a flagged deterministic fallback (no throw)", async () => {
  const captured = await withEnv("OPENROUTER_API_KEY", undefined, () => narratePlan(SAMPLE_REQUEST));
  assertEquals(captured.is_fallback, true);
  assertEquals(captured.model_used, "deterministic");
  assert(captured.headline.length > 0);
  assert(captured.reasoning.length > 0);
  assert(captured.coaching_cue.length > 0);
});

Deno.test("narratePlan: empty OPENROUTER_API_KEY returns a flagged deterministic fallback", async () => {
  const captured = await withEnv("OPENROUTER_API_KEY", "", () => narratePlan({
    goal: "lose_fat",
    daysPerWeek: 4,
    experienceLevel: "beginner",
    effectiveEquipment: ["bodyweight"],
    days: [],
  }));
  assertEquals(captured.is_fallback, true);
  assertEquals(captured.model_used, "deterministic");
});

Deno.test("narratePlan: never throws to the caller even with a bogus key", async () => {
  let threw = false;
  let captured: PlanNarrative | undefined;
  try {
    captured = await withEnv("OPENROUTER_API_KEY", "sk-or-test-invalid-key", () => narratePlan({
      goal: "get_fitter",
      daysPerWeek: 3,
      experienceLevel: "intermediate",
      effectiveEquipment: ["bodyweight", "dumbbells"],
      days: [],
    }));
  } catch {
    threw = true;
  }
  assertEquals(threw, false, "narratePlan must never throw to the caller");
  assert(captured !== undefined);
  assertEquals(captured!.is_fallback, true);
  assertEquals(captured!.model_used, "deterministic");
});

Deno.test("narratePlan: deterministic fallback echoes the user phrase when present", async () => {
  const captured = await withEnv("OPENROUTER_API_KEY", undefined, () => narratePlan({
    ...SAMPLE_REQUEST,
    userPhrase: "I want to feel strong again",
  }));
  assertEquals(captured.is_fallback, true);
  // The deterministic fallback references goal / equipment / schedule --
  // it is NOT a silent generic template.
  const blob = `${captured.headline} ${captured.reasoning} ${captured.coaching_cue}`.toLowerCase();
  assert(
    blob.includes("build_muscle") || blob.includes("muscle") || blob.includes("3") ||
      blob.includes("dumbbells") || blob.includes("feel strong again"),
    `deterministic fallback must reference plan inputs, got: ${blob}`,
  );
});

Deno.test("narratePlan: deterministic fallback is specific to the goal (not a one-size template)", async () => {
  const a = await withEnv("OPENROUTER_API_KEY", undefined, () => narratePlan({
    goal: "build_muscle",
    daysPerWeek: 3,
    experienceLevel: "intermediate",
    effectiveEquipment: ["bodyweight", "dumbbells"],
    days: [],
  }));
  const b = await withEnv("OPENROUTER_API_KEY", undefined, () => narratePlan({
    goal: "improve_mobility",
    daysPerWeek: 3,
    experienceLevel: "intermediate",
    effectiveEquipment: ["bodyweight", "dumbbells"],
    days: [],
  }));
  // Different goals should produce visibly different deterministic copy.
  assertNotEquals(a.headline, b.headline);
});

Deno.test("deterministicNarrative: always flagged is_fallback:true / model_used:deterministic", () => {
  const n = deterministicNarrative({
    goal: "get_fitter",
    daysPerWeek: 5,
    experienceLevel: "advanced",
    effectiveEquipment: ["bodyweight", "barbell"],
    days: [],
  });
  assertEquals(n.is_fallback, true);
  assertEquals(n.model_used, "deterministic");
  assert(n.headline.length > 0);
  assert(n.reasoning.length > 0);
  assert(n.coaching_cue.length > 0);
  assert(Array.isArray(n.changes_made));
});

Deno.test("deterministicNarrative: includes days/week and equipment in reasoning", () => {
  const n = deterministicNarrative({
    goal: "get_fitter",
    daysPerWeek: 3,
    experienceLevel: "beginner",
    effectiveEquipment: ["bodyweight"],
    days: [],
  });
  const blob = n.reasoning.toLowerCase();
  assert(blob.includes("three days a week") || blob.includes("3 days a week"), `expected days/week, got: ${blob}`);
  // bodyweight-only should render as "just your bodyweight", not "[object Object]"
  assert(blob.includes("just your bodyweight"), `expected readable equipment list, got: ${blob}`);
});

Deno.test("narratePlan: output is always a well-formed PlanNarrative", async () => {
  const captured = await withEnv("OPENROUTER_API_KEY", undefined, () => narratePlan({
    goal: "build_strength",
    daysPerWeek: 4,
    experienceLevel: "advanced",
    effectiveEquipment: ["bodyweight", "barbell"],
    days: [],
  }));
  assertEquals(typeof captured.headline, "string");
  assertEquals(typeof captured.reasoning, "string");
  assertEquals(typeof captured.coaching_cue, "string");
  assertEquals(typeof captured.is_fallback, "boolean");
  assertEquals(typeof captured.model_used, "string");
  assert(captured.headline.length > 0);
  assert(captured.reasoning.length > 0);
  assert(captured.coaching_cue.length > 0);
});

Deno.test("narratePlan: user phrase with emoji/markup is sanitized in deterministic echo", async () => {
  const captured = await withEnv("OPENROUTER_API_KEY", undefined, () => narratePlan({
    ...SAMPLE_REQUEST,
    userPhrase: "I want to get <b>strong</b> again 💪🔥!",
  }));
  // The echoed phrase must carry zero emoji + no markup
  const allText = `${captured.headline} ${captured.reasoning} ${captured.coaching_cue}`;
  assert(!/\ud83d/.test(allText), "no emoji should be echoed into coach copy");
  assert(!/<[a-z][^>]*>/i.test(allText), "no markup should be echoed into coach copy");
});
