-- ============================================================
-- MIGRATION 002: POJO INFRA360 PRODUCTION FEATURES
-- Adds Quotations, Vendors, Subcontractors, Site Tickets, and Drawings
-- ============================================================

-- 1. QUOTATIONS / BOQ TABLE
CREATE TABLE IF NOT EXISTS quotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    quotation_number VARCHAR(50) UNIQUE NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    client_phone VARCHAR(20),
    total_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(15, 2) DEFAULT 0.00,
    grand_total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'Draft' CHECK (status IN ('Draft', 'Sent', 'Approved', 'Rejected')),
    valid_until DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Quotation Line Items
CREATE TABLE IF NOT EXISTS quotation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quotation_id UUID REFERENCES quotations(id) ON DELETE CASCADE,
    item_description TEXT NOT NULL,
    unit VARCHAR(20) NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1.0,
    unit_price DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_price DECIMAL(15, 2) NOT NULL DEFAULT 0.00
);

-- 2. VENDORS & SUPPLIERS TABLE
CREATE TABLE IF NOT EXISTS vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(255),
    gst_number VARCHAR(30),
    address TEXT,
    category VARCHAR(100), -- e.g. Cement, Steel, Electrical, Plumbing
    balance_due DECIMAL(15, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vendor Transactions / Ledger
CREATE TABLE IF NOT EXISTS vendor_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('Purchase', 'Payment', 'Return')),
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT,
    reference_number VARCHAR(100),
    transaction_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SUBCONTRACTORS TABLE
CREATE TABLE IF NOT EXISTS subcontractors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    specialization VARCHAR(100), -- e.g. Civil, Electrical, Plumbing, Painting
    phone VARCHAR(20),
    contract_value DECIMAL(15, 2) DEFAULT 0.00,
    paid_amount DECIMAL(15, 2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Completed', 'Terminated')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. SITE TICKETS / ISSUES TABLE
CREATE TABLE IF NOT EXISTS site_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority VARCHAR(20) DEFAULT 'Medium' CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
    reported_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. SITE DRAWINGS & BLUEPRINTS TABLE
CREATE TABLE IF NOT EXISTS site_drawings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) CHECK (category IN ('Architectural', 'Structural', 'Electrical', 'Plumbing', 'HVAC', 'Other')),
    version VARCHAR(20) DEFAULT 'v1.0',
    file_url TEXT NOT NULL,
    notes TEXT,
    uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on new tables
ALTER TABLE quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcontractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_drawings ENABLE ROW LEVEL SECURITY;

-- Select policies for authenticated users
CREATE POLICY "Authenticated read quotations" ON quotations FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read quotation_items" ON quotation_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read vendors" ON vendors FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read vendor_transactions" ON vendor_transactions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read subcontractors" ON subcontractors FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read site_tickets" ON site_tickets FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read site_drawings" ON site_drawings FOR SELECT TO authenticated USING (true);

-- Insert/Update policies for authenticated users
CREATE POLICY "Authenticated write quotations" ON quotations FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated write quotation_items" ON quotation_items FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated write vendors" ON vendors FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated write vendor_transactions" ON vendor_transactions FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated write subcontractors" ON subcontractors FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated write site_tickets" ON site_tickets FOR ALL TO authenticated USING (true);
CREATE POLICY "Authenticated write site_drawings" ON site_drawings FOR ALL TO authenticated USING (true);
