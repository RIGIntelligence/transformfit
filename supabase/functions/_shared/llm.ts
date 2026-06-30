// Shared LLM proxy for TransformFit edge functions.
//
// All OpenRouter calls go through here so that:
//   - the API key stays server-side (Supabase Edge Function secret OPENROUTER_API_KEY),
//   - the model is env-driven (OPENROUTER_MODEL, default z-ai/glm-5.1),
//   - response_format: json_object is enforced,
//   - every failure resolves to a DETERMINISTIC narrative flagged
//     is_fallback:true / model_used:"deterministic" (never a silent template,
//     never a thrown error, never a 501).
//
// This is the single chokepoint for the deterministic-decision -> LLM-narrate
// pattern (architecture.md §4.2, M2 narration, reused by dai-adapt in M3). The
// deterministic engine computes every number; the LLM ONLY writes narrative.
// If the LLM call fails, the deterministic narrative is surfaced honestly.

import type { GeneratedPlan } from "./engines/plan_generation.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Narrative fields — the ONLY things the LLM (or fallback) writes. */
export interface PlanNarrative {
  headline: string;
  reasoning: string;
  changes_made: string[];
  coaching_cue: string;
  /** Always present. "z-ai/glm-5.1" on LLM success, "deterministic" on fallback. */
  model_used: string;
  /** false on LLM success; true whenever the deterministic fallback is used. */
  is_fallback: boolean;
}

/** The plan-narration request — deterministic plan + optional user phrase. */
export interface NarrateRequest {
  goal: string;
  daysPerWeek: number;
  experienceLevel: string | null;
  effectiveEquipment: string[];
  days: Array<{
    dayNumber: number;
    focus: string;
    split: string;
    exercises: Array<{
      id: string;
      name: string;
      muscleGroup: string;
      equipment: string;
      sets: number;
      repsMin: number;
      repsMax: number;
      rpeTarget: number;
    }>;
  }>;
  /** The user's free-text "why now" phrase (may be null/undefined). */
  userPhrase?: string | null;
}

/** Full narrate response: always 200-shaped. */
export interface NarrateResult extends PlanNarrative {
  /** Echo of the deterministic input the narration describes. */
  plan: GeneratedPlan;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
export const DEFAULT_MODEL = "z-ai/glm-5.1";

// ---------------------------------------------------------------------------
// Deterministic fallback (NEVER a silent one-size template)
// ---------------------------------------------------------------------------

const _GOAL_COPY: Record<string, { headline: string; reasoning: string; cue: string }> = {
  build_muscle: {
    headline: "Built to grow — your muscle-first plan is ready.",
    reasoning:
      "This plan prioritizes the rep ranges and volume that drive hypertrophy, spread across your available days so each muscle group gets work and recovery.",
    cue: "Track your sets. Small reps-in-reserve wins this week add up to visible change.",
  },
  build_strength: {
    headline: "Strength is your base — here's how we build it.",
    reasoning:
      "Lower reps, heavier loads, and enough rest between sets to let your nervous system recover. Every session moves the bar toward a new level.",
    cue: "Warm up with intent. The first set should feel easy — the last set should feel earned.",
  },
  lose_fat: {
    headline: "Move more, recover well — your fat-loss cadence is set.",
    reasoning:
      "Higher-rep, full-body work that keeps your heart rate up and your metabolism working between sessions. Consistency is the lever.",
    cue: "Show up on your off days too — a walk counts more than you think.",
  },
  get_fitter: {
    headline: "General fitness, dialed in — your weekly mix is ready.",
    reasoning:
      "A balanced rotation of push, pull, legs, and core across your chosen days. The goal is steady progress without beating you up.",
    cue: "Notice which session you look forward to. That's the one to protect.",
  },
  improve_mobility: {
    headline: "Move better, feel better — your mobility plan is set.",
    reasoning:
      "Controlled ranges, more sets at moderate effort, and enough variety to work every major joint. Focus on quality of movement, not load.",
    cue: "Breathe into each rep. If a range feels tight, stay there a beat longer.",
  },
  train_for_sport: {
    headline: "Sport-ready — your athletic base is loading.",
    reasoning:
      "Power-endurance work in the rep ranges that transfer to the field. We build work capacity without drowning you in volume.",
    cue: "Explosive on the lift, controlled on the return. That's the rhythm that carries over.",
  },
};

function _goalCopy(goal: string) {
  return _GOAL_COPY[goal] ?? _GOAL_COPY["get_fitter"];
}

function _daysWord(n: number): string {
  const words = ["zero", "one", "two", "three", "four", "five", "six", "seven"];
  return words[n] ?? `${n}`;
}

function _eqList(eq: string[]): string {
  const readable = eq.filter((e) => e !== "bodyweight").map((e) => e.replace(/_/g, " "));
  if (readable.length === 0) return "just your bodyweight";
  if (readable.length === 1) return readable[0];
  return `${readable.slice(0, -1).join(", ")} and ${readable[readable.length - 1]}`;
}

/**
 * Deterministic, honest narrative. NEVER a silent one-size template: it
 * explicitly references the user's goal, schedule, equipment, experience, and
 * (when present) their "why now" phrase. Returned flagged is_fallback:true /
 * model_used:"deterministic" so callers and UI can surface the fallback state.
 */
export function deterministicNarrative(req: NarrateRequest): PlanNarrative {
  const c = _goalCopy(req.goal);
  const eq = _eqList(req.effectiveEquipment);
  const days = _daysWord(req.daysPerWeek);
  const exp = req.experienceLevel ?? "intermediate";
  const saneHeadline = "headline" in c ? c.headline : (c as { headline: string }).headline;
  const saneCue = "cue" in c ? c.cue : (c as { cues: string }).cues;

  const phraseClause = req.userPhrase && req.userPhrase.trim().length > 0
    ? ` You told me "${sanitizeUserPhrase(req.userPhrase)}" — that's the through-line here.`
    : "";

  const headline = saneHeadline;
  const reasoning =
    `${c.reasoning} You're training ${days} days a week as a ${exp} with access to ${eq}.${phraseClause}`;
  const coaching_cue = saneCue;

  return {
    headline,
    reasoning,
    changes_made: [`Plan built for ${req.goal} goal`, `${req.daysPerWeek} sessions/week`],
    coaching_cue,
    model_used: "deterministic",
    is_fallback: true,
  };
}

/** Strip emoji + markup from a user phrase before echoing it into coach copy. */
export function sanitizeUserPhrase(raw: string): string {
  // Remove emoji/symbol ranges, collapse whitespace, strip HTML-ish markup.
  const noEmoji = raw
    // emoji & symbol blocks
    .replace(/[\u{1F600}-\u{1F64F}]/gu, "")
    .replace(/[\u{1F300}-\u{1F5FF}]/gu, "")
    .replace(/[\u{1F680}-\u{1F6FF}]/gu, "")
    .replace(/[\u{1F1E0}-\u{1F1FF}]/gu, "")
    .replace(/[\u{2600}-\u{26FF}]/gu, "")
    .replace(/[\u{2700}-\u{27BF}]/gu, "")
    .replace(/[\u{FE00}-\u{FE0F}]/gu, "")
    .replace(/[\u{1F900}-\u{1F9FF}]/gu, "")
    .replace(/[\u{200D}\u{20E3}\u{FE0F}]/gu, "")
    // angle-bracket markup
    .replace(/<[^>]*>/g, "");
  return noEmoji.replace(/\s+/g, " ").trim();
}

// ---------------------------------------------------------------------------
// LLM call
// ---------------------------------------------------------------------------

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

/** Build the prompt for the narration LLM. */
function buildNarratePrompt(req: NarrateRequest): { system: string; user: string } {
  const planJson = JSON.stringify({
    goal: req.goal,
    daysPerWeek: req.daysPerWeek,
    experienceLevel: req.experienceLevel,
    effectiveEquipment: req.effectiveEquipment,
    days: req.days,
  }, null, 2);
  const system = [
    "You are a concise, evidence-informed strength coach writing a PLAN REVEAL narration.",
    "You ONLY write the narrative fields (headline, reasoning, coaching cue). You must NEVER change or invent any number, exercise, set, rep, rpe, weight, or equipment. Those are computed by the engine and are immutable.",
    "Rules:",
    "  - <= 60 words per message block total across headline + reasoning + cue.",
    "  - No emoji. No generic encouragement ('you got this', 'great job').",
    "  - Include at least one specific data token from the plan (a goal, a day count, an equipment name, a set/rep target).",
    "  - Echo the user's 'why now' phrase (if supplied) recognizably, but emoji/markup-stripped.",
    "Return ONLY a JSON object with keys: headline, reasoning, changes_made (array of short strings), coaching_cue. No prose outside the JSON.",
  ].join(" ");

  const user = [
    "Here is the deterministic training plan (numbers are immutable):",
    "```",
    planJson,
    "```",
    req.userPhrase ? `The user's own "why now" phrase (sanitize if it contains emoji/markup): "${req.userPhrase}"` : "No user phrase supplied.",
    "",
    "Write the plan-reveal narrative.",
  ].join("\n");

  return { system, user };
}

/** Parse the LLM content into a PlanNarrative, or null on any failure. */
function parseNarrative(content: string): PlanNarrative | null {
  // Find the first JSON object in the content (defensive against fenced prose).
  const start = content.indexOf("{");
  const end = content.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) return null;
  let obj: unknown;
  try {
    obj = JSON.parse(content.slice(start, end + 1));
  } catch {
    return null;
  }
  if (typeof obj !== "object" || obj === null) return null;
  const o = obj as Record<string, unknown>;
  const headline = typeof o.headline === "string" ? o.headline.trim() : "";
  const reasoning = typeof o.reasoning === "string" ? o.reasoning.trim() : "";
  const coaching_cue = typeof o.coaching_cue === "string" ? o.coaching_cue.trim() : "";
  const changes = Array.isArray(o.changes_made) ? o.changes_made.filter((x): x is string => typeof x === "string") : [];
  if (!headline || !reasoning || !coaching_cue) return null;
  return {
    headline,
    reasoning,
    changes_made: changes,
    coaching_cue,
    model_used: "", // filled in by caller with the real model name
    is_fallback: false,
  };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Narrate a deterministic training plan.
 *
 * Attempts an LLM call (OpenRouter, response_format: json_object, server-side
 * key). On ANY failure — missing key, HTTP error, malformed content, timeout —
 * returns a deterministic narrative flagged is_fallback:true /
 * model_used:"deterministic". Never throws. Never returns 501.
 *
 * @param req The deterministic plan + options.
 * @returns A PlanNarrative; check `is_fallback` to know if it's the LLM or the deterministic copy.
 */
export async function narratePlan(req: NarrateRequest): Promise<PlanNarrative> {
  const apiKey = (Deno.env.get("OPENROUTER_API_KEY") ?? "").trim();
  const model = (Deno.env.get("OPENROUTER_MODEL") ?? DEFAULT_MODEL).trim() || DEFAULT_MODEL;

  if (!apiKey) {
    return deterministicNarrative(req);
  }

  const { system, user } = buildNarratePrompt(req);
  const messages: ChatMessage[] = [
    { role: "system", content: system },
    { role: "user", content: user },
  ];

  let resp: Response;
  try {
    // Abort after 20s — the onboarding reveal must not stall the client.
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 20000);
    resp = await fetch(OPENROUTER_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "https://transformfit.test",
        "X-Title": "TransformFit",
      },
      body: JSON.stringify({
        model,
        messages,
        response_format: { type: "json_object" },
        temperature: 0.7,
        max_tokens: 600,
      }),
      signal: controller.signal,
    });
    clearTimeout(timer);
  } catch {
    return deterministicNarrative(req);
  }

  if (!resp.ok) {
    return deterministicNarrative(req);
  }

  let json: unknown;
  try {
    json = await resp.json();
  } catch {
    return deterministicNarrative(req);
  }

  // OpenRouter chat-completions shape.
  const body = json as { choices?: Array<{ message?: { content?: string } }> };
  const choices = body.choices;
  const content = choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    return deterministicNarrative(req);
  }

  const parsed = parseNarrative(content);
  if (!parsed) {
    return deterministicNarrative(req);
  }
  parsed.model_used = model;
  return parsed;
}
