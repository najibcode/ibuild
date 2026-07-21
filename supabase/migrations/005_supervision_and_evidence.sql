-- ============================================================
-- MIGRATION 005: SUPERVISION, COMMUNICATION THREADS & EVIDENCE SUITE
-- Adds Ticket Conversation Messages, Phase-Grouped Evidence Checklists,
-- Drawing Archiving, and System Settings for Feature Visibility.
-- ============================================================

-- 1. TICKET CONVERSATION MESSAGES TABLE
CREATE TABLE IF NOT EXISTS ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES site_tickets(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    sender_name VARCHAR(255) NOT NULL,
    sender_role VARCHAR(50) NOT NULL CHECK (sender_role IN ('admin', 'supervisor', 'client', 'other')),
    message_text TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for ticket_id
CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket ON ticket_messages(ticket_id);

-- 2. EXTEND PROJECT CHECKLISTS TABLE FOR PHASES AND EVIDENCE
ALTER TABLE project_checklists ADD COLUMN IF NOT EXISTS phase_group VARCHAR(100) DEFAULT 'Foundation';
ALTER TABLE project_checklists ADD COLUMN IF NOT EXISTS due_date DATE;
ALTER TABLE project_checklists ADD COLUMN IF NOT EXISTS assigned_person VARCHAR(255);
ALTER TABLE project_checklists ADD COLUMN IF NOT EXISTS evidence_image_url TEXT;
ALTER TABLE project_checklists ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE project_checklists ADD COLUMN IF NOT EXISTS approval_status VARCHAR(50) DEFAULT 'Not Started' 
    CHECK (approval_status IN ('Not Started', 'In Progress', 'Submitted', 'Approved', 'Rejected', 'Blocked'));

-- 3. EXTEND SITE DRAWINGS TABLE FOR ARCHIVING AND FILE SIZES
ALTER TABLE site_drawings ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE site_drawings ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT DEFAULT 0;

-- 4. SYSTEM SETTINGS TABLE FOR ADMIN FEATURE VISIBILITY CONFIGURATION
CREATE TABLE IF NOT EXISTS system_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS policies
ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated read ticket_messages" ON ticket_messages FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated write ticket_messages" ON ticket_messages FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated read system_settings" ON system_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated write system_settings" ON system_settings FOR ALL TO authenticated USING (true);
