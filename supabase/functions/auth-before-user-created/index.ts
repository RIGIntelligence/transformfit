// Supabase Auth Hook: before_user_created (HTTP / Edge Function)
//
// Rejects signups whose email domain is `example.com` (case-insensitive, exact
// domain match — subdomains like `sub.example.com` are NOT blocked). This
// satisfies VAL-AUTH-002: GoTrue must reject `@example.com` signups with a 4xx
// error and create no user, while realistic domains (@gmail.com,
// @transformfit.test) still succeed.
//
// Contract (https://supabase.com/docs/guides/auth/auth-hooks/before-user-created-hook):
//   Request body : { metadata: {...}, user: { email, ... } }
//   Allow        : HTTP 200/204 with `{}` (or empty body).
//   Reject       : HTTP 200 with `{ "error": { "http_code": <int>, "message": <str> } }`.
//
// IMPORTANT: GoTrue's HTTP hook client treats any non-2xx response status as an
// "unexpected failure" (HTTP 500 to the client). To propagate a specific 4xx to
// the signup caller, the hook MUST return HTTP 200 and carry the desired
// client-facing status inside `error.http_code`. Verified empirically against
// project zuwtgdqsxmtiqojckpus: a 422 response status yields
// `{"code":500,"error_code":"unexpected_failure","msg":"Unexpected status code
// returned from hook: 422"}`, whereas HTTP 200 + `error.http_code=422`
// propagates a 422 to the /auth/v1/signup caller.
//
// Deployed with `--no-verify-jwt` because GoTrue invokes the hook server-side
// without a user JWT. The function performs no data writes and only inspects
// the email domain, so unauthenticated direct calls are harmless.

const BLOCKED_DOMAIN = "example.com";

/**
 * Decide whether a signup email should be blocked.
 * Returns `true` only when the email's domain is exactly `example.com`
 * (case-insensitive). Subdomains are not matched.
 */
export function isBlockedEmail(email: string | null | undefined): boolean {
  if (!email) return false;
  const atIdx = email.lastIndexOf("@");
  if (atIdx < 0 || atIdx === email.length - 1) return false;
  const domain = email.slice(atIdx + 1).toLowerCase();
  return domain === BLOCKED_DOMAIN;
}

function reject(message: string, httpCode = 422): Response {
  // GoTrue's HTTP hook client only accepts 2xx response statuses. The
  // client-facing status is carried inside `error.http_code`, which GoTrue
  // propagates to the /auth/v1/signup caller.
  return new Response(
    JSON.stringify({ error: { http_code: httpCode, message } }),
    {
      status: 200,
      headers: { "content-type": "application/json" },
    },
  );
}

function allow(): Response {
  return new Response("{}", {
    status: 200,
    headers: { "content-type": "application/json" },
  });
}

export async function handler(req: Request): Promise<Response> {
  // The hook is invoked via POST. Be tolerant: an empty body / non-JSON body
  // is treated as "no email to evaluate" -> allow (let GoTrue apply its own
  // validation). We never 5xx; an unexpected error also falls back to allow so
  // the hook never hard-blocks all signups on a runtime fault.
  if (req.method !== "POST") {
    return allow();
  }

  let payload: { user?: { email?: string } } = {};
  try {
    const text = await req.text();
    if (text.length > 0) {
      payload = JSON.parse(text);
    }
  } catch {
    return allow();
  }

  const email = payload?.user?.email;
  if (isBlockedEmail(email)) {
    return reject(
      "Signups from the example.com domain are not permitted.",
      422,
    );
  }

  return allow();
}

Deno.serve(handler);
