// Unit tests for the coach-stream edge function.
//
// Run: deno test --allow-all supabase/functions/coach-stream/index_test.ts
//
// coach-stream takes a coaching request (persona, templateType, toneArcPhase,
// intensity, context) and returns either a streamed or single-response coaching
// message. On LLM failure, returns a deterministic fallback flagged
// is_fallback:true / model_used:"deterministic". Always 200, never 501.
// The acting user is resolved from the JWT ONLY.
import { assert, assertEquals, assertNotEquals } from "@std/assert";
import {
  type CoachStreamRequest,
  type CoachStreamResponse,
  handler,
} from "./index.ts";

// --- helpers ---------------------------------------------------------------

const TEST_JWT_SECRET = "transformfit-test-jwt-secret";
Deno.env.set("SUPABASE_JWT_SECRET", TEST_JWT_SECRET);
Deno.env.set("SUPABASE_JWT_ISSUER", "supabase");
Deno.env.set("SUPABASE_JWT_AUDIENCE", "authenticated");
// Ensure Ollama points to a port that refuses connections immediately
// (connection refused < 1ms vs 15-30s timeout on localhost:11434).
Deno.env.set("OLLAMA_HOST", "http://127.0.0.1:1");

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

const VALID_BODY: CoachStreamRequest = {
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

// --- deterministic fallback tests ---

Deno.test("coach-stream: valid JWT -> 200 with deterministic fallback (no Ollama)", async () => {
  const jwt = await makeJwt({
    sub: "user-a",
    email: "a@transformfit.test",
    role: "authenticated",
  });
  const res = await handler(authedReq(jwt, VALID_BODY));
  assertEquals(res.status, 200);
  const body = await res.json() as CoachStreamResponse;
  // Deterministic fallback flagged honestly.
  assertEquals(body.isFallback, true);
  assertEquals(body.modelUsed, "deterministic");
  assertEquals(body.persona, "motivator");
  assertEquals(body.templateType, "session_start");
  assert(typeof body.message === "string" && body.message.length > 0);
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
  const body = await res.json() as CoachStreamResponse;
  assert(body.message.includes("82") || body.message.includes("Readiness"));
});

Deno.test("coach-stream: deterministic message uses userPhrase in fallback", async () => {
  const jwt = await makeJwt({ sub: "user-c", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, {
      ...VALID_BODY,
      deterministicMessage: "Custom fallback message for testing.",
    }),
  );
  const body = await res.json() as CoachStreamResponse;
  assertEquals(body.message, "Custom fallback message for testing.");
  assertEquals(body.isFallback, true);
});

Deno.test("coach-stream: all personas produce deterministic output", async () => {
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
    assert(body.message.length > 0);
  }
});

Deno.test("coach-stream: all template types produce deterministic output", async () => {
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
    assert(body.message.length > 0);
  }
});

Deno.test("coach-stream: never returns 501", async () => {
  const jwt = await makeJwt({ sub: "user-f", role: "authenticated" });
  const res = await handler(authedReq(jwt, VALID_BODY));
  assertNotEquals(res.status, 501);
});

Deno.test("coach-stream: optional context fields are handled gracefully", async () => {
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
  assert(body.message.length > 0);
});
