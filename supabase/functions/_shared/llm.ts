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

// Local Ollama integration (RIG Mac Studio).
// When OLLAMA_HOST is set, narration tries the local model first — zero API
// cost, sub-second latency on the LAN. Falls back to OpenRouter if the local
// call fails or times out.
const OLLAMA_HOST = (Deno.env.get("OLLAMA_HOST") ?? "").trim();
const OLLAMA_MODEL = (Deno.env.get("OLLAMA_MODEL") ?? "ornith:35b").trim();

// ---------------------------------------------------------------------------
// R1–R8 message-rule guardrail — deterministic post-composition lint.
//
// Applied to BOTH the deterministic-fallback and the LLM-success path so the
// doctrine message rules (TRANSFORMFIT-DOCTRINE.md L1-4..L1-11 and the
// harness message_rule_lint.py R1-R8) hold regardless of the narration
// source. Auto-correctable rules (R2 word-count, R3 no-emoji, R4
// no-banned-phrase, R8 <=1-question, and packet-number contradiction) are
// handled here. The deterministic fallback currently exceeds 60 words on
// common goal/equip/phrase combos (the ONB-032 bug) and echoes a user '?'
// verbatim (the ONB-036 bug); the LLM-success path (parseNarrative) currently
// has no guardrail at all beyond trimming — this block fixes both.
// ---------------------------------------------------------------------------

/** Banned generic-encouragement phrases (R4, L1-7). */
export const BANNED_PHRASES: readonly string[] = [
  "great job",
  "you got this",
  "keep it up",
  "you're crushing it",
  "way to go",
  "nice work",
  "awesome job",
  "proud of you",
  "you're doing great",
  "fantastic work",
  "good for you",
  "well done",
  "good job",
  "amazing job",
  "keep going",
  "hang in there",
];

/** Data-token keywords (R5, L1-8): a narrative passes if it contains a
 * number OR one of these — tied to a concrete plan datum. */
export const DATA_KEYWORDS: readonly string[] = [
  "goal",
  "days a week",
  "days/week",
  "session",
  "sets",
  "reps",
  "rpe",
  "week",
];

/** Emoji character-class (Unicode ranges), reused by the sanitizer + guardrail. */
const EMOJI_RE =
  /[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+/gu;

/** Context the guardrail needs to detect packet-number contradictions. */
export interface GuardrailContext {
  goal: string;
  daysPerWord: string;
  daysPerWeek: number;
  effectiveEquipment: string[];
  dayCount: number;
  exerciseCount: number;
  goalCopy: { headline: string; reasoning: string; cue: string };
}

export function buildGuardrailContext(req: NarrateRequest): GuardrailContext {
  return {
    goal: req.goal,
    daysPerWord: _daysWord(req.daysPerWeek),
    daysPerWeek: req.daysPerWeek,
    effectiveEquipment: req.effectiveEquipment,
    dayCount: req.days.length,
    exerciseCount: req.days.reduce((n, d) => n + d.exercises.length, 0),
    goalCopy: _goalCopy(req.goal),
  };
}

/** Word count (whitespace-delimited; 0 for empty/whitespace-only). */
export function wordCount(s: string): number {
  const t = s.trim();
  return t.length === 0 ? 0 : t.split(/\s+/).length;
}

/** Emoji count (number of matched emoji runs). */
export function emojiCount(s: string): number {
  const m = s.match(EMOJI_RE);
  return m ? m.length : 0;
}

/** Question-mark count. */
export function questionCount(s: string): number {
  return (s.match(/\?/g) || []).length;
}

/** Whether the text contains a banned generic-encouragement phrase (R4). */
export function hasBannedPhrase(s: string): boolean {
  const lower = s.toLowerCase();
  return BANNED_PHRASES.some((p) => lower.includes(p.toLowerCase()));
}

/** Whether the text references >=1 concrete data token: a digit or a
 * plan-bound keyword (goal / schedule / session / sets / reps / rpe). */
export function hasDataToken(s: string): boolean {
  if (/\d/.test(s)) return true;
  const lower = s.toLowerCase();
  return DATA_KEYWORDS.some((k) => lower.includes(k.toLowerCase()));
}

/** Strip all emoji runs (R3). */
export function stripEmoji(s: string): string {
  return s.replace(EMOJI_RE, "").replace(/\s+/g, " ").trim();
}

/** Strip banned generic-encouragement phrases (R4). Case-insensitive,
 * cleans up leftover whitespace/punctuation from removal. */
export function stripBannedPhrases(s: string): string {
  let out = s;
  for (const p of BANNED_PHRASES) {
    out = out.replace(
      new RegExp(p.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "gi"),
      "",
    );
  }
  return out.replace(/\s{2,}/g, " ").replace(/^\s*,\s*/, "").replace(
    /,\s*$/,
    "",
  ).trim();
}

/** Reduce question marks to at most one (R8) — keeps the first. */
export function stripExcessQuestions(s: string): string {
  let seen = 0;
  return s.replace(/\?/g, (m) => {
    seen += 1;
    return seen === 1 ? m : "";
  });
}

/** Truncate to at most `maxWords` words (R2). Cuts on a word boundary and
 * appends an ellipsis only if truncation happened. */
export function truncateWords(s: string, maxWords: number): string {
  const words = s.trim().split(/\s+/);
  if (words.length <= maxWords) return s.trim();
  const trimmed = words.slice(0, maxWords).join(" ");
  return trimmed.replace(/[,\s]+$/, "") + "…";
}

/** Detect a packet-number contradiction: the text names a cardinal day-count
 * (digit or English number word) that disagrees with the known plan
 * days/week. Returns a human-readable offending-field description, or null
 * when the quoted plan numbers are consistent with the packet. */
export function detectPacketContradiction(
  text: string,
  ctx: GuardrailContext,
): string | null {
  const lower = text.toLowerCase();
  const daysNum = ctx.daysPerWeek;

  // Match bare "N days" / "train(ing) N days" / "N-day" patterns that state
  // an absolute day count (distinct from "N days a week").
  const dayNumRe = new RegExp(`(\\d+)[\\s-]*days?(?:\\s*a\\s*week)?`, "gi");
  let m: RegExpExecArray | null;
  while ((m = dayNumRe.exec(lower)) !== null) {
    // Skip the canonical "N days a week" phrasing that matches our real value.
    const before = lower.slice(Math.max(0, m.index - 20), m.index);
    const after = lower.slice(
      m.index + m[0].length,
      m.index + m[0].length + 12,
    );
    if (/a(\s*week)?$/.test(after.trim())) {
      // "N days a week" — only contradictory if N != daysNum.
      const n = parseInt(m[1], 10);
      if (!Number.isNaN(n) && n !== daysNum) {
        return `daysPerWeek(claimed ${n} days a week, actual ${daysNum})`;
      }
      continue;
    }
    if (/\bweek\b/.test(after) || /\bweek\b/.test(before)) continue;
    const n = parseInt(m[1], 10);
    if (!Number.isNaN(n) && n !== daysNum) {
      return `daysPerWeek(claimed ${n} days, actual ${daysNum})`;
    }
  }

  // English number words (one..twelve) in "X days" patterns.
  const numWords: Record<string, number> = {
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
    eleven: 11,
    twelve: 12,
  };
  const wordRe = new RegExp(
    `\\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)[\\s-]*days?\\b`,
    "gi",
  );
  while ((m = wordRe.exec(lower)) !== null) {
    const after = lower.slice(
      m.index + m[0].length,
      m.index + m[0].length + 12,
    );
    if (/a(\s*week)?$/.test(after.trim())) {
      const claimed = numWords[m[1].toLowerCase()];
      if (claimed !== undefined && claimed !== daysNum) {
        return `daysPerWeek(claimed ${m[1]} days a week, actual ${daysNum})`;
      }
      continue;
    }
    const claimed = numWords[m[1].toLowerCase()];
    if (claimed !== undefined && claimed !== daysNum) {
      return `daysPerWeek(claimed ${m[1]} days, actual ${daysNum})`;
    }
  }
  return null;
}

/** Apply auto-correctable R2-R3-R4-R8 rules to a single text field. Order:
 * emoji (R3) → excess questions (R8) → banned phrases (R4) → word truncation
 * (R2, last so appended tokens stay inside the per-field budget). Note this
 * truncates the FIELD to 60 words; the composed-block R2 (<=60 words for the
 * joined headline+reasoning+coaching_cue) is enforced separately in
 * applyNarrativeGuardrail via truncateComposedBlock. */
export function applyFieldGuardrail(text: string): string {
  let t = text;
  t = stripEmoji(t);
  t = stripExcessQuestions(t);
  t = stripBannedPhrases(t);
  t = truncateWords(t, 60);
  return t;
}

/** Truncate the COMPOSED message block (headline + reasoning + coaching_cue
 * joined as a single string) to <=60 words. The harness message_rule_lint.py
 * applies R2 to the joined block, NOT per-field — so even when each field is
 * individually under 60 words, the joined block can exceed it (ONB-032).
 *
 * Strategy: iteratively remove one word from the MIDDLE of the LONGEST field,
 * re-join, and re-check until the composed block is within budget. We remove
 * from the middle (keeping the first ~half and last ~half words) rather than
 * truncating from the end so that trailing content — notably the echoed user
 * phrase appended to the deterministic reasoning — is preserved (R1 echo).
 * Truncating the longest field each round minimizes the number of fields
 * touched and preserves the most content overall. */
export function truncateComposedBlock(
  headline: string,
  reasoning: string,
  coaching_cue: string,
  maxWords = 60,
): { headline: string; reasoning: string; coaching_cue: string } {
  let h = headline;
  let r = reasoning;
  let c = coaching_cue;

  // Iteratively trim the longest field until the joined block fits.
  for (let guard = 0; guard < 500; guard++) {
    const block = [h, r, c].filter(Boolean).join(" ");
    if (wordCount(block) <= maxWords) break;

    // Find the longest field by word count and trim one word from its middle.
    const fields: Array<[number, () => string, (v: string) => void]> = [
      [wordCount(h), () => h, (v: string) => h = v],
      [wordCount(r), () => r, (v: string) => r = v],
      [wordCount(c), () => c, (v: string) => c = v],
    ];
    fields.sort((a, b) => b[0] - a[0]);
    const [, get, set] = fields[0];
    const current = get();
    const currentWc = wordCount(current.replace(/…$/, ""));
    if (currentWc <= 1) {
      // Can't trim further without emptying; empty it to guarantee termination.
      set("");
    } else {
      // Remove one word from the middle (keep first ~half + last ~half).
      const words = current.replace(/…$/, "").split(/\s+/);
      const mid = Math.floor(words.length / 2);
      words.splice(mid, 1);
      set(words.join(" "));
    }
  }

  return { headline: h, reasoning: r, coaching_cue: c };
}

/** Run the full R1-R8 guardrail on a composed narrative. Auto-corrects each
 * field for R2/R3/R4/R8, then regenerates any field from the deterministic
 * template when (a) the text contradicts an immutable packet number, or (b)
 * the composed block has no data token (R5). Returns the corrected narrative
 * plus the list of corrections applied (for observability/tests). */
export function applyNarrativeGuardrail(
  n: PlanNarrative,
  req: NarrateRequest,
): { narrative: PlanNarrative; corrections: string[] } {
  const ctx = buildGuardrailContext(req);
  const corrections: string[] = [];

  let headline = applyFieldGuardrail(n.headline);
  let reasoning = applyFieldGuardrail(n.reasoning);
  let coaching_cue = applyFieldGuardrail(n.coaching_cue);
  if (headline !== n.headline) {
    corrections.push("headline: R2/R3/R4/R8 corrected");
  }
  if (reasoning !== n.reasoning) {
    corrections.push("reasoning: R2/R3/R4/R8 corrected");
  }
  if (coaching_cue !== n.coaching_cue) {
    corrections.push("coaching_cue: R2/R3/R4/R8 corrected");
  }

  // Packet-number contradiction — regenerate the offending field from the
  // deterministic template so we never ship a hallucinated number.
  const contradiction = detectPacketContradiction(
    `${headline} ${reasoning} ${coaching_cue}`,
    ctx,
  );
  if (contradiction) {
    reasoning = applyFieldGuardrail(
      `${ctx.goalCopy.reasoning} You're training ${ctx.daysPerWord} days a week.`,
    );
    corrections.push(
      `reasoning: regenerated (contradiction: ${contradiction})`,
    );
  }

  // Data-token requirement (R5) over the composed block.
  const block = [headline, reasoning, coaching_cue].filter(Boolean).join(" ");
  if (!hasDataToken(block)) {
    reasoning = applyFieldGuardrail(
      `${ctx.goalCopy.reasoning} You're training ${ctx.daysPerWord} days a week.`,
    );
    corrections.push("reasoning: regenerated (no data token / R5)");
  }

  // Narrative-level R8: the composed message block must have <=1 '?' total.
  // Per-field strip keeps the first '?' *per field*; if multiple fields each
  // retain one, the block total can still exceed the doctrine limit. Prune
  // trailing '?' from reasoning then coaching_cue until the composed block
  // carries at most one '?'. (Headlines in our templates never contain '?',
  // so this is ordinarily a no-op — added because R8 is per-message-block, not
  // per-field, and LLM output is not constrained by our template patterns.)
  let r8Repaired = false;
  const r8Block = () =>
    questionCount(`${headline} ${reasoning} ${coaching_cue}`);
  if (r8Block() > 1) {
    coaching_cue = _dropExcessFromField(coaching_cue, 0);
  }
  if (r8Block() > 1) {
    reasoning = _dropExcessFromField(reasoning, 0);
  }
  if (r8Block() > 1) {
    // Last-resort: drop '?' from the headline too (should be rare).
    headline = _dropExcessFromField(headline, 1);
    r8Repaired = true;
  }
  if (r8Repaired) {
    corrections.push("narrative: R8 trimmed to <=1 '?' across message block");
  }

  // Composed-block R2: the harness message_rule_lint.py applies R2 to the
  // JOINED block (headline + reasoning + coaching_cue), not per-field. After
  // per-field cleaning, the joined block can still exceed 60 words — truncate
  // the longest field iteratively until the composed block fits (ONB-032 fix).
  const before = [headline, reasoning, coaching_cue].filter(Boolean).join(" ");
  const trimmed = truncateComposedBlock(headline, reasoning, coaching_cue);
  if (
    trimmed.headline !== headline || trimmed.reasoning !== reasoning ||
    trimmed.coaching_cue !== coaching_cue
  ) {
    const after = [trimmed.headline, trimmed.reasoning, trimmed.coaching_cue]
      .filter(Boolean).join(
        " ",
      );
    corrections.push(
      `narrative: R2 composed-block truncated from ${wordCount(before)} to ${
        wordCount(after)
      } words`,
    );
  }
  headline = trimmed.headline;
  reasoning = trimmed.reasoning;
  coaching_cue = trimmed.coaching_cue;

  return {
    narrative: {
      headline,
      reasoning,
      changes_made: n.changes_made,
      coaching_cue,
      model_used: n.model_used,
      is_fallback: n.is_fallback,
    },
    corrections,
  };
}

/** Drop all '?' characters from a field text (used by the narrative-level R8
 * trim when trailing fields must contribute zero '?'). */
function _dropExcessFromField(text: string, keep: number): string {
  let seen = 0;
  return text.replace(/\?/g, (m) => {
    seen += 1;
    return seen <= keep ? m : "";
  });
}

/** Truncate a composed block text so it contains at most one '?', keeping the
 * first occurrence. */
function _truncateQuestionsToOne(text: string): string {
  let seen = 0;
  return text.replace(/\?/g, (m) => {
    seen += 1;
    return seen === 1 ? m : "";
  });
}

// ---------------------------------------------------------------------------
// Deterministic fallback (NEVER a silent one-size template)
// ---------------------------------------------------------------------------

const _GOAL_COPY: Record<
  string,
  { headline: string; reasoning: string; cue: string }
> = {
  build_muscle: {
    headline: "Built to grow — your muscle-first plan is ready.",
    reasoning:
      "This plan prioritizes the rep ranges and volume that drive hypertrophy, spread across your available days so each muscle group gets work and recovery.",
    cue:
      "Track your sets. Small reps-in-reserve wins this week add up to visible change.",
  },
  build_strength: {
    headline: "Strength is your base — here's how we build it.",
    reasoning:
      "Lower reps, heavier loads, and enough rest between sets to let your nervous system recover. Every session moves the bar toward a new level.",
    cue:
      "Warm up with intent. The first set should feel easy — the last set should feel earned.",
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
    cue:
      "Breathe into each rep. If a range feels tight, stay there a beat longer.",
  },
  train_for_sport: {
    headline: "Sport-ready — your athletic base is loading.",
    reasoning:
      "Power-endurance work in the rep ranges that transfer to the field. We build work capacity without drowning you in volume.",
    cue:
      "Explosive on the lift, controlled on the return. That's the rhythm that carries over.",
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
  const readable = eq.filter((e) => e !== "bodyweight").map((e) =>
    e.replace(/_/g, " ")
  );
  if (readable.length === 0) return "just your bodyweight";
  if (readable.length === 1) return readable[0];
  return `${readable.slice(0, -1).join(", ")} and ${
    readable[readable.length - 1]
  }`;
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
  const saneHeadline = "headline" in c
    ? c.headline
    : (c as { headline: string }).headline;
  const saneCue = "cue" in c ? c.cue : (c as { cues: string }).cues;

  const phraseClause = req.userPhrase && req.userPhrase.trim().length > 0
    ? ` You told me "${
      sanitizeUserPhrase(req.userPhrase)
    }" — that's the through-line here.`
    : "";

  const composed: PlanNarrative = {
    headline: saneHeadline,
    reasoning:
      `${c.reasoning} You're training ${days} days a week as a ${exp} with access to ${eq}.${phraseClause}`,
    changes_made: [
      `Plan built for ${req.goal} goal`,
      `${req.daysPerWeek} sessions/week`,
    ],
    coaching_cue: saneCue,
    model_used: "deterministic",
    is_fallback: true,
  };

  // Run the R1-R8 guardrail so the deterministic fallback obeys every
  // message rule — currently the reasoning exceeds 60 words on common
  // goal/equip/phrase combos (ONB-032) and could echo a user '?' (ONB-036).
  return applyNarrativeGuardrail(composed, req).narrative;
}

/** Strip emoji + markup + question marks from a user phrase before echoing
 * it into coach copy (R8 at the input layer: a user-supplied '?' must not be
 * echoed back as an extra question mark — ONB-036). */
export function sanitizeUserPhrase(raw: string): string {
  // Remove emoji/symbol ranges, collapse whitespace, strip HTML-ish markup,
  // and strip question marks.
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
  // Strip question marks (R8 input sanitizer).
  return noEmoji.replace(/\?/g, "").replace(/\s+/g, " ").trim();
}

// ---------------------------------------------------------------------------
// LLM call
// ---------------------------------------------------------------------------

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

/** Build the prompt for the narration LLM. */
function buildNarratePrompt(
  req: NarrateRequest,
): { system: string; user: string } {
  const planJson = JSON.stringify(
    {
      goal: req.goal,
      daysPerWeek: req.daysPerWeek,
      experienceLevel: req.experienceLevel,
      effectiveEquipment: req.effectiveEquipment,
      days: req.days,
    },
    null,
    2,
  );
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
    req.userPhrase
      ? `The user's own "why now" phrase (sanitize if it contains emoji/markup): "${req.userPhrase}"`
      : "No user phrase supplied.",
    "",
    "Write the plan-reveal narrative.",
  ].join("\n");

  return { system, user };
}

/** Parse the LLM content into a PlanNarrative, or null on any failure.
 * Runs the full R1-R8 guardrail on the parsed text fields so the
 * LLM-success path is held to the same doctrine standard as the deterministic
 * fallback (originally parseNarrative only trimmed — that was the gap). */
export function parseNarrative(
  content: string,
  req: NarrateRequest,
): PlanNarrative | null {
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
  const coaching_cue = typeof o.coaching_cue === "string"
    ? o.coaching_cue.trim()
    : "";
  const changes = Array.isArray(o.changes_made)
    ? o.changes_made.filter((x): x is string => typeof x === "string")
    : [];
  if (!headline || !reasoning || !coaching_cue) return null;
  const raw: PlanNarrative = {
    headline,
    reasoning,
    changes_made: changes,
    coaching_cue,
    model_used: "", // filled in by caller with the real model name
    is_fallback: false,
  };
  return applyNarrativeGuardrail(raw, req).narrative;
}

// ---------------------------------------------------------------------------
// Local Ollama narration (primary path when OLLAMA_HOST is set)
// ---------------------------------------------------------------------------

/** Try local Ollama for narration. Returns parsed narrative or null (→ caller
 * falls back to OpenRouter, then deterministic). Uses /api/chat so the system
 * prompt is passed properly. Timeout is 30s — coaching must not stall onboarding. */
async function narrateViaOllama(
  req: NarrateRequest,
): Promise<PlanNarrative | null> {
  if (!OLLAMA_HOST) return null;

  const { system, user } = buildNarratePrompt(req);

  let resp: Response;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 30000);
    resp = await fetch(`${OLLAMA_HOST}/api/chat`, {
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
  } catch {
    return null; // timeout or connection refused → fallback
  }

  if (!resp.ok) return null;

  let json: unknown;
  try {
    json = await resp.json();
  } catch {
    return null;
  }

  // Ollama /api/chat shape: { message: { content: "..." } }
  const body = json as { message?: { content?: string } };
  const content = body.message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    return null;
  }

  const parsed = parseNarrative(content, req);
  if (!parsed) return null;
  parsed.model_used = `ollama:${OLLAMA_MODEL}`;
  return parsed;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Narrate a deterministic training plan.
 *
 * Tries (in order):
 *   1. Local Ollama (ornith:35b) when OLLAMA_HOST is set — zero cost, LAN-fast.
 *   2. OpenRouter (z-ai/glm-5.1) via server-side key, response_format: json_object.
 *   3. Deterministic narrative (flagged is_fallback:true).
 *
 * On ANY failure at any tier, falls through to the next. Never throws.
 * Never returns 501. The deterministic engine numbers are immutable; the
 * LLM (local or cloud) only writes narrative.
 *
 * @param req The deterministic plan + options.
 * @returns A PlanNarrative; check `is_fallback` and `model_used` for the source.
 */
export async function narratePlan(req: NarrateRequest): Promise<PlanNarrative> {
  // 1. Try local Ollama first (zero cost, low latency on LAN).
  if (OLLAMA_HOST) {
    const local = await narrateViaOllama(req);
    if (local) return local;
    // Local failed → fall through to OpenRouter.
  }

  const apiKey = (Deno.env.get("OPENROUTER_API_KEY") ?? "").trim();
  const model = (Deno.env.get("OPENROUTER_MODEL") ?? DEFAULT_MODEL).trim() ||
    DEFAULT_MODEL;

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

  const parsed = parseNarrative(content, req);
  if (!parsed) {
    return deterministicNarrative(req);
  }
  parsed.model_used = model;
  return parsed;
}
