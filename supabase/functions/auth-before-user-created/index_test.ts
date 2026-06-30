// Unit + handler tests for the before_user_created auth hook edge function.
// Run: deno test --allow-all supabase/functions/auth-before-user-created/index_test.ts
import { assert, assertEquals } from "jsr:@std/assert";
import { handler, isBlockedEmail } from "./index.ts";

function hookReq(body: unknown, method = "POST"): Request {
  return new Request("https://zuwtgdqsxmtiqojckpus.functions.supabase.co/auth-before-user-created", {
    method,
    body: method === "POST" ? JSON.stringify(body) : undefined,
    headers: { "content-type": "application/json" },
  });
}

// --- Pure decision function ---

Deno.test("isBlockedEmail: blocks plain example.com", () => {
  assert(isBlockedEmail("user@example.com"));
});

Deno.test("isBlockedEmail: blocks case-insensitive EXAMPLE.COM", () => {
  assert(isBlockedEmail("user@EXAMPLE.COM"));
  assert(isBlockedEmail("User@Example.Com"));
  assert(isBlockedEmail("user@EXAMPLE.com"));
});

Deno.test("isBlockedEmail: does NOT block subdomains of example.com", () => {
  assertEquals(isBlockedEmail("user@sub.example.com"), false);
  assertEquals(isBlockedEmail("user@mail.example.com"), false);
});

Deno.test("isBlockedEmail: allows realistic domains", () => {
  assertEquals(isBlockedEmail("user@gmail.com"), false);
  assertEquals(isBlockedEmail("user@transformfit.test"), false);
  assertEquals(isBlockedEmail("user@supabase.co"), false);
});

Deno.test("isBlockedEmail: handles malformed / missing emails safely", () => {
  assertEquals(isBlockedEmail(null), false);
  assertEquals(isBlockedEmail(undefined), false);
  assertEquals(isBlockedEmail(""), false);
  assertEquals(isBlockedEmail("no-at-sign"), false);
  assertEquals(isBlockedEmail("trailing-at@"), false);
});

// --- Handler end-to-end (Request -> Response) ---

Deno.test("handler: @example.com -> HTTP 200 with error.http_code=422 (GoTrue propagates 422 to client)", async () => {
  const res = await handler(hookReq({ user: { email: "tester@example.com" } }));
  // GoTrue's HTTP hook client requires a 2xx response status; the
  // client-facing 422 is carried inside error.http_code.
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("content-type"), "application/json");
  const body = await res.json();
  assert(typeof body.error === "object");
  assertEquals(body.error.http_code, 422);
  assert(typeof body.error.message === "string" && body.error.message.length > 0);
});

Deno.test("handler: @EXAMPLE.Com -> error.http_code=422 (case-insensitive domain)", async () => {
  const res = await handler(hookReq({ user: { email: "Tester@EXAMPLE.Com" } }));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.error.http_code, 422);
});

Deno.test("handler: @gmail.com -> 200 with empty object (allow)", async () => {
  const res = await handler(hookReq({ user: { email: "tester@gmail.com" } }));
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("content-type"), "application/json");
  const body = await res.json();
  assertEquals(body, {});
});

Deno.test("handler: @transformfit.test -> 200 (allow realistic domain)", async () => {
  const res = await handler(hookReq({ user: { email: "val@transformfit.test" } }));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), {});
});

Deno.test("handler: sub.example.com -> 200 (subdomains NOT blocked)", async () => {
  const res = await handler(hookReq({ user: { email: "user@sub.example.com" } }));
  assertEquals(res.status, 200);
});

Deno.test("handler: missing user.email -> 200 (no email to evaluate)", async () => {
  const res = await handler(hookReq({ user: {} }));
  assertEquals(res.status, 200);
});

Deno.test("handler: malformed JSON body -> 200 (fail-open, never 5xx)", async () => {
  const req = new Request("https://hook.local/", {
    method: "POST",
    body: "not-json{",
    headers: { "content-type": "application/json" },
  });
  const res = await handler(req);
  assertEquals(res.status, 200);
});

Deno.test("handler: empty body -> 200", async () => {
  const req = new Request("https://hook.local/", { method: "POST" });
  const res = await handler(req);
  assertEquals(res.status, 200);
});

Deno.test("handler: non-POST method -> 200 (hook only invoked via POST)", async () => {
  const res = await handler(hookReq({}, "GET"));
  assertEquals(res.status, 200);
});

Deno.test("handler: realistic payload shape from GoTrue -> allow", async () => {
  const payload = {
    metadata: {
      uuid: "8b34dcdd-9df1-4c10-850a-b3277c653040",
      time: "2025-04-29T13:13:24.755552-07:00",
      name: "before-user-created",
      ip_address: "127.0.0.1",
    },
    user: {
      id: "ff7fc9ae-3b1b-4642-9241-64adb9848a03",
      aud: "authenticated",
      role: "",
      email: "newuser@transformfit.test",
      phone: "",
      app_metadata: { provider: "email", providers: ["email"] },
      user_metadata: {},
      identities: [],
      created_at: "0001-01-01T00:00:00Z",
      updated_at: "0001-01-01T00:00:00Z",
      is_anonymous: false,
    },
  };
  const res = await handler(hookReq(payload));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), {});
});

Deno.test("handler: realistic payload with @example.com -> error.http_code=422 reject", async () => {
  const payload = {
    metadata: { name: "before-user-created", ip_address: "127.0.0.1" },
    user: { id: "u1", email: "spammer@Example.com", is_anonymous: false },
  };
  const res = await handler(hookReq(payload));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.error.http_code, 422);
});
