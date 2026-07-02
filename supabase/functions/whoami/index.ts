// whoami — the canonical authenticated edge function.
//
// Establishes the edge-function auth pattern (architecture.md §4.2):
//   - The acting user is resolved FROM THE JWT ONLY via _shared/auth.ts.
//   - Any caller-supplied `user_id` in the request body is IGNORED and
//     reflected back as `body_user_id_ignored` so impersonation is observable.
//   - Requests with no / malformed / undecodable JWT are rejected with 401
//     and perform NO mutation (this function is read-only by construction).
//
// Deploy with `--verify-jwt` so the Supabase gateway validates the JWT
// signature + expiry before the function runs; _shared/auth.ts enforces
// presence + decodability + `sub` as defense-in-depth and so the
// impersonation guard is testable.
//
// This is an auth-only function (no OpenRouter / no data writes). It is the
// minimal surface for VAL-AUTH-022 (JWT-only, body user_id ignored) and
// VAL-AUTH-023 (no/invalid JWT -> 401, no mutation).

import { resolveUser, type AuthUser } from "../_shared/auth.ts";

interface WhoamiResponse {
  user: AuthUser;
  /** The user_id supplied in the request body, if any — explicitly IGNORED. */
  body_user_id_ignored: string | null;
  /** "jwt" — the user was resolved from the JWT, never from the body. */
  source: "jwt";
  /** True iff the request body supplied a user_id that differed from the JWT subject. */
  impersonation_attempt: boolean;
}

export async function handler(req: Request): Promise<Response> {
  const { user, response } = await resolveUser(req);
  if (response !== null || user === null) {
    // No/invalid JWT: reject and perform no mutation (read-only function).
    return response ?? new Response("Unauthorized", { status: 401 });
  }

  // Parse the body ONLY to surface (and explicitly ignore) any caller-supplied
  // user_id. We never use a body user_id as the acting identity.
  let bodyUserId: string | null = null;
  try {
    if (req.method === "POST" || req.method === "PUT" || req.method === "PATCH") {
      const text = await req.text();
      if (text.length > 0) {
        const parsed: unknown = JSON.parse(text);
        if (parsed && typeof parsed === "object" && "user_id" in parsed) {
          const v = (parsed as Record<string, unknown>).user_id;
          bodyUserId = typeof v === "string" ? v : null;
        }
      }
    }
  } catch {
    // Malformed body is irrelevant for whoami; the JWT-derived user stands.
    bodyUserId = bodyUserId; // keep whatever (likely null) we have
  }

  const result: WhoamiResponse = {
    user,
    body_user_id_ignored: bodyUserId,
    source: "jwt",
    impersonation_attempt:
      bodyUserId !== null && bodyUserId !== user.id,
  };

  return new Response(JSON.stringify(result), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
}

Deno.serve(handler);
