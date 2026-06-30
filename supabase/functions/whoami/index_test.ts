// Handler tests for the whoami edge function.
// Run: deno test --allow-all supabase/functions/whoami/index_test.ts
import { assert, assertEquals } from "jsr:@std/assert";
import { handler } from "./index.ts";

/** Build a minimal JWT with the given payload (signature not verified by helper). */
function makeJwt(payload: Record<string, unknown>): string {
  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  return `${enc({ alg: "HS256", typ: "JWT" })}.${enc(payload)}.sig`;
}

function whoamiReq(opts: {
  jwt?: string | null;
  body?: unknown;
  method?: string;
}): Request {
  const headers = new Headers();
  if (opts.jwt !== undefined && opts.jwt !== null) {
    headers.set("authorization", `Bearer ${opts.jwt}`);
  }
  const method = opts.method ?? "POST";
  return new Request("https://zuwtgdqsxmtiqojckpus.functions.supabase.co/whoami", {
    method,
    headers,
    body: method !== "GET" && method !== "DELETE"
      ? JSON.stringify(opts.body ?? {})
      : undefined,
  });
}

// --- JWT-only enforcement (VAL-AUTH-022): body user_id ignored ---

Deno.test("whoami: A's JWT + body user_id=B -> 200, user=A, body ignored, impersonation flagged", async () => {
  const jwtA = makeJwt({ sub: "user-a", email: "a@transformfit.test", role: "authenticated" });
  const res = await handler(whoamiReq({ jwt: jwtA, body: { user_id: "user-b" } }));
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("content-type"), "application/json");
  const body = await res.json();
  assertEquals(body.user.id, "user-a");
  assertEquals(body.user.email, "a@transformfit.test");
  assertEquals(body.source, "jwt");
  assertEquals(body.body_user_id_ignored, "user-b");
  assertEquals(body.impersonation_attempt, true);
});

Deno.test("whoami: body user_id === jwt sub -> impersonation_attempt false", async () => {
  const jwt = makeJwt({ sub: "user-a" });
  const res = await handler(whoamiReq({ jwt, body: { user_id: "user-a" } }));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.user.id, "user-a");
  assertEquals(body.body_user_id_ignored, "user-a");
  assertEquals(body.impersonation_attempt, false);
});

Deno.test("whoami: no body user_id -> body_user_id_ignored null", async () => {
  const jwt = makeJwt({ sub: "user-a" });
  const res = await handler(whoamiReq({ jwt, body: { other: "x" } }));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.body_user_id_ignored, null);
  assertEquals(body.impersonation_attempt, false);
});

// --- No / invalid JWT -> 401, no mutation (VAL-AUTH-023) ---

Deno.test("whoami: no Authorization header -> 401 JSON error", async () => {
  const res = await handler(whoamiReq({ jwt: null, body: { user_id: "user-b" } }));
  assertEquals(res.status, 401);
  assertEquals(res.headers.get("content-type"), "application/json");
  const body = await res.json();
  assert(typeof body.error === "string" && body.error.length > 0);
});

Deno.test("whoami: malformed Authorization (no Bearer) -> 401", async () => {
  const req = new Request("https://x/whoami", {
    method: "POST",
    headers: { authorization: "Token xyz" },
    body: "{}",
  });
  const res = await handler(req);
  assertEquals(res.status, 401);
});

Deno.test("whoami: garbage token -> 401", async () => {
  const res = await handler(whoamiReq({ jwt: "not.a.jwt.really", body: {} }));
  assertEquals(res.status, 401);
});

Deno.test("whoami: JWT missing sub -> 401", async () => {
  const jwt = makeJwt({ email: "a@transformfit.test" });
  const res = await handler(whoamiReq({ jwt, body: {} }));
  assertEquals(res.status, 401);
});

Deno.test("whoami: malformed JSON body does not crash; JWT user still returned", async () => {
  const jwt = makeJwt({ sub: "user-a" });
  const req = new Request("https://x/whoami", {
    method: "POST",
    headers: { authorization: `Bearer ${jwt}`, "content-type": "application/json" },
    body: "<<<not json",
  });
  const res = await handler(req);
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.user.id, "user-a");
  assertEquals(body.body_user_id_ignored, null);
});

Deno.test("whoami: GET with valid JWT -> 200 (no body to parse)", async () => {
  const jwt = makeJwt({ sub: "user-a" });
  const res = await handler(whoamiReq({ jwt, method: "GET" }));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.user.id, "user-a");
  assertEquals(body.source, "jwt");
});
