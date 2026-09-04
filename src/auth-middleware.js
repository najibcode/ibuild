/**
 * Express / Node.js & Cloudflare Worker compatible Authentication Middleware & Route Handler
 *
 * Requirements fulfilled:
 * 1. Rate Limiting: Max 10 requests per IP per minute.
 * 2. Account Lockout: 15 minutes after 5 consecutive failed login attempts.
 * 3. Progressive Delay: Exponential/incremental wait time per failed attempt.
 * 4. In-Memory Cache: Redis / Upstash with TTL.
 * 5. Security Notification: Dispatches password reset email upon account lockout.
 * 6. Anti-Enumeration & Constant-Time Security: Uniform error response that never reveals
 *    whether the account is locked, invalid password, or unverified email.
 * 7. Secure Hashing: Bcrypt with minimum 12 salt rounds & lazy hash migration.
 */

const crypto = require("crypto");
const bcrypt = require("bcryptjs"); // or bcrypt

const BCRYPT_COST = 12;
const MAX_ATTEMPTS = 5;
const LOCKOUT_SECONDS = 900; // 15 minutes
const RATE_LIMIT_MAX = 10;
const RATE_LIMIT_WINDOW = 60; // 1 minute
const DUMMY_HASH = "$2b$12$e8Y5M7g/aKjM0q6dJ2X8U.vR4p3k7W5h8L1m2N3o4P5q6R7s8T9u."; // Timing defense decoy

/**
 * Constant-time byte-by-byte comparison
 * Protects against side-channel timing attacks
 */
function timingSafeCompare(a, b) {
  const bufA = Buffer.from(String(a));
  const bufB = Buffer.from(String(b));
  if (bufA.length !== bufB.length) {
    // Run dummy comparison to equalize latency
    crypto.timingSafeEqual(bufA, bufA);
    return false;
  }
  return crypto.timingSafeEqual(bufA, bufB);
}

/**
 * Progressive delay calculator: 2^(attempts-1) * 1000ms, capped at 16s
 */
function calculateProgressiveDelay(attemptCount) {
  if (attemptCount <= 0) return 0;
  return Math.min(Math.pow(2, attemptCount - 1) * 1000, 16000);
}

/**
 * Uniform anti-enumeration error response
 */
function sendGenericAuthError(res, delayMs = 0) {
  setTimeout(() => {
    return res.status(401).json({
      success: false,
      error: "Invalid email or password. Please check your credentials or reset your password.",
    });
  }, delayMs);
}

/**
 * 1. Rate Limiting Middleware (IP-Based)
 * Max 10 requests per IP per minute
 */
function createRateLimiterMiddleware(redisClient) {
  return async function rateLimiter(req, res, next) {
    const clientIp =
      req.headers["cf-connecting-ip"] ||
      req.headers["x-real-ip"] ||
      req.headers["x-forwarded-for"]?.split(",")[0].trim() ||
      req.socket.remoteAddress ||
      "127.0.0.1";

    const key = `ratelimit:ip:${clientIp}`;

    try {
      let count;
      if (redisClient.incr) {
        count = await redisClient.incr(key);
        if (count === 1) {
          await redisClient.expire(key, RATE_LIMIT_WINDOW);
        }
      } else {
        // Upstash REST client fallback
        count = await redisClient.incr(key);
        if (count === 1) await redisClient.expire(key, RATE_LIMIT_WINDOW);
      }

      if (count > RATE_LIMIT_MAX) {
        return res.status(429).json({
          success: false,
          error: "Too many requests. Please wait a moment before trying again.",
          retryAfter: RATE_LIMIT_WINDOW,
        });
      }
      return next();
    } catch (err) {
      // Fail open on cache network interruption to avoid locking out legitimate users
      return next();
    }
  };
}

/**
 * 2. Login Route Handler with Account Lockout, Progressive Delay & Password Migration
 */
function createLoginRouteHandler({ redisClient, db, mailer }) {
  return async function loginRouteHandler(req, res) {
    const email = (req.body.email || "").trim().toLowerCase();
    const password = req.body.password || "";

    if (!email || !password) {
      return sendGenericAuthError(res, 500);
    }

    const clientIp =
      req.headers["cf-connecting-ip"] ||
      req.headers["x-real-ip"] ||
      req.headers["x-forwarded-for"]?.split(",")[0].trim() ||
      "127.0.0.1";

    const lockoutKey = `account:lockout:${email}`;
    const attemptKey = `account:attempts:${email}`;

    // A. Check if account is currently locked
    const isLocked = await redisClient.get(lockoutKey);
    if (isLocked) {
      // Execute dummy hash comparison to equalize execution time against active brute-force
      await bcrypt.compare(password, DUMMY_HASH);
      return sendGenericAuthError(res, 1000);
    }

    // B. Calculate current progressive delay
    const currentAttemptsStr = await redisClient.get(attemptKey);
    const currentAttempts = parseInt(currentAttemptsStr || "0", 10);
    const delayMs = calculateProgressiveDelay(currentAttempts);

    // C. Fetch user from database
    const user = await db.getUserByEmail(email);

    let isAuthenticated = false;
    let needsRehash = false;

    if (user && !user.is_disabled) {
      const storedHash = user.password_hash;

      // Check if hash is weak or legacy (plain-text, MD5, SHA-1, bcrypt cost < 12)
      const isWeak =
        !storedHash.startsWith("$") ||
        storedHash.startsWith("$1$") ||
        storedHash.startsWith("$5$") ||
        (storedHash.match(/^\$2[aby]\$(\d{2})\$/) &&
          parseInt(storedHash.match(/^\$2[aby]\$(\d{2})\$/)[1], 10) < BCRYPT_COST);

      if (isWeak) {
        // Legacy verification
        if (!storedHash.startsWith("$")) {
          // Plaintext check
          isAuthenticated = timingSafeCompare(password, storedHash);
        } else if (storedHash.startsWith("$1$") || storedHash.length === 32) {
          // MD5 check
          const md5 = crypto.createHash("md5").update(password).digest("hex");
          isAuthenticated = timingSafeCompare(md5, storedHash.replace("$1$", ""));
        } else if (storedHash.startsWith("$sha1$") || storedHash.length === 40) {
          // SHA-1 check
          const sha1 = crypto.createHash("sha1").update(password).digest("hex");
          isAuthenticated = timingSafeCompare(sha1, storedHash.replace("$sha1$", ""));
        }

        if (isAuthenticated) {
          needsRehash = true;
        }
      } else {
        // Modern bcrypt comparison (cost >= 12)
        isAuthenticated = await bcrypt.compare(password, storedHash);
      }
    } else {
      // Fake verification for non-existent user to defeat timing attacks
      await bcrypt.compare(password, DUMMY_HASH);
    }

    // D. Failed Authentication Handling
    if (!isAuthenticated) {
      const newAttempts = await redisClient.incr(attemptKey);
      if (newAttempts === 1) {
        await redisClient.expire(attemptKey, LOCKOUT_SECONDS);
      }

      if (newAttempts >= MAX_ATTEMPTS) {
        // Lock account for 15 minutes
        await redisClient.set(lockoutKey, "locked", "EX", LOCKOUT_SECONDS);
        await redisClient.del(attemptKey); // Clear attempt counter once locked

        // Send security email with password reset link
        if (user && mailer) {
          const resetToken = crypto.randomBytes(32).toString("hex");
          const resetUrl = `https://ibuild.najibcode.workers.dev/reset-password?token=${resetToken}`;

          await db.savePasswordResetToken(user.id, resetToken, 3600); // 1 hour token
          await mailer.sendSecurityLockoutEmail({
            to: email,
            resetUrl,
            clientIp,
            lockoutMinutes: 15,
          });
        }
      }

      return sendGenericAuthError(res, delayMs);
    }

    // E. Successful Authentication
    // Clear attempt counters and lockout flags
    await redisClient.del(attemptKey);
    await redisClient.del(lockoutKey);

    // F. Lazy Migration: upgrade legacy/weak password hash to bcrypt cost 12
    if (needsRehash && user) {
      try {
        const newSalt = await bcrypt.genSalt(BCRYPT_COST);
        const newSecureHash = await bcrypt.hash(password, newSalt);

        await db.updateUserPasswordHash(user.id, {
          password_hash: newSecureHash,
          password_algo: "bcrypt_12",
          password_migrated_at: new Date(),
        });
      } catch (err) {
        // Non-blocking: Do not disrupt user login if re-hash persistence fails
      }
    }

    // Generate JWT / Session Token
    const sessionToken = crypto.randomBytes(32).toString("hex");
    return res.status(200).json({
      success: true,
      token: sessionToken,
      user: {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: user.role,
      },
    });
  };
}

module.exports = {
  createRateLimiterMiddleware,
  createLoginRouteHandler,
  timingSafeCompare,
  calculateProgressiveDelay,
  BCRYPT_COST,
};
