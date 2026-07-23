-- Migration 006: Daily Progress Evidence & Before/After Media Schema
-- Ensures daily_progress table has full support for before & after evidence photos, work notes, and site completion tracking.

CREATE TABLE IF NOT EXISTS public.daily_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    morning_image_url TEXT,
    morning_notes TEXT,
    evening_image_url TEXT,
    evening_notes TEXT,
    image_url TEXT,
    notes TEXT,
    progress_percentage INT DEFAULT 0,
    supervisor_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_project_date UNIQUE(project_id, date)
);

-- Safely alter table to add columns if table was created in earlier schema
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS morning_image_url TEXT;
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS morning_notes TEXT;
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS evening_image_url TEXT;
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS evening_notes TEXT;
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS progress_percentage INT DEFAULT 0;
ALTER TABLE public.daily_progress ADD COLUMN IF NOT EXISTS supervisor_id UUID;

-- RLS Policies
ALTER TABLE public.daily_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read daily_progress" ON public.daily_progress
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated insert/update daily_progress" ON public.daily_progress
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
