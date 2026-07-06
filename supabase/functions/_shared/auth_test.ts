// Unit tests for the shared JWT-resolution helper.
// Run: deno test --allow-all supabase/functions/_shared/auth_test.ts
import { assert, assertEquals, assertNotEquals } from "@std/assert";
import {
  base64urlDecode,
  decodeJwtPayload,
  resolveUser,
  unauthorized,
} from "./auth.ts";

const TEST_JWT_SECRET = "transformfit-test-jwt-secret";
Deno.env.set("SUPABASE_JWT_SECRET", TEST_JWT_SECRET);
Deno.env.set("SUPABASE_JWT_ISSUER", "supabase");
Deno.env.set("SUPABASE_JWT_AUDIENCE", "authenticated");

function withJwtDefaults(
  payload: Record<string, unknown>,
): Record<string, unknown> {
  return {
    exp: Math.floor(Date.now() / 1000) + 3600,
    iss: "supabase",
    aud: "authenticated",
    ...payload,
  };
}

function enc(obj: unknown): string {
  const json = JSON.stringify(obj);
  const b64 = btoa(json);
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function encBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

/** Build a signed HS256 JWT with the given payload. */
async function makeJwt(payload: Record<string, unknown>): Promise<string> {
  const header = { alg: "HS256", typ: "JWT" };
  const signingInput = `${enc(header)}.${enc(withJwtDefaults(payload))}`;
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

function makeForgedJwt(payload: Record<string, unknown>): string {
  return `${enc({ alg: "HS256", typ: "JWT" })}.${
    enc(withJwtDefaults(payload))
  }.signature`;
}

function reqWithAuth(token: string | null): Request {
  const headers = new Headers();
  if (token) headers.set("authorization", `Bearer ${token}`);
  return new Request(
    "https://zuwtgdqsxmtiqojckpus.functions.supabase.co/whoami",
    {
      method: "POST",
      headers,
      body: JSON.stringify({ user_id: "body-b" }),
    },
  );
}

// --- base64urlDecode ---

/** base64url-encode a UTF-8 string (mirror of the helper's decode for round-trips). */
function b64url(input: string): string {
  const bytes = new TextEncoder().encode(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

Deno.test("base64urlDecode: round-trips arbitrary UTF-8 (uses - and _)", () => {
  for (
    const s of [
      "hello world",
      "?>--",
      "a",
      "aa",
      "aaa",
      "\u00e9clair",
      "multi byte \u2603",
    ]
  ) {
    assertEquals(
      base64urlDecode(b64url(s)),
      s,
      `round-trip failed for ${JSON.stringify(s)}`,
    );
  }
});

Deno.test("base64urlDecode: handles padding variants (1 and 3 trailing chars)", () => {
  assertEquals(base64urlDecode(b64url("a")), "a"); // 1 char -> needs ==
  assertEquals(base64urlDecode(b64url("aa")), "aa"); // 2 chars -> no pad
  assertEquals(base64urlDecode(b64url("aaa")), "aaa"); // 3 chars -> needs =
});

Deno.test("base64urlDecode: returns null on a length that is 1 mod 4 (invalid base64)", () => {
  // 5 chars is 1 mod 4 -> impossible valid base64 (after padding logic).
  assertEquals(base64urlDecode("YWJsZ"), null);
});

// --- decodeJwtPayload ---

Deno.test("decodeJwtPayload: decodes a well-formed token payload", async () => {
  const jwt = await makeJwt({
    sub: "user-a",
    email: "a@transformfit.test",
    role: "authenticated",
  });
  const p = decodeJwtPayload(jwt);
  assert(p !== null);
  assertEquals(p?.sub, "user-a");
  assertEquals(p?.email, "a@transformfit.test");
  assertEquals(p?.role, "authenticated");
});

Deno.test("decodeJwtPayload: returns null for wrong segment count", () => {
  assertEquals(decodeJwtPayload("only.two"), null);
  assertEquals(decodeJwtPayload("only.one.two.three"), null);
});

Deno.test("decodeJwtPayload: returns null for non-JSON payload", () => {
  const enc = (s: string) =>
    btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const bad = `header.${enc("not-json{")}.sig`;
  assertEquals(decodeJwtPayload(bad), null);
});

// --- unauthorized ---

Deno.test("unauthorized: returns 401 with JSON error body, no mutation", () => {
  const res = unauthorized("nope");
  assertEquals(res.status, 401);
  assertEquals(res.headers.get("content-type"), "application/json");
  // not a 200, not a 5xx
  assertNotEquals(res.status, 200);
});

// --- resolveUser: JWT-only resolution, body user_id ignored ---

Deno.test("resolveUser: valid JWT -> user from sub, ignores body (body is not read)", async () => {
  const jwt = await makeJwt({
    sub: "jwt-user-a",
    email: "a@transformfit.test",
    role: "authenticated",
  });
  const { user, response } = await resolveUser(reqWithAuth(jwt));
  assertEquals(response, null);
  assert(user !== null);
  assertEquals(user!.id, "jwt-user-a");
  assertEquals(user!.email, "a@transformfit.test");
  assertEquals(user!.role, "authenticated");
});

Deno.test("resolveUser: a body user_id is NEVER consulted; the JWT sub wins", async () => {
  // The request body carries user_id=body-b, but resolveUser only reads the
  // Authorization header, so the resolved user is the JWT subject.
  const jwt = await makeJwt({ sub: "jwt-user-a" });
  const { user } = await resolveUser(reqWithAuth(jwt));
  assert(user !== null);
  assertEquals(user!.id, "jwt-user-a");
  assertNotEquals(user!.id, "body-b");
});

Deno.test("resolveUser: missing Authorization header -> 401", async () => {
  const { user, response } = await resolveUser(reqWithAuth(null));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: malformed Authorization (no Bearer prefix) -> 401", async () => {
  const req = new Request("https://x/whoami", {
    headers: { authorization: "Token abc" },
  });
  const { user, response } = await resolveUser(req);
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: empty bearer token -> 401", async () => {
  const req = new Request("https://x/whoami", {
    headers: { authorization: "Bearer  " },
  });
  const { user, response } = await resolveUser(req);
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: garbage token (not a JWT) -> 401", async () => {
  const { user, response } = await resolveUser(reqWithAuth("not.a.jwt.really"));
  // "really" base64-decodes to a non-JSON string -> null payload -> 401
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: JWT with no sub -> 401", async () => {
  const jwt = await makeJwt({ email: "a@transformfit.test" }); // no sub
  const { user, response } = await resolveUser(reqWithAuth(jwt));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: JWT with empty sub -> 401", async () => {
  const jwt = await makeJwt({ sub: "" });
  const { user, response } = await resolveUser(reqWithAuth(jwt));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: rejects forged JWT signatures", async () => {
  const jwt = makeForgedJwt({ sub: "user-a" });
  const { user, response } = await resolveUser(reqWithAuth(jwt));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: rejects expired JWTs", async () => {
  const jwt = await makeJwt({
    sub: "user-a",
    exp: Math.floor(Date.now() / 1000) - 10,
  });
  const { user, response } = await resolveUser(reqWithAuth(jwt));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: case-insensitive header name (Authorization)", async () => {
  const jwt = await makeJwt({ sub: "user-x" });
  const req = new Request("https://x/whoami", {
    headers: { Authorization: `Bearer ${jwt}` },
  });
  const { user, response } = await resolveUser(req);
  assertEquals(response, null);
  assert(user !== null);
  assertEquals(user!.id, "user-x");
});

Deno.test("resolveUser: is read-only (calling it never throws on bad body)", async () => {
  // Even with a totally unreadable body, resolveUser only touches headers.
  const jwt = await makeJwt({ sub: "user-y" });
  const req = new Request("https://x/whoami", {
    method: "POST",
    headers: { authorization: `Bearer ${jwt}` },
    body: "<<<not json",
  });
  const { user, response } = await resolveUser(req);
  assertEquals(response, null);
  assert(user !== null);
  assertEquals(user!.id, "user-y");
});
