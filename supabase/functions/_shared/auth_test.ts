// Unit tests for the shared JWT-resolution helper.
// Run: deno test --allow-all supabase/functions/_shared/auth_test.ts
import { assert, assertEquals, assertNotEquals } from "jsr:@std/assert";
import {
  base64urlDecode,
  decodeJwtPayload,
  resolveUser,
  unauthorized,
} from "./auth.ts";

/** Build a minimal JWT (header.payload.signature) with the given payload. */
function makeJwt(payload: Record<string, unknown>): string {
  const header = { alg: "HS256", typ: "JWT" };
  const enc = (obj: unknown) => {
    const json = JSON.stringify(obj);
    // base64url encode
    const b64 = btoa(json);
    return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  };
  return `${enc(header)}.${enc(payload)}.signature`;
}

function reqWithAuth(token: string | null): Request {
  const headers = new Headers();
  if (token) headers.set("authorization", `Bearer ${token}`);
  return new Request("https://zuwtgdqsxmtiqojckpus.functions.supabase.co/whoami", {
    method: "POST",
    headers,
    body: JSON.stringify({ user_id: "body-b" }),
  });
}

// --- base64urlDecode ---

/** base64url-encode a UTF-8 string (mirror of the helper's decode for round-trips). */
function b64url(input: string): string {
  const bytes = new TextEncoder().encode(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

Deno.test("base64urlDecode: round-trips arbitrary UTF-8 (uses - and _)", () => {
  for (const s of ["hello world", "?>--", "a", "aa", "aaa", "\u00e9clair", "multi byte \u2603"]) {
    assertEquals(base64urlDecode(b64url(s)), s, `round-trip failed for ${JSON.stringify(s)}`);
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

Deno.test("decodeJwtPayload: decodes a well-formed token payload", () => {
  const jwt = makeJwt({ sub: "user-a", email: "a@transformfit.test", role: "authenticated" });
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
  const enc = (s: string) => btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
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

Deno.test("resolveUser: valid JWT -> user from sub, ignores body (body is not read)", () => {
  const jwt = makeJwt({ sub: "jwt-user-a", email: "a@transformfit.test", role: "authenticated" });
  const { user, response } = resolveUser(reqWithAuth(jwt));
  assertEquals(response, null);
  assert(user !== null);
  assertEquals(user!.id, "jwt-user-a");
  assertEquals(user!.email, "a@transformfit.test");
  assertEquals(user!.role, "authenticated");
});

Deno.test("resolveUser: a body user_id is NEVER consulted; the JWT sub wins", () => {
  // The request body carries user_id=body-b, but resolveUser only reads the
  // Authorization header, so the resolved user is the JWT subject.
  const jwt = makeJwt({ sub: "jwt-user-a" });
  const { user } = resolveUser(reqWithAuth(jwt));
  assert(user !== null);
  assertEquals(user!.id, "jwt-user-a");
  assertNotEquals(user!.id, "body-b");
});

Deno.test("resolveUser: missing Authorization header -> 401", () => {
  const { user, response } = resolveUser(reqWithAuth(null));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: malformed Authorization (no Bearer prefix) -> 401", () => {
  const req = new Request("https://x/whoami", {
    headers: { authorization: "Token abc" },
  });
  const { user, response } = resolveUser(req);
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: empty bearer token -> 401", () => {
  const req = new Request("https://x/whoami", {
    headers: { authorization: "Bearer  " },
  });
  const { user, response } = resolveUser(req);
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: garbage token (not a JWT) -> 401", () => {
  const { user, response } = resolveUser(reqWithAuth("not.a.jwt.really"));
  // "really" base64-decodes to a non-JSON string -> null payload -> 401
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: JWT with no sub -> 401", () => {
  const jwt = makeJwt({ email: "a@transformfit.test" }); // no sub
  const { user, response } = resolveUser(reqWithAuth(jwt));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: JWT with empty sub -> 401", () => {
  const jwt = makeJwt({ sub: "" });
  const { user, response } = resolveUser(reqWithAuth(jwt));
  assertEquals(user, null);
  assert(response !== null);
  assertEquals(response!.status, 401);
});

Deno.test("resolveUser: case-insensitive header name (Authorization)", () => {
  const jwt = makeJwt({ sub: "user-x" });
  const req = new Request("https://x/whoami", {
    headers: { Authorization: `Bearer ${jwt}` },
  });
  const { user, response } = resolveUser(req);
  assertEquals(response, null);
  assert(user !== null);
  assertEquals(user!.id, "user-x");
});

Deno.test("resolveUser: is read-only (calling it never throws on bad body)", () => {
  // Even with a totally unreadable body, resolveUser only touches headers.
  const jwt = makeJwt({ sub: "user-y" });
  const req = new Request("https://x/whoami", {
    method: "POST",
    headers: { authorization: `Bearer ${jwt}` },
    body: "<<<not json",
  });
  const { user, response } = resolveUser(req);
  assertEquals(response, null);
  assert(user !== null);
  assertEquals(user!.id, "user-y");
});
