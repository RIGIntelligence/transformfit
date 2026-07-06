// Unit tests for the post-session-analysis edge function.
//
// Run: deno test --allow-all supabase/functions/post-session-analysis/index_test.ts
//
// post-session-analysis takes session data (sets, previous bests, duration),
// runs the deterministic analysis engine, narrates via Ollama (or returns a
// deterministic fallback), and ALWAYS returns 200 with a complete analysis
// packet (never 501/empty). The acting user is resolved from the JWT ONLY.
import { assert, assertEquals, assertNotEquals } from "@std/assert";
import {
  type DebriefNarrative,
  type PostSessionAnalysisResponse,
  handler,
} from "./index.ts";

// --- helpers ---------------------------------------------------------------

const TEST_JWT_SECRET = "transformfit-test-jwt-secret";
Deno.env.set("SUPABASE_JWT_SECRET", TEST_JWT_SECRET);
Deno.env.set("SUPABASE_JWT_ISSUER", "supabase");
Deno.env.set("SUPABASE_JWT_AUDIENCE", "authenticated");
// Ensure Ollama host cannot resolve — forces deterministic fallback.
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

function authedReq(token: string, body: unknown): Request {
  return new Request(
    "https://zuwtgdqsxmtiqojckpus.functions.supabase.co/post-session-analysis",
    {
      method: "POST",
      headers: {
        "authorization": `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
}

function anonReq(body: unknown): Request {
  return new Request(
    "https://zuwtgdqsxmtiqojckpus.functions.supabase.co/post-session-analysis",
    {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    },
  );
}

const VALID_BODY = {
  sets: [
    { exerciseId: "barbell_bench_press", weightKg: 80, reps: 8, rpe: 7 },
    { exerciseId: "barbell_bench_press", weightKg: 80, reps: 7, rpe: 8 },
    { exerciseId: "barbell_bench_press", weightKg: 80, reps: 6, rpe: 9 },
  ],
  previousBests: [
    { exerciseId: "barbell_bench_press", estimatedOneRmKg: 100 },
  ],
  durationMinutes: 45,
  readinessScoreBefore: 72,
  corridorRepsMin: 5,
  corridorRepsMax: 12,
  corridorRpeTarget: 7,
};

// --- auth tests ---

Deno.test("post-session-analysis: rejects request with no JWT (4xx)", async () => {
  const res = await handler(anonReq(VALID_BODY));
  assert(
    res.status >= 400 && res.status < 500,
    `expected 4xx, got ${res.status}`,
  );
});

Deno.test("post-session-analysis: rejects malformed JWT (4xx)", async () => {
  const res = await handler(authedReq("not.a.real.jwt", VALID_BODY));
  assert(
    res.status >= 400 && res.status < 500,
    `expected 4xx, got ${res.status}`,
  );
});

// --- validation tests ---

Deno.test("post-session-analysis: rejects non-array sets", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(authedReq(jwt, { ...VALID_BODY, sets: "bad" }));
  assertEquals(res.status, 400);
  const body = await res.json();
  assert(body.error.includes("sets"));
});

Deno.test("post-session-analysis: rejects set with missing exerciseId", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, {
      ...VALID_BODY,
      sets: [{ weightKg: 80, reps: 8 }],
    }),
  );
  assertEquals(res.status, 400);
});

Deno.test("post-session-analysis: rejects set with negative weightKg", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, {
      ...VALID_BODY,
      sets: [{ exerciseId: "bench", weightKg: -5, reps: 8 }],
    }),
  );
  assertEquals(res.status, 400);
});

Deno.test("post-session-analysis: rejects set with rpe out of range", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, {
      ...VALID_BODY,
      sets: [{ exerciseId: "bench", weightKg: 80, reps: 8, rpe: 15 }],
    }),
  );
  assertEquals(res.status, 400);
});

Deno.test("post-session-analysis: rejects non-integer durationMinutes", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const res = await handler(
    authedReq(jwt, { ...VALID_BODY, durationMinutes: 45.5 }),
  );
  assertEquals(res.status, 400);
});

Deno.test("post-session-analysis: rejects malformed JSON body", async () => {
  const jwt = await makeJwt({ sub: "user-a", role: "authenticated" });
  const req = new Request(
    "https://zuwtgdqsxmtiqojckpus.functions.supabase.co/post-session-analysis",
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

Deno.test("post-session-analysis: valid JWT -> 200 with complete analysis packet", async () => {
  const jwt = await makeJwt({
    sub: "user-a",
    email: "a@transformfit.test",
    role: "authenticated",
  });
  const res = await handler(authedReq(jwt, VALID_BODY));
  assertEquals(res.status, 200);
  const body = await res.json() as PostSessionAnalysisResponse;
  // User from JWT.
  assertEquals(body.user.id, "user-a");
  assertEquals(body.source, "jwt");
  // Analysis is present and deterministic.
  assert(body.analysis !== undefined);
  assertEquals(body.analysis.totalSets, 3);
  assertEquals(body.analysis.totalReps, 21); // 8 + 7 + 6
  assert(body.analysis.totalVolumeKg > 0);
  // Narrative is present (deterministic fallback since no Ollama).
  assert(body.narrative !== undefined);
  assertEquals(body.narrative.is_fallback, true);
  assertEquals(body.narrative.model_used, "deterministic");
  assert(body.narrative.volume_summary.length > 0);
  assert(body.narrative.what_changed.length > 0);
  assert(body.narrative.coaching_takeaway.length > 0);
});

Deno.test("post-session-analysis: empty sets -> 200 with zero analysis", async () => {
  const jwt = await makeJwt({ sub: "user-b", role: "authenticated" });
  const res = await handler(authedReq(jwt, { ...VALID_BODY, sets: [] }));
  assertEquals(res.status, 200);
  const body = await res.json() as PostSessionAnalysisResponse;
  assertEquals(body.analysis.totalSets, 0);
  assertEquals(body.analysis.totalReps, 0);
  assertEquals(body.analysis.totalVolumeKg, 0);
});

Deno.test("post-session-analysis: oneRM changes computed correctly", async () => {
  const jwt = await makeJwt({ sub: "user-c", role: "authenticated" });
  const res = await handler(authedReq(jwt, VALID_BODY));
  const body = await res.json() as PostSessionAnalysisResponse;
  // Should have oneRM changes for barbell_bench_press.
  assert(body.analysis.oneRmChanges.length > 0);
  const change = body.analysis.oneRmChanges.find(
    (c) => c.exerciseId === "barbell_bench_press",
  );
  assert(change !== undefined);
  // Epley: 80 * (1 + 8/30) = 101.33
  assert(change.sessionOneRmKg > 80);
});

Deno.test("post-session-analysis: corridor status computed", async () => {
  const jwt = await makeJwt({ sub: "user-d", role: "authenticated" });
  const res = await handler(authedReq(jwt, VALID_BODY));
  const body = await res.json() as PostSessionAnalysisResponse;
  assert(
    ["in_corridor", "above_corridor", "below_corridor"].includes(
      body.analysis.corridorStatus,
    ),
  );
  assert(body.analysis.corridorReason.length > 0);
});

Deno.test("post-session-analysis: readiness impact computed", async () => {
  const jwt = await makeJwt({ sub: "user-e", role: "authenticated" });
  const res = await handler(authedReq(jwt, VALID_BODY));
  const body = await res.json() as PostSessionAnalysisResponse;
  assert(body.analysis.readinessImpact >= 0);
  assert(body.analysis.readinessImpact <= 20);
  assert(body.analysis.readinessImpactReason.length > 0);
});

Deno.test("post-session-analysis: never returns 501", async () => {
  const jwt = await makeJwt({ sub: "user-f", role: "authenticated" });
  const res = await handler(authedReq(jwt, VALID_BODY));
  assertNotEquals(res.status, 501);
  assertEquals(res.status, 200);
});

Deno.test("post-session-analysis: previousBests is optional", async () => {
  const jwt = await makeJwt({ sub: "user-g", role: "authenticated" });
  const bodyWithoutBests = { ...VALID_BODY };
  delete (bodyWithoutBests as Record<string, unknown>).previousBests;
  const res = await handler(authedReq(jwt, bodyWithoutBests));
  assertEquals(res.status, 200);
  const body = await res.json() as PostSessionAnalysisResponse;
  // First session with no prior baseline — delta should be 0.
  for (const change of body.analysis.oneRmChanges) {
    assertEquals(change.deltaKg, 0);
  }
});
