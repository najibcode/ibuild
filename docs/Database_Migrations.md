# Database Migration & Versioning Strategy

This document establishes the guidelines, naming standards, relational extensions, and historical migration logs for the Supabase PostgreSQL database in **IBUILD ERP**.

---

## 1. Database Coding Standards & Naming Conventions

* **Tables & Columns**: Always write names in `lower_snake_case` (e.g., `project_id`, `daily_rate`, `tea_allowance`).
* **Primary Keys**: Always use a unique identifier named `id` (`UUID PRIMARY KEY DEFAULT gen_random_uuid()`).
* **Foreign Keys**: Explicitly prefix with target table and `_id` suffix (e.g., `employee_id REFERENCES public.employees(id)`).
* **Timestamps**: Every table includes `created_at` and `updated_at` with UTC timezone defaults:
  ```sql
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
  ```

---

## 2. Applied Migrations Catalog

| Migration File | Purpose & Changes |
|---|---|
| **`001_rbac_tables.sql`** | Core RBAC schema (`roles`, `permissions`, `role_permissions`, `user_roles`). |
| **`002_enterprise_production_features.sql`** | Subcontractors, bill items, payment methods, retention tracking. |
| **`003_project_operations.sql`** | Project operations hub, phase groupings, and progress metrics. |
| **`004_commercial_workflows.sql`** | Sales bills, GST invoices, and party ledger integrations. |
| **`005_supervision_and_evidence.sql`** | Site drawings, defects/snags, checklists, and photo evidence. |
| **`006_daily_progress_evidence.sql`** | Daily progress report photos, weather conditions, worker muster. |
| **`007_machinery_equipment.sql`** | Heavy equipment directory, rental rates, and maintenance records. |
| **`008_tea_snack_allowance.sql`** | Daily tea & snack allowance column (`tea_allowance NUMERIC(10,2)`). |
| **`009_imagekit_metadata.sql`** | CDN photo metadata, thumbnail URLs, and document storage attachments. |
| **`010_admin_control_center.sql`** | System settings, user administration, and audit logs. |
| **`011_drawings_storage_and_categories.sql`** | Architectural and structural drawing categorization and file storage. |
| **`012_fix_user_roles_recursion.sql`** | Initial non-recursive policy patch for `user_roles`. |
| **`013_activities_table.sql`** | User activity logging table for site operations. |
| **`014_user_custom_permissions.sql`** | Granular user-level custom permission overrides. |
| **`015_add_avatar_url_to_profiles.sql`** | Avatar URLs on user profiles with CDN links. |
| **`016_subcontractors_project_and_sync.sql`** | Project-level subcontractor linking and retention balance calculations. |
| **`017_production_repair_triggers_and_constraints.sql`** | **Atomic Spend Calculation Trigger** (`update_project_spent_atomic`), **Attendance Unique Constraint** (`UNIQUE (employee_id, date)`), and Metadata Sanitizer. |
| **`018_employee_salary_and_workforce_repair.sql`** | Schema support for both `salary` and `daily_rate`, with bidirectional synchronization trigger `trg_sync_employee_rates`. |
| **`019_attendance_wage_rate_snapshot.sql`** | Attendance historical wage snapshotting trigger (`trg_snapshot_attendance_wages`) for immutable past payroll records. |
| **`020_strict_rls_and_non_recursive_rbac.sql`** | **Consolidated Production Security Migration**: Non-recursive `SECURITY DEFINER` role check functions, zero-recursion `user_roles` policies, table-by-table RLS denial for Employee accounts on all financial tables, `inventory_transactions` schema definition, test account role sanitization, and project-scoped access. |

---

## 3. Key Production Database Triggers & Functions

### A. Non-Recursive Role Resolver (`get_auth_role()`)
```sql
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
  IF auth.uid() IS NULL THEN RETURN 'anonymous'; END IF;

  -- 1. Fast O(1) JWT claim check
  v_role := lower(COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role',
    ''
  ));
  IF v_role <> '' THEN RETURN v_role; END IF;

  -- 2. Profiles table check (avoids user_roles recursion)
  SELECT lower(role_display) INTO v_role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
  IF v_role IS NOT NULL AND v_role <> '' THEN RETURN v_role; END IF;

  -- 3. Auth users metadata check
  SELECT lower((raw_user_meta_data->>'role')::text) INTO v_role FROM auth.users WHERE id = auth.uid() LIMIT 1;
  IF v_role IS NOT NULL AND v_role <> '' THEN RETURN v_role; END IF;

  RETURN 'employee';
END;
$$;
```

### B. Atomic Project Spend Calculation
```sql
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
    SELECT COALESCE(SUM(amount), 0.00) INTO v_total FROM public.expenses WHERE project_id = v_project_id;
    UPDATE public.projects SET spent = v_total, updated_at = timezone('utc'::text, now()) WHERE id = v_project_id;
  END IF;
  RETURN NULL;
END;
$$;
```

### C. Attendance Historical Wage Rate Snapshotting
```sql
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
    FROM public.employees WHERE id = NEW.employee_id LIMIT 1;

    NEW.wage_rate := COALESCE(v_rate, 600.00);
    NEW.tea_allowance := COALESCE(v_tea, 0.00);
  END IF;
  RETURN NEW;
END;
$$;
```

---

## 4. Execution & Rollback Instructions

### Applying Migrations
All migration scripts are idempotent with `IF NOT EXISTS` and `OR REPLACE` clauses. To apply to Supabase:
1. Open the [Supabase Dashboard -> SQL Editor](https://supabase.com/dashboard/project/dxjvvashdbhlfvsjfdjq/sql).
2. Paste the contents of [supabase/migrations/020_strict_rls_and_non_recursive_rbac.sql](file:///Users/najib/ibuild/supabase/migrations/020_strict_rls_and_non_recursive_rbac.sql).
3. Click **Run**. Schema cache is automatically reloaded via `NOTIFY pgrst, 'reload schema'`.

### Rollback Strategy
In the event a rollback is required:
1. Restore previous policy definitions using `DROP POLICY ... ON table_name` and re-applying legacy policy scripts if necessary.
2. Trigger functions can be safely dropped or replaced with previous signatures using `DROP TRIGGER IF EXISTS ...`.
