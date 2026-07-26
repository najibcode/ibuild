-- ============================================================
-- MIGRATION 007: MACHINERY & HEAVY EQUIPMENT FLEET
-- Table for machinery fleet management, site allocations, fuel burn, and rental rates
-- ============================================================

CREATE TABLE IF NOT EXISTS equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'General',
    tag_number VARCHAR(50) NOT NULL,
    site_name VARCHAR(255) DEFAULT 'Main Site',
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'Operational' CHECK (status IN ('Operational', 'In Use', 'Maintenance', 'Idle')),
    rental_cost_per_day DECIMAL(15, 2) DEFAULT 0.00,
    fuel_consumption_liters_per_day DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;

-- Policies for authenticated users
CREATE POLICY "Authenticated read equipment" ON equipment FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated write equipment" ON equipment FOR ALL TO authenticated USING (true);
