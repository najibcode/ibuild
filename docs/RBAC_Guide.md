# IBUILD ERP — Role-Based Access Control (RBAC) Guide

## Overview

IBUILD ERP implements a database-driven RBAC system with three roles: **Admin**, **Owner**, and **Supervisor**. Permissions are stored in Supabase and cached in-app after login via Riverpod providers.

---

## Roles

### Admin
- Technical administrator with full system access
- Can manage users, settings, database backups, and view system logs
- **Cannot**: Change company ownership or permanently delete financial history

### Owner
- Business owner with complete business visibility
- Can view/create/delete all projects, employees, billing, expenses, reports
- **Cannot**: Access system settings, backend configuration, or developer tools

### Supervisor
- Site supervisor managing daily construction operations
- Can view/edit all projects, mark attendance, manage inventory, submit expenses, create daily progress reports
- **Cannot**: Delete employees or projects, access billing, access settings, manage users

---

## Permission Keys

| Module | Permission Key | Description |
|---|---|---|
| Dashboard | `dashboard.view` | View dashboard |
| Project | `project.view` | View projects |
| Project | `project.create` | Create projects |
| Project | `project.update` | Update projects |
| Project | `project.delete` | Delete projects |
| Employee | `employee.view` | View employees |
| Employee | `employee.create` | Create employees |
| Employee | `employee.update` | Update employees |
| Employee | `employee.delete` | Delete employees |
| Attendance | `attendance.view` | View attendance |
| Attendance | `attendance.create` | Mark attendance |
| Attendance | `attendance.update` | Update attendance |
| Inventory | `inventory.view` | View inventory |
| Inventory | `inventory.create` | Add inventory items |
| Inventory | `inventory.update` | Update inventory items |
| Inventory | `inventory.delete` | Delete inventory items |
| Billing | `billing.view` | View bills |
| Billing | `billing.create` | Create bills |
| Billing | `billing.update` | Update bills |
| Billing | `billing.delete` | Delete bills |
| Expense | `expense.view` | View expenses |
| Expense | `expense.create` | Create expenses |
| Expense | `expense.update` | Update expenses |
| Expense | `expense.delete` | Delete expenses |
| Reports | `reports.view` | View reports |
| Reports | `reports.export` | Export reports |
| Daily Progress | `daily_progress.view` | View daily progress |
| Daily Progress | `daily_progress.create` | Create daily progress |
| Daily Progress | `daily_progress.update` | Update daily progress |
| Settings | `settings.manage` | Manage application settings |
| Users | `users.manage` | Manage users |
| Roles | `roles.manage` | Manage roles and permissions |
| System | `system.manage` | Manage system configuration |

---

## Database Tables

### `roles`
| Column | Type | Description |
|---|---|---|
| id | UUID PK | Auto-generated |
| name | VARCHAR(50) UNIQUE | admin, owner, supervisor |
| description | TEXT | Role description |
| created_at | TIMESTAMPTZ | Creation timestamp |

### `permissions`
| Column | Type | Description |
|---|---|---|
| id | UUID PK | Auto-generated |
| key | VARCHAR(100) UNIQUE | e.g. `employee.create` |
| description | TEXT | Human-readable description |
| module | VARCHAR(50) | Module group (employee, project, etc.) |
| created_at | TIMESTAMPTZ | Creation timestamp |

### `role_permissions`
| Column | Type | Description |
|---|---|---|
| id | UUID PK | Auto-generated |
| role_id | UUID FK → roles | The role |
| permission_id | UUID FK → permissions | The permission |
| UNIQUE(role_id, permission_id) | | No duplicates |

### `user_roles`
| Column | Type | Description |
|---|---|---|
| id | UUID PK | Auto-generated |
| user_id | UUID FK → auth.users | The user |
| role_id | UUID FK → roles | The assigned role |
| UNIQUE(user_id) | | One role per user |

---

## Flutter Architecture

### Providers (lib/features/rbac/presentation/providers/permission_provider.dart)

```dart
// Fetch user's role once after login
final userRoleProvider = FutureProvider<UserRole?>(...);

// Fetch all permission keys for the role
final userPermissionsProvider = FutureProvider<Set<String>>(...);

// Fast synchronous permission check
final hasPermissionProvider = Provider.family<bool, String>(...);

// Current role name string
final currentRoleProvider = Provider<String>(...);

// Boolean helpers
final isAdminProvider = Provider<bool>(...);
final isOwnerProvider = Provider<bool>(...);
final isSupervisorProvider = Provider<bool>(...);
```

### Widgets

**PermissionGuard** — Wraps any widget, shows it only if user has permission:
```dart
PermissionGuard(
  permission: 'employee.delete',
  child: IconButton(onPressed: _delete, icon: Icon(Icons.delete)),
)
```

**PermissionButton** — Permission-aware ElevatedButton:
```dart
PermissionButton(
  permission: 'project.create',
  onPressed: _createProject,
  child: Text('New Project'),
)
```

---

## Adding a New Role

1. Insert into `roles` table in Supabase
2. Insert into `role_permissions` for each permission the role should have
3. No Flutter code changes needed — the app reads roles and permissions from the database

## Assigning a Role to a User

```sql
INSERT INTO user_roles (user_id, role_id)
SELECT 'USER_UUID', id FROM roles WHERE name = 'owner';
```

---

## Setup

1. Run `supabase/migrations/001_rbac_tables.sql` in your Supabase SQL Editor
2. The migration auto-assigns the `admin` role to `admin@ibuild.in`
3. For new users, insert into `user_roles` with the desired role
