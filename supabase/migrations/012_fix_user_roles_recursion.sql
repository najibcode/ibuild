-- Migration 012: Fix infinite recursion in user_roles RLS policies

-- Drop the recursive policies
DROP POLICY IF EXISTS "Admins can manage all user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Users can read own role" ON public.user_roles;
DROP POLICY IF EXISTS "Users can insert own role" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can read user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can insert own role" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can update user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Authenticated users can delete user_roles" ON public.user_roles;

-- 1. Non-recursive read policy: authenticated users can read role associations
CREATE POLICY "Authenticated users can read user_roles"
    ON public.user_roles FOR SELECT
    TO authenticated
    USING (true);

-- 2. Non-recursive insert policy
CREATE POLICY "Authenticated users can insert user_roles"
    ON public.user_roles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);

-- 3. Non-recursive update policy
CREATE POLICY "Authenticated users can update user_roles"
    ON public.user_roles FOR UPDATE
    TO authenticated
    USING (auth.uid() IS NOT NULL);

-- 4. Non-recursive delete policy
CREATE POLICY "Authenticated users can delete user_roles"
    ON public.user_roles FOR DELETE
    TO authenticated
    USING (auth.uid() IS NOT NULL);
