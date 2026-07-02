// Shared JWT-resolution helper for authenticated edge functions.
//
// Binding invariant (architecture.md §4.2, L6, VAL-AUTH-022/023):
//   Edge functions resolve the acting user FROM THE JWT ONLY. Any caller-
//   supplied `user_id` in the request body / query is IGNORED (impersonation
//   guard). Requests with no / malformed / undecodable JWT are rejected with
//   401 and perform NO data mutation.
//
// Signature verification: this helper verifies HS256 Supabase JWTs using
// SUPABASE_JWT_SECRET and fails closed when the secret is unavailable. It also
// checks exp, iss, and aud so a function accidentally deployed with
// `--no-verify-jwt` still rejects forged or expired tokens.
//
// This helper NEVER trusts a caller-supplied user_id. The returned `AuthUser`
// is derived exclusively from the JWT `sub` / `email` / `role` claims.

/** The acting user, resolved from the JWT only. */
export interface AuthUser {
  id: string;
  email: string | null;
  role: string | null;
}

/** Result of resolveUser: either a valid user, or a rejection Response to send. */
export interface ResolveResult {
  user: AuthUser | null;
  /** When non-null, send this Response to the caller (401) and stop. */
  response: Response | null;
}

/** Build a 401 Response with a JSON error body. Performs no mutation. */
export function unauthorized(message: string): Response {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status: 401,
      headers: { "content-type": "application/json" },
    },
  );
}

/**
 * Base64url-decode a string into a UTF-8 string.
 * Handles the URL-safe alphabet (- and _ instead of + and /) and missing padding.
 */
export function base64urlDecode(input: string): string | null {
  try {
    // Convert base64url -> base64, pad to a multiple of 4.
    let s = input.replace(/-/g, "+").replace(/_/g, "/");
    const pad = s.length % 4;
    if (pad === 2) s += "==";
    else if (pad === 3) s += "=";
    else if (pad === 1) return null; // invalid length
    // atob decodes base64 to a binary string; decode as UTF-8.
    const binary = atob(s);
    const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
    return new TextDecoder("utf-8").decode(bytes);
  } catch {
    return null;
  }
}

/** Payload type for the decoded JWT middle segment. */
export interface JwtPayload {
  sub?: string;
  email?: string;
  role?: string;
  exp?: number;
  iat?: number;
  iss?: string;
  aud?: string | string[];
  [key: string]: unknown;
}

export interface JwtHeader {
  alg?: string;
  typ?: string;
  [key: string]: unknown;
}

/**
 * Decode (NOT signature-verify) a JWT's payload. Returns null if the token is
 * structurally invalid. Signature + expiry verification is the gateway's job
 * (deploy with --verify-jwt); this helper only extracts the claims it needs
 * and enforces structural validity + a `sub`.
 */
export function decodeJwtPayload(token: string): JwtPayload | null {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const json = base64urlDecode(parts[1]);
  if (json === null) return null;
  try {
    const payload = JSON.parse(json);
    if (typeof payload !== "object" || payload === null) return null;
    return payload as JwtPayload;
  } catch {
    return null;
  }
}

export function decodeJwtHeader(token: string): JwtHeader | null {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const json = base64urlDecode(parts[0]);
  if (json === null) return null;
  try {
    const header = JSON.parse(json);
    if (typeof header !== "object" || header === null) return null;
    return header as JwtHeader;
  } catch {
    return null;
  }
}

function base64urlToBytes(input: string): Uint8Array | null {
  try {
    let s = input.replace(/-/g, "+").replace(/_/g, "/");
    const pad = s.length % 4;
    if (pad === 2) s += "==";
    else if (pad === 3) s += "=";
    else if (pad === 1) return null;
    const binary = atob(s);
    return Uint8Array.from(binary, (c) => c.charCodeAt(0));
  } catch {
    return null;
  }
}

async function verifyHs256(token: string, secret: string): Promise<boolean> {
  const parts = token.split(".");
  if (parts.length !== 3) return false;
  const header = decodeJwtHeader(token);
  if (!header || header.alg !== "HS256") return false;
  const signature = base64urlToBytes(parts[2]);
  if (signature === null) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const signatureBytes = new Uint8Array(signature.byteLength);
  signatureBytes.set(signature);
  return await crypto.subtle.verify(
    "HMAC",
    key,
    signatureBytes,
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
}

function expectedIssuer(): string {
  return Deno.env.get("SUPABASE_JWT_ISSUER") ?? "supabase";
}

function expectedAudience(): string {
  return Deno.env.get("SUPABASE_JWT_AUDIENCE") ?? "authenticated";
}

function hasAudience(payload: JwtPayload, expected: string): boolean {
  const aud = payload.aud;
  if (typeof aud === "string") return aud === expected;
  if (Array.isArray(aud)) return aud.includes(expected);
  return false;
}

/**
 * Resolve the acting user from the request's Authorization: Bearer <jwt>
 * header. Any caller-supplied user_id (in the body / query) is deliberately
 * ignored — this function never reads the body.
 *
 * Returns { user, response: null } on success, or { user: null, response } on
 * rejection (missing / malformed / undecodable JWT, or no `sub` claim).
 */
export async function resolveUser(req: Request): Promise<ResolveResult> {
  const authHeader =
    req.headers.get("authorization") ?? req.headers.get("Authorization");
  if (!authHeader) {
    return { user: null, response: unauthorized("Missing Authorization header.") };
  }
  const match = /^Bearer\s+(.+)$/i.exec(authHeader.trim());
  if (!match) {
    return { user: null, response: unauthorized("Invalid Authorization header; expected 'Bearer <jwt>'.") };
  }
  const token = match[1].trim();
  if (token.length === 0) {
    return { user: null, response: unauthorized("Empty bearer token.") };
  }
  const payload = decodeJwtPayload(token);
  if (!payload) {
    return { user: null, response: unauthorized("Invalid or malformed JWT.") };
  }
  const secret = Deno.env.get("SUPABASE_JWT_SECRET")?.trim();
  if (!secret) {
    return { user: null, response: unauthorized("JWT verification is not configured.") };
  }
  if (!(await verifyHs256(token, secret))) {
    return { user: null, response: unauthorized("Invalid JWT signature.") };
  }
  const now = Math.floor(Date.now() / 1000);
  if (typeof payload.exp !== "number" || payload.exp <= now) {
    return { user: null, response: unauthorized("JWT is expired or missing exp.") };
  }
  if (payload.iss !== expectedIssuer()) {
    return { user: null, response: unauthorized("JWT issuer is invalid.") };
  }
  if (!hasAudience(payload, expectedAudience())) {
    return { user: null, response: unauthorized("JWT audience is invalid.") };
  }
  if (!payload.sub || typeof payload.sub !== "string" || payload.sub.length === 0) {
    return { user: null, response: unauthorized("JWT has no subject (sub) claim.") };
  }
  return {
    user: {
      id: payload.sub,
      email: typeof payload.email === "string" ? payload.email : null,
      role: typeof payload.role === "string" ? payload.role : null,
    },
    response: null,
  };
}
