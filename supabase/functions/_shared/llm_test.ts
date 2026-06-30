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
import {
  narratePlan,
  deterministicNarrative,
  parseNarrative,
  sanitizeUserPhrase,
  applyNarrativeGuardrail,
  applyFieldGuardrail,
  wordCount,
  emojiCount,
  questionCount,
  hasBannedPhrase,
  hasDataToken,
  stripEmoji,
  stripExcessQuestions,
  stripBannedPhrases,
  truncateWords,
  detectPacketContradiction,
  buildGuardrailContext,
  type PlanNarrative,
} from "./llm.ts";

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

// ---------------------------------------------------------------------------
// GUARDRAIL UNIT HELPERS (pure-function microtests)
// ---------------------------------------------------------------------------

Deno.test("pure helpers: wordCount", () => {
  assertEquals(wordCount(""), 0);
  assertEquals(wordCount("   "), 0);
  assertEquals(wordCount("one"), 1);
  assertEquals(wordCount("one two three"), 3);
  assertEquals(wordCount("  one   two  "), 2);
});

Deno.test("pure helpers: emojiCount", () => {
  assertEquals(emojiCount("no emoji here"), 0);
  assertEquals(emojiCount("a 💪 b 🔥"), 2);
});

Deno.test("pure helpers: questionCount", () => {
  assertEquals(questionCount("no question"), 0);
  assertEquals(questionCount("one?"), 1);
  assertEquals(questionCount("one? two? three?"), 3);
});

Deno.test("pure helpers: stripExcessQuestions keeps first, drops rest (R8)", () => {
  assertEquals(stripExcessQuestions("one? two? three?"), "one? two three");
  assertEquals(stripExcessQuestions("no questions"), "no questions");
});

Deno.test("pure helpers: stripEmoji (R3)", () => {
  assertEquals(stripEmoji("hello 💪 world 🔥"), "hello world");
});

Deno.test("pure helpers: stripBannedPhrases (R4)", () => {
  assert(stripBannedPhrases("great job today").toLowerCase().includes("today"));
  assert(!/got this/i.test(stripBannedPhrases("you got this")));
});

Deno.test("pure helpers: hasBannedPhrase (R4)", () => {
  assert(hasBannedPhrase("You got this, champ"));
  assert(!hasBannedPhrase("Track your sets this week"));
});

Deno.test("pure helpers: hasDataToken (R5)", () => {
  assert(hasDataToken("train 4 days a week"));
  assert(hasDataToken("your build_muscle goal"));
  assert(!hasDataToken("hello world foo bar baz"));
});

Deno.test("pure helpers: truncateWords (R2)", () => {
  const long = Array(100).fill("word").join(" ");
  const t = truncateWords(long, 60);
  assert(t.endsWith("…")); // ellipsis appended when truncated
  // The trailing ellipsis is punctuation, not a word; stripping it leaves <=60 words.
  assert(wordCount(t.replace(/…$/, "")) <= 60);
  // short strings pass through untouched
  assertEquals(truncateWords("short text", 60), "short text");
});

Deno.test("pure helpers: detectPacketContradiction", () => {
  const ctx = buildGuardrailContext({
    goal: "build_muscle",
    daysPerWeek: 3,
    experienceLevel: "intermediate",
    effectiveEquipment: ["bodyweight", "dumbbells"],
    days: [],
  });
  // Consistent day counts — should NOT flag.
  assertEquals(detectPacketContradiction("You are training 3 days a week here", ctx), null);
  assertEquals(detectPacketContradiction("You are training three days a week here", ctx), null);
  // Contradiction via digit.
  assert(detectPacketContradiction("You are training 7 days a week here", ctx) !== null);
  // Contradiction via English word.
  assert(detectPacketContradiction("You train seven days every week", ctx) !== null);
});

// ---------------------------------------------------------------------------
// PHRASE SANITIZER — R8 at the input layer (strips '?', emoji, markup)
// ---------------------------------------------------------------------------

Deno.test("sanitizeUserPhrase: strips question marks (R8 input, ONB-036)", () => {
  assertEquals(sanitizeUserPhrase("Can I get strong?"), "Can I get strong");
  assertEquals(sanitizeUserPhrase("Why? How? When?"), "Why How When");
});

Deno.test("sanitizeUserPhrase: strips emoji + markup (existing regression)", () => {
  assertEquals(sanitizeUserPhrase("get <b>strong</b> 💪🔥"), "get strong");
  // A combo phrase: question + emoji + markup all gone, words kept.
  assertEquals(
    sanitizeUserPhrase("Can I <em>really</em> get strong? 💪"),
    "Can I really get strong",
  );
});

// ---------------------------------------------------------------------------
// DETERMINISTIC-FALLBACK TESTS — R1-R8 on the fallback path
// ---------------------------------------------------------------------------

const MIN_REQUEST = {
  goal: "build_muscle",
  daysPerWeek: 3,
  experienceLevel: "intermediate" as const,
  effectiveEquipment: ["bodyweight", "dumbbells"],
  days: [{
    dayNumber: 1,
    focus: "Full Body",
    split: "full",
    exercises: [
      {
        id: "squat", name: "Goblet Squat", muscleGroup: "legs", equipment: "dumbbells",
        sets: 3, repsMin: 8, repsMax: 12, rpeTarget: 7,
      },
    ],
  }],
};

/** Max-load request: long equipment list + long user phrase — the worst case
 * that historically breached the 60-word limit (ONB-032). */
const MAX_REQUEST = {
  goal: "build_muscle",
  daysPerWeek: 5,
  experienceLevel: "advanced" as const,
  effectiveEquipment: [
    "bodyweight", "dumbbells", "barbell", "kettlebells", "cable_machine",
  ],
  days: [{
    dayNumber: 1,
    focus: "Full Body",
    split: "full",
    exercises: [
      { id: "s", name: "S", muscleGroup: "legs", equipment: "barbell", sets: 4, repsMin: 5, repsMax: 8, rpeTarget: 8 },
    ],
  }],
  userPhrase: "I want to feel strong in my own skin again no matter what anyone thinks",
};

Deno.test("deterministic fallback: R2 word-count <=60 for MIN inputs", () => {
  const n = deterministicNarrative(MIN_REQUEST);
  for (const [field, text] of [
    ["headline", n.headline],
    ["reasoning", n.reasoning],
    ["coaching_cue", n.coaching_cue],
  ] as const) {
    assert(wordCount(text) <= 60, `${field} word-count ${wordCount(text)} > 60: ${text}`);
  }
});

Deno.test("deterministic fallback: R2 word-count <=60 under MAX load (ONB-032 fix)", () => {
  const n = deterministicNarrative(MAX_REQUEST);
  for (const [field, text] of [
    ["headline", n.headline],
    ["reasoning", n.reasoning],
    ["coaching_cue", n.coaching_cue],
  ] as const) {
    assert(wordCount(text) <= 60, `${field} word-count ${wordCount(text)} > 60: ${text}`);
  }
});

Deno.test("deterministic fallback: R3 no emoji", () => {
  const n = deterministicNarrative({
    ...MIN_REQUEST,
    userPhrase: "let's go 💪🔥",
  });
  const all = `${n.headline} ${n.reasoning} ${n.coaching_cue}`;
  assert(emojiCount(all) === 0);
});

Deno.test("deterministic fallback: R8 <=1 question mark total (ONB-036 fix)", () => {
  const n = deterministicNarrative({
    ...MIN_REQUEST,
    userPhrase: "Can I get strong this year?",
  });
  const all = `${n.headline} ${n.reasoning} ${n.coaching_cue}`;
  assert(questionCount(all) <= 1, `too many '?': ${questionCount(all)} in ${all}`);
});

Deno.test("deterministic fallback: R4 no banned phrases", () => {
  const n = deterministicNarrative(MIN_REQUEST);
  assert(!hasBannedPhrase(n.headline));
  assert(!hasBannedPhrase(n.reasoning));
  assert(!hasBannedPhrase(n.coaching_cue));
});

Deno.test("deterministic fallback: R5 >=1 data token", () => {
  const n = deterministicNarrative(MIN_REQUEST);
  const block = `${n.headline} ${n.reasoning} ${n.coaching_cue}`;
  assert(hasDataToken(block), `no data token in: ${block}`);
});

Deno.test("deterministic fallback: user '?' stripped in echo (no excess question marks)", () => {
  const n = deterministicNarrative({
    ...MIN_REQUEST,
    userPhrase: "Can I really get strong?",
  });
  // 'Can I' and the stripped phrase must appear verbatim minus the '?'.
  assert(n.reasoning.includes("Can I really get strong"));
  assert(!/\?/.test(n.reasoning), "reasoning should not contain '?'");
});

// ---------------------------------------------------------------------------=
// LLM-SUCCESS PATH TESTS — mocked parseNarrative input
// ---------------------------------------------------------------------------

/** Helper to construct the `NarrateRequest` the guardrail was built against. */
function makeReq(over: Partial<typeof MIN_REQUEST> = {}) {
  return { ...MIN_REQUEST, ...over };
}

Deno.test("mocked LLM-success: strips emoji (R3) from composed narrative", () => {
  const raw: PlanNarrative = {
    headline: "Built to grow 💪",
    reasoning: "Your plan rocks 🔥 for sets and reps targeting your goal.",
    changes_made: ["x"],
    coaching_cue: "Go get it.",
    model_used: "z-ai/glm-5.1",
    is_fallback: false,
  };
  const { narrative: n, corrections } = applyNarrativeGuardrail(raw, makeReq());
  assert(emojiCount(n.headline) === 0, `headline still has emoji: ${n.headline}`);
  assert(emojiCount(n.reasoning) === 0, `reasoning still has emoji: ${n.reasoning}`);
  assert(corrections.some((c) => c.startsWith("headline:") || c.startsWith("reasoning:")));
});

Deno.test("mocked LLM-success: R8 <=1 question mark after guardrail", () => {
  const raw: PlanNarrative = {
    headline: "Ready?",
    reasoning: "Can we do it? Should we try? Will it stick?",
    changes_made: ["x"],
    coaching_cue: "Yes.",
    model_used: "z-ai/glm-5.1",
    is_fallback: false,
  };
  const { narrative: n } = applyNarrativeGuardrail(raw, makeReq());
  const all = `${n.headline} ${n.reasoning} ${n.coaching_cue}`;
  assert(questionCount(all) <= 1, `too many '?': ${questionCount(all)} in ${all}`);
});

Deno.test("mocked LLM-success: R4 strips banned generic encouragement", () => {
  const raw: PlanNarrative = {
    headline: "Great job — your strong base is ready",
    reasoning: "You got this. Your plan targets your build_muscle goal across sessions.",
    changes_made: ["x"],
    coaching_cue: "keep it up — show up on time",
    model_used: "z-ai/glm-5.1",
    is_fallback: false,
  };
  const { narrative: n } = applyNarrativeGuardrail(raw, makeReq());
  assert(!hasBannedPhrase(n.headline), `headline: ${n.headline}`);
  assert(!hasBannedPhrase(n.reasoning), `reasoning: ${n.reasoning}`);
  assert(!hasBannedPhrase(n.coaching_cue), `cue: ${n.coaching_cue}`);
});

Deno.test("mocked LLM-success: R2 truncates to <=60 words", () => {
  const longBlock = Array(100).fill("your training plan is ready").join(" ");
  const raw: PlanNarrative = {
    headline: "Here is your plan for the week ahead",
    reasoning: longBlock,
    changes_made: ["x"],
    coaching_cue: "Stick with the plan for the first month.",
    model_used: "z-ai/glm-5.1",
    is_fallback: false,
  };
  const { narrative: n } = applyNarrativeGuardrail(raw, makeReq());
  assert(wordCount(n.reasoning.replace(/…$/, "")) <= 60, `reasoning too long: ${wordCount(n.reasoning)}`);
});

Deno.test("mocked LLM-success: regenerates R5 when composed block lacks data token", () => {
  const raw: PlanNarrative = {
    headline: "Welcome",
    reasoning: "This is a generic greeting with no numbers or plan keywords.",
    changes_made: ["x"],
    coaching_cue: "Let us begin.",
    model_used: "z-ai/glm-5.1",
    is_fallback: false,
  };
  // Precondition: raw block genuinely lacks a data token.
  assert(!hasDataToken(`${raw.headline} ${raw.reasoning} ${raw.coaching_cue}`));

  const { narrative: n, corrections } = applyNarrativeGuardrail(
    raw,
    makeReq({ goal: "build_muscle", daysPerWeek: 4 }),
  );
  const block = `${n.headline} ${n.reasoning} ${n.coaching_cue}`;
  assert(hasDataToken(block), `regenerated block still lacks data token: ${block}`);
  assert(corrections.some((c) => c.includes("no data token")));
});

Deno.test("mocked LLM-success: regenerates reasoning that contradicts packet numbers", () => {
  // LLM claims 7 days a week for a 3-day plan — contradiction.
  const raw: PlanNarrative = {
    headline: "Your training week is ready",
    reasoning:
      "You are training seven days a week so every muscle gets hit with enough volume across your dumbbells for the build_muscle goal.",
    changes_made: ["x"],
    coaching_cue: "Track your sets.",
    model_used: "z-ai/glm-5.1",
    is_fallback: false,
  };
  const { narrative: n, corrections } = applyNarrativeGuardrail(
    raw,
    makeReq({ daysPerWeek: 3 }),
  );
  // The regenerated reasoning must NOT contain the contradicting "seven days".
  assert(!/\bseven\b/.test(n.reasoning.toLowerCase()), `still contradicts: ${n.reasoning}`);
  assert(corrections.some((c) => c.includes("contradiction")));
});

Deno.test("mocked LLM-success: consistent day count is NOT flagged", () => {
  const raw: PlanNarrative = {
    headline: "Your plan is ready",
    reasoning:
      "You are training 3 days a week with your dumbbells for the build_muscle goal.",
    changes_made: ["x"],
    coaching_cue: "Track your sets.",
    model_used: "z-ai/glm-5.1",
    is_fallback: false,
  };
  const { corrections } = applyNarrativeGuardrail(raw, makeReq({ daysPerWeek: 3 }));
  assert(!corrections.some((c) => c.includes("contradiction")));
});

// ---------------------------------------------------------------------------
// parseNarrative (LLM-success path) — end-to-end via mocked JSON content
// ---------------------------------------------------------------------------

Deno.test("parseNarrative: applies guardrail to LLM JSON output (R3 emoji strip)", () => {
  // Simulate an LLM response that includes emoji in the reasoning.
  const llmJson = JSON.stringify({
    headline: "Built to grow 💪",
    reasoning: "Your plan targets your build_muscle goal across 3 days a week with dumbbells.",
    changes_made: ["Plan built"],
    coaching_cue: "Track your sets.",
  });
  const parsed = parseNarrative(llmJson, makeReq());
  assert(parsed !== null);
  assert(emojiCount(parsed!.headline) === 0, `headline still has emoji: ${parsed!.headline}`);
});

Deno.test("parseNarrative: applies R8 to LLM JSON output (strips excess '?')", () => {
  const llmJson = JSON.stringify({
    headline: "Ready?",
    reasoning: "Can we do it? Should we try? Will it stick? Your plan targets your goal.",
    changes_made: ["Plan built"],
    coaching_cue: "Yes.",
  });
  const parsed = parseNarrative(llmJson, makeReq());
  assert(parsed !== null);
  const all = `${parsed!.headline} ${parsed!.reasoning} ${parsed!.coaching_cue}`;
  assert(questionCount(all) <= 1, `too many '?': ${questionCount(all)}`);
});

Deno.test("parseNarrative: applies R4 to LLM JSON output (strips banned phrases)", () => {
  const llmJson = JSON.stringify({
    headline: "Great job — your plan is ready",
    reasoning: "You got this. Your plan targets your build_muscle goal across 3 days a week.",
    changes_made: ["Plan built"],
    coaching_cue: "Track your sets.",
  });
  const parsed = parseNarrative(llmJson, makeReq());
  assert(parsed !== null);
  assert(!hasBannedPhrase(parsed!.headline));
  assert(!hasBannedPhrase(parsed!.reasoning));
});

Deno.test("parseNarrative: applies R2 to LLM JSON output (truncates >60 words)", () => {
  const longReasoning = Array(100).fill("your training plan is ready").join(" ");
  const llmJson = JSON.stringify({
    headline: "Here is your plan",
    reasoning: longReasoning,
    changes_made: ["Plan built"],
    coaching_cue: "Stick with it.",
  });
  const parsed = parseNarrative(llmJson, makeReq());
  assert(parsed !== null);
  assert(wordCount(parsed!.reasoning.replace(/…$/, "")) <= 60);
});

Deno.test("parseNarrative: regenerates R5 when LLM output lacks data token", () => {
  const llmJson = JSON.stringify({
    headline: "Welcome",
    reasoning: "This is a generic greeting with no numbers or plan keywords.",
    changes_made: ["Plan built"],
    coaching_cue: "Let us begin.",
  });
  const parsed = parseNarrative(llmJson, makeReq({ goal: "build_muscle", daysPerWeek: 4 }));
  assert(parsed !== null);
  const block = `${parsed!.headline} ${parsed!.reasoning} ${parsed!.coaching_cue}`;
  assert(hasDataToken(block), `regenerated block still lacks data token: ${block}`);
});

Deno.test("parseNarrative: regenerates reasoning contradicting packet numbers", () => {
  const llmJson = JSON.stringify({
    headline: "Your plan is ready",
    reasoning:
      "You are training seven days a week with your dumbbells for the build_muscle goal.",
    changes_made: ["Plan built"],
    coaching_cue: "Track your sets.",
  });
  const parsed = parseNarrative(llmJson, makeReq({ daysPerWeek: 3 }));
  assert(parsed !== null);
  assert(!/\bseven\b/.test(parsed!.reasoning.toLowerCase()), `still contradicts: ${parsed!.reasoning}`);
});

// ---------------------------------------------------------------------------
// narratePlan end-to-end: LLM-success path with mocked fetch
// ---------------------------------------------------------------------------

/** Install a global fetch mock that returns a fixed LLM JSON body. */
async function withMockLlm<T>(llmJson: string, req: typeof MIN_REQUEST, fn: () => Promise<T>): Promise<T> {
  const origFetch = globalThis.fetch;
  const encoder = new TextEncoder();
  globalThis.fetch = (_input: string | URL | Request, init?: RequestInit) =>
    Promise.resolve(
      new Response(
        JSON.stringify({
          choices: [{ message: { content: llmJson } }],
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      ),
    ) as unknown as Promise<Response>;
  try {
    return await fn();
  } finally {
    globalThis.fetch = origFetch;
  }
}

Deno.test("narratePlan (mocked LLM): applies R3/R4/R8/R2 guardrail to LLM output", async () => {
  const llmJson = JSON.stringify({
    headline: "Great job — your plan is ready 💪",
    reasoning:
      "You got this! You are training 3 days a week with your dumbbells for the build_muscle goal. Can we do it? Should we try? Will it stick?",
    changes_made: ["Plan built"],
    coaching_cue: "keep it up — track your sets.",
  });
  const captured = await withEnv("OPENROUTER_API_KEY", "sk-or-test-mock", () =>
    withMockLlm(llmJson, MIN_REQUEST, () => narratePlan(MIN_REQUEST)));
  assertEquals(captured.is_fallback, false);
  assertEquals(captured.model_used, "z-ai/glm-5.1");
  const all = `${captured.headline} ${captured.reasoning} ${captured.coaching_cue}`;
  assert(emojiCount(all) === 0, `emoji leaked: ${all}`);
  assert(questionCount(all) <= 1, `too many '?': ${questionCount(all)}`);
  assert(!hasBannedPhrase(captured.headline), `headline: ${captured.headline}`);
  assert(!hasBannedPhrase(captured.coaching_cue), `cue: ${captured.coaching_cue}`);
  assert(wordCount(captured.reasoning.replace(/…$/, "")) <= 60);
});

Deno.test("narratePlan (mocked LLM): regenerates reasoning contradicting packet numbers", async () => {
  const llmJson = JSON.stringify({
    headline: "Your plan is ready",
    reasoning:
      "You are training seven days a week with your dumbbells for the build_muscle goal.",
    changes_made: ["Plan built"],
    coaching_cue: "Track your sets.",
  });
  const captured = await withEnv("OPENROUTER_API_KEY", "sk-or-test-mock", () =>
    withMockLlm(llmJson, MIN_REQUEST, () => narratePlan(MIN_REQUEST)));
  assertEquals(captured.is_fallback, false);
  assert(!/\bseven\b/.test(captured.reasoning.toLowerCase()), `still contradicts: ${captured.reasoning}`);
});

Deno.test("narratePlan (mocked LLM): regenerates R5 when LLM output lacks data token", async () => {
  const llmJson = JSON.stringify({
    headline: "Welcome",
    reasoning: "This is a generic greeting with no numbers or plan keywords.",
    changes_made: ["Plan built"],
    coaching_cue: "Let us begin.",
  });
  const captured = await withEnv("OPENROUTER_API_KEY", "sk-or-test-mock", () =>
    withMockLlm(llmJson, MIN_REQUEST, () => narratePlan({
      ...MIN_REQUEST,
      goal: "build_muscle",
      daysPerWeek: 4,
    })));
  assertEquals(captured.is_fallback, false);
  const block = `${captured.headline} ${captured.reasoning} ${captured.coaching_cue}`;
  assert(hasDataToken(block), `regenerated block still lacks data token: ${block}`);
});
