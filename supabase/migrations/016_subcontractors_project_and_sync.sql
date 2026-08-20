-- ============================================================
-- MIGRATION 016: SUBCONTRACTORS PROJECT LINKING & FINANCIAL SYNC
-- ============================================================

-- 1. Add project_id, site_name, contact_person, and scope_of_work columns to subcontractors table
ALTER TABLE public.subcontractors ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL;
ALTER TABLE public.subcontractors ADD COLUMN IF NOT EXISTS site_name TEXT;
ALTER TABLE public.subcontractors ADD COLUMN IF NOT EXISTS contact_person TEXT;
ALTER TABLE public.subcontractors ADD COLUMN IF NOT EXISTS scope_of_work TEXT;
ALTER TABLE public.subcontractors ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 2. Index for fast querying by project
CREATE INDEX IF NOT EXISTS idx_subcontractors_project_id ON public.subcontractors (project_id);

-- 3. Ensure RLS policies are permissive for authenticated users
ALTER TABLE public.subcontractors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read subcontractors" ON public.subcontractors;
CREATE POLICY "Authenticated read subcontractors"
    ON public.subcontractors FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Authenticated write subcontractors" ON public.subcontractors;
CREATE POLICY "Authenticated write subcontractors"
    ON public.subcontractors FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
