-- ============================================================
-- IBUILD ERP — RBAC Migration
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. Roles table
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) UNIQUE NOT NULL,   -- e.g. 'employee.create'
    description TEXT,
    module VARCHAR(50) NOT NULL,        -- e.g. 'employee', 'project'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Role-Permission mapping (many-to-many)
CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE NOT NULL,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(role_id, permission_id)
);

-- 4. User-Role mapping
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id)  -- Each user has exactly one role
);

-- ============================================================
-- SEED DATA: Roles
-- ============================================================

INSERT INTO roles (name, description) VALUES
    ('admin', 'Technical administrator with full system access'),
    ('owner', 'Business owner with full business access'),
    ('supervisor', 'Site supervisor managing day-to-day operations')
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- SEED DATA: Permissions
-- ============================================================

INSERT INTO permissions (key, description, module) VALUES
    -- Dashboard
    ('dashboard.view', 'View dashboard', 'dashboard'),
    -- Projects
    ('project.view', 'View projects', 'project'),
    ('project.create', 'Create projects', 'project'),
    ('project.update', 'Update projects', 'project'),
    ('project.delete', 'Delete projects', 'project'),
    -- Employees
    ('employee.view', 'View employees', 'employee'),
    ('employee.create', 'Create employees', 'employee'),
    ('employee.update', 'Update employees', 'employee'),
    ('employee.delete', 'Delete employees', 'employee'),
    -- Attendance
    ('attendance.view', 'View attendance', 'attendance'),
    ('attendance.create', 'Mark attendance', 'attendance'),
    ('attendance.update', 'Update attendance', 'attendance'),
    -- Inventory
    ('inventory.view', 'View inventory', 'inventory'),
    ('inventory.create', 'Add inventory items', 'inventory'),
    ('inventory.update', 'Update inventory items', 'inventory'),
    ('inventory.delete', 'Delete inventory items', 'inventory'),
    -- Billing
    ('billing.view', 'View bills', 'billing'),
    ('billing.create', 'Create bills', 'billing'),
    ('billing.update', 'Update bills', 'billing'),
    ('billing.delete', 'Delete bills', 'billing'),
    -- Expenses
    ('expense.view', 'View expenses', 'expense'),
    ('expense.create', 'Create expenses', 'expense'),
    ('expense.update', 'Update expenses', 'expense'),
    ('expense.delete', 'Delete expenses', 'expense'),
    -- Reports
    ('reports.view', 'View reports', 'reports'),
    ('reports.export', 'Export reports', 'reports'),
    -- Daily Progress
    ('daily_progress.view', 'View daily progress', 'daily_progress'),
    ('daily_progress.create', 'Create daily progress', 'daily_progress'),
    ('daily_progress.update', 'Update daily progress', 'daily_progress'),
    -- System / Settings
    ('settings.manage', 'Manage application settings', 'settings'),
    ('users.manage', 'Manage users', 'users'),
    ('roles.manage', 'Manage roles and permissions', 'roles'),
    ('system.manage', 'Manage system configuration', 'system')
ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- SEED DATA: Role-Permission Assignments
-- ============================================================

-- Helper: Admin gets ALL permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Helper: Owner gets everything EXCEPT settings/users/roles/system
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'owner'
  AND p.key NOT IN ('settings.manage', 'users.manage', 'roles.manage', 'system.manage')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Helper: Supervisor gets limited permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'supervisor'
  AND p.key IN (
    'dashboard.view',
    'project.view',
    'project.update',
    'employee.view',
    'attendance.view',
    'attendance.create',
    'attendance.update',
    'inventory.view',
    'inventory.create',
    'inventory.update',
    'expense.view',
    'expense.create',
    'reports.view',
    'daily_progress.view',
    'daily_progress.create',
    'daily_progress.update'
  )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ============================================================
-- SEED DATA: Assign admin role to existing admin user
-- (uses the email from auth.users to find the user)
-- ============================================================

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM auth.users u, roles r
WHERE u.email = 'admin@ibuild.in'
  AND r.name = 'admin'
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================
-- ROW LEVEL SECURITY (RLS) — basic policies
-- ============================================================

-- Enable RLS on RBAC tables
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read roles/permissions (needed for the app to load them)
CREATE POLICY "Authenticated users can read roles"
    ON roles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can read permissions"
    ON permissions FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can read role_permissions"
    ON role_permissions FOR SELECT
    TO authenticated
    USING (true);

-- Users can read their own user_roles entry
CREATE POLICY "Users can read own role"
    ON user_roles FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Users can insert their own role entry
CREATE POLICY "Users can insert own role"
    ON user_roles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Admins can manage user_roles (for user management)
CREATE POLICY "Admins can manage all user_roles"
    ON user_roles FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = auth.uid() AND r.name = 'admin'
        )
    );
