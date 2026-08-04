-- Migration 009: ImageKit Metadata Table & Folder Mapping Schema
-- Stores metadata for all uploaded images to ImageKit without storing raw binary bytes.

CREATE TABLE IF NOT EXISTS public.app_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id TEXT NOT NULL,
    image_url TEXT NOT NULL,
    image_path TEXT NOT NULL,
    folder TEXT NOT NULL,
    uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
    inventory_id UUID,
    bill_id UUID
);

-- Indexing for fast lookups by module entity
CREATE INDEX IF NOT EXISTS idx_app_images_project ON public.app_images(project_id);
CREATE INDEX IF NOT EXISTS idx_app_images_employee ON public.app_images(employee_id);
CREATE INDEX IF NOT EXISTS idx_app_images_folder ON public.app_images(folder);

-- RLS Policies
ALTER TABLE public.app_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read app_images" ON public.app_images
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated write app_images" ON public.app_images
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
