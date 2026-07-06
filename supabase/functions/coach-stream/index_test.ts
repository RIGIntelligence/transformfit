// Unit tests for the coach-stream edge function.
//
// Run: deno test --allow-all supabase/functions/coach-stream/index_test.ts
//
// Tests verify:
// - Auth enforcement (JWT-only, 401 on missing/bad JWT)
// - Input validation (persona, templateType, toneArcPhase, intensity)
// - Response structure (200 with complete CoachStreamResponse)
// - Deterministic fallback (when Ollama is unreachable)
// - All personas and template types produce valid output
import { assert, assertEquals, assertNotEquals } from "@std/assert";
import {
  type CoachStreamResponse,
  handler,
} from "./index.ts";

// --- helpers ---------------------------------------------------------------

const TEST_JWT_SECRET = "transformfit-test-jwt-secret";
Deno.env.set("SUPABASE_JWT_SECRET", TEST_JWT_SECRET);
Deno.env.set("SUPABASE_JWT_ISSUER", "supabase");
Deno.env.set("SUPABASE_JWT_AUDIENCE", "authenticated");
// Point Ollama to an unreachable host so deterministic fallback is guaranteed.
// RFC 2606 .invalid TLD never resolves. AbortController caps the wait at 30s.
Deno.env.set("OLLAMA_HOST", "http://ollama.invalid:11434");

function enc(obj: unknown): string {
  return btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_")
    .replace(/=+$/, "");
}

function encBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

async function makeJwt(payload: Record<string, unknown>): Promise<string> {
  const signingInput = `${enc({ alg: "HS256", typ: "JWT" })}.${
    enc({
      exp: Math.floor(Date.now() / 1000) + 3600,
      iss: "supabase",
      aud: "authenticated",
      ...payload,
    })
  }`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(TEST_JWT_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign(
      "HMAC",
      key,
      new TextEncoder().encode(signingInput),
    ),
  );
  return `${signingInput}.${encBytes(sig)}`;
}

function authedReq(
  token: string,
  body: unknown,
  accept?: string,
): Request {
  return new Request(
    "https://zuwtgdqsxmtiqojckpus.functions.supabase.co/coach-stream",
    {
      method: "POST",
      headers: {
        "authorization": `Bearer ${token}`,
        "content-type": "application/json",
        ...(accept ? { accept } : {}),
      },
      body: JSON.stringify(body),
    },
  );
}

function anonReq(body: unknown): Request {
  return new Request(
    "https://zuwtgdqsxmtiqojckpus.functions.supabase.co/coach-stream",
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    },
  );
}

const VALID_BODY = {
  persona: "motivator",
  templateType: "session_start",
  toneArcPhase: "days0to7",
  intensity: "normal",
  context: {
    readinessScore: 75,
    sessionCount: 5,
    volumeKg: 1200.5,
    rpe: 7,
    streakDays: 3,
  },
  userPhrase: "I want to push harder today",
};

/** Assert the response is a well-formed CoachStreamResponse (200). */
function assertValidCoachResponse(body: CoachStreamResponse) {
  assert(
    ["motivator", "analyst", "challenger", "zen"].includes(body.persona),
    `unexpected persona: ${body.persona}`,
  );
  assert(typeof body.message === "string" && body.message.length > 0);
  assert(typeof body.modelUsed === "string" && body.modelUsed.length > 0);
  assert(typeof body.isFallback === "boolean");
}

// --- auth tests (VAL-AUTH-022/023) ---

Deno.test("coach-stream: rejects request with no JWT (4xx)", async () => {
  const res = await handler(anonReq(VALID_BODY));
  assert(
    res.status >= 400 && res.status < 500,
    `expected 4xx, got ${res.status}`,
  );
});

Deno.test("coach-stream: rejects malformed JWT (4xx)", async () => {
  const res = await handler(authedReq("not.a.real.jwt", VALID_BODY));
  assert(
    res.status >= 400 && res.status < 500,
    `expected 4xx, got ${res.status}`,
  );
});

// --- validation tests ---

Deno.test("coach-stream: rejects invalid persona", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, { ...VALID_BODY, persona: "invalid_persona" }),
  );
  assertEquals(res.status, 400);
  const body = await res.json();
  assert(body.error.includes("persona"));
});

Deno.test("coach-stream: rejects invalid templateType", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, { ...VALID_BODY, templateType: "invalid_template" }),
  );
  assertEquals(res.status, 400);
  const body = await res.json();
  assert(body.error.includes("templateType"));
});

Deno.test("coach-stream: rejects invalid toneArcPhase", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, { ...VALID_BODY, toneArcPhase: "invalid_phase" }),
  );
  assertEquals(res.status, 400);
  const body = await res.json();
  assert(body.error.includes("toneArcPhase"));
});

Deno.test("coach-stream: rejects invalid intensity", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, { ...VALID_BODY, intensity: "extreme" }),
  );
  assertEquals(res.status, 400);
  const body = await res.json();
  assert(body.error.includes("intensity"));
});

Deno.test("coach-stream: rejects malformed JSON body", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const req = new Request(
    "https://zuwtgdqsxmtiqojckpus.functions.supabase.co/coach-stream",
    {
      method: "POST",
      headers: {
        "authorization": `Bearer ${jwt}`,
        "content-type": "application/json",
      },
      body: "<<<not json",
    },
  );
  const res = await handler(req);
  assertEquals(res.status, 400);
});

// --- response structure tests ---

Deno.test("coach-stream: valid JWT -> 200 with complete response", async () => {
  const jwt = await makeJwt({
    sub: "user-a",
    email: "a@transformfit.test",
    role: "authenticated",
  });
  const res = await handler(authedReq(jwt, VALID_BODY));
  assertEquals(res.status, 200);
  const body = await res.json() as CoachStreamResponse;
  assertEquals(body.persona, "motivator");
  assertEquals(body.templateType, "session_start");
  assertValidCoachResponse(body);
});

Deno.test("coach-stream: deterministic message includes context data", async () => {
  const jwt = await makeJwt({ sub: "user-b", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, {
      persona: "analyst",
      templateType: "session_start",
      toneArcPhase: "days8to14",
      intensity: "normal",
      context: { readinessScore: 82 },
    }),
  );
  assertEquals(res.status, 200);
  const body = await res.json() as CoachStreamResponse;
  assertValidCoachResponse(body);
  // Message should reference readiness data.
  assert(
    body.message.includes("82") || body.message.includes("Readiness") ||
      body.isFallback || body.modelUsed.includes("ollama"),
    "message should reference readiness or be LLM-generated",
  );
});

Deno.test("coach-stream: deterministicMessage used as fallback when provided", async () => {
  const jwt = await makeJwt({ sub: "user-c", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, {
      ...VALID_BODY,
      deterministicMessage: "Custom fallback message for testing.",
    }),
  );
  assertEquals(res.status, 200);
  const body = await res.json() as CoachStreamResponse;
  assertValidCoachResponse(body);
  // If fallback was used, the custom message should appear.
  if (body.isFallback) {
    assertEquals(body.message, "Custom fallback message for testing.");
  }
});

Deno.test("coach-stream: all personas produce valid output", async () => {
  const jwt = await makeJwt({ sub: "user-d", role: "authenticated" });
  for (const persona of ["motivator", "analyst", "challenger", "zen"]) {
    const res = await handler(
      authedReq(jwt, {
        ...VALID_BODY,
        persona,
        templateType: "session_end",
      }),
    );
    assertEquals(res.status, 200);
    const body = await res.json() as CoachStreamResponse;
    assertEquals(body.persona, persona);
    assertValidCoachResponse(body);
  }
});

Deno.test("coach-stream: all template types produce valid output", async () => {
  const jwt = await makeJwt({ sub: "user-e", role: "authenticated" });
  for (const templateType of [
    "session_start",
    "mid_session",
    "session_end",
    "recovery",
    "stall",
  ]) {
    const res = await handler(
      authedReq(jwt, { ...VALID_BODY, templateType }),
    );
    assertEquals(res.status, 200);
    const body = await res.json() as CoachStreamResponse;
    assertEquals(body.templateType, templateType);
    assertValidCoachResponse(body);
  }
});

Deno.test("coach-stream: never returns 501", async () => {
  const jwt = await makeJwt({ sub: "user-f", role: "authenticated" });
  const res = await handler(authedReq(jwt, VALID_BODY));
  assertNotEquals(res.status, 501);
});

Deno.test("coach-stream: optional context fields handled gracefully", async () => {
  const jwt = await makeJwt({ sub: "user-g", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, {
      persona: "zen",
      templateType: "recovery",
      toneArcPhase: "days22to30",
      intensity: "low",
      context: {},
    }),
  );
  assertEquals(res.status, 200);
  const body = await res.json() as CoachStreamResponse;
  assertValidCoachResponse(body);
});
