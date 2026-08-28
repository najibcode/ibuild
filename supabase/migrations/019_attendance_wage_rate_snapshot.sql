-- ============================================================
-- MIGRATION 019: ATTENDANCE HISTORICAL WAGE RATE & ALLOWANCE SNAPSHOTS
-- Ensures wage increments only affect future attendance records without altering historical logs
-- ============================================================

-- 1. Add wage_rate and tea_allowance columns to attendance table
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS wage_rate NUMERIC(10, 2);
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS tea_allowance NUMERIC(10, 2);

-- 2. Populate existing historical attendance rows from employees table if wage_rate is currently null
UPDATE public.attendance a
SET wage_rate = COALESCE(a.wage_rate, e.salary, 0.00),
    tea_allowance = COALESCE(a.tea_allowance, e.tea_snack_allowance, 20.00)
FROM public.employees e
WHERE a.employee_id = e.id AND a.wage_rate IS NULL;

-- 3. Trigger to automatically snapshot employee's current salary and tea allowance if not explicitly provided
CREATE OR REPLACE FUNCTION public.snapshot_attendance_wages()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.wage_rate IS NULL THEN
    SELECT COALESCE(salary, daily_rate, 0.00), COALESCE(tea_snack_allowance, 20.00)
    INTO NEW.wage_rate, NEW.tea_allowance
    FROM public.employees
    WHERE id = NEW.employee_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_snapshot_attendance_wages ON public.attendance;
CREATE TRIGGER trg_snapshot_attendance_wages
BEFORE INSERT ON public.attendance
FOR EACH ROW
EXECUTE FUNCTION public.snapshot_attendance_wages();

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
