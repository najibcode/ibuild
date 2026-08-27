-- ============================================================
-- MIGRATION 017: PRODUCTION READINESS REPAIRS
-- 1. Fix Oversized Auth Metadata / Restore Compact JWTs (<8KB)
-- 2. Atomic Database Spend Triggers & Reconciliation Functions
-- 3. Database Attendance Uniqueness Constraint
-- 4. Append-only Audit Logs & RLS Module Hardening
-- ============================================================

-- ── 1. STRIP LARGE / BASE64 METADATA FROM auth.users ──────────
-- Remove bloated avatar_url and logo_url from raw_user_meta_data
UPDATE auth.users
SET raw_user_meta_data = (
  raw_user_meta_data - 'avatar_url' - 'logo_url' - 'raw_avatar' - 'image_bytes'
)
WHERE raw_user_meta_data ? 'avatar_url' 
   OR raw_user_meta_data ? 'logo_url'
   OR raw_user_meta_data ? 'raw_avatar'
   OR raw_user_meta_data ? 'image_bytes'
   OR length(raw_user_meta_data::text) > 4096;

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

-- ── 2. ATOMIC PROJECT SPEND TRIGGER ON expenses ───────────────

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

-- ── 3. ATTENDANCE UNIQUENESS CONSTRAINT ───────────────────────

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

-- ── 4. APPEND-ONLY AUDIT LOGS & RLS POLICIES ──────────────────

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
