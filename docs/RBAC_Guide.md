# IBUILD ERP — Role-Based Access Control (RBAC) & Security Guide

## 1. Overview

IBUILD ERP implements a strict, multi-tiered Role-Based Access Control (RBAC) system backed by **PostgreSQL Row-Level Security (RLS)** in Supabase and cached on the client via Riverpod providers.

The architecture strictly enforces permissions at the **database level**, ensuring that regardless of client-side routing, unauthorized API or database requests cannot access restricted rows.

---

## 2. Roles & Access Scope

| Role | Operational Scope | Financial Visibility | Workforce & Rates | Administrative Rights |
|---|---|---|---|---|
| **Admin** | Full System Access | Full Access | Full Access (Rates & Salary) | Manage Users, Roles, Settings, Backups |
| **Owner** | Full Portfolio Oversight | Full Billing, Expenses, Ledgers | Full Access (Rates & Salary) | Company Business Operations |
| **Supervisor** | Assigned Sites, Tasks, DPRs | Site-Level Expenses & Bills | Site Staff (Check-in & Muster) | Operational Site Management |
| **Employee** | Assigned Tasks & Snags Only | ❌ **Strictly Denied (0 rows)** | ❌ **Own Record Only (Coworkers Hidden)** | ❌ None |

### Role Profiles in Detail

#### 👑 Admin
- **Description**: Technical and administrative administrator.
- **Capabilities**: Full CRUD across all 22+ tables, role assignments, custom permission overrides, system settings, and audit logs.
- **Restrictions**: Cannot bypass immutable audit log append-only constraints.

#### 🏢 Owner
- **Description**: Executive business owner with full commercial visibility.
- **Capabilities**: Comprehensive financial variance, client invoicing (`sales_bills`), vendor payables (`bills`), payment ledgers, profit & loss reports, and project creation.
- **Restrictions**: System technical configurations and backend user role infrastructure.

#### 👷 Supervisor
- **Description**: Field site engineer and operations supervisor.
- **Capabilities**: Project operations, daily progress reporting (DPR), attendance logging, site material inventory, machinery deployment, expense vouchers, and defect snagging.
- **Restrictions**: Restricted from accessing global system settings, company-wide accounting ledgers, or deleting core projects/employees.

#### 🛠️ Employee / Field Worker
- **Description**: Individual site worker, specialist technician, or contractor.
- **Capabilities**: Read own profile, log own attendance, view assigned project checklist items, and view/resolve assigned site tickets (snags).
- **Strict Isolation**:
  - **Zero Financial Rows**: `expenses`, `bills`, `sales_bills`, `payment_ledger`, `quotations`, `vendors`, `subcontractors`, `properties`, and `system_settings` return 0 rows.
  - **No Salary / Rate Discovery**: An employee cannot view coworkers' daily wage rates, salaries, or attendance logs.

---

## 3. Non-Recursive RLS Architecture (PostgreSQL 42P17 Prevention)

### The Recursion Problem
In standard RLS implementations, a policy on `public.user_roles` that queries `user_roles` to verify if the caller is an admin causes **PostgreSQL error 42P17: infinite recursion detected in policy for relation "user_roles"**.

### The IBUILD Solution ([Migration 020](file:///Users/najib/ibuild/supabase/migrations/020_strict_rls_and_non_recursive_rbac.sql))
We decouple role and project resolution from table-level cross-referencing:

1. **`SECURITY DEFINER` Non-Recursive Role Helper Functions**:
   ```sql
   CREATE OR REPLACE FUNCTION public.get_auth_role()
   RETURNS text
   LANGUAGE plpgsql
   STABLE
   SECURITY DEFINER
   SET search_path = public
   AS $$ ... $$;

   CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean ...;
   CREATE OR REPLACE FUNCTION public.is_owner() RETURNS boolean ...;
   CREATE OR REPLACE FUNCTION public.is_supervisor() RETURNS boolean ...;
   CREATE OR REPLACE FUNCTION public.is_employee() RETURNS boolean ...;
   ```

2. **`SECURITY DEFINER` Project Assignment Bypass Helpers**:
   To prevent circular sub-queries between `projects` and `project_checklists` / `site_tickets`:
   ```sql
   CREATE OR REPLACE FUNCTION public.get_supervisor_project_ids()
   RETURNS SETOF uuid
   LANGUAGE sql
   STABLE
   SECURITY DEFINER
   SET search_path = public
   AS $$
     SELECT id FROM public.projects WHERE supervisor_id = auth.uid();
   $$;

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
          OR assigned_person = (SELECT COALESCE(full_name, name) FROM public.profiles WHERE id = auth.uid() LIMIT 1)
       UNION
       SELECT project_id FROM public.site_tickets
       WHERE assigned_to = auth.uid() OR reported_by = auth.uid()
     ) sub
     WHERE project_id IS NOT NULL;
   $$;
   ```

3. **Automated Synchronization Trigger**:
   When a role is assigned in `user_roles`, `trg_sync_user_role_to_profile` automatically updates `public.profiles.role_display` and `auth.users.raw_user_meta_data`.

4. **Clean, Non-Recursive Policies on `user_roles`**:
   ```sql
   CREATE POLICY "User roles select policy"
     ON public.user_roles FOR SELECT TO authenticated
     USING (auth.uid() = user_id OR public.is_owner());
   ```

---

## 4. Permission Keys

| Module | Permission Key | Description | Admin | Owner | Supervisor | Employee |
|---|---|---|---|---|---|---|
| **Dashboard** | `dashboard.view` | View dashboard summary | ✅ | ✅ | ✅ | ✅ (Scoped) |
| **Project** | `project.view` | View projects | ✅ | ✅ | ✅ | ✅ (Assigned) |
| **Project** | `project.create` | Create new projects | ✅ | ✅ | ❌ | ❌ |
| **Project** | `project.update` | Update project metadata | ✅ | ✅ | ✅ (Assigned) | ❌ |
| **Project** | `project.delete` | Delete project record | ✅ | ✅ | ❌ | ❌ |
| **Workforce** | `employee.view` | View employee directory | ✅ | ✅ | ✅ | ❌ (Own only) |
| **Workforce** | `employee.create` | Add new employee | ✅ | ✅ | ✅ | ❌ |
| **Workforce** | `employee.update` | Edit employee / rates | ✅ | ✅ | ✅ | ❌ |
| **Attendance**| `attendance.view` | View attendance records | ✅ | ✅ | ✅ (Assigned) | ❌ (Own only) |
| **Attendance**| `attendance.create`| Mark attendance muster | ✅ | ✅ | ✅ | ✅ (Own checkin) |
| **Financials** | `expense.view` | View expense vouchers | ✅ | ✅ | ✅ (Assigned) | ❌ (0 rows) |
| **Financials** | `expense.create` | Submit expense voucher | ✅ | ✅ | ✅ (Assigned) | ❌ |
| **Financials** | `billing.view` | View vendor & sales bills | ✅ | ✅ | ❌ (0 rows) | ❌ (0 rows) |
| **Financials** | `billing.create` | Issue client invoices | ✅ | ✅ | ❌ | ❌ |
| **Inventory** | `inventory.view` | View material stock | ✅ | ✅ | ✅ | ✅ (Read-only) |
| **Inventory** | `inventory.mutate` | Add / update stock items | ✅ | ✅ | ✅ | ❌ |
| **Equipment** | `equipment.view` | View machinery fleet | ✅ | ✅ | ✅ | ❌ (0 rows) |
| **Settings** | `settings.manage`| Manage system settings | ✅ | ❌ | ❌ | ❌ |
| **Users** | `users.manage` | Manage user credentials | ✅ | ❌ | ❌ | ❌ |

---

## 5. Flutter Client Architecture

### Providers (`lib/features/rbac/presentation/providers/permission_provider.dart`)

```dart
// Resolves active user role with multi-layer fallback
final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final repo = ref.watch(roleRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return repo.fetchUserRole(userId);
});

// Fast boolean role helpers
final isAdminProvider = Provider<bool>((ref) => ref.watch(userRoleProvider).value?.roleName == 'admin');
final isOwnerProvider = Provider<bool>((ref) => ref.watch(userRoleProvider).value?.roleName == 'owner');
final isSupervisorProvider = Provider<bool>((ref) => ref.watch(userRoleProvider).value?.roleName == 'supervisor');
final isEmployeeProvider = Provider<bool>((ref) => ref.watch(userRoleProvider).value?.roleName == 'employee');
```

### UI Guards & Components

**`PermissionGuard`** — Selectively renders widgets based on permission keys:
```dart
PermissionGuard(
  permission: 'billing.create',
  child: ElevatedButton(onPressed: _openInvoiceModal, child: Text('New Invoice')),
)
```

---

## 6. How to Assign Roles to Users

To assign a role to a user in Supabase:
```sql
-- Example: Assigning 'supervisor' role to a user using native UUID lookup
INSERT INTO public.user_roles (user_id, role_id)
VALUES (
  'USER-UUID-HERE',
  (SELECT id FROM public.roles WHERE name = 'supervisor' LIMIT 1)
)
ON CONFLICT (user_id, role_id) DO NOTHING;
```
The database trigger automatically updates `profiles.role_display` and auth metadata, instantly granting the user their scoped permissions.
