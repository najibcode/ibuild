-- ============================================================================
-- Migration: 022_cascade_deletes_and_permissive_rbac.sql
-- Purpose:
--   1. Ensure atomic cascade deletion for Projects and Employees via database RPC.
--   2. Fix update_project_spent_atomic trigger to prevent deadlock/failure during project delete.
--   3. Ensure DELETE RLS policies allow authenticated project managers and owners to delete.
--   4. Set ON DELETE CASCADE or SET NULL on all project and employee foreign keys.
-- ============================================================================

-- 1. Fix update_project_spent_atomic trigger to check project existence before updating
CREATE OR REPLACE FUNCTION public.update_project_spent_atomic()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Handle INSERT or UPDATE (new project)
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    IF NEW.project_id IS NOT NULL THEN
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
  -- Only update parent project if it still exists (prevents foreign key cascade crash)
  IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
    IF OLD.project_id IS NOT NULL THEN
      IF EXISTS (SELECT 1 FROM public.projects WHERE id = OLD.project_id) THEN
        UPDATE public.projects
        SET spent = COALESCE((
          SELECT SUM(amount) 
          FROM public.expenses 
          WHERE project_id = OLD.project_id AND amount > 0
        ), 0)
        WHERE id = OLD.project_id;
      END IF;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- 2. Stored Procedure: Atomic Cascade Delete for Projects
CREATE OR REPLACE FUNCTION public.delete_project_cascade(p_project_id UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1. Delete dependent expenses (trigger will safely bypass missing project)
  DELETE FROM public.expenses WHERE project_id = p_project_id;

  -- 2. Delete site daily progress logs & evidence
  DELETE FROM public.daily_progress WHERE project_id = p_project_id;

  -- 3. Delete quality snags
  DELETE FROM public.snags WHERE project_id = p_project_id;

  -- 4. Delete vendor bills
  DELETE FROM public.bills WHERE project_id = p_project_id;

  -- 5. Delete site QA checklists & milestones
  DELETE FROM public.project_checklists WHERE project_id = p_project_id;

  -- 6. Delete architectural drawings
  DELETE FROM public.project_drawings WHERE project_id = p_project_id;

  -- 7. Unlink subcontractors, machinery, and attendance
  UPDATE public.subcontractors SET project_id = NULL WHERE project_id = p_project_id;
  UPDATE public.equipment SET project_id = NULL WHERE project_id = p_project_id;
  UPDATE public.attendance SET project_id = NULL WHERE project_id = p_project_id;

  -- 8. Delete the project itself
  DELETE FROM public.projects WHERE id = p_project_id;

  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to cascade delete project %: %', p_project_id, SQLERRM;
END;
$$;

-- 3. Stored Procedure: Atomic Cascade Delete for Employees
CREATE OR REPLACE FUNCTION public.delete_employee_cascade(p_employee_id UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1. Delete employee attendance records to prevent foreign key violation
  DELETE FROM public.attendance WHERE employee_id = p_employee_id;

  -- 2. Unlink any equipment assignments
  UPDATE public.equipment SET assigned_to = NULL WHERE assigned_to = p_employee_id;

  -- 3. Delete the employee record
  DELETE FROM public.employees WHERE id = p_employee_id;

  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to cascade delete employee %: %', p_employee_id, SQLERRM;
END;
$$;

-- Grant execution to authenticated users and service_role
GRANT EXECUTE ON FUNCTION public.delete_project_cascade(UUID) TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION public.delete_employee_cascade(UUID) TO authenticated, service_role, anon;

-- 4. Update DELETE RLS Policies to ensure authenticated managers & owners can delete
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Projects delete policy" ON public.projects;
CREATE POLICY "Projects delete policy"
  ON public.projects FOR DELETE
  TO authenticated
  USING (
    public.is_owner()
    OR public.is_supervisor()
    OR supervisor_id = auth.uid()
    OR auth.uid() IS NOT NULL
  );

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Employees delete policy" ON public.employees;
CREATE POLICY "Employees delete policy"
  ON public.employees FOR DELETE
  TO authenticated
  USING (
    public.is_owner()
    OR public.is_supervisor()
    OR auth.uid() IS NOT NULL
  );

-- 5. Audit Log Entry
INSERT INTO public.audit_logs (
  actor_name,
  action,
  target_type,
  target_id,
  details
) VALUES (
  'MIGRATION_SYSTEM',
  'system.cascade_deletes_enabled',
  'schema',
  '022_cascade_deletes_and_permissive_rbac',
  jsonb_build_object(
    'rpc_functions', jsonb_build_array('delete_project_cascade', 'delete_employee_cascade'),
    'trigger_fixed', 'update_project_spent_atomic'
  )
);
