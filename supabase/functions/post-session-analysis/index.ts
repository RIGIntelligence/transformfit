// post-session-analysis — the M5 Debrief edge function.
//
// Establishes the deterministic-decision -> LLM-narrate pattern for post-
// session debrief (architecture §4.2):
//
//   1. Resolve the acting user FROM THE JWT ONLY (_shared/auth.ts).
//   2. Validate session data (exercises, sets, weights, reps, RPE, duration).
//   3. Run the DETERMINISTIC analysis engine
//      (_shared/engines/post_session_analysis.ts) -> immutable result.
//   4. Narrate via local Ollama (model ornith:35b on localhost:11434). On
//      failure, return a deterministic narrative flagged
//      is_fallback:true / model_used:"deterministic".
//   5. ALWAYS return 200 with a complete analysis packet (never 501/empty).
//
// Doctrine L6-2 (deterministic-before-agentic): numbers come ONLY from the
// engine. The LLM writes narrative only. Never silent. Always surfaced.

import { type AuthUser, resolveUser } from "../_shared/auth.ts";
import {
  type AnalysisLoggedSet,
  type AnalysisPreviousBest,
  type PostSessionAnalysisResult,
  computePostSessionAnalysis,
} from "../_shared/engines/post_session_analysis.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface PostSessionAnalysisResponse {
  user: AuthUser;
  source: "jwt";
  analysis: PostSessionAnalysisResult;
  /** LLM-written narrative on success; deterministic+flagged on fallback. */
  narrative: DebriefNarrative;
}

export interface DebriefNarrative {
  volume_summary: string;
  what_changed: string;
  coaching_takeaway: string;
  /** false on LLM success; true whenever the deterministic fallback is used. */
  is_fallback: boolean;
  /** "ornith:35b" on LLM success, "deterministic" on fallback. */
  model_used: string;
}

interface PostSessionAnalysisRequest {
  sets?: unknown;
  previousBests?: unknown;
  durationMinutes?: unknown;
  readinessScoreBefore?: unknown;
  corridorRepsMin?: unknown;
  corridorRepsMax?: unknown;
  corridorRpeTarget?: unknown;
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

function validateSets(raw: unknown): AnalysisLoggedSet[] {
  if (!Array.isArray(raw)) {
    throw new Error("sets must be an array.");
  }
  const out: AnalysisLoggedSet[] = [];
  for (let i = 0; i < raw.length; i++) {
    const item = raw[i];
    if (typeof item !== "object" || item === null) {
      throw new Error(`sets[${i}] must be an object.`);
    }
    const obj = item as Record<string, unknown>;
    const exerciseId = typeof obj.exerciseId === "string"
      ? obj.exerciseId.trim()
      : "";
    if (exerciseId.length === 0) {
      throw new Error(`sets[${i}].exerciseId must be a non-empty string.`);
    }
    const weightKg = Number(obj.weightKg);
    if (!Number.isFinite(weightKg) || weightKg < 0) {
      throw new Error(`sets[${i}].weightKg must be a non-negative number.`);
    }
    const reps = Number(obj.reps);
    if (!Number.isInteger(reps) || reps < 0) {
      throw new Error(`sets[${i}].reps must be a non-negative integer.`);
    }
    const rpe = obj.rpe === undefined || obj.rpe === null
      ? null
      : Number(obj.rpe);
    if (
      rpe !== null &&
      (!Number.isInteger(rpe) || rpe < 1 || rpe > 10)
    ) {
      throw new Error(`sets[${i}].rpe must be an integer from 1 to 10.`);
    }
    out.push({ exerciseId, weightKg, reps, rpe });
  }
  return out;
}

function validatePreviousBests(raw: unknown): AnalysisPreviousBest[] {
  if (raw === undefined || raw === null) return [];
  if (!Array.isArray(raw)) {
    throw new Error("previousBests must be an array.");
  }
  return raw.map((item, i) => {
    if (typeof item !== "object" || item === null) {
      throw new Error(`previousBests[${i}] must be an object.`);
    }
    const obj = item as Record<string, unknown>;
    const exerciseId = typeof obj.exerciseId === "string"
      ? obj.exerciseId.trim()
      : "";
    if (exerciseId.length === 0) {
      throw new Error(`previousBests[${i}].exerciseId must be non-empty.`);
    }
    const estimatedOneRmKg = Number(obj.estimatedOneRmKg);
    if (!Number.isFinite(estimatedOneRmKg) || estimatedOneRmKg < 0) {
      throw new Error(
        `previousBests[${i}].estimatedOneRmKg must be a non-negative number.`,
      );
    }
    return { exerciseId, estimatedOneRmKg };
  });
}

function optInt(value: unknown, field: string): number | undefined {
  if (value === undefined || value === null) return undefined;
  const n = Number(value);
  if (!Number.isInteger(n)) {
    throw new Error(`${field} must be an integer.`);
  }
  return n;
}

// ---------------------------------------------------------------------------
// Deterministic narrative fallback
// ---------------------------------------------------------------------------

function deterministicNarrative(
  result: PostSessionAnalysisResult,
): DebriefNarrative {
  const volKg = result.totalVolumeKg.toLocaleString("en-US", {
    maximumFractionDigits: 0,
  });
  const volumeSummary =
    `${result.totalSets} sets, ${result.totalReps} reps, ${volKg} kg total volume.`;

  const changesParts: string[] = [];
  for (const c of result.oneRmChanges.slice(0, 3)) {
    const sign = c.deltaKg > 0 ? "+" : "";
    changesParts.push(
      `${c.exerciseId}: ${c.sessionOneRmKg} kg est. 1RM (${sign}${c.deltaKg} kg).`,
    );
  }
  const whatChanged = changesParts.length > 0
    ? changesParts.join(" ")
    : "No prior baseline; this session establishes your 1RM estimates.";

  const takeaway =
    `${result.corridorReason} ${result.readinessImpactReason}`;

  return {
    volume_summary: volumeSummary,
    what_changed: whatChanged,
    coaching_takeaway: takeaway,
    is_fallback: true,
    model_used: "deterministic",
  };
}

// ---------------------------------------------------------------------------
// Ollama LLM narration
// ---------------------------------------------------------------------------

const OLLAMA_HOST =
  (Deno.env.get("OLLAMA_HOST") ?? "http://localhost:11434").trim();
const OLLAMA_MODEL = (Deno.env.get("OLLAMA_MODEL") ?? "ornith:35b").trim();

interface OllamaChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

function buildDebriefPrompt(result: PostSessionAnalysisResult): {
  system: string;
  user: string;
} {
  const analysisJson = JSON.stringify(result, null, 2);
  const system = [
    "You are a concise, evidence-informed strength coach writing a POST-SESSION DEBRIEF.",
    "You ONLY write narrative fields. You must NEVER change or invent any number. The analysis is computed by the engine and is immutable.",
    "Rules:",
    "  - <= 60 words per narrative field.",
    "  - No emoji. No generic encouragement ('you got this', 'great job').",
    "  - Include specific data tokens from the analysis (volume, sets, reps, 1RM).",
    "Return ONLY a JSON object with keys: volume_summary, what_changed, coaching_takeaway.",
  ].join(" ");
  const user = [
    "Here is the deterministic session analysis (numbers are immutable):",
    "```",
    analysisJson,
    "```",
    "Write the post-session debrief narrative.",
  ].join("\n");
  return { system, user };
}

function parseDebriefNarrative(
  content: string,
): { volume_summary: string; what_changed: string; coaching_takeaway: string } | null {
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
  const volumeSummary = typeof o.volume_summary === "string"
    ? o.volume_summary.trim()
    : "";
  const whatChanged = typeof o.what_changed === "string"
    ? o.what_changed.trim()
    : "";
  const coachingTakeaway = typeof o.coaching_takeaway === "string"
    ? o.coaching_takeaway.trim()
    : "";
  if (!volumeSummary || !whatChanged || !coachingTakeaway) return null;
  return {
    volume_summary: volumeSummary,
    what_changed: whatChanged,
    coaching_takeaway: coachingTakeaway,
  };
}

async function narrateDebrief(
  result: PostSessionAnalysisResult,
): Promise<DebriefNarrative> {
  const { system, user } = buildDebriefPrompt(result);
  const messages: OllamaChatMessage[] = [
    { role: "system", content: system },
    { role: "user", content: user },
  ];

  let resp: Response;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 15000);
    resp = await fetch(`${OLLAMA_HOST}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        messages,
        stream: false,
        format: "json",
        options: { temperature: 0.7 },
      }),
      signal: controller.signal,
    });
    clearTimeout(timer);
  } catch {
    return deterministicNarrative(result);
  }

  if (!resp.ok) {
    return deterministicNarrative(result);
  }

  let json: unknown;
  try {
    json = await resp.json();
  } catch {
    return deterministicNarrative(result);
  }

  const body = json as { message?: { content?: string } };
  const content = body.message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    return deterministicNarrative(result);
  }

  const parsed = parseDebriefNarrative(content);
  if (!parsed) {
    return deterministicNarrative(result);
  }

  return {
    volume_summary: parsed.volume_summary,
    what_changed: parsed.what_changed,
    coaching_takeaway: parsed.coaching_takeaway,
    is_fallback: false,
    model_used: OLLAMA_MODEL,
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

  // 2. Parse the body.
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Malformed JSON body." }), {
      status: 400,
      headers: jsonHeaders,
    });
  }
  const body = (raw ?? {}) as Record<string, unknown> & PostSessionAnalysisRequest;

  // 3. Validate.
  let sets: AnalysisLoggedSet[];
  let previousBests: AnalysisPreviousBest[];
  let durationMinutes: number | undefined;
  let readinessScoreBefore: number | undefined;
  let corridorRepsMin: number | undefined;
  let corridorRepsMax: number | undefined;
  let corridorRpeTarget: number | undefined;
  try {
    sets = validateSets(body.sets);
    previousBests = validatePreviousBests(body.previousBests);
    durationMinutes = optInt(body.durationMinutes, "durationMinutes");
    readinessScoreBefore = optInt(
      body.readinessScoreBefore,
      "readinessScoreBefore",
    );
    corridorRepsMin = optInt(body.corridorRepsMin, "corridorRepsMin");
    corridorRepsMax = optInt(body.corridorRepsMax, "corridorRepsMax");
    corridorRpeTarget = optInt(body.corridorRpeTarget, "corridorRpeTarget");
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: e instanceof Error ? e.message : "Invalid request.",
      }),
      { status: 400, headers: jsonHeaders },
    );
  }

  // 4. Run the deterministic engine.
  const analysis = computePostSessionAnalysis({
    sets,
    previousBests,
    durationMinutes: durationMinutes ?? null,
    readinessScoreBefore: readinessScoreBefore ?? null,
    corridorRepsMin,
    corridorRepsMax,
    corridorRpeTarget,
  });

  // 5. Narrate (LLM or deterministic fallback).
  const narrative = await narrateDebrief(analysis);

  const res: PostSessionAnalysisResponse = {
    user,
    source: "jwt",
    analysis,
    narrative,
  };

  // ALWAYS 200 with a complete packet.
  return new Response(JSON.stringify(res), {
    status: 200,
    headers: jsonHeaders,
  });
}

Deno.serve(handler);
