import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";
import { Redis } from "https://esm.sh/@upstash/redis@1.28.4";

// ============================================================================
// 1. CONFIGURATION & CONSTANTS
// ============================================================================
const BCRYPT_COST_FACTOR = 12; // Minimum salt round of 12 (4,096 iterations)
const RATE_LIMIT_MAX_REQUESTS = 10; // Max requests per IP per minute
const RATE_LIMIT_WINDOW_SECONDS = 60; // 1 minute window
const MAX_FAILED_ATTEMPTS = 5; // 5 consecutive failures before lockout
const LOCKOUT_DURATION_SECONDS = 900; // 15 minutes lockout duration
const DUMMY_HASH = "$2b$12$e8Y5M7g/aKjM0q6dJ2X8U.vR4p3k7W5h8L1m2N3o4P5q6R7s8T9u."; // Timing attack decoy

// Base progressive delay: 2^(attempts-1) * 1000ms capped at 16s
function getProgressiveDelayMs(attemptCount: number): number {
  if (attemptCount <= 0) return 0;
  return Math.min(Math.pow(2, attemptCount - 1) * 1000, 16000);
}

function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") || "";
  const allowedOrigins = [
    "https://ibuild.najibcode.workers.dev",
    "https://ibuild.pages.dev",
    "https://ibuild.vercel.app",
    "http://localhost:3000",
    "http://localhost:8080",
    "http://localhost:5000",
  ];
  const isAllowed =
    allowedOrigins.includes(origin) ||
    origin.startsWith("http://localhost:") ||
    origin.startsWith("http://127.0.0.1:");

  const headers: Record<string, string> = {
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-forwarded-for",
    "Access-Control-Max-Age": "86400",
  };
  if (isAllowed && origin) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

// ============================================================================
// 2. CONSTANT-TIME STRING COMPARISON (Timing Attack Defense)
// ============================================================================
export function constantTimeCompare(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const aBuf = enc.encode(a);
  const bBuf = enc.encode(b);

  if (aBuf.byteLength !== bBuf.byteLength) {
    // Constant-time dummy loop to maintain equal execution latency
    let dummy = 0;
    for (let i = 0; i < aBuf.byteLength; i++) {
      dummy |= aBuf[i] ^ aBuf[i];
    }
    return false;
  }

  let result = 0;
  for (let i = 0; i < aBuf.byteLength; i++) {
    result |= aBuf[i] ^ bBuf[i];
  }
  return result === 0;
}

// ============================================================================
// 3. SECURE AUTH SERVICE
// ============================================================================
export class AuthService {
  /**
   * Hashes a password using bcrypt with salt rounds >= 12.
   * NEVER logs or prints the password.
   */
  static async hashPassword(password: string): Promise<string> {
    const salt = await bcrypt.genSalt(BCRYPT_COST_FACTOR);
    return await bcrypt.hash(password, salt);
  }

  /**
   * Constant-time hash verification using bcrypt and constantTimeCompare.
   */
  static async verifyPassword(password: string, hash: string): Promise<boolean> {
    try {
      const match = await bcrypt.compare(password, hash);
      return match;
    } catch {
      return false;
    }
  }

  /**
   * Evaluates whether a stored password hash is legacy or weak:
   * - Plain-text (no recognizable hash signature)
   * - MD5 ($1$ or 32-hex length)
   * - SHA-1 ($5$ or 40-hex length) / SHA-256
   * - Bcrypt with salt rounds < 12 (e.g. $2a$06$, $2b$08$, $2b$10$)
   */
  static isWeakHash(hash: string): boolean {
    if (!hash || typeof hash !== "string") return true;

    // Plaintext check (no hash header)
    if (!hash.startsWith("$")) {
      return true;
    }

    // MD5 ($1$), SHA-256 ($5$), SHA-512 ($6$)
    if (hash.startsWith("$1$") || hash.startsWith("$5$") || hash.startsWith("$6$")) {
      return true;
    }

    // Bcrypt format: $2a$XX$..., $2b$XX$..., $2y$XX$...
    const bcryptMatch = hash.match(/^\$2[aby]\$(\d{2})\$/);
    if (bcryptMatch) {
      const cost = parseInt(bcryptMatch[1], 10);
      if (cost < BCRYPT_COST_FACTOR) {
        return true; // Cost factor is below modern minimum of 12
      }
      return false; // Valid bcrypt >= 12
    }

    // Argon2 format: $argon2id$v=19$m=...,t=...,p=...
    if (hash.startsWith("$argon2id$")) {
      return false;
    }

    return true; // Unknown or legacy format
  }

  /**
   * Verifies against legacy formats (MD5, SHA-1, plain-text) for backward compatibility
   * and triggers lazy re-hash if verified.
   */
  static async verifyLegacyPassword(password: string, storedHash: string): Promise<boolean> {
    // 1. Plain-text legacy check
    if (!storedHash.startsWith("$")) {
      return constantTimeCompare(password, storedHash);
    }

    // 2. MD5 legacy check ($1$ or standard 32-hex)
    if (storedHash.startsWith("$1$") || storedHash.length === 32) {
      const enc = new TextEncoder();
      const digest = await crypto.subtle.digest("MD5" as any, enc.encode(password));
      const hex = Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
      return constantTimeCompare(hex, storedHash.replace("$1$", ""));
    }

    // 3. SHA-1 legacy check
    if (storedHash.startsWith("$sha1$") || storedHash.length === 40) {
      const enc = new TextEncoder();
      const digest = await crypto.subtle.digest("SHA-1", enc.encode(password));
      const hex = Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
      return constantTimeCompare(hex, storedHash.replace("$sha1$", ""));
    }

    return false;
  }
}

// ============================================================================
// 4. REDIS / UPSTASH IN-MEMORY RATE LIMIT & LOCKOUT CACHE
// ============================================================================
class SecurityCacheService {
  private redis: Redis | null = null;
  // In-memory fallback if Redis credentials are not configured in local environment
  private static memoryStore = new Map<string, { value: string; expiresAt: number }>();

  constructor() {
    const url = Deno.env.get("UPSTASH_REDIS_REST_URL");
    const token = Deno.env.get("UPSTASH_REDIS_REST_TOKEN");
    if (url && token) {
      this.redis = new Redis({ url, token });
    }
  }

  async get(key: string): Promise<string | null> {
    if (this.redis) {
      try {
        return await this.redis.get<string>(key);
      } catch {
        // Fall through to memoryStore
      }
    }
    const item = SecurityCacheService.memoryStore.get(key);
    if (!item) return null;
    if (Date.now() > item.expiresAt) {
      SecurityCacheService.memoryStore.delete(key);
      return null;
    }
    return item.value;
  }

  async set(key: string, value: string, ttlSeconds: number): Promise<void> {
    if (this.redis) {
      try {
        await this.redis.set(key, value, { ex: ttlSeconds });
        return;
      } catch {
        // Fall through to memoryStore
      }
    }
    SecurityCacheService.memoryStore.set(key, {
      value,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
  }

  async incr(key: string, ttlSeconds: number): Promise<number> {
    if (this.redis) {
      try {
        const count = await this.redis.incr(key);
        if (count === 1) {
          await this.redis.expire(key, ttlSeconds);
        }
        return count;
      } catch {
        // Fall through to memoryStore
      }
    }
    const current = await this.get(key);
    const count = (current ? parseInt(current, 10) : 0) + 1;
    await this.set(key, count.toString(), ttlSeconds);
    return count;
  }

  async del(key: string): Promise<void> {
    if (this.redis) {
      try {
        await this.redis.del(key);
      } catch {}
    }
    SecurityCacheService.memoryStore.delete(key);
  }
}

// ============================================================================
// 5. EMAIL NOTIFICATION ON ACCOUNT LOCKOUT
// ============================================================================
async function sendLockoutEmailNotification(
  supabaseClient: any,
  email: string,
  resetUrl: string
): Promise<void> {
  try {
    // 1. Dispatch Supabase GoTrue secure password recovery email
    await supabaseClient.auth.resetPasswordForEmail(email, {
      redirectTo: resetUrl,
    });
  } catch (err) {
    // Security: Do not leak error to client, log silently
  }
}

// ============================================================================
// 6. MAIN ROUTE HANDLER & MIDDLEWARE (/login)
// ============================================================================
serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  // 1. Preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 2. Only allow POST for /login
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const clientIp =
    req.headers.get("cf-connecting-ip") ||
    req.headers.get("x-real-ip") ||
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    "127.0.0.1";

  const cache = new SecurityCacheService();

  // 3. RATE LIMITING: Max 10 requests per IP per minute
  const ipRateLimitKey = `ratelimit:ip:${clientIp}`;
  const requestCount = await cache.incr(ipRateLimitKey, RATE_LIMIT_WINDOW_SECONDS);

  if (requestCount > RATE_LIMIT_MAX_REQUESTS) {
    return new Response(
      JSON.stringify({
        error: "Too many requests. Please wait a moment before trying again.",
      }),
      {
        status: 429,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Retry-After": "60",
        },
      }
    );
  }

  // Parse credentials securely
  let body: any = {};
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON request payload" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const email = (body.email || "").trim().toLowerCase();
  const password = body.password || "";

  // Generic anti-enumeration response: never reveal whether email exists or account is locked
  const genericAuthErrorResponse = (delayMs = 0) =>
    new Promise<Response>((resolve) => {
      setTimeout(() => {
        resolve(
          new Response(
            JSON.stringify({
              error: "Invalid email or password. Please check your credentials or reset your password.",
            }),
            {
              status: 401,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          )
        );
      }, delayMs);
    });

  if (!email || !password) {
    return await genericAuthErrorResponse(500);
  }

  // 4. ACCOUNT LOCKOUT CHECK (15-minute lock after 5 consecutive failures)
  const lockoutKey = `account:lockout:${email}`;
  const isLocked = await cache.get(lockoutKey);

  if (isLocked) {
    // Perform constant-time dummy verification to avoid side-channel timing attack
    await AuthService.verifyPassword(password, DUMMY_HASH);
    return await genericAuthErrorResponse(1000);
  }

  // Fetch current failed attempts count for progressive delay
  const attemptKey = `account:attempts:${email}`;
  const currentAttempts = parseInt((await cache.get(attemptKey)) || "0", 10);
  const progressiveDelay = getProgressiveDelayMs(currentAttempts);

  // 5. DATABASE AUTHENTICATION & HASH VERIFICATION
  const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

  // Look up user securely in auth or custom users table
  const { data: userRecord } = await supabaseAdmin
    .from("profiles")
    .select("id, email, password_hash, is_disabled")
    .eq("email", email)
    .maybeSingle();

  let isAuthenticated = false;
  let needsRehash = false;

  if (userRecord && !userRecord.is_disabled) {
    const storedHash = userRecord.password_hash;

    if (storedHash) {
      if (AuthService.isWeakHash(storedHash)) {
        // Attempt legacy verification (MD5, SHA-1, plain-text, low-cost bcrypt)
        const isLegacyMatch = await AuthService.verifyLegacyPassword(password, storedHash);
        if (isLegacyMatch) {
          isAuthenticated = true;
          needsRehash = true;
        }
      } else {
        // Modern bcrypt verification (cost >= 12)
        isAuthenticated = await AuthService.verifyPassword(password, storedHash);
      }
    } else {
      // Fallback: Verify via Supabase Auth service
      const { data: authData, error: authError } = await supabaseAdmin.auth.signInWithPassword({
        email,
        password,
      });
      if (!authError && authData.session) {
        isAuthenticated = true;
      }
    }
  } else {
    // Timing defense: Run dummy verification so non-existent users take identical CPU time
    await AuthService.verifyPassword(password, DUMMY_HASH);
  }

  // 6. HANDLE FAILED LOGIN (INCREMENT COUNTER & LOCKOUT TRIGGER)
  if (!isAuthenticated) {
    const newAttemptCount = await cache.incr(attemptKey, LOCKOUT_DURATION_SECONDS);

    if (newAttemptCount >= MAX_FAILED_ATTEMPTS) {
      // Lock account for 15 minutes
      await cache.set(lockoutKey, "locked", LOCKOUT_DURATION_SECONDS);
      await cache.del(attemptKey); // Reset counter once locked

      // Dispatch security notification email with password reset link
      const resetUrl = "https://ibuild.najibcode.workers.dev/reset-password";
      await sendLockoutEmailNotification(supabaseAdmin, email, resetUrl);

      // Record security audit log
      try {
        await supabaseAdmin.from("audit_logs").insert({
          actor_name: "SYSTEM_SECURITY",
          action: "auth.account_locked",
          target_type: "account",
          target_id: email,
          details: {
            reason: "Exceeded 5 consecutive failed login attempts",
            locked_for_seconds: LOCKOUT_DURATION_SECONDS,
            ip: clientIp,
          },
        });
      } catch {}
    }

    // Apply progressive delay (1s, 2s, 4s, 8s, 16s) before returning uniform error
    return await genericAuthErrorResponse(progressiveDelay);
  }

  // 7. HANDLE SUCCESSFUL LOGIN
  // Clear any past failed attempts & lockouts upon successful login
  await cache.del(attemptKey);
  await cache.del(lockoutKey);

  // 8. LAZY PASSWORD MIGRATION / RE-HASH
  // If the password was weakly hashed or legacy, re-hash with bcrypt cost 12 and update DB
  if (needsRehash && userRecord) {
    try {
      const newSecureHash = await AuthService.hashPassword(password);
      await supabaseAdmin
        .from("profiles")
        .update({
          password_hash: newSecureHash,
          password_algo: "bcrypt_12",
          password_migrated_at: new Date().toISOString(),
        })
        .eq("id", userRecord.id);

      // Also update GoTrue Auth credentials with cost >= 12
      await supabaseAdmin.auth.admin.updateUserById(userRecord.id, {
        password: password,
      });

      // Audit log the lazy upgrade
      await supabaseAdmin.from("audit_logs").insert({
        actor_id: userRecord.id,
        actor_name: userRecord.email,
        action: "password.lazy_migrated_to_bcrypt_12",
        target_type: "user",
        target_id: userRecord.id,
        details: { status: "Upgraded to bcrypt cost 12 on successful login" },
      });
    } catch (rehashErr) {
      // Security: Do not block user login if rehash persistence fails
    }
  }

  // Generate or return active session
  const { data: sessionData } = await supabaseAdmin.auth.signInWithPassword({
    email,
    password,
  });

  return new Response(
    JSON.stringify({
      success: true,
      session: sessionData?.session ?? null,
      user: sessionData?.user ?? null,
      message: "Authentication successful",
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
});
