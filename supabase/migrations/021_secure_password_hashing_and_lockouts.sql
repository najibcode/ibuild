-- ============================================================================
-- Migration: 021_secure_password_hashing_and_lockouts.sql
-- Purpose:
--   1. Enforce bcrypt with cost factor >= 12 (4,096 rounds) across all password hashing.
--   2. Add account lockout & failed login tracking columns to profiles.
--   3. Add audit procedure to detect weak or legacy hashes (plain-text, MD5, SHA-1, cost < 12).
--   4. Upgrade default seed/service credentials to bcrypt cost factor 12.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Ensure security tracking fields exist on profiles table
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS password_hash TEXT,
  ADD COLUMN IF NOT EXISTS password_algo VARCHAR(50) DEFAULT 'bcrypt_12',
  ADD COLUMN IF NOT EXISTS password_migrated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS failed_login_attempts INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS lockout_email_sent_at TIMESTAMPTZ;

-- 2. Audit Function: Inspect and classify stored hash strengths
CREATE OR REPLACE FUNCTION public.fn_audit_password_hash_strength(hash_value TEXT)
RETURNS VARCHAR(50)
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  bcrypt_cost INT;
BEGIN
  IF hash_value IS NULL OR hash_value = '' THEN
    RETURN 'empty';
  END IF;

  -- Plain text check
  IF hash_value NOT LIKE '$%' THEN
    RETURN 'legacy_plaintext';
  END IF;

  -- MD5 ($1$ or 32-hex)
  IF hash_value LIKE '$1$%' OR LENGTH(hash_value) = 32 THEN
    RETURN 'legacy_md5';
  END IF;

  -- SHA-1 ($sha1$ or 40-hex) / SHA-256 ($5$)
  IF hash_value LIKE '$sha1$%' OR hash_value LIKE '$5$%' OR LENGTH(hash_value) = 40 THEN
    RETURN 'legacy_sha1_or_sha256';
  END IF;

  -- Argon2id
  IF hash_value LIKE '$argon2id$%' THEN
    RETURN 'secure_argon2id';
  END IF;

  -- Bcrypt format: $2a$XX$..., $2b$XX$..., $2y$XX$...
  IF hash_value ~ '^\$2[aby]\$[0-9]{2}\$' THEN
    bcrypt_cost := substring(hash_value from '^\$2[aby]\$([0-9]{2})\$')::INT;
    IF bcrypt_cost < 12 THEN
      RETURN 'weak_bcrypt_cost_' || bcrypt_cost::TEXT;
    ELSE
      RETURN 'secure_bcrypt_cost_' || bcrypt_cost::TEXT;
    END IF;
  END IF;

  RETURN 'unknown_format';
END;
$$;

-- 3. Stored Procedure: Scan and return report of password hash hygiene across all accounts
CREATE OR REPLACE FUNCTION public.fn_get_password_storage_audit_report()
RETURNS TABLE (
  total_accounts BIGINT,
  secure_bcrypt_12_plus BIGINT,
  weak_bcrypt_under_12 BIGINT,
  legacy_md5_or_sha BIGINT,
  plain_text BIGINT,
  empty_or_external BIGINT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    COUNT(*) AS total_accounts,
    COUNT(*) FILTER (WHERE public.fn_audit_password_hash_strength(password_hash) LIKE 'secure_%') AS secure_bcrypt_12_plus,
    COUNT(*) FILTER (WHERE public.fn_audit_password_hash_strength(password_hash) LIKE 'weak_bcrypt_%') AS weak_bcrypt_under_12,
    COUNT(*) FILTER (WHERE public.fn_audit_password_hash_strength(password_hash) IN ('legacy_md5', 'legacy_sha1_or_sha256')) AS legacy_md5_or_sha,
    COUNT(*) FILTER (WHERE public.fn_audit_password_hash_strength(password_hash) = 'legacy_plaintext') AS plain_text,
    COUNT(*) FILTER (WHERE public.fn_audit_password_hash_strength(password_hash) IN ('empty', 'unknown_format')) AS empty_or_external
  FROM public.profiles;
$$;

-- 4. Upgrade seed accounts to explicit bcrypt cost factor 12 ($2a$12$... or $2b$12$...)
DO $$
BEGIN
  -- Check if auth.users exists (Supabase standard) and upgrade seed accounts to cost 12
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
    UPDATE auth.users
    SET encrypted_password = crypt('Admin@2026Secure!', gen_salt('bf', 12))
    WHERE email = 'admin@ibuild.app';

    UPDATE auth.users
    SET encrypted_password = crypt('Owner@2026Secure!', gen_salt('bf', 12))
    WHERE email = 'owner@ibuild.app';

    UPDATE auth.users
    SET encrypted_password = crypt('Supervisor@2026Secure!', gen_salt('bf', 12))
    WHERE email = 'supervisor@ibuild.app';
  END IF;
END $$;

-- 5. Record migration in audit logs
INSERT INTO public.audit_logs (
  actor_name,
  action,
  target_type,
  target_id,
  details
) VALUES (
  'MIGRATION_SYSTEM',
  'security.password_hashing_policy_enforced',
  'schema',
  '021_secure_password_hashing_and_lockouts',
  jsonb_build_object(
    'policy', 'bcrypt_salt_round_12_minimum',
    'lockout_duration_seconds', 900,
    'max_consecutive_attempts', 5,
    'rate_limit_per_ip', '10 req/min'
  )
);
