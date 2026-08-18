-- 011_drawings_storage_and_categories.sql
-- Ensure site_drawings category check constraint supports all construction drawing categories and mapping

ALTER TABLE site_drawings DROP CONSTRAINT IF EXISTS site_drawings_category_check;

ALTER TABLE site_drawings ADD CONSTRAINT site_drawings_category_check 
CHECK (category IN (
    'Floor Plans & Mapping',
    'Architectural',
    'Structural',
    'Electrical',
    'Plumbing',
    'HVAC',
    'Site Photos & Progress',
    'Other'
));

-- Ensure storage buckets exist for site drawings and blueprints
INSERT INTO storage.buckets (id, name, public)
VALUES ('site-drawings', 'site-drawings', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('drawings', 'drawings', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for public reading and authenticated uploading
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Public Read Site Drawings'
    ) THEN
        CREATE POLICY "Public Read Site Drawings" ON storage.objects
        FOR SELECT USING (bucket_id IN ('site-drawings', 'drawings', 'site-progress'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated Upload Site Drawings'
    ) THEN
        CREATE POLICY "Authenticated Upload Site Drawings" ON storage.objects
        FOR INSERT TO authenticated WITH CHECK (bucket_id IN ('site-drawings', 'drawings', 'site-progress'));
    END IF;
END $$;
