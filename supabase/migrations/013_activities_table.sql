-- Migration 013: Activities & System Notifications Table

CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    action_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activities_created_at ON public.activities (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activities_action_type ON public.activities (action_type);
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities (user_id);

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read activities" ON public.activities;
CREATE POLICY "Authenticated users can read activities"
    ON public.activities FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert activities" ON public.activities;
CREATE POLICY "Authenticated users can insert activities"
    ON public.activities FOR INSERT
    TO authenticated
    WITH CHECK (true);
