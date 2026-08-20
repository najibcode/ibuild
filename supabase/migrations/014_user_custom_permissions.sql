-- Migration 014: Add custom_permissions JSONB array to profiles table

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS custom_permissions JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role_display TEXT DEFAULT 'employee';

-- Comment on column
COMMENT ON COLUMN public.profiles.custom_permissions IS 'List of granted ERP operational function permission keys for the user';
