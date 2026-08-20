-- ============================================================
-- MIGRATION 015: ADD AVATAR_URL & PROFILE METADATA COLUMNS
-- ============================================================

-- 1. Add avatar_url and ensure other admin columns exist on public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role_display TEXT DEFAULT 'employee';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS custom_permissions JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS company_name TEXT DEFAULT 'IBUILD';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 2. Ensure RLS policies allow profiles management by authenticated users and admins
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read all profiles" ON public.profiles;
CREATE POLICY "Authenticated users can read all profiles"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert profiles" ON public.profiles;
CREATE POLICY "Authenticated users can insert profiles"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update own or admin profiles" ON public.profiles;
CREATE POLICY "Authenticated users can update own or admin profiles"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 3. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
