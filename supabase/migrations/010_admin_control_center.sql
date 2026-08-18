-- ============================================================
-- MIGRATION 010: ADMIN CONTROL CENTER & AUDIT LOGS
-- ============================================================

-- 1. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    actor_name VARCHAR(255),
    action VARCHAR(100) NOT NULL,           -- e.g. 'user.created', 'role.changed', 'user.disabled', 'password.reset', 'settings.updated'
    target_type VARCHAR(50) NOT NULL,       -- e.g. 'user', 'project', 'setting', 'role'
    target_id TEXT,                          -- UUID or identifier of affected entity
    details JSONB DEFAULT '{}'::jsonb,      -- Rich metadata and delta changes
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for timeline queries
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs (action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs (actor_id);

-- 2. EXTEND PROFILES TABLE FOR ADMIN MANAGEMENT
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role_display VARCHAR(50);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 3. SEED EMPLOYEE ROLE
INSERT INTO public.roles (name, description) VALUES
    ('employee', 'Regular field employee or worker with restricted operational view')
ON CONFLICT (name) DO NOTHING;

-- 4. RLS POLICIES FOR AUDIT LOGS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view audit logs (transparency for admins and authorized roles)
DROP POLICY IF EXISTS "Authenticated users can read audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated users can read audit logs"
    ON public.audit_logs FOR SELECT
    TO authenticated
    USING (true);

-- Allow authenticated users or service role to insert audit logs
DROP POLICY IF EXISTS "Authenticated users can insert audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated users can insert audit logs"
    ON public.audit_logs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- 5. ENSURE RLS FOR USER ROLES MANAGEMENT
DROP POLICY IF EXISTS "Admins can manage all user_roles" ON public.user_roles;
CREATE POLICY "Admins can manage all user_roles"
    ON public.user_roles FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            JOIN public.roles r ON ur.role_id = r.id
            WHERE ur.user_id = auth.uid() AND r.name = 'admin'
        )
        OR auth.uid() = user_id
    );
