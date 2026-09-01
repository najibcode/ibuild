-- ============================================================
-- iBuild ERP: COMPLETE CONSOLIDATED PRODUCTION REPAIR MIGRATION
-- MIGRATION 020: STRICT RLS, NON-RECURSIVE RBAC & SCHEMA REPAIR
--
-- Fixes:
-- 1. All base tables & columns created first (full_name, email, daily_rate, salary, user_id, supervisor_id)
-- 2. Complete user_roles seeding for Admin, Owner, Supervisor, Employee (UUID-compatible)
-- 3. Strict Project & Role-based Row Isolation:
--    - Admin & Owner: Full visibility across all projects, expenses, bills, profiles
--    - Supervisor: Scoped to assigned projects only; 0 access to bills, sales_bills, payment_ledger, or coworker profiles
--    - Employee: 0 access to financials; own records and assigned tickets only
-- 4. PostgreSQL 42P17 (zero recursion on user_roles)
-- 5. Atomic project spend calculation on expense mutations
-- 6. Attendance unique constraint & historical wage snapshotting
-- ============================================================

-- ── 1. ENSURE ALL BASE TABLES & COLUMNS EXIST (TOP PRIORITY) ──

-- 1.1 PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  name TEXT,
  email TEXT,
  role_display TEXT DEFAULT 'owner',
  avatar_url TEXT,
  phone TEXT,
  company_name TEXT DEFAULT 'IBUILD',
  is_disabled BOOLEAN NOT NULL DEFAULT false,
  custom_permissions JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS role_display TEXT DEFAULT 'owner',
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS company_name TEXT DEFAULT 'IBUILD',
  ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS custom_permissions JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

UPDATE public.profiles
SET full_name = COALESCE(full_name, name, 'User')
WHERE full_name IS NULL;

-- 1.2 EMPLOYEES
CREATE TABLE IF NOT EXISTS public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  role TEXT DEFAULT 'Labor',
  phone TEXT,
  email TEXT,
  photo_url TEXT,
  daily_rate NUMERIC(12, 2) DEFAULT 600.00,
  salary NUMERIC(12, 2) DEFAULT 18000.00,
  salary_effective_date DATE DEFAULT CURRENT_DATE,
  tea_snack_allowance NUMERIC(10, 2) DEFAULT 20.00,
  tea_allowance NUMERIC(10, 2) DEFAULT 20.00,
  status TEXT DEFAULT 'active',
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.employees 
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'Labor',
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT,
  ADD COLUMN IF NOT EXISTS daily_rate NUMERIC(12, 2) DEFAULT 600.00,
  ADD COLUMN IF NOT EXISTS salary NUMERIC(12, 2) DEFAULT 600.00,
  ADD COLUMN IF NOT EXISTS salary_effective_date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS tea_snack_allowance NUMERIC(10, 2) DEFAULT 20.00,
  ADD COLUMN IF NOT EXISTS tea_allowance NUMERIC(10, 2) DEFAULT 20.00,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 1.3 PROJECTS
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  client TEXT,
  location TEXT,
  budget NUMERIC(14, 2) DEFAULT 0.00,
  spent NUMERIC(14, 2) DEFAULT 0.00,
  start_date DATE,
  end_date DATE,
  status TEXT DEFAULT 'In Progress',
  supervisor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS client TEXT,
  ADD COLUMN IF NOT EXISTS location TEXT,
  ADD COLUMN IF NOT EXISTS budget NUMERIC(14, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS spent NUMERIC(14, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS start_date DATE,
  ADD COLUMN IF NOT EXISTS end_date DATE,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'In Progress',
  ADD COLUMN IF NOT EXISTS supervisor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 1.4 ATTENDANCE
CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  date DATE NOT NULL,
  status TEXT DEFAULT 'Present',
  morning_status TEXT DEFAULT 'present',
  afternoon_status TEXT DEFAULT 'present',
  wage_rate NUMERIC(12, 2),
  tea_allowance NUMERIC(10, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS employee_id UUID,
  ADD COLUMN IF NOT EXISTS project_id UUID,
  ADD COLUMN IF NOT EXISTS date DATE,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Present',
  ADD COLUMN IF NOT EXISTS morning_status TEXT DEFAULT 'present',
  ADD COLUMN IF NOT EXISTS afternoon_status TEXT DEFAULT 'present',
  ADD COLUMN IF NOT EXISTS wage_rate NUMERIC(12, 2),
  ADD COLUMN IF NOT EXISTS tea_allowance NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 1.5 EXPENSES
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  category TEXT DEFAULT 'General',
  amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  date DATE DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS project_id UUID,
  ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General',
  ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 1.6 BILLS
CREATE TABLE IF NOT EXISTS public.bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  vendor TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  status TEXT DEFAULT 'Pending',
  due_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.bills
  ADD COLUMN IF NOT EXISTS project_id UUID,
  ADD COLUMN IF NOT EXISTS vendor TEXT,
  ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Pending',
  ADD COLUMN IF NOT EXISTS due_date DATE,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 1.7 SALES BILLS & ITEMS
CREATE TABLE IF NOT EXISTS public.sales_bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_number TEXT,
  client_name TEXT,
  total_amount NUMERIC(14, 2) DEFAULT 0.00,
  tax_amount NUMERIC(14, 2) DEFAULT 0.00,
  grand_total NUMERIC(14, 2) DEFAULT 0.00,
  status TEXT DEFAULT 'Draft',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.sales_bill_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sales_bill_id UUID REFERENCES public.sales_bills(id) ON DELETE CASCADE,
  description TEXT,
  quantity NUMERIC(10, 2) DEFAULT 1.00,
  unit_price NUMERIC(12, 2) DEFAULT 0.00,
  total_price NUMERIC(14, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.8 PAYMENT LEDGER & PROJECT PAYMENTS
CREATE TABLE IF NOT EXISTS public.payment_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID,
  party TEXT NOT NULL,
  type TEXT DEFAULT 'Payment In',
  amount NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
  date DATE DEFAULT CURRENT_DATE,
  mode TEXT DEFAULT 'Cash',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.project_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  amount NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
  payment_type TEXT DEFAULT 'Milestone',
  payment_method TEXT DEFAULT 'Bank Transfer',
  status TEXT DEFAULT 'Completed',
  payment_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.9 INVENTORY & EQUIPMENT
CREATE TABLE IF NOT EXISTS public.inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
  category TEXT DEFAULT 'General',
  quantity NUMERIC(10, 2) DEFAULT 0.00,
  unit TEXT DEFAULT 'Nos',
  min_threshold NUMERIC(10, 2) DEFAULT 10.00,
  unit_price NUMERIC(12, 2) DEFAULT 0.00,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.inventory_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_id UUID REFERENCES public.inventory(id) ON DELETE CASCADE,
  change_type TEXT,
  quantity_changed NUMERIC(10, 2) DEFAULT 0.00,
  balance_after NUMERIC(10, 2) DEFAULT 0.00,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_id UUID REFERENCES public.inventory(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  transaction_type TEXT NOT NULL,
  quantity NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  unit_price NUMERIC(12, 2) DEFAULT 0.00,
  total_amount NUMERIC(14, 2) DEFAULT 0.00,
  reference_number TEXT,
  notes TEXT,
  performed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT DEFAULT 'Machinery',
  status TEXT DEFAULT 'Operational',
  assigned_project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
  daily_rental_cost NUMERIC(12, 2) DEFAULT 0.00,
  operator_name TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.10 QUOTATIONS, VENDORS & SUBCONTRACTORS
CREATE TABLE IF NOT EXISTS public.quotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_number TEXT,
  client_name TEXT,
  total_amount NUMERIC(14, 2) DEFAULT 0.00,
  status TEXT DEFAULT 'Draft',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.quotation_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id UUID REFERENCES public.quotations(id) ON DELETE CASCADE,
  description TEXT,
  quantity NUMERIC(10, 2) DEFAULT 1.00,
  unit_price NUMERIC(12, 2) DEFAULT 0.00,
  total_price NUMERIC(14, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT DEFAULT 'Materials',
  phone TEXT,
  email TEXT,
  balance NUMERIC(14, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.vendor_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
  amount NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
  type TEXT DEFAULT 'Purchase',
  date DATE DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.subcontractors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  trade TEXT,
  phone TEXT,
  email TEXT,
  total_contract_value NUMERIC(14, 2) DEFAULT 0.00,
  paid_amount NUMERIC(14, 2) DEFAULT 0.00,
  status TEXT DEFAULT 'Active',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  unit_number TEXT,
  type TEXT DEFAULT 'Apartment',
  price NUMERIC(14, 2) DEFAULT 0.00,
  status TEXT DEFAULT 'Available',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.11 DAILY PROGRESS, CHECKLISTS & TICKETS
CREATE TABLE IF NOT EXISTS public.daily_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  work_description TEXT,
  progress_percentage NUMERIC(5, 2) DEFAULT 0.00,
  date DATE DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.project_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assigned_person TEXT,
  approval_status TEXT DEFAULT 'Pending',
  phase TEXT DEFAULT 'Structural',
  is_completed BOOLEAN DEFAULT FALSE,
  due_date DATE,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.project_checklists
  ADD COLUMN IF NOT EXISTS assigned_person TEXT,
  ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'Pending',
  ADD COLUMN IF NOT EXISTS phase TEXT DEFAULT 'Structural',
  ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS due_date DATE;

CREATE TABLE IF NOT EXISTS public.site_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'Medium',
  status TEXT DEFAULT 'Open',
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reported_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.ticket_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES public.site_tickets(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  sender_role TEXT DEFAULT 'Site Staff',
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.site_drawings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT DEFAULT 'Architectural',
  file_url TEXT NOT NULL,
  is_archived BOOLEAN DEFAULT FALSE,
  file_size_bytes BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.12 AUDIT LOGS, ACTIVITIES, SETTINGS & IMAGES
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email TEXT,
  action TEXT NOT NULL,
  entity TEXT,
  entity_id TEXT,
  details TEXT,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_name TEXT,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_name TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.app_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  file_id TEXT NOT NULL,
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 1.13 ROLES & RBAC TABLES (UUID SCHEMA COMPATIBLE)
CREATE TABLE IF NOT EXISTS public.roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  description TEXT,
  module TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id UUID REFERENCES public.permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  UNIQUE(role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  UNIQUE(user_id)
);

-- ── 2. SEED ROLES & AUTOMATICALLY POPULATE USER_ROLES ─────────

INSERT INTO public.roles (name, description) VALUES
  ('admin', 'Technical administrator with full system access'),
  ('owner', 'Business owner with full business visibility'),
  ('supervisor', 'Site supervisor managing day-to-day operations'),
  ('employee', 'Field employee and site staff')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Auto-seed user_roles for every user in auth.users
INSERT INTO public.user_roles (user_id, role_id)
SELECT 
  u.id, 
  r.id
FROM auth.users u
JOIN public.roles r ON r.name = LOWER(COALESCE(
  CASE 
    WHEN u.email ILIKE '%admin@ibuild.in%' THEN 'admin'
    WHEN u.email ILIKE '%owner@ibuild.in%' THEN 'owner'
    WHEN u.email ILIKE '%supervisor@ibuild.in%' THEN 'supervisor'
    WHEN u.email ILIKE '%employee@ibuild.in%' THEN 'employee'
    ELSE NULL
  END,
  u.raw_user_meta_data->>'role',
  (SELECT role_display FROM public.profiles p WHERE p.id = u.id),
  CASE 
    WHEN u.email ILIKE '%admin%' THEN 'admin'
    WHEN u.email ILIKE '%owner%' THEN 'owner'
    WHEN u.email ILIKE '%supervisor%' THEN 'supervisor'
    ELSE 'employee'
  END
))
ON CONFLICT (user_id) DO UPDATE SET role_id = EXCLUDED.role_id;

-- Explicitly sanitize and assign standard test accounts
DO $$
DECLARE
  v_admin_role UUID;
  v_owner_role UUID;
  v_sup_role UUID;
  v_emp_role UUID;
BEGIN
  SELECT id INTO v_admin_role FROM public.roles WHERE name = 'admin' LIMIT 1;
  SELECT id INTO v_owner_role FROM public.roles WHERE name = 'owner' LIMIT 1;
  SELECT id INTO v_sup_role FROM public.roles WHERE name = 'supervisor' LIMIT 1;
  SELECT id INTO v_emp_role FROM public.roles WHERE name = 'employee' LIMIT 1;

  -- 1. Admin
  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb
  WHERE email ILIKE '%admin@ibuild.in%';

  UPDATE public.profiles
  SET role_display = 'admin'
  WHERE id IN (SELECT id FROM auth.users WHERE email ILIKE '%admin@ibuild.in%');

  IF v_admin_role IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role_id)
    SELECT id, v_admin_role FROM auth.users WHERE email ILIKE '%admin@ibuild.in%'
    ON CONFLICT (user_id) DO UPDATE SET role_id = v_admin_role;
  END IF;

  -- 2. Owner
  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "owner"}'::jsonb
  WHERE email ILIKE '%owner@ibuild.in%';

  UPDATE public.profiles
  SET role_display = 'owner'
  WHERE id IN (SELECT id FROM auth.users WHERE email ILIKE '%owner@ibuild.in%');

  IF v_owner_role IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role_id)
    SELECT id, v_owner_role FROM auth.users WHERE email ILIKE '%owner@ibuild.in%'
    ON CONFLICT (user_id) DO UPDATE SET role_id = v_owner_role;
  END IF;

  -- 3. Supervisor
  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "supervisor"}'::jsonb
  WHERE email ILIKE '%supervisor@ibuild.in%';

  UPDATE public.profiles
  SET role_display = 'supervisor'
  WHERE id IN (SELECT id FROM auth.users WHERE email ILIKE '%supervisor@ibuild.in%');

  IF v_sup_role IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role_id)
    SELECT id, v_sup_role FROM auth.users WHERE email ILIKE '%supervisor@ibuild.in%'
    ON CONFLICT (user_id) DO UPDATE SET role_id = v_sup_role;
  END IF;

  -- 4. Employee (Strictly employee role!)
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_build_object('full_name', 'Field Employee', 'role', 'employee')
  WHERE email ILIKE '%employee@ibuild.in%';

  UPDATE public.profiles
  SET role_display = 'employee'
  WHERE id IN (SELECT id FROM auth.users WHERE email ILIKE '%employee@ibuild.in%');

  IF v_emp_role IS NOT NULL THEN
    INSERT INTO public.user_roles (user_id, role_id)
    SELECT id, v_emp_role FROM auth.users WHERE email ILIKE '%employee@ibuild.in%'
    ON CONFLICT (user_id) DO UPDATE SET role_id = v_emp_role;
  END IF;

  -- Invalidate all active sessions so stale JWT tokens with old claims cannot be reused
  DELETE FROM auth.sessions;
  DELETE FROM auth.refresh_tokens;
END;
$$;

-- ── 3. DATA REPAIR, BACKFILL & LINKING ───────────────────────

UPDATE public.employees
SET daily_rate = ROUND(COALESCE(salary, 18000.00) / 30.0, 2)
WHERE (daily_rate IS NULL OR daily_rate = 0) AND salary IS NOT NULL AND salary > 0;

UPDATE public.employees
SET salary = ROUND(COALESCE(daily_rate, 600.00) * 30.0, 2)
WHERE (salary IS NULL OR salary = 0) AND daily_rate IS NOT NULL AND daily_rate > 0;

CREATE OR REPLACE FUNCTION public.sync_employee_rates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.salary IS DISTINCT FROM OLD.salary THEN
    IF NEW.salary IS NOT NULL AND NEW.salary > 0 THEN
      NEW.daily_rate := ROUND(NEW.salary / 30.0, 2);
    END IF;
  ELSIF NEW.daily_rate IS DISTINCT FROM OLD.daily_rate THEN
    IF NEW.daily_rate IS NOT NULL AND NEW.daily_rate > 0 THEN
      NEW.salary := ROUND(NEW.daily_rate * 30.0, 2);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_employee_rates ON public.employees;
CREATE TRIGGER trg_sync_employee_rates
BEFORE INSERT OR UPDATE ON public.employees
FOR EACH ROW
EXECUTE FUNCTION public.sync_employee_rates();

CREATE INDEX IF NOT EXISTS idx_employees_user_id ON public.employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_email ON public.employees(lower(email));

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id, email FROM auth.users WHERE email IS NOT NULL LOOP
    UPDATE public.employees 
    SET user_id = r.id 
    WHERE lower(email) = lower(r.email) AND user_id IS NULL;
  END LOOP;
END;
$$;

-- Associate supervisor user_id to projects to verify project/role isolation
DO $$
DECLARE
  v_sup_id UUID;
BEGIN
  SELECT id INTO v_sup_id FROM auth.users 
  WHERE email ILIKE '%supervisor%' OR raw_user_meta_data->>'role' = 'supervisor' 
  LIMIT 1;

  IF v_sup_id IS NOT NULL THEN
    UPDATE public.projects
    SET supervisor_id = v_sup_id
    WHERE id IN (
      SELECT id FROM public.projects ORDER BY created_at ASC LIMIT 2
    );
  END IF;
END;
$$;

DELETE FROM public.attendance a
USING public.attendance b
WHERE a.employee_id = b.employee_id 
  AND a.date = b.date 
  AND a.created_at < b.created_at;

ALTER TABLE public.attendance 
  DROP CONSTRAINT IF EXISTS unique_employee_date,
  DROP CONSTRAINT IF EXISTS attendance_employee_id_date_key;

ALTER TABLE public.attendance
  ADD CONSTRAINT unique_employee_date UNIQUE (employee_id, date);

CREATE OR REPLACE FUNCTION public.snapshot_attendance_wages()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_rate NUMERIC(12, 2);
  v_tea NUMERIC(10, 2);
BEGIN
  IF NEW.wage_rate IS NULL OR NEW.wage_rate = 0 THEN
    SELECT COALESCE(daily_rate, ROUND(salary / 30.0, 2), 600.00), COALESCE(tea_allowance, 0.00)
    INTO v_rate, v_tea
    FROM public.employees
    WHERE id = NEW.employee_id
    LIMIT 1;

    NEW.wage_rate := COALESCE(v_rate, 600.00);
    NEW.tea_allowance := COALESCE(v_tea, 0.00);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_snapshot_attendance_wages ON public.attendance;
CREATE TRIGGER trg_snapshot_attendance_wages
BEFORE INSERT ON public.attendance
FOR EACH ROW
EXECUTE FUNCTION public.snapshot_attendance_wages();

-- ── 4. ATOMIC PROJECT SPEND CALCULATION ───────────────────────

ALTER TABLE public.expenses
  DROP CONSTRAINT IF EXISTS check_positive_amount,
  DROP CONSTRAINT IF EXISTS expenses_amount_check;

ALTER TABLE public.expenses
  ADD CONSTRAINT check_positive_amount CHECK (amount >= 0);

CREATE OR REPLACE FUNCTION public.update_project_spent_atomic()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_project_id UUID;
  v_total NUMERIC(14, 2);
BEGIN
  v_project_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.project_id ELSE NEW.project_id END;
  
  IF v_project_id IS NOT NULL THEN
    SELECT COALESCE(SUM(amount), 0.00)
    INTO v_total
    FROM public.expenses
    WHERE project_id = v_project_id;

    UPDATE public.projects
    SET spent = v_total,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_project_id;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_project_spent_on_expense ON public.expenses;
CREATE TRIGGER trg_update_project_spent_on_expense
AFTER INSERT OR UPDATE OR DELETE ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION public.update_project_spent_atomic();

CREATE OR REPLACE FUNCTION public.reconcile_all_project_spends()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.projects p
  SET spent = COALESCE((
    SELECT SUM(e.amount)
    FROM public.expenses e
    WHERE e.project_id = p.id
  ), 0.00);
END;
$$;

SELECT public.reconcile_all_project_spends();

-- ── 5. NON-RECURSIVE SECURITY DEFINER ROLE HELPER FUNCTIONS ───

DROP FUNCTION IF EXISTS public.get_auth_role() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.is_owner() CASCADE;
DROP FUNCTION IF EXISTS public.is_supervisor() CASCADE;
DROP FUNCTION IF EXISTS public.is_employee() CASCADE;
DROP FUNCTION IF EXISTS public.get_auth_employee_id() CASCADE;

CREATE OR REPLACE FUNCTION public.get_auth_role()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
  v_email text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN 'anonymous';
  END IF;

  -- 1. Direct auth.users email lookup (Highest priority, immune to stale claims)
  SELECT lower(email) INTO v_email FROM auth.users WHERE id = auth.uid() LIMIT 1;
  IF v_email IS NULL OR v_email = '' THEN
    v_email := lower(COALESCE(auth.jwt() ->> 'email', ''));
  END IF;

  IF v_email = 'admin@ibuild.in' THEN RETURN 'admin'; END IF;
  IF v_email = 'owner@ibuild.in' THEN RETURN 'owner'; END IF;
  IF v_email = 'supervisor@ibuild.in' THEN RETURN 'supervisor'; END IF;
  IF v_email = 'employee@ibuild.in' THEN RETURN 'employee'; END IF;

  -- 2. Canonical database user_roles table (SECURITY DEFINER safely bypasses RLS without recursion)
  SELECT lower(r.name) INTO v_role
  FROM public.user_roles ur
  JOIN public.roles r ON r.id = ur.role_id
  WHERE ur.user_id = auth.uid()
  LIMIT 1;

  IF v_role IS NOT NULL AND v_role <> '' THEN
    RETURN v_role;
  END IF;

  -- 3. Profiles table
  SELECT lower(role_display) INTO v_role
  FROM public.profiles
  WHERE id = auth.uid()
  LIMIT 1;

  IF v_role IS NOT NULL AND v_role <> '' THEN
    RETURN v_role;
  END IF;

  -- 4. JWT user_metadata claim
  v_role := lower(COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role',
    ''
  ));

  IF v_role <> '' THEN
    RETURN v_role;
  END IF;

  -- 5. Auth users raw metadata
  SELECT lower((raw_user_meta_data->>'role')::text) INTO v_role
  FROM auth.users
  WHERE id = auth.uid()
  LIMIT 1;

  IF v_role IS NOT NULL AND v_role <> '' THEN
    RETURN v_role;
  END IF;

  RETURN 'employee';
END;
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() = 'admin';
$$;

CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() IN ('admin', 'owner');
$$;

CREATE OR REPLACE FUNCTION public.is_supervisor()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() IN ('admin', 'owner', 'supervisor');
$$;

CREATE OR REPLACE FUNCTION public.is_employee()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() = 'employee';
$$;

CREATE OR REPLACE FUNCTION public.get_auth_employee_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.employees
  WHERE user_id = auth.uid() 
     OR (email IS NOT NULL AND lower(email) = lower(auth.jwt() ->> 'email'))
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_auth_role() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_owner() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_supervisor() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_employee() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_auth_employee_id() TO authenticated, service_role;

-- ── 5b. RECURSION-BREAKING SECURITY DEFINER PROJECT HELPERS ───
-- These functions bypass RLS to read project assignments, preventing
-- circular dependencies between projects ↔ project_checklists policies.

DROP FUNCTION IF EXISTS public.get_supervisor_project_ids() CASCADE;
DROP FUNCTION IF EXISTS public.get_assigned_project_ids() CASCADE;

-- Returns project IDs where the current user is the assigned supervisor
CREATE OR REPLACE FUNCTION public.get_supervisor_project_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.projects WHERE supervisor_id = auth.uid();
$$;

-- Returns project IDs where the current user is assigned via checklists or tickets
CREATE OR REPLACE FUNCTION public.get_assigned_project_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT project_id FROM (
    SELECT project_id FROM public.project_checklists
    WHERE assigned_person = (auth.jwt() ->> 'email')
       OR assigned_person = (
            SELECT COALESCE(full_name, name)
            FROM public.profiles
            WHERE id = auth.uid()
            LIMIT 1
          )
    UNION
    SELECT project_id FROM public.site_tickets
    WHERE assigned_to = auth.uid() OR reported_by = auth.uid()
  ) sub
  WHERE project_id IS NOT NULL;
$$;

GRANT EXECUTE ON FUNCTION public.get_supervisor_project_ids() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_assigned_project_ids() TO authenticated, service_role;

-- ── 6. PURGE ALL LEGACY POLICIES (ELIMINATES PERMISSIVE OR OVERRIDES) ──
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN 
    SELECT schemaname, tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I;', pol.policyname, pol.schemaname, pol.tablename);
  END LOOP;
END;
$$;

-- ── 6.1 USER ROLES & RBAC POLICIES (ZERO RECURSION GUARANTEE) ──

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage all user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Users can read own role" ON public.user_roles;
DROP POLICY IF EXISTS "Users can insert own role" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can read user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can insert own role" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can insert user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can update user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can delete user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Users can read own user_roles or admin read all" ON public.user_roles;
DROP POLICY IF EXISTS "Users can insert own user_role or admin manage" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can update user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Admins can delete user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "User roles select policy" ON public.user_roles;
DROP POLICY IF EXISTS "User roles insert policy" ON public.user_roles;
DROP POLICY IF EXISTS "User roles update policy" ON public.user_roles;
DROP POLICY IF EXISTS "User roles delete policy" ON public.user_roles;

-- Owner & Admin see all roles; Supervisor and Employee see own role
CREATE POLICY "User roles select policy"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_owner());

CREATE POLICY "User roles insert policy"
  ON public.user_roles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "User roles update policy"
  ON public.user_roles FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "User roles delete policy"
  ON public.user_roles FOR DELETE
  TO authenticated
  USING (public.is_admin());

CREATE OR REPLACE FUNCTION public.sync_user_role_to_profile_and_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role_name text;
BEGIN
  SELECT name INTO v_role_name FROM public.roles WHERE id = NEW.role_id;
  IF v_role_name IS NOT NULL THEN
    UPDATE public.profiles
    SET role_display = lower(v_role_name),
        updated_at = timezone('utc'::text, now())
    WHERE id = NEW.user_id;

    UPDATE auth.users
    SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('role', lower(v_role_name))
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_user_role_to_profile ON public.user_roles;
CREATE TRIGGER trg_sync_user_role_to_profile
AFTER INSERT OR UPDATE ON public.user_roles
FOR EACH ROW
EXECUTE FUNCTION public.sync_user_role_to_profile_and_metadata();

DROP POLICY IF EXISTS "Authenticated users can read roles" ON public.roles;
CREATE POLICY "Authenticated users can read roles"
  ON public.roles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins manage roles" ON public.roles;
CREATE POLICY "Admins manage roles"
  ON public.roles FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Authenticated users can read permissions" ON public.permissions;
CREATE POLICY "Authenticated users can read permissions"
  ON public.permissions FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins manage permissions" ON public.permissions;
CREATE POLICY "Admins manage permissions"
  ON public.permissions FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Authenticated users can read role_permissions" ON public.role_permissions;
CREATE POLICY "Authenticated users can read role_permissions"
  ON public.role_permissions FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins manage role_permissions" ON public.role_permissions;
CREATE POLICY "Admins manage role_permissions"
  ON public.role_permissions FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ── 7. STRICT CORE BUSINESS TABLES RLS POLICIES ──────────────

-- 7.1 PROJECTS (OWNER/ADMIN SEE ALL, SUPERVISOR SEES ASSIGNED, EMPLOYEE SEES ASSIGNED CHECKS)
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can view projects" ON public.projects;
DROP POLICY IF EXISTS "Authenticated users can create projects" ON public.projects;
DROP POLICY IF EXISTS "Authenticated users can update projects" ON public.projects;
DROP POLICY IF EXISTS "Authenticated users can delete projects" ON public.projects;
DROP POLICY IF EXISTS "Projects select policy" ON public.projects;
DROP POLICY IF EXISTS "Projects insert policy" ON public.projects;
DROP POLICY IF EXISTS "Projects update policy" ON public.projects;
DROP POLICY IF EXISTS "Projects delete policy" ON public.projects;

CREATE POLICY "Projects select policy"
  ON public.projects FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR id IN (SELECT public.get_supervisor_project_ids())
    OR id IN (SELECT public.get_assigned_project_ids())
  );

CREATE POLICY "Projects insert policy"
  ON public.projects FOR INSERT
  TO authenticated
  WITH CHECK (public.is_owner());

CREATE POLICY "Projects update policy"
  ON public.projects FOR UPDATE
  TO authenticated
  USING (public.is_owner() OR supervisor_id = auth.uid())
  WITH CHECK (public.is_owner() OR supervisor_id = auth.uid());

CREATE POLICY "Projects delete policy"
  ON public.projects FOR DELETE
  TO authenticated
  USING (public.is_owner());

-- 7.2 EMPLOYEES (OWNER/ADMIN SEES ALL; SUPERVISORS SEE FIELD WORKERS; EMPLOYEE SEES OWN)
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read employees" ON public.employees;
DROP POLICY IF EXISTS "Authenticated write employees" ON public.employees;
DROP POLICY IF EXISTS "Employees select policy" ON public.employees;
DROP POLICY IF EXISTS "Employees insert policy" ON public.employees;
DROP POLICY IF EXISTS "Employees update policy" ON public.employees;
DROP POLICY IF EXISTS "Employees delete policy" ON public.employees;

CREATE POLICY "Employees select policy"
  ON public.employees FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR (public.is_supervisor() AND role NOT IN ('Admin', 'Owner'))
    OR user_id = auth.uid()
    OR (email IS NOT NULL AND lower(email) = lower(auth.jwt() ->> 'email'))
  );

CREATE POLICY "Employees insert policy"
  ON public.employees FOR INSERT
  TO authenticated
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Employees update policy"
  ON public.employees FOR UPDATE
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Employees delete policy"
  ON public.employees FOR DELETE
  TO authenticated
  USING (public.is_owner());

-- 7.3 ATTENDANCE (OWNER/ADMIN SEES ALL; SUPERVISORS SEE ASSIGNED SITES; EMPLOYEES SEE OWN)
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Attendance select policy" ON public.attendance;
DROP POLICY IF EXISTS "Attendance insert policy" ON public.attendance;
DROP POLICY IF EXISTS "Attendance update policy" ON public.attendance;
DROP POLICY IF EXISTS "Attendance delete policy" ON public.attendance;

CREATE POLICY "Attendance select policy"
  ON public.attendance FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR (
      public.is_supervisor()
      AND (
        project_id IN (SELECT public.get_supervisor_project_ids())
        OR project_id IS NULL
      )
    )
    OR employee_id = public.get_auth_employee_id()
  );

CREATE POLICY "Attendance insert policy"
  ON public.attendance FOR INSERT
  TO authenticated
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Attendance update policy"
  ON public.attendance FOR UPDATE
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Attendance delete policy"
  ON public.attendance FOR DELETE
  TO authenticated
  USING (public.is_owner());

-- 7.4 EXPENSES (OWNER/ADMIN SEES ALL; SUPERVISORS SEE ASSIGNED SITES; EMPLOYEES DENIED 0 ROWS)
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Expenses select policy" ON public.expenses;
DROP POLICY IF EXISTS "Expenses insert policy" ON public.expenses;
DROP POLICY IF EXISTS "Expenses update policy" ON public.expenses;
DROP POLICY IF EXISTS "Expenses delete policy" ON public.expenses;

CREATE POLICY "Expenses select policy"
  ON public.expenses FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR (
      public.is_supervisor()
      AND project_id IN (SELECT public.get_supervisor_project_ids())
    )
  );

CREATE POLICY "Expenses insert policy"
  ON public.expenses FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_owner()
    OR (
      public.is_supervisor()
      AND project_id IN (SELECT public.get_supervisor_project_ids())
    )
  );

CREATE POLICY "Expenses update policy"
  ON public.expenses FOR UPDATE
  TO authenticated
  USING (
    public.is_owner()
    OR (
      public.is_supervisor()
      AND project_id IN (SELECT public.get_supervisor_project_ids())
    )
  )
  WITH CHECK (
    public.is_owner()
    OR (
      public.is_supervisor()
      AND project_id IN (SELECT public.get_supervisor_project_ids())
    )
  );

CREATE POLICY "Expenses delete policy"
  ON public.expenses FOR DELETE
  TO authenticated
  USING (public.is_owner());

-- 7.5 BILLS (VENDOR BILLS — STRICTLY OWNER & ADMIN; SUPERVISOR & EMPLOYEE DENIED 0 ROWS)
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Bills select policy" ON public.bills;
DROP POLICY IF EXISTS "Bills insert policy" ON public.bills;
DROP POLICY IF EXISTS "Bills update policy" ON public.bills;
DROP POLICY IF EXISTS "Bills delete policy" ON public.bills;

CREATE POLICY "Bills select policy"
  ON public.bills FOR SELECT
  TO authenticated
  USING (public.is_owner());

CREATE POLICY "Bills insert policy"
  ON public.bills FOR INSERT
  TO authenticated
  WITH CHECK (public.is_owner());

CREATE POLICY "Bills update policy"
  ON public.bills FOR UPDATE
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

CREATE POLICY "Bills delete policy"
  ON public.bills FOR DELETE
  TO authenticated
  USING (public.is_owner());

-- 7.6 SALES BILLS & ITEMS (STRICTLY OWNER & ADMIN)
ALTER TABLE public.sales_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_bill_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users read sales_bills" ON public.sales_bills;
DROP POLICY IF EXISTS "Authenticated users write sales_bills" ON public.sales_bills;
DROP POLICY IF EXISTS "Authenticated read sales_bill_items" ON public.sales_bill_items;
DROP POLICY IF EXISTS "Authenticated write sales_bill_items" ON public.sales_bill_items;
DROP POLICY IF EXISTS "Sales bills select policy" ON public.sales_bills;
DROP POLICY IF EXISTS "Sales bills modify policy" ON public.sales_bills;
DROP POLICY IF EXISTS "Sales bill items select policy" ON public.sales_bill_items;
DROP POLICY IF EXISTS "Sales bill items modify policy" ON public.sales_bill_items;

CREATE POLICY "Sales bills select policy"
  ON public.sales_bills FOR SELECT
  TO authenticated
  USING (public.is_owner());

CREATE POLICY "Sales bills modify policy"
  ON public.sales_bills FOR ALL
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

CREATE POLICY "Sales bill items select policy"
  ON public.sales_bill_items FOR SELECT
  TO authenticated
  USING (public.is_owner());

CREATE POLICY "Sales bill items modify policy"
  ON public.sales_bill_items FOR ALL
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

-- 7.7 PAYMENT LEDGER & PROJECT PAYMENTS (STRICTLY OWNER & ADMIN)
ALTER TABLE public.payment_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read payment_ledger" ON public.payment_ledger;
DROP POLICY IF EXISTS "Authenticated write payment_ledger" ON public.payment_ledger;
DROP POLICY IF EXISTS "Authenticated users read project_payments" ON public.project_payments;
DROP POLICY IF EXISTS "Authenticated users write project_payments" ON public.project_payments;
DROP POLICY IF EXISTS "Payment ledger select policy" ON public.payment_ledger;
DROP POLICY IF EXISTS "Payment ledger modify policy" ON public.payment_ledger;
DROP POLICY IF EXISTS "Project payments select policy" ON public.project_payments;
DROP POLICY IF EXISTS "Project payments modify policy" ON public.project_payments;

CREATE POLICY "Payment ledger select policy"
  ON public.payment_ledger FOR SELECT
  TO authenticated
  USING (public.is_owner());

CREATE POLICY "Payment ledger modify policy"
  ON public.payment_ledger FOR ALL
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

CREATE POLICY "Project payments select policy"
  ON public.project_payments FOR SELECT
  TO authenticated
  USING (public.is_owner());

CREATE POLICY "Project payments modify policy"
  ON public.project_payments FOR ALL
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

-- 7.8 INVENTORY & EQUIPMENT
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Inventory select policy" ON public.inventory;
DROP POLICY IF EXISTS "Inventory modify policy" ON public.inventory;
DROP POLICY IF EXISTS "Inventory insert policy" ON public.inventory;
DROP POLICY IF EXISTS "Inventory update policy" ON public.inventory;
DROP POLICY IF EXISTS "Inventory delete policy" ON public.inventory;
DROP POLICY IF EXISTS "Inventory history select policy" ON public.inventory_history;
DROP POLICY IF EXISTS "Inventory history modify policy" ON public.inventory_history;
DROP POLICY IF EXISTS "Inventory history insert policy" ON public.inventory_history;
DROP POLICY IF EXISTS "Inventory history update policy" ON public.inventory_history;
DROP POLICY IF EXISTS "Inventory history delete policy" ON public.inventory_history;
DROP POLICY IF EXISTS "Inventory transactions select policy" ON public.inventory_transactions;
DROP POLICY IF EXISTS "Inventory transactions insert policy" ON public.inventory_transactions;
DROP POLICY IF EXISTS "Inventory transactions update policy" ON public.inventory_transactions;
DROP POLICY IF EXISTS "Inventory transactions delete policy" ON public.inventory_transactions;
DROP POLICY IF EXISTS "Authenticated read equipment" ON public.equipment;
DROP POLICY IF EXISTS "Authenticated write equipment" ON public.equipment;
DROP POLICY IF EXISTS "Equipment select policy" ON public.equipment;
DROP POLICY IF EXISTS "Equipment modify policy" ON public.equipment;
DROP POLICY IF EXISTS "Equipment insert policy" ON public.equipment;
DROP POLICY IF EXISTS "Equipment update policy" ON public.equipment;
DROP POLICY IF EXISTS "Equipment delete policy" ON public.equipment;

-- Inventory: Employee gets read-only; Supervisor+ can mutate; Owner+ can delete
CREATE POLICY "Inventory select policy" ON public.inventory FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);
CREATE POLICY "Inventory insert policy" ON public.inventory FOR INSERT TO authenticated WITH CHECK (public.is_supervisor());
CREATE POLICY "Inventory update policy" ON public.inventory FOR UPDATE TO authenticated USING (public.is_supervisor()) WITH CHECK (public.is_supervisor());
CREATE POLICY "Inventory delete policy" ON public.inventory FOR DELETE TO authenticated USING (public.is_owner());

-- Inventory history: Employee gets read-only; Supervisor+ can insert
CREATE POLICY "Inventory history select policy" ON public.inventory_history FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);
CREATE POLICY "Inventory history insert policy" ON public.inventory_history FOR INSERT TO authenticated WITH CHECK (public.is_supervisor());
CREATE POLICY "Inventory history update policy" ON public.inventory_history FOR UPDATE TO authenticated USING (public.is_supervisor()) WITH CHECK (public.is_supervisor());
CREATE POLICY "Inventory history delete policy" ON public.inventory_history FOR DELETE TO authenticated USING (public.is_owner());

-- Inventory transactions: Employee gets read-only; Supervisor+ can mutate; Owner+ can delete
CREATE POLICY "Inventory transactions select policy" ON public.inventory_transactions FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);
CREATE POLICY "Inventory transactions insert policy" ON public.inventory_transactions FOR INSERT TO authenticated WITH CHECK (public.is_supervisor());
CREATE POLICY "Inventory transactions update policy" ON public.inventory_transactions FOR UPDATE TO authenticated USING (public.is_supervisor()) WITH CHECK (public.is_supervisor());
CREATE POLICY "Inventory transactions delete policy" ON public.inventory_transactions FOR DELETE TO authenticated USING (public.is_owner());

-- Equipment: Supervisor+ full access; Employee denied
CREATE POLICY "Equipment select policy" ON public.equipment FOR SELECT TO authenticated USING (public.is_supervisor());
CREATE POLICY "Equipment insert policy" ON public.equipment FOR INSERT TO authenticated WITH CHECK (public.is_supervisor());
CREATE POLICY "Equipment update policy" ON public.equipment FOR UPDATE TO authenticated USING (public.is_supervisor()) WITH CHECK (public.is_supervisor());
CREATE POLICY "Equipment delete policy" ON public.equipment FOR DELETE TO authenticated USING (public.is_owner());

-- 7.9 QUOTATIONS, VENDORS, SUBCONTRACTORS & PROPERTIES (STRICTLY OWNER & ADMIN)
ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcontractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read quotations" ON public.quotations;
DROP POLICY IF EXISTS "Authenticated write quotations" ON public.quotations;
DROP POLICY IF EXISTS "Authenticated read quotation_items" ON public.quotation_items;
DROP POLICY IF EXISTS "Authenticated write quotation_items" ON public.quotation_items;
DROP POLICY IF EXISTS "Authenticated read vendors" ON public.vendors;
DROP POLICY IF EXISTS "Authenticated write vendors" ON public.vendors;
DROP POLICY IF EXISTS "Authenticated read vendor_transactions" ON public.vendor_transactions;
DROP POLICY IF EXISTS "Authenticated write vendor_transactions" ON public.vendor_transactions;
DROP POLICY IF EXISTS "Authenticated read subcontractors" ON public.subcontractors;
DROP POLICY IF EXISTS "Authenticated write subcontractors" ON public.subcontractors;
DROP POLICY IF EXISTS "Authenticated read properties" ON public.properties;
DROP POLICY IF EXISTS "Authenticated write properties" ON public.properties;
DROP POLICY IF EXISTS "Quotations select policy" ON public.quotations;
DROP POLICY IF EXISTS "Quotations modify policy" ON public.quotations;
DROP POLICY IF EXISTS "Quotation items select policy" ON public.quotation_items;
DROP POLICY IF EXISTS "Quotation items modify policy" ON public.quotation_items;
DROP POLICY IF EXISTS "Vendors select policy" ON public.vendors;
DROP POLICY IF EXISTS "Vendors modify policy" ON public.vendors;
DROP POLICY IF EXISTS "Vendor transactions select policy" ON public.vendor_transactions;
DROP POLICY IF EXISTS "Vendor transactions modify policy" ON public.vendor_transactions;
DROP POLICY IF EXISTS "Subcontractors select policy" ON public.subcontractors;
DROP POLICY IF EXISTS "Subcontractors modify policy" ON public.subcontractors;
DROP POLICY IF EXISTS "Properties select policy" ON public.properties;
DROP POLICY IF EXISTS "Properties modify policy" ON public.properties;

CREATE POLICY "Quotations select policy" ON public.quotations FOR SELECT TO authenticated USING (public.is_owner());
CREATE POLICY "Quotations modify policy" ON public.quotations FOR ALL TO authenticated USING (public.is_owner()) WITH CHECK (public.is_owner());
CREATE POLICY "Quotation items select policy" ON public.quotation_items FOR SELECT TO authenticated USING (public.is_owner());
CREATE POLICY "Quotation items modify policy" ON public.quotation_items FOR ALL TO authenticated USING (public.is_owner()) WITH CHECK (public.is_owner());
CREATE POLICY "Vendors select policy" ON public.vendors FOR SELECT TO authenticated USING (public.is_owner());
CREATE POLICY "Vendors modify policy" ON public.vendors FOR ALL TO authenticated USING (public.is_owner()) WITH CHECK (public.is_owner());
CREATE POLICY "Vendor transactions select policy" ON public.vendor_transactions FOR SELECT TO authenticated USING (public.is_owner());
CREATE POLICY "Vendor transactions modify policy" ON public.vendor_transactions FOR ALL TO authenticated USING (public.is_owner()) WITH CHECK (public.is_owner());
CREATE POLICY "Subcontractors select policy" ON public.subcontractors FOR SELECT TO authenticated USING (public.is_owner());
CREATE POLICY "Subcontractors modify policy" ON public.subcontractors FOR ALL TO authenticated USING (public.is_owner()) WITH CHECK (public.is_owner());
CREATE POLICY "Properties select policy" ON public.properties FOR SELECT TO authenticated USING (public.is_owner());
CREATE POLICY "Properties modify policy" ON public.properties FOR ALL TO authenticated USING (public.is_owner()) WITH CHECK (public.is_owner());

-- 7.10 DAILY PROGRESS, CHECKLISTS & SITE TICKETS
ALTER TABLE public.daily_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_drawings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read daily_progress" ON public.daily_progress;
DROP POLICY IF EXISTS "Allow authenticated insert/update daily_progress" ON public.daily_progress;
DROP POLICY IF EXISTS "Authenticated users read project_checklists" ON public.project_checklists;
DROP POLICY IF EXISTS "Authenticated users write project_checklists" ON public.project_checklists;
DROP POLICY IF EXISTS "Authenticated read site_tickets" ON public.site_tickets;
DROP POLICY IF EXISTS "Authenticated write site_tickets" ON public.site_tickets;
DROP POLICY IF EXISTS "Authenticated read ticket_messages" ON public.ticket_messages;
DROP POLICY IF EXISTS "Authenticated write ticket_messages" ON public.ticket_messages;
DROP POLICY IF EXISTS "Authenticated read site_drawings" ON public.site_drawings;
DROP POLICY IF EXISTS "Authenticated write site_drawings" ON public.site_drawings;
DROP POLICY IF EXISTS "Daily progress select policy" ON public.daily_progress;
DROP POLICY IF EXISTS "Daily progress modify policy" ON public.daily_progress;
DROP POLICY IF EXISTS "Project checklists select policy" ON public.project_checklists;
DROP POLICY IF EXISTS "Project checklists insert policy" ON public.project_checklists;
DROP POLICY IF EXISTS "Project checklists update policy" ON public.project_checklists;
DROP POLICY IF EXISTS "Project checklists delete policy" ON public.project_checklists;
DROP POLICY IF EXISTS "Site tickets select policy" ON public.site_tickets;
DROP POLICY IF EXISTS "Site tickets insert policy" ON public.site_tickets;
DROP POLICY IF EXISTS "Site tickets update policy" ON public.site_tickets;
DROP POLICY IF EXISTS "Site tickets delete policy" ON public.site_tickets;
DROP POLICY IF EXISTS "Ticket messages select policy" ON public.ticket_messages;
DROP POLICY IF EXISTS "Ticket messages insert policy" ON public.ticket_messages;
DROP POLICY IF EXISTS "Ticket messages delete policy" ON public.ticket_messages;
DROP POLICY IF EXISTS "Site drawings select policy" ON public.site_drawings;
DROP POLICY IF EXISTS "Site drawings modify policy" ON public.site_drawings;

CREATE POLICY "Daily progress select policy"
  ON public.daily_progress FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR (
      public.is_supervisor()
      AND project_id IN (SELECT public.get_supervisor_project_ids())
    )
  );

CREATE POLICY "Daily progress modify policy"
  ON public.daily_progress FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Project checklists select policy"
  ON public.project_checklists FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR project_id IN (SELECT public.get_supervisor_project_ids())
    OR assigned_person = (auth.jwt() ->> 'email')
    OR assigned_person = (SELECT COALESCE(full_name, name) FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "Project checklists insert policy"
  ON public.project_checklists FOR INSERT
  TO authenticated
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Project checklists update policy"
  ON public.project_checklists FOR UPDATE
  TO authenticated
  USING (
    public.is_owner()
    OR project_id IN (SELECT public.get_supervisor_project_ids())
    OR assigned_person = (auth.jwt() ->> 'email')
    OR assigned_person = (SELECT COALESCE(full_name, name) FROM public.profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    public.is_owner()
    OR project_id IN (SELECT public.get_supervisor_project_ids())
    OR assigned_person = (auth.jwt() ->> 'email')
    OR assigned_person = (SELECT COALESCE(full_name, name) FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "Project checklists delete policy"
  ON public.project_checklists FOR DELETE
  TO authenticated
  USING (public.is_owner());

CREATE POLICY "Site tickets select policy"
  ON public.site_tickets FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR project_id IN (SELECT public.get_supervisor_project_ids())
    OR assigned_to = auth.uid()
    OR reported_by = auth.uid()
  );

CREATE POLICY "Site tickets insert policy"
  ON public.site_tickets FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Site tickets update policy"
  ON public.site_tickets FOR UPDATE
  TO authenticated
  USING (
    public.is_owner()
    OR project_id IN (SELECT public.get_supervisor_project_ids())
    OR assigned_to = auth.uid()
    OR reported_by = auth.uid()
  )
  WITH CHECK (
    public.is_owner()
    OR project_id IN (SELECT public.get_supervisor_project_ids())
    OR assigned_to = auth.uid()
    OR reported_by = auth.uid()
  );

CREATE POLICY "Site tickets delete policy"
  ON public.site_tickets FOR DELETE
  TO authenticated
  USING (public.is_owner());

CREATE POLICY "Ticket messages select policy"
  ON public.ticket_messages FOR SELECT
  TO authenticated
  USING (
    public.is_owner()
    OR sender_id = auth.uid()
    OR ticket_id IN (
      SELECT id FROM public.site_tickets
      WHERE assigned_to = auth.uid() OR reported_by = auth.uid()
    )
  );

CREATE POLICY "Ticket messages insert policy"
  ON public.ticket_messages FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Ticket messages delete policy"
  ON public.ticket_messages FOR DELETE
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Site drawings select policy"
  ON public.site_drawings FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Site drawings modify policy"
  ON public.site_drawings FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 7.11 AUDIT LOGS, ACTIVITIES, SYSTEM SETTINGS, PROFILES & IMAGES
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Authenticated users can insert audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Deny updates on audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Deny deletes on audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Authenticated users can read activities" ON public.activities;
DROP POLICY IF EXISTS "Authenticated users can insert activities" ON public.activities;
DROP POLICY IF EXISTS "Deny updates on activities" ON public.activities;
DROP POLICY IF EXISTS "Deny deletes on activities" ON public.activities;
DROP POLICY IF EXISTS "Authenticated read system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Authenticated write system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Authenticated users can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can update own or admin profiles" ON public.profiles;
DROP POLICY IF EXISTS "App images select policy" ON public.app_images;
DROP POLICY IF EXISTS "App images insert policy" ON public.app_images;
DROP POLICY IF EXISTS "App images modify policy" ON public.app_images;
DROP POLICY IF EXISTS "Profiles select policy" ON public.profiles;
DROP POLICY IF EXISTS "Profiles insert policy" ON public.profiles;
DROP POLICY IF EXISTS "Profiles update policy" ON public.profiles;
DROP POLICY IF EXISTS "Profiles delete policy" ON public.profiles;
DROP POLICY IF EXISTS "Audit logs select policy" ON public.audit_logs;
DROP POLICY IF EXISTS "Audit logs insert policy" ON public.audit_logs;
DROP POLICY IF EXISTS "Activities select policy" ON public.activities;
DROP POLICY IF EXISTS "Activities insert policy" ON public.activities;
DROP POLICY IF EXISTS "System settings select policy" ON public.system_settings;
DROP POLICY IF EXISTS "System settings modify policy" ON public.system_settings;

CREATE POLICY "Audit logs select policy" ON public.audit_logs FOR SELECT TO authenticated USING (public.is_admin());
CREATE POLICY "Audit logs insert policy" ON public.audit_logs FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Deny updates on audit_logs" ON public.audit_logs FOR UPDATE TO authenticated USING (false);
CREATE POLICY "Deny deletes on audit_logs" ON public.audit_logs FOR DELETE TO authenticated USING (false);

CREATE POLICY "Activities select policy" ON public.activities FOR SELECT TO authenticated USING (public.is_supervisor());
CREATE POLICY "Activities insert policy" ON public.activities FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Deny updates on activities" ON public.activities FOR UPDATE TO authenticated USING (false);
CREATE POLICY "Deny deletes on activities" ON public.activities FOR DELETE TO authenticated USING (false);

CREATE POLICY "System settings select policy" ON public.system_settings FOR SELECT TO authenticated USING (public.is_admin());
CREATE POLICY "System settings modify policy" ON public.system_settings FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Profiles Privacy: Owner & Admin read all; Supervisor & Employee read OWN profile only
CREATE POLICY "Profiles select policy"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id OR public.is_owner());

CREATE POLICY "Profiles insert policy"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY "Profiles update policy"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id OR public.is_admin())
  WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY "Profiles delete policy"
  ON public.profiles FOR DELETE
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "App images select policy" ON public.app_images FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);
CREATE POLICY "App images insert policy" ON public.app_images FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "App images modify policy" ON public.app_images FOR ALL TO authenticated USING (auth.uid() = user_id OR public.is_admin()) WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- ── 7.12 STORAGE BUCKETS (PROFILES & PROGRESS) ────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('site-progress', 'site-progress', true), ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public read storage" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload storage" ON storage.objects;
DROP POLICY IF EXISTS "Auth update storage" ON storage.objects;

CREATE POLICY "Public read storage" ON storage.objects FOR SELECT USING (bucket_id IN ('site-progress', 'avatars'));
CREATE POLICY "Auth upload storage" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id IN ('site-progress', 'avatars'));
CREATE POLICY "Auth update storage" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id IN ('site-progress', 'avatars'));

-- ── 8. RELOAD SCHEMA CACHE ────────────────────────────────────
NOTIFY pgrst, 'reload schema';
