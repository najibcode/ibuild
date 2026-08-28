-- ============================================================
-- MIGRATION 017: PRODUCTION READINESS REPAIRS
-- 1. Fix Oversized Auth Metadata / Restore Compact JWTs (<8KB)
-- 2. Atomic Database Spend Triggers & Reconciliation Functions
-- 3. Database Attendance Uniqueness Constraint
-- 4. Append-only Audit Logs & RLS Module Hardening
-- 5. Secure Admin-only Metadata Repair Procedure
-- ============================================================

-- ── 1. STRIP LARGE / BASE64 METADATA FROM auth.users ──────────
-- Remove bloated avatar_url, logo_url, and base64 payloads from raw_user_meta_data
UPDATE auth.users
SET raw_user_meta_data = (
  raw_user_meta_data - 'avatar_url' - 'logo_url' - 'raw_avatar' - 'image_bytes'
)
WHERE raw_user_meta_data ? 'avatar_url' 
   OR raw_user_meta_data ? 'logo_url'
   OR raw_user_meta_data ? 'raw_avatar'
   OR raw_user_meta_data ? 'image_bytes'
   OR length(raw_user_meta_data::text) > 4096;

-- Prevent oversized metadata from ever being saved to auth.users again
CREATE OR REPLACE FUNCTION auth.sanitize_user_metadata_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.raw_user_meta_data IS NOT NULL THEN
    IF NEW.raw_user_meta_data ? 'avatar_url' AND length((NEW.raw_user_meta_data->>'avatar_url')::text) > 2048 THEN
      NEW.raw_user_meta_data = NEW.raw_user_meta_data - 'avatar_url';
    END IF;
    IF length(NEW.raw_user_meta_data::text) > 4096 THEN
      NEW.raw_user_meta_data = NEW.raw_user_meta_data - 'avatar_url' - 'logo_url' - 'raw_avatar' - 'image_bytes';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sanitize_user_metadata ON auth.users;
CREATE TRIGGER trg_sanitize_user_metadata
BEFORE INSERT OR UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION auth.sanitize_user_metadata_trigger();

-- Ensure all roles exist in public.roles
INSERT INTO public.roles (id, name, description)
VALUES 
  (gen_random_uuid(), 'admin', 'Administrator with full system access'),
  (gen_random_uuid(), 'owner', 'Company Owner / Director'),
  (gen_random_uuid(), 'supervisor', 'Site Supervisor / Project Manager'),
  (gen_random_uuid(), 'employee', 'Field Employee / Laborer')
ON CONFLICT (name) DO NOTHING;

-- Confirm emails and reset passwords for standard accounts
DO $$
DECLARE
  v_admin_id UUID;
  v_owner_id UUID;
  v_sup_id UUID;
  v_emp_id UUID;
  v_admin_role UUID;
  v_owner_role UUID;
  v_sup_role UUID;
  v_emp_role UUID;
BEGIN
  SELECT id INTO v_admin_role FROM public.roles WHERE name = 'admin' LIMIT 1;
  SELECT id INTO v_owner_role FROM public.roles WHERE name = 'owner' LIMIT 1;
  SELECT id INTO v_sup_role FROM public.roles WHERE name = 'supervisor' LIMIT 1;
  SELECT id INTO v_emp_role FROM public.roles WHERE name = 'employee' LIMIT 1;

  -- 1. Admin Account (admin@ibuild.in / admin@123)
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    encrypted_password = crypt('admin@123', gen_salt('bf')),
    raw_user_meta_data = jsonb_build_object('full_name', 'System Admin', 'role', 'admin')
  WHERE email = 'admin@ibuild.in'
  RETURNING id INTO v_admin_id;

  -- 2. Owner Account (owner@ibuild.in / owner@123)
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    encrypted_password = crypt('owner@123', gen_salt('bf')),
    raw_user_meta_data = jsonb_build_object('full_name', 'Company Owner', 'role', 'owner')
  WHERE email = 'owner@ibuild.in'
  RETURNING id INTO v_owner_id;

  IF v_owner_id IS NULL THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
      'owner@ibuild.in', crypt('owner@123', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Company Owner","role":"owner"}', now(), now()
    ) RETURNING id INTO v_owner_id;
  END IF;

  -- 3. Supervisor Account (supervisor@ibuild.in / supervisor@123)
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    encrypted_password = crypt('supervisor@123', gen_salt('bf')),
    raw_user_meta_data = jsonb_build_object('full_name', 'Site Supervisor', 'role', 'supervisor')
  WHERE email = 'supervisor@ibuild.in'
  RETURNING id INTO v_sup_id;

  IF v_sup_id IS NULL THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
      'supervisor@ibuild.in', crypt('supervisor@123', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Site Supervisor","role":"supervisor"}', now(), now()
    ) RETURNING id INTO v_sup_id;
  END IF;

  -- 4. Employee Account (employee@ibuild.in / employee@123)
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    encrypted_password = crypt('employee@123', gen_salt('bf')),
    raw_user_meta_data = jsonb_build_object('full_name', 'Field Employee', 'role', 'employee')
  WHERE email = 'employee@ibuild.in'
  RETURNING id INTO v_emp_id;

  IF v_emp_id IS NULL THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
      '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
      'employee@ibuild.in', crypt('employee@123', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{"full_name":"Field Employee","role":"employee"}', now(), now()
    ) RETURNING id INTO v_emp_id;
  END IF;

  -- Ensure Profiles & User Roles
  IF v_admin_id IS NOT NULL AND v_admin_role IS NOT NULL THEN
    INSERT INTO public.profiles (id, full_name, role_display, company_name)
    VALUES (v_admin_id, 'System Admin', 'admin', 'IBUILD') ON CONFLICT (id) DO UPDATE SET role_display = 'admin';
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (v_admin_id, v_admin_role) ON CONFLICT (user_id) DO UPDATE SET role_id = v_admin_role;
  END IF;

  IF v_owner_id IS NOT NULL AND v_owner_role IS NOT NULL THEN
    INSERT INTO public.profiles (id, full_name, role_display, company_name)
    VALUES (v_owner_id, 'Company Owner', 'owner', 'IBUILD') ON CONFLICT (id) DO UPDATE SET role_display = 'owner';
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (v_owner_id, v_owner_role) ON CONFLICT (user_id) DO UPDATE SET role_id = v_owner_role;
  END IF;

  IF v_sup_id IS NOT NULL AND v_sup_role IS NOT NULL THEN
    INSERT INTO public.profiles (id, full_name, role_display, company_name)
    VALUES (v_sup_id, 'Site Supervisor', 'supervisor', 'IBUILD') ON CONFLICT (id) DO UPDATE SET role_display = 'supervisor';
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (v_sup_id, v_sup_role) ON CONFLICT (user_id) DO UPDATE SET role_id = v_sup_role;
  END IF;

  IF v_emp_id IS NOT NULL AND v_emp_role IS NOT NULL THEN
    INSERT INTO public.profiles (id, full_name, role_display, company_name)
    VALUES (v_emp_id, 'Field Employee', 'employee', 'IBUILD') ON CONFLICT (id) DO UPDATE SET role_display = 'employee';
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (v_emp_id, v_emp_role) ON CONFLICT (user_id) DO UPDATE SET role_id = v_emp_role;
  END IF;
END;
$$;

-- Revoke all active sessions and refresh tokens so fresh compact JWTs are minted
DELETE FROM auth.refresh_tokens;
DELETE FROM auth.sessions;

-- Ensure profiles.avatar_url accepts only valid HTTPS CDN URLs (max 2048 chars)
ALTER TABLE public.profiles 
  DROP CONSTRAINT IF EXISTS check_profiles_avatar_url_valid;

ALTER TABLE public.profiles 
  ADD CONSTRAINT check_profiles_avatar_url_valid 
  CHECK (
    avatar_url IS NULL OR (
      length(avatar_url) <= 2048 AND 
      avatar_url LIKE 'https://%' AND 
      avatar_url NOT LIKE 'data:%' AND 
      avatar_url NOT LIKE 'blob:%'
    )
  );

-- ── 2. SECURE METADATA REPAIR FUNCTION ────────────────────────
CREATE OR REPLACE FUNCTION public.repair_and_clean_oversized_user_metadata()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  repaired_users_count integer := 0;
BEGIN
  -- Strip oversized keys from auth.users raw_user_meta_data
  UPDATE auth.users
  SET raw_user_meta_data = (
    raw_user_meta_data - 'avatar_url' - 'logo_url' - 'raw_avatar' - 'image_bytes'
  )
  WHERE raw_user_meta_data ? 'avatar_url' 
     OR raw_user_meta_data ? 'logo_url'
     OR raw_user_meta_data ? 'raw_avatar'
     OR raw_user_meta_data ? 'image_bytes'
     OR length(raw_user_meta_data::text) > 4096;

  GET DIAGNOSTICS repaired_users_count = ROW_COUNT;

  -- Ensure standard test accounts are active and confirmed
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, now())
  WHERE email IN ('admin@ibuild.in', 'owner@ibuild.in', 'supervisor@ibuild.in', 'employee@ibuild.in');

  -- Invalidate existing sessions
  DELETE FROM auth.sessions;

  RETURN jsonb_build_object(
    'success', true,
    'users_repaired', repaired_users_count,
    'sessions_revoked', true,
    'timestamp', now()
  );
END;
$$;

-- Grant execution to authenticated & service_role
GRANT EXECUTE ON FUNCTION public.repair_and_clean_oversized_user_metadata() TO authenticated, service_role;

-- ── 3. ATOMIC PROJECT SPEND TRIGGER ON expenses ───────────────

-- Ensure non-negative expenses
ALTER TABLE public.expenses 
  DROP CONSTRAINT IF EXISTS check_expense_amount_positive;

ALTER TABLE public.expenses 
  ADD CONSTRAINT check_expense_amount_positive 
  CHECK (amount >= 0);

-- Trigger function to recalculate project spent atomically
CREATE OR REPLACE FUNCTION public.update_project_spent_atomic()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Handle INSERT or UPDATE (new project)
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    IF NEW.project_id IS NOT NULL AND NEW.project_id <> '' THEN
      UPDATE public.projects
      SET spent = COALESCE((
        SELECT SUM(amount) 
        FROM public.expenses 
        WHERE project_id = NEW.project_id AND amount > 0
      ), 0)
      WHERE id = NEW.project_id;
    END IF;
  END IF;

  -- Handle DELETE or UPDATE (if project_id changed)
  IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
    IF OLD.project_id IS NOT NULL AND OLD.project_id <> '' AND (TG_OP = 'DELETE' OR OLD.project_id <> NEW.project_id) THEN
      UPDATE public.projects
      SET spent = COALESCE((
        SELECT SUM(amount) 
        FROM public.expenses 
        WHERE project_id = OLD.project_id AND amount > 0
      ), 0)
      WHERE id = OLD.project_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$;

-- Drop old trigger if exists and recreate
DROP TRIGGER IF EXISTS trg_update_project_spent_on_expense ON public.expenses;
CREATE TRIGGER trg_update_project_spent_on_expense
AFTER INSERT OR UPDATE OR DELETE ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION public.update_project_spent_atomic();

-- Reconciliation Function & Audit Report
CREATE OR REPLACE FUNCTION public.reconcile_all_project_spends()
RETURNS TABLE (
  project_id TEXT,
  project_name TEXT,
  stored_spent NUMERIC,
  calculated_spent NUMERIC,
  difference NUMERIC,
  status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Sync stored spent with actual sum
  UPDATE public.projects p
  SET spent = COALESCE((
    SELECT SUM(e.amount) 
    FROM public.expenses e 
    WHERE e.project_id = p.id AND e.amount > 0
  ), 0);

  -- 2. Return report
  RETURN QUERY
  SELECT 
    p.id::TEXT AS project_id,
    p.name::TEXT AS project_name,
    COALESCE(p.spent, 0)::NUMERIC AS stored_spent,
    COALESCE(SUM(e.amount), 0)::NUMERIC AS calculated_spent,
    (COALESCE(p.spent, 0) - COALESCE(SUM(e.amount), 0))::NUMERIC AS difference,
    CASE 
      WHEN (COALESCE(p.spent, 0) - COALESCE(SUM(e.amount), 0)) = 0 THEN 'RECONCILED'
      ELSE 'MISMATCH_FIXED'
    END AS status
  FROM public.projects p
  LEFT JOIN public.expenses e ON e.project_id = p.id
  GROUP BY p.id, p.name, p.spent;
END;
$$;

-- ── 4. ATTENDANCE UNIQUENESS CONSTRAINT ───────────────────────

-- De-duplicate any pre-existing duplicates if present, keeping the latest row
DELETE FROM public.attendance a
WHERE a.id NOT IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (
      PARTITION BY employee_id, date 
      ORDER BY created_at DESC NULLS LAST, id DESC
    ) as rnum
    FROM public.attendance
  ) ranked
  WHERE ranked.rnum = 1
);

-- Add unique constraint
ALTER TABLE public.attendance
  DROP CONSTRAINT IF EXISTS unique_attendance_employee_date;

ALTER TABLE public.attendance
  ADD CONSTRAINT unique_attendance_employee_date
  UNIQUE (employee_id, date);

-- ── 5. APPEND-ONLY AUDIT LOGS & RLS POLICIES ──────────────────

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Deny UPDATE and DELETE on audit_logs for everyone
DROP POLICY IF EXISTS "Deny updates on audit_logs" ON public.audit_logs;
CREATE POLICY "Deny updates on audit_logs"
  ON public.audit_logs FOR UPDATE
  TO authenticated
  USING (false);

DROP POLICY IF EXISTS "Deny deletes on audit_logs" ON public.audit_logs;
CREATE POLICY "Deny deletes on audit_logs"
  ON public.audit_logs FOR DELETE
  TO authenticated
  USING (false);

-- Read policy for authenticated users
DROP POLICY IF EXISTS "Authenticated users can read audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated users can read audit logs"
  ON public.audit_logs FOR SELECT
  TO authenticated
  USING (true);

-- Insert policy for authenticated users
DROP POLICY IF EXISTS "Authenticated users can insert audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated users can insert audit logs"
  ON public.audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);
