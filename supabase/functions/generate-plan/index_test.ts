// Unit tests for the generate-plan edge function.
//
// Run: deno test --allow-all supabase/functions/generate-plan/index_test.ts
//
// generate-plan takes deterministic plan intake, runs the Deno plan-generation
// engine, narrates via _shared/llm.ts (or returns a deterministic fallback
// flagged is_fallback:true / model_used:"deterministic" on LLM failure), and
// ALWAYS returns 200 with a complete plan packet (never 501/empty). The acting
// user is resolved from the JWT ONLY; any caller-supplied user_id is ignored.
import { assert, assertEquals, assertNotEquals } from "jsr:@std/assert";
import { handler, type GeneratePlanResponse } from "./index.ts";

// --- helpers ---------------------------------------------------------------

const TEST_JWT_SECRET = "transformfit-test-jwt-secret";
Deno.env.set("SUPABASE_JWT_SECRET", TEST_JWT_SECRET);
Deno.env.set("SUPABASE_JWT_ISSUER", "supabase");
Deno.env.set("SUPABASE_JWT_AUDIENCE", "authenticated");

function enc(obj: unknown): string {
  return btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function encBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function makeJwt(payload: Record<string, unknown>): Promise<string> {
  const signingInput = `${enc({ alg: "HS256", typ: "JWT" })}.${enc({
    exp: Math.floor(Date.now() / 1000) + 3600,
    iss: "supabase",
    aud: "authenticated",
    ...payload,
  })}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(TEST_JWT_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(signingInput),
  ));
  return `${signingInput}.${encBytes(sig)}`;
}

function authedReq(token: string, body: unknown): Request {
  return new Request("https://zuwtgdqsxmtiqojckpus.functions.supabase.co/generate-plan", {
    method: "POST",
    headers: {
      "authorization": `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

function anonReq(body: unknown): Request {
  return new Request("https://zuwtgdqsxmtiqojckpus.functions.supabase.co/generate-plan", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

const VALID_BODY = {
  goal: "build_muscle",
  daysPerWeek: 3,
  equipment: ["dumbbells", "pull_up_bar"],
  experienceLevel: "intermediate",
  limitations: ["none"],
  userPhrase: "I want to feel strong again",
};

// ---------------------------------------------------------------------------

Deno.test("generate-plan: rejects request with no JWT (4xx, no mutation)", async () => {
  const res = await handler(anonReq(VALID_BODY));
  assert(res.status >= 400 && res.status < 500, `expected 4xx, got ${res.status}`);
});

Deno.test("generate-plan: rejects malformed JWT (4xx)", async () => {
  const res = await handler(authedReq("not.a.real.jwt", VALID_BODY));
  assert(res.status >= 400 && res.status < 500, `expected 4xx, got ${res.status}`);
});

Deno.test("generate-plan: valid JWT -> 200 with a complete deterministic plan packet", async () => {
  const jwt = await makeJwt({ sub: "user-a", email: "a@transformfit.test", role: "authenticated" });
  // Ensure no OpenRouter key so the deterministic fallback path fires.
  const prev = Deno.env.get("OPENROUTER_API_KEY");
  Deno.env.delete("OPENROUTER_API_KEY");
  let res: Response;
  try {
    res = await handler(authedReq(jwt, VALID_BODY));
  } finally {
    if (prev !== undefined) Deno.env.set("OPENROUTER_API_KEY", prev);
  }
  assertEquals(res.status, 200);
  const body = await res.json() as GeneratePlanResponse;
  // Plan numbers are present and deterministic.
  assert(body.plan !== undefined, "response must include a plan");
  assertEquals(body.plan.goal, "build_muscle");
  assertEquals(body.plan.daysPerWeek, 3);
  assertEquals(body.plan.days.length, 3);
  // Narrative fields are present.
  assert(typeof body.headline === "string" && body.headline.length > 0);
  assert(typeof body.reasoning === "string" && body.reasoning.length > 0);
  assert(typeof body.coaching_cue === "string" && body.coaching_cue.length > 0);
  // Acting user is from the JWT.
  assertEquals(body.user.id, "user-a");
  assertEquals(body.user.email, "a@transformfit.test");
  // Acting user is the source, body user_id (absent here) ignored.
  assertEquals(body.source, "jwt");
  // Fallback is flagged honestly (no LLM key in this test).
  assertEquals(body.is_fallback, true);
  assertEquals(body.model_used, "deterministic");
});

Deno.test("generate-plan: acting user resolved from JWT ONLY; body user_id=B ignored when JWT sub=A", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const prev = Deno.env.get("OPENROUTER_API_KEY");
  Deno.env.delete("OPENROUTER_API_KEY");
  let res: Response;
  try {
    res = await handler(authedJwtWithBody(jwt, "user-b", {
      goal: "lose_fat",
      daysPerWeek: 4,
      equipment: ["kettlebells"],
      experienceLevel: "beginner",
    }));
  } finally {
    if (prev !== undefined) Deno.env.set("OPENROUTER_API_KEY", prev);
  }
  assertEquals(res.status, 200);
  const body = await res.json() as GeneratePlanResponse;
  assertEquals(body.user.id, "user-a");
  // The body-supplied user_id was ignored; the acting user is the JWT subject.
  assertEquals(body.impersonation_attempt, true);
  assertEquals(body.source, "jwt");
});

Deno.test("generate-plan: never returns 501 even on LLM failure (always 200)", async () => {
  // No OpenRouter key => deterministic fallback. Still 200.
  const jwt = await makeJwt({ sub: "user-c" });
  const prev = Deno.env.get("OPENROUTER_API_KEY");
  Deno.env.delete("OPENROUTER_API_KEY");
  let res: Response;
  try {
    res = await handler(authedReq(jwt, {
      goal: "get_fitter",
      daysPerWeek: 2,
      equipment: [],
      experienceLevel: "beginner",
    }));
  } finally {
    if (prev !== undefined) Deno.env.set("OPENROUTER_API_KEY", prev);
  }
  assertNotEquals(res.status, 501);
  assertEquals(res.status, 200);
  const body = await res.json() as GeneratePlanResponse;
  assertEquals(body.is_fallback, true);
  assertEquals(body.model_used, "deterministic");
  // The deterministic plan is still complete (length-2 split).
  assertEquals(body.plan.days.length, 2);
  // Bodyweight-only plan is non-empty.
  const total = body.plan.days.reduce((s, d) => s + d.exercises.length, 0);
  assert(total > 0, "deterministic plan must be non-empty");
});

Deno.test("generate-plan: numbers/exercises come ONLY from the engine (immaterial of LLM)", async () => {
  const jwt = await makeJwt({ sub: "user-d" });
  const prev = Deno.env.get("OPENROUTER_API_KEY");
  Deno.env.delete("OPENROUTER_API_KEY");
  let a: GeneratePlanResponse, b: GeneratePlanResponse;
  try {
    const r1 = await handler(authedReq(jwt, {
      goal: "build_muscle",
      daysPerWeek: 3,
      equipment: ["dumbbells"],
      experienceLevel: "intermediate",
    }));
    const r2 = await handler(authedReq(jwt, {
      goal: "build_muscle",
      daysPerWeek: 3,
      equipment: ["dumbbells"],
      experienceLevel: "intermediate",
    }));
    a = await r1.json();
    b = await r2.json();
  } finally {
    if (prev !== undefined) Deno.env.set("OPENROUTER_API_KEY", prev);
  }
  // Identical intake -> identical plan JSON (determinism).
  assertEquals(JSON.stringify(a.plan), JSON.stringify(b.plan));
  // Equipment filter honored: only bodyweight + dumbbells.
  const eqs = new Set<string>(["bodyweight", "dumbbells"]);
  for (const d of a.plan.days) {
    for (const e of d.exercises) {
      assert(eqs.has(e.equipment), `${e.id} uses ${e.equipment}, outside effective set`);
    }
  }
});

Deno.test("generate-plan: surfaced fallback has user phrase echo in reasoning", async () => {
  const jwt = await makeJwt({ sub: "user-e" });
  const prev = Deno.env.get("OPENROUTER_API_KEY");
  Deno.env.delete("OPENROUTER_API_KEY");
  let res: Response;
  try {
    res = await handler(authedReq(jwt, {
      ...VALID_BODY,
      userPhrase: "I want to feel strong again",
    }));
  } finally {
    if (prev !== undefined) Deno.env.set("OPENROUTER_API_KEY", prev);
  }
  const body = await res.json() as GeneratePlanResponse;
  assert(body.reasoning.toLowerCase().includes("feel strong again"));
});

// Helper: build a request with both JWT and a body user_id.
function authedJwtWithBody(token: string, bodyUserId: string, intake: unknown): Request {
  return new Request("https://zuwtgdqsxmtiqojckpus.functions.supabase.co/generate-plan", {
    method: "POST",
    headers: {
      "authorization": `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(Object.assign({ user_id: bodyUserId }, intake)),
  });
}
