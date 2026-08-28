-- ============================================================
-- MIGRATION 018: EMPLOYEE SALARY, DAILY WAGES & WORKFORCE REPAIR
-- Ensures full support for salary, daily_rate, tea_snack_allowance, and profile photos
-- ============================================================

-- 1. Ensure employees table exists with complete schema
CREATE TABLE IF NOT EXISTS public.employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'Labor',
    salary NUMERIC(10, 2) DEFAULT 0.00,
    daily_rate NUMERIC(10, 2) DEFAULT 0.00,
    tea_snack_allowance NUMERIC(10, 2) DEFAULT 20.00,
    status TEXT DEFAULT 'active',
    photo_url TEXT,
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 2. Safely add any missing columns to existing employees table
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'Labor';
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS salary NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS daily_rate NUMERIC(10, 2) DEFAULT 0.00;
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS tea_snack_allowance NUMERIC(10, 2) DEFAULT 20.00;
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 3. Synchronize existing salary and daily_rate values
UPDATE public.employees 
SET salary = COALESCE(salary, daily_rate, 0.00),
    daily_rate = COALESCE(daily_rate, salary, 0.00),
    tea_snack_allowance = COALESCE(tea_snack_allowance, 20.00)
WHERE salary IS NULL OR daily_rate IS NULL OR tea_snack_allowance IS NULL;

-- 4. Trigger to keep salary and daily_rate automatically synchronized
CREATE OR REPLACE FUNCTION public.sync_employee_rates()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.salary IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.salary IS NULL OR NEW.salary <> OLD.salary) THEN
    NEW.daily_rate = NEW.salary;
  ELSIF NEW.daily_rate IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.daily_rate IS NULL OR NEW.daily_rate <> OLD.daily_rate) THEN
    NEW.salary = NEW.daily_rate;
  END IF;
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_employee_rates ON public.employees;
CREATE TRIGGER trg_sync_employee_rates
BEFORE INSERT OR UPDATE ON public.employees
FOR EACH ROW
EXECUTE FUNCTION public.sync_employee_rates();

-- 5. Row Level Security Policies for Workforce Management
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read employees" ON public.employees;
CREATE POLICY "Authenticated read employees"
    ON public.employees FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Authenticated write employees" ON public.employees;
CREATE POLICY "Authenticated write employees"
    ON public.employees FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 6. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
