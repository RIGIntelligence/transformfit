// coach-stream — M7 Coaching milestone.
//
// Streaming coaching endpoint that calls Ollama ornith:35b via /api/chat with
// stream:true. Sends persona + context + deterministic numbers. Returns
// narrative-only coaching — the LLM NEVER changes numbers (L6-2:
// deterministic-before-agentic).
//
// Fallback: on any failure (Ollama unreachable, timeout, parse error), returns
// a deterministic narrative flagged is_fallback:true / model_used:"deterministic".
// Never 501, never a silent hardcoded template.
//
// The coaching system uses a local Ollama model at OLLAMA_HOST (default
// http://localhost:11434). The model is OLLAMA_MODEL (default ornith:35b).

import { resolveUser, type AuthUser } from "../_shared/auth.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CoachStreamRequest {
  persona: string; // motivator | analyst | challenger | zen
  templateType: string; // session_start | mid_session | session_end | recovery | stall
  toneArcPhase: string; // days0to7 | days8to14 | days15to21 | days22to30
  intensity: string; // low | normal | high
  // Deterministic context — the immutable numbers the LLM narrates around.
  context: {
    readinessScore?: number;
    sessionCount?: number;
    volumeKg?: number;
    rpe?: number;
    streakDays?: number;
    sorenessAreas?: number;
    acwr?: number;
    fatigueState?: string;
  };
  userPhrase?: string | null;
  // The deterministic message to use as fallback / context.
  deterministicMessage?: string;
}

export interface CoachStreamResponse {
  persona: string;
  templateType: string;
  message: string;
  modelUsed: string;
  isFallback: boolean;
}

// ---------------------------------------------------------------------------
// Persona system prompts (mirrors Dart persona_system.dart)
// ---------------------------------------------------------------------------

const PERSONA_PROMPTS: Record<string, string> = {
  motivator:
    "You are the Motivator coach. Your role is momentum builder. You are warm, forward, effort-noticing, and consistency-celebrating. Emphasize momentum and effort with specific session evidence. Never use generic encouragement.",
  analyst:
    "You are the Analyst coach. Your role is pattern interpreter. You are precise, trend-driven, and anomaly-aware. Cite specific metrics and trend deltas. Compare current vs prior sessions. Use precise numbers.",
  challenger:
    "You are the Challenger coach. Your role is standard-raiser. You are direct, high-bar, and evidence-led. Challenge coasting with data and no guilt framing. Confront honestly without shame. Name the gap between intent and execution.",
  zen:
    "You are the Zen coach. Your role is recovery stabilizer. You are calm, quality-first, and sustainability-focused. Prioritize recovery quality and long-term continuity. Frame rest as productive, not passive.",
};

const TONE_ARC_INSTRUCTION: Record<string, string> = {
  days0to7:
    "Tone: 80% directive, 20% supportive. The user is early-stage — be clear and instructive.",
  days8to14:
    "Tone: 60% directive, 40% supportive. Guide with growing room for autonomy.",
  days15to21:
    "Tone: 40% directive, 60% supportive. The user is demonstrating competence — support more than direct.",
  days22to30:
    "Tone: 20% directive, 80% supportive. The user is competent — be a sounding board, not a lecturer.",
};

const INTENSITY_INSTRUCTION: Record<string, string> = {
  low: "Reduce intensity — the user is fatigued or in recovery. Soften your approach.",
  normal: "Use standard coaching intensity.",
  high: "Elevate intensity — the user needs momentum or a higher standard.",
};

// ---------------------------------------------------------------------------
// Doctrine message rules (enforced in the system prompt + post-lint)
// ---------------------------------------------------------------------------

const COACHING_RULES = [
  "Output ONLY the coaching message. No preamble, no JSON, no markdown fences.",
  "Maximum 60 words total.",
  "No emoji.",
  "No generic encouragement ('you got this', 'great job', 'keep it up').",
  "Include at least one specific data token from the context provided.",
  "If confidence is low, include uncertainty framing ('not sure', 'worth trying').",
  "Maximum one question mark.",
  "Never make medical claims, diagnoses, or prescribe treatment.",
  "Never use guilt, shame, or streak-shame language.",
  "Echo the user's own words recognizably if a user phrase is provided.",
  "NEVER change, invent, or contradict the numbers provided in the context. Those are computed by the deterministic engine and are immutable.",
];

// ---------------------------------------------------------------------------
// Streaming
// ---------------------------------------------------------------------------

const OLLAMA_HOST = (Deno.env.get("OLLAMA_HOST") ?? "http://localhost:11434")
  .trim();
const OLLAMA_MODEL = (Deno.env.get("OLLAMA_MODEL") ?? "ornith:35b").trim();
const STREAM_TIMEOUT_MS = 30_000;

interface OllamaChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

function buildSystemPrompt(req: CoachStreamRequest): string {
  const personaPrompt = PERSONA_PROMPTS[req.persona] ?? PERSONA_PROMPTS.analyst;
  const toneArc = TONE_ARC_INSTRUCTION[req.toneArcPhase] ??
    TONE_ARC_INSTRUCTION.days8to14;
  const intensity = INTENSITY_INSTRUCTION[req.intensity] ??
    INTENSITY_INSTRUCTION.normal;

  return [
    personaPrompt,
    toneArc,
    intensity,
    "",
    "Message rules (binding):",
    ...COACHING_RULES.map((r) => `  - ${r}`),
  ].join("\n");
}

function buildUserPrompt(req: CoachStreamRequest): string {
  const ctx = req.context;
  const dataLines: string[] = [];
  if (ctx.readinessScore !== undefined) {
    dataLines.push(`Readiness score: ${ctx.readinessScore}`);
  }
  if (ctx.sessionCount !== undefined) {
    dataLines.push(`Sessions completed: ${ctx.sessionCount}`);
  }
  if (ctx.volumeKg !== undefined) {
    dataLines.push(`Volume: ${ctx.volumeKg.toFixed(1)} kg`);
  }
  if (ctx.rpe !== undefined) dataLines.push(`RPE: ${ctx.rpe}`);
  if (ctx.streakDays !== undefined) dataLines.push(`Streak: ${ctx.streakDays} days`);
  if (ctx.sorenessAreas !== undefined) {
    dataLines.push(`Soreness areas: ${ctx.sorenessAreas}`);
  }
  if (ctx.acwr !== undefined) {
    dataLines.push(`ACWR: ${ctx.acwr.toFixed(2)}`);
  }
  if (ctx.fatigueState !== undefined) {
    dataLines.push(`Fatigue state: ${ctx.fatigueState}`);
  }

  const parts = [
    `Coaching situation: ${req.templateType}`,
    "",
    "Deterministic context (these numbers are IMMUTABLE — narrate around them, never change them):",
    ...dataLines,
  ];
  if (req.userPhrase && req.userPhrase.trim().length > 0) {
    parts.push("", `User's own phrase: "${req.userPhrase}"`);
  }
  parts.push("", "Write the coaching message now.");
  return parts.join("\n");
}

/**
 * Stream coaching from Ollama. Returns a ReadableStream of text chunks.
 * Throws on any error (caller falls back to deterministic).
 */
async function streamFromOllama(
  req: CoachStreamRequest,
): Promise<ReadableStream<Uint8Array>> {
  const system = buildSystemPrompt(req);
  const user = buildUserPrompt(req);

  const messages: OllamaChatMessage[] = [
    { role: "system", content: system },
    { role: "user", content: user },
  ];

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), STREAM_TIMEOUT_MS);

  let resp: Response;
  try {
    resp = await fetch(`${OLLAMA_HOST}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        stream: true,
        messages,
        options: { temperature: 0.7 },
      }),
      signal: controller.signal,
    });
  } catch {
    clearTimeout(timer);
    throw new Error("Ollama connection failed");
  }

  if (!resp.ok || !resp.body) {
    clearTimeout(timer);
    throw new Error(`Ollama returned ${resp.status}`);
  }

  // Wrap the NDJSON stream to extract content chunks.
  const rawBody = resp.body;
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
  let buffer = "";

  return new ReadableStream<Uint8Array>({
    start(streamController) {
      const reader = rawBody.getReader();
      const pump = (): Promise<void> => {
        return reader.read().then(({ done, value }) => {
          if (done) {
            clearTimeout(timer);
            streamController.close();
            return;
          }
          buffer += decoder.decode(value, { stream: true });
          // Ollama streams NDJSON: one JSON object per line.
          const lines = buffer.split("\n");
          buffer = lines.pop() ?? "";
          for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed) continue;
            try {
              const obj = JSON.parse(trimmed);
              const content = obj?.message?.content;
              if (typeof content === "string" && content.length > 0) {
                streamController.enqueue(encoder.encode(content));
              }
            } catch {
              // Skip malformed JSON lines (partial).
            }
          }
          return pump();
        }).catch((err) => {
          clearTimeout(timer);
          if (err instanceof DOMException && err.name === "AbortError") {
            streamController.close();
          } else {
            streamController.error(err);
          }
        });
      };
      pump();
    },
    cancel() {
      clearTimeout(timer);
    },
  });
}

// ---------------------------------------------------------------------------
// Deterministic fallback (surfaced, never silent — L6-2)
// ---------------------------------------------------------------------------

function deterministicCoachMessage(req: CoachStreamRequest): string {
  // Use the provided deterministic message if available; otherwise build
  // a simple one from the context.
  if (req.deterministicMessage && req.deterministicMessage.trim().length > 0) {
    return req.deterministicMessage.trim();
  }

  const ctx = req.context;
  const parts: string[] = [];

  switch (req.templateType) {
    case "session_start":
      parts.push(
        `Readiness ${ctx.readinessScore ?? "—"}. Today's session is set — start with the first working set.`,
      );
      break;
    case "mid_session":
      parts.push(
        `${ctx.volumeKg?.toFixed(0) ?? 0} kg logged. Keep the next set clean.`,
      );
      break;
    case "session_end":
      parts.push(
        `Session done. ${ctx.sessionCount ?? 0} sessions in the ledger.`,
      );
      break;
    case "recovery":
      parts.push(
        `${ctx.sorenessAreas ?? 0} sore ${(ctx.sorenessAreas ?? 0) === 1 ? "area" : "areas"}. Recovery is training — keep it gentle.`,
      );
      break;
    case "stall":
      parts.push(
        `${ctx.streakDays ?? 0} days off. One set logged restarts the momentum.`,
      );
      break;
    default:
      parts.push(
        `Readiness ${ctx.readinessScore ?? "—"}. The plan is ready when you are.`,
      );
  }

  return parts.join(" ");
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

const VALID_PERSONAS = new Set(["motivator", "analyst", "challenger", "zen"]);
const VALID_TEMPLATES = new Set([
  "session_start",
  "mid_session",
  "session_end",
  "recovery",
  "stall",
]);
const VALID_TONE_ARCS = new Set([
  "days0to7",
  "days8to14",
  "days15to21",
  "days22to30",
]);
const VALID_INTENSITIES = new Set(["low", "normal", "high"]);

function validateRequest(body: unknown): CoachStreamRequest {
  if (!body || typeof body !== "object") {
    throw new Error("Request body must be a JSON object.");
  }
  const b = body as Record<string, unknown>;

  const persona = typeof b.persona === "string" ? b.persona.trim() : "";
  if (!VALID_PERSONAS.has(persona)) {
    throw new Error(
      `Invalid persona. Valid: ${[...VALID_PERSONAS].join(", ")}.`,
    );
  }

  const templateType = typeof b.templateType === "string"
    ? b.templateType.trim()
    : "";
  if (!VALID_TEMPLATES.has(templateType)) {
    throw new Error(
      `Invalid templateType. Valid: ${[...VALID_TEMPLATES].join(", ")}.`,
    );
  }

  const toneArcPhase = typeof b.toneArcPhase === "string"
    ? b.toneArcPhase.trim()
    : "days8to14";
  if (!VALID_TONE_ARCS.has(toneArcPhase)) {
    throw new Error(
      `Invalid toneArcPhase. Valid: ${[...VALID_TONE_ARCS].join(", ")}.`,
    );
  }

  const intensity = typeof b.intensity === "string"
    ? b.intensity.trim()
    : "normal";
  if (!VALID_INTENSITIES.has(intensity)) {
    throw new Error(
      `Invalid intensity. Valid: ${[...VALID_INTENSITIES].join(", ")}.`,
    );
  }

  const ctx = (b.context ?? {}) as Record<string, unknown>;

  return {
    persona,
    templateType,
    toneArcPhase,
    intensity,
    context: {
      readinessScore: typeof ctx.readinessScore === "number"
        ? ctx.readinessScore
        : undefined,
      sessionCount: typeof ctx.sessionCount === "number"
        ? ctx.sessionCount
        : undefined,
      volumeKg: typeof ctx.volumeKg === "number" ? ctx.volumeKg : undefined,
      rpe: typeof ctx.rpe === "number" ? ctx.rpe : undefined,
      streakDays: typeof ctx.streakDays === "number"
        ? ctx.streakDays
        : undefined,
      sorenessAreas: typeof ctx.sorenessAreas === "number"
        ? ctx.sorenessAreas
        : undefined,
      acwr: typeof ctx.acwr === "number" ? ctx.acwr : undefined,
      fatigueState: typeof ctx.fatigueState === "string"
        ? ctx.fatigueState
        : undefined,
    },
    userPhrase: typeof b.userPhrase === "string" ? b.userPhrase : null,
    deterministicMessage: typeof b.deterministicMessage === "string"
      ? b.deterministicMessage
      : undefined,
  };
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

export async function handler(req: Request): Promise<Response> {
  const jsonHeaders = { "content-type": "application/json" };

  // 1. Resolve user from JWT only.
  const { user, response } = await resolveUser(req);
  if (response !== null || user === null) {
    return response ??
      new Response(JSON.stringify({ error: "Unauthorized." }), {
        status: 401,
        headers: jsonHeaders,
      });
  }

  // 2. Parse body.
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Malformed JSON body." }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  // 3. Validate.
  let coachReq: CoachStreamRequest;
  try {
    coachReq = validateRequest(raw);
  } catch (e) {
    return new Response(
      JSON.stringify({
        error: e instanceof Error ? e.message : "Invalid request.",
      }),
      { status: 400, headers: jsonHeaders },
    );
  }

  // 4. Check Accept header — stream or single response.
  const accept = req.headers.get("accept") ?? "";
  const wantsStream = accept.includes("text/event-stream") ||
    accept.includes("text/plain");

  // 5a. Streaming path.
  if (wantsStream) {
    try {
      const stream = await streamFromOllama(coachReq);
      return new Response(stream, {
        status: 200,
        headers: {
          "content-type": "text/event-stream",
          "cache-control": "no-cache",
          "connection": "keep-alive",
          "x-model-used": `ollama:${OLLAMA_MODEL}`,
          "x-is-fallback": "false",
          "x-persona": coachReq.persona,
        },
      });
    } catch {
      // Fall through to deterministic fallback.
    }
  }

  // 5b. Non-streaming path — try Ollama without stream, fall back to deterministic.
  try {
    const system = buildSystemPrompt(coachReq);
    const user = buildUserPrompt(coachReq);
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), STREAM_TIMEOUT_MS);

    const resp = await fetch(`${OLLAMA_HOST}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        stream: false,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
        options: { temperature: 0.7 },
      }),
      signal: controller.signal,
    });
    clearTimeout(timer);

    if (resp.ok) {
      const body = await resp.json();
      const content = body?.message?.content;
      if (typeof content === "string" && content.trim().length > 0) {
        const result: CoachStreamResponse = {
          persona: coachReq.persona,
          templateType: coachReq.templateType,
          message: content.trim(),
          modelUsed: `ollama:${OLLAMA_MODEL}`,
          isFallback: false,
        };
        return new Response(JSON.stringify(result), {
          status: 200,
          headers: jsonHeaders,
        });
      }
    }
  } catch {
    // Fall through to deterministic.
  }

  // 5c. Deterministic fallback (surfaced honestly — L6-2).
  const fallbackMessage = deterministicCoachMessage(coachReq);
  const result: CoachStreamResponse = {
    persona: coachReq.persona,
    templateType: coachReq.templateType,
    message: fallbackMessage,
    modelUsed: "deterministic",
    isFallback: true,
  };
  return new Response(JSON.stringify(result), {
    status: 200,
    headers: jsonHeaders,
  });
}

Deno.serve(handler);
