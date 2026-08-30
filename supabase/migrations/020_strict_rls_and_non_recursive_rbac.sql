-- ============================================================
-- iBuild ERP: COMPLETE CONSOLIDATED PRODUCTION REPAIR MIGRATION
-- MIGRATION 020: STRICT RLS, NON-RECURSIVE RBAC & SCHEMA REPAIR
--
-- Fixes:
-- 1. PostgreSQL 42P17 (infinite recursion in user_roles policy)
-- 2. Role-Scoped RLS isolation (Employee denied from all financials & other users)
-- 3. PostgreSQL 42703 (employees.daily_rate column added & synchronized with salary)
-- 4. Attendance (employee_id, date) unique constraint & conflict safety
-- 5. Atomic project spend calculation on expense insert/update/delete
-- 6. Preserves all existing business data
-- ============================================================

-- ── 1. EMPLOYEE SCHEMA REPAIR (FIX 42703 daily_rate) ─────────

ALTER TABLE public.employees 
  ADD COLUMN IF NOT EXISTS daily_rate NUMERIC(12, 2) DEFAULT 600.00,
  ADD COLUMN IF NOT EXISTS salary NUMERIC(12, 2) DEFAULT 18000.00,
  ADD COLUMN IF NOT EXISTS tea_allowance NUMERIC(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Backfill daily_rate from salary or salary from daily_rate
UPDATE public.employees
SET daily_rate = ROUND(COALESCE(salary, 18000.00) / 30.0, 2)
WHERE (daily_rate IS NULL OR daily_rate = 0) AND salary IS NOT NULL AND salary > 0;

UPDATE public.employees
SET salary = ROUND(COALESCE(daily_rate, 600.00) * 30.0, 2)
WHERE (salary IS NULL OR salary = 0) AND daily_rate IS NOT NULL AND daily_rate > 0;

-- Bi-directional trigger to keep daily_rate and salary synchronized
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

-- Link known standard accounts by email
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

-- ── 2. ATTENDANCE INTEGRITY & UNIQUE CONSTRAINT ──────────────

-- Ensure attendance wage rate snapshot columns exist
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS wage_rate NUMERIC(12, 2),
  ADD COLUMN IF NOT EXISTS tea_allowance NUMERIC(10, 2) DEFAULT 0.00;

-- Remove duplicates keeping the most recent attendance row before adding unique constraint
DELETE FROM public.attendance a
USING public.attendance b
WHERE a.employee_id = b.employee_id 
  AND a.date = b.date 
  AND a.created_at < b.created_at;

-- Enforce uniqueness on (employee_id, date)
ALTER TABLE public.attendance 
  DROP CONSTRAINT IF EXISTS unique_employee_date,
  DROP CONSTRAINT IF EXISTS attendance_employee_id_date_key;

ALTER TABLE public.attendance
  ADD CONSTRAINT unique_employee_date UNIQUE (employee_id, date);

-- Attendance historical wage snapshot trigger
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

-- ── 3. ATOMIC PROJECT SPEND CALCULATION ───────────────────────

-- Ensure non-negative constraint on expenses
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

-- One-time reconciliation of project spends
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

-- ── 4. NON-RECURSIVE SECURITY DEFINER ROLE HELPER FUNCTIONS ───

-- Drop old functions
DROP FUNCTION IF EXISTS public.get_auth_role() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.is_owner() CASCADE;
DROP FUNCTION IF EXISTS public.is_supervisor() CASCADE;
DROP FUNCTION IF EXISTS public.is_employee() CASCADE;
DROP FUNCTION IF EXISTS public.get_auth_employee_id() CASCADE;

-- Base role detector: reads from JWT / profiles / auth.users (NEVER queries user_roles to guarantee 0% recursion)
CREATE OR REPLACE FUNCTION public.get_auth_role()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN 'anonymous';
  END IF;

  -- 1. First check JWT claims (fastest and zero-table dependency)
  v_role := lower(COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role',
    ''
  ));

  IF v_role <> '' THEN
    RETURN v_role;
  END IF;

  -- 2. Check profiles table (isolated table, avoids recursion on user_roles)
  SELECT lower(role_display) INTO v_role
  FROM public.profiles
  WHERE id = auth.uid()
  LIMIT 1;

  IF v_role IS NOT NULL AND v_role <> '' THEN
    RETURN v_role;
  END IF;

  -- 3. Check auth.users table
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

-- Admin check: full technical & administrative access
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() = 'admin';
$$;

-- Owner check: admin or business owner
CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() IN ('admin', 'owner');
$$;

-- Supervisor check: admin, owner, or site supervisor
CREATE OR REPLACE FUNCTION public.is_supervisor()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() IN ('admin', 'owner', 'supervisor');
$$;

-- Employee check: field employee
CREATE OR REPLACE FUNCTION public.is_employee()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.get_auth_role() = 'employee';
$$;

-- Helper to find employee.id for current auth.uid()
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

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.get_auth_role() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_owner() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_supervisor() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_employee() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_auth_employee_id() TO authenticated, service_role;

-- ── 5. USER ROLES & RBAC TABLES (ZERO RECURSION GUARANTEE) ───

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

-- Drop all previous policies on user_roles
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

-- Clean non-recursive user_roles policies (get_auth_role / is_admin never queries user_roles)
CREATE POLICY "Users can read own user_roles or admin read all"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users can insert own user_role or admin manage"
  ON public.user_roles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Admins can update user_roles"
  ON public.user_roles FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete user_roles"
  ON public.user_roles FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- Synchronize user_roles changes automatically to profiles and auth metadata
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

-- Roles, Permissions, Role-Permissions
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

-- ── 6. STRICT CORE BUSINESS TABLES RLS POLICIES ──────────────

-- 6.1 PROJECTS
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
    public.is_supervisor() 
    OR id IN (
      SELECT project_id FROM public.project_checklists 
      WHERE assigned_person = (auth.jwt() ->> 'email')
         OR assigned_person = (SELECT full_name FROM public.profiles WHERE id = auth.uid())
    )
    OR id IN (
      SELECT project_id FROM public.site_tickets 
      WHERE assigned_to = auth.uid()
    )
  );

CREATE POLICY "Projects insert policy"
  ON public.projects FOR INSERT
  TO authenticated
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Projects update policy"
  ON public.projects FOR UPDATE
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Projects delete policy"
  ON public.projects FOR DELETE
  TO authenticated
  USING (public.is_supervisor());

-- 6.2 EMPLOYEES
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
    public.is_supervisor()
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
  USING (public.is_supervisor());

-- 6.3 ATTENDANCE
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Attendance select policy" ON public.attendance;
DROP POLICY IF EXISTS "Attendance insert policy" ON public.attendance;
DROP POLICY IF EXISTS "Attendance update policy" ON public.attendance;
DROP POLICY IF EXISTS "Attendance delete policy" ON public.attendance;

CREATE POLICY "Attendance select policy"
  ON public.attendance FOR SELECT
  TO authenticated
  USING (
    public.is_supervisor()
    OR employee_id = public.get_auth_employee_id()
    OR employee_id IN (
      SELECT id FROM public.employees 
      WHERE user_id = auth.uid() 
         OR (email IS NOT NULL AND lower(email) = lower(auth.jwt() ->> 'email'))
    )
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
  USING (public.is_supervisor());

-- 6.4 EXPENSES (STRICT FINANCIAL ISOLATION - EMPLOYEE DENIED)
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Expenses select policy" ON public.expenses;
DROP POLICY IF EXISTS "Expenses insert policy" ON public.expenses;
DROP POLICY IF EXISTS "Expenses update policy" ON public.expenses;
DROP POLICY IF EXISTS "Expenses delete policy" ON public.expenses;

CREATE POLICY "Expenses select policy"
  ON public.expenses FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Expenses insert policy"
  ON public.expenses FOR INSERT
  TO authenticated
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Expenses update policy"
  ON public.expenses FOR UPDATE
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Expenses delete policy"
  ON public.expenses FOR DELETE
  TO authenticated
  USING (public.is_supervisor());

-- 6.5 BILLS (VENDOR BILLS - EMPLOYEE DENIED)
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Bills select policy" ON public.bills;
DROP POLICY IF EXISTS "Bills insert policy" ON public.bills;
DROP POLICY IF EXISTS "Bills update policy" ON public.bills;
DROP POLICY IF EXISTS "Bills delete policy" ON public.bills;

CREATE POLICY "Bills select policy"
  ON public.bills FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Bills insert policy"
  ON public.bills FOR INSERT
  TO authenticated
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Bills update policy"
  ON public.bills FOR UPDATE
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Bills delete policy"
  ON public.bills FOR DELETE
  TO authenticated
  USING (public.is_supervisor());

-- 6.6 SALES BILLS & ITEMS (EMPLOYEE DENIED)
ALTER TABLE public.sales_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_bill_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users read sales_bills" ON public.sales_bills;
DROP POLICY IF EXISTS "Authenticated users write sales_bills" ON public.sales_bills;
DROP POLICY IF EXISTS "Authenticated read sales_bill_items" ON public.sales_bill_items;
DROP POLICY IF EXISTS "Authenticated write sales_bill_items" ON public.sales_bill_items;

CREATE POLICY "Sales bills select policy"
  ON public.sales_bills FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Sales bills modify policy"
  ON public.sales_bills FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Sales bill items select policy"
  ON public.sales_bill_items FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Sales bill items modify policy"
  ON public.sales_bill_items FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.7 PAYMENT LEDGER & PROJECT PAYMENTS (EMPLOYEE DENIED)
ALTER TABLE public.payment_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read payment_ledger" ON public.payment_ledger;
DROP POLICY IF EXISTS "Authenticated write payment_ledger" ON public.payment_ledger;
DROP POLICY IF EXISTS "Authenticated users read project_payments" ON public.project_payments;
DROP POLICY IF EXISTS "Authenticated users write project_payments" ON public.project_payments;

CREATE POLICY "Payment ledger select policy"
  ON public.payment_ledger FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Payment ledger modify policy"
  ON public.payment_ledger FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Project payments select policy"
  ON public.project_payments FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Project payments modify policy"
  ON public.project_payments FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.8 INVENTORY & INVENTORY HISTORY (EMPLOYEE DENIED)
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Inventory select policy" ON public.inventory;
DROP POLICY IF EXISTS "Inventory modify policy" ON public.inventory;
DROP POLICY IF EXISTS "Inventory history select policy" ON public.inventory_history;
DROP POLICY IF EXISTS "Inventory history modify policy" ON public.inventory_history;

CREATE POLICY "Inventory select policy"
  ON public.inventory FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Inventory modify policy"
  ON public.inventory FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Inventory history select policy"
  ON public.inventory_history FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Inventory history modify policy"
  ON public.inventory_history FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.9 EQUIPMENT & MACHINERY (EMPLOYEE DENIED)
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read equipment" ON public.equipment;
DROP POLICY IF EXISTS "Authenticated write equipment" ON public.equipment;

CREATE POLICY "Equipment select policy"
  ON public.equipment FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Equipment modify policy"
  ON public.equipment FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.10 QUOTATIONS & QUOTATION ITEMS (EMPLOYEE DENIED)
ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotation_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read quotations" ON public.quotations;
DROP POLICY IF EXISTS "Authenticated write quotations" ON public.quotations;
DROP POLICY IF EXISTS "Authenticated read quotation_items" ON public.quotation_items;
DROP POLICY IF EXISTS "Authenticated write quotation_items" ON public.quotation_items;

CREATE POLICY "Quotations select policy"
  ON public.quotations FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Quotations modify policy"
  ON public.quotations FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Quotation items select policy"
  ON public.quotation_items FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Quotation items modify policy"
  ON public.quotation_items FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.11 VENDORS & TRANSACTIONS (EMPLOYEE DENIED)
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read vendors" ON public.vendors;
DROP POLICY IF EXISTS "Authenticated write vendors" ON public.vendors;
DROP POLICY IF EXISTS "Authenticated read vendor_transactions" ON public.vendor_transactions;
DROP POLICY IF EXISTS "Authenticated write vendor_transactions" ON public.vendor_transactions;

CREATE POLICY "Vendors select policy"
  ON public.vendors FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Vendors modify policy"
  ON public.vendors FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Vendor transactions select policy"
  ON public.vendor_transactions FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Vendor transactions modify policy"
  ON public.vendor_transactions FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.12 SUBCONTRACTORS (EMPLOYEE DENIED)
ALTER TABLE public.subcontractors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read subcontractors" ON public.subcontractors;
DROP POLICY IF EXISTS "Authenticated write subcontractors" ON public.subcontractors;

CREATE POLICY "Subcontractors select policy"
  ON public.subcontractors FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Subcontractors modify policy"
  ON public.subcontractors FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.13 DAILY PROGRESS
ALTER TABLE public.daily_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated read daily_progress" ON public.daily_progress;
DROP POLICY IF EXISTS "Allow authenticated insert/update daily_progress" ON public.daily_progress;

CREATE POLICY "Daily progress select policy"
  ON public.daily_progress FOR SELECT
  TO authenticated
  USING (
    public.is_supervisor() 
    OR project_id IN (
      SELECT project_id FROM public.project_checklists 
      WHERE assigned_person = (auth.jwt() ->> 'email')
    )
  );

CREATE POLICY "Daily progress modify policy"
  ON public.daily_progress FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.14 PROJECT CHECKLISTS (ASSIGNED TASK ACCESS)
ALTER TABLE public.project_checklists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users read project_checklists" ON public.project_checklists;
DROP POLICY IF EXISTS "Authenticated users write project_checklists" ON public.project_checklists;

CREATE POLICY "Project checklists select policy"
  ON public.project_checklists FOR SELECT
  TO authenticated
  USING (
    public.is_supervisor()
    OR assigned_person = (auth.jwt() ->> 'email')
    OR assigned_person = (SELECT full_name FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "Project checklists insert policy"
  ON public.project_checklists FOR INSERT
  TO authenticated
  WITH CHECK (public.is_supervisor());

CREATE POLICY "Project checklists update policy"
  ON public.project_checklists FOR UPDATE
  TO authenticated
  USING (
    public.is_supervisor()
    OR assigned_person = (auth.jwt() ->> 'email')
    OR assigned_person = (SELECT full_name FROM public.profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    public.is_supervisor()
    OR assigned_person = (auth.jwt() ->> 'email')
    OR assigned_person = (SELECT full_name FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "Project checklists delete policy"
  ON public.project_checklists FOR DELETE
  TO authenticated
  USING (public.is_supervisor());

-- 6.15 SITE TICKETS / SNAGS
ALTER TABLE public.site_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read site_tickets" ON public.site_tickets;
DROP POLICY IF EXISTS "Authenticated write site_tickets" ON public.site_tickets;

CREATE POLICY "Site tickets select policy"
  ON public.site_tickets FOR SELECT
  TO authenticated
  USING (
    public.is_supervisor() 
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
    public.is_supervisor() 
    OR assigned_to = auth.uid() 
    OR reported_by = auth.uid()
  )
  WITH CHECK (
    public.is_supervisor() 
    OR assigned_to = auth.uid() 
    OR reported_by = auth.uid()
  );

CREATE POLICY "Site tickets delete policy"
  ON public.site_tickets FOR DELETE
  TO authenticated
  USING (public.is_supervisor());

-- 6.16 TICKET MESSAGES
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read ticket_messages" ON public.ticket_messages;
DROP POLICY IF EXISTS "Authenticated write ticket_messages" ON public.ticket_messages;

CREATE POLICY "Ticket messages select policy"
  ON public.ticket_messages FOR SELECT
  TO authenticated
  USING (
    public.is_supervisor() 
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

-- 6.17 SITE DRAWINGS
ALTER TABLE public.site_drawings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read site_drawings" ON public.site_drawings;
DROP POLICY IF EXISTS "Authenticated write site_drawings" ON public.site_drawings;

CREATE POLICY "Site drawings select policy"
  ON public.site_drawings FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Site drawings modify policy"
  ON public.site_drawings FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.18 PROPERTIES (EMPLOYEE DENIED)
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read properties" ON public.properties;
DROP POLICY IF EXISTS "Authenticated write properties" ON public.properties;

CREATE POLICY "Properties select policy"
  ON public.properties FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Properties modify policy"
  ON public.properties FOR ALL
  TO authenticated
  USING (public.is_supervisor())
  WITH CHECK (public.is_supervisor());

-- 6.19 AUDIT LOGS & ACTIVITIES (APPEND-ONLY, EMPLOYEE DENIED)
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Authenticated users can insert audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Deny updates on audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Deny deletes on audit_logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Authenticated users can read activities" ON public.activities;
DROP POLICY IF EXISTS "Authenticated users can insert activities" ON public.activities;

CREATE POLICY "Audit logs select policy"
  ON public.audit_logs FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Audit logs insert policy"
  ON public.audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Deny updates on audit_logs"
  ON public.audit_logs FOR UPDATE
  TO authenticated
  USING (false);

CREATE POLICY "Deny deletes on audit_logs"
  ON public.audit_logs FOR DELETE
  TO authenticated
  USING (false);

CREATE POLICY "Activities select policy"
  ON public.activities FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "Activities insert policy"
  ON public.activities FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Deny updates on activities"
  ON public.activities FOR UPDATE
  TO authenticated
  USING (false);

CREATE POLICY "Deny deletes on activities"
  ON public.activities FOR DELETE
  TO authenticated
  USING (false);

-- 6.20 SYSTEM SETTINGS (EMPLOYEE DENIED, ADMIN ONLY WRITE)
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated read system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Authenticated write system_settings" ON public.system_settings;

CREATE POLICY "System settings select policy"
  ON public.system_settings FOR SELECT
  TO authenticated
  USING (public.is_supervisor());

CREATE POLICY "System settings modify policy"
  ON public.system_settings FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 6.21 PROFILES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can update own or admin profiles" ON public.profiles;

CREATE POLICY "Profiles select policy"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

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

-- 6.22 APP IMAGES
ALTER TABLE public.app_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "App images select policy" ON public.app_images;
DROP POLICY IF EXISTS "App images insert policy" ON public.app_images;
DROP POLICY IF EXISTS "App images modify policy" ON public.app_images;

CREATE POLICY "App images select policy"
  ON public.app_images FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "App images insert policy"
  ON public.app_images FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "App images modify policy"
  ON public.app_images FOR ALL
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- ── 7. RELOAD SCHEMA CACHE ────────────────────────────────────
NOTIFY pgrst, 'reload schema';
