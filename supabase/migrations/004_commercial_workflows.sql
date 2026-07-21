-- ============================================================
-- MIGRATION 004: COMMERCIAL WORKFLOWS SUITE
-- Adds Extended Supplier/Vendor, Trade Partner/Subcontractor,
-- Sales Bill Items, Payment Ledger, and Property/Agent tables.
-- ============================================================

-- 1. EXTEND VENDORS / SUPPLIERS TABLE
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS total_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS paid_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false;

-- 2. EXTEND SUBCONTRACTORS / TRADE PARTNERS TABLE
ALTER TABLE subcontractors ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE subcontractors ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE subcontractors ADD COLUMN IF NOT EXISTS gst_number VARCHAR(30);
ALTER TABLE subcontractors ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false;

-- 3. SALES BILL ITEMS TABLE
CREATE TABLE IF NOT EXISTS sales_bill_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sales_bill_id UUID NOT NULL REFERENCES sales_bills(id) ON DELETE CASCADE,
    particular TEXT NOT NULL,
    unit VARCHAR(20) DEFAULT 'Pcs',
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1.0,
    unit_price DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_price DECIMAL(15, 2) NOT NULL DEFAULT 0.00
);

-- Index for sales_bill_id
CREATE INDEX IF NOT EXISTS idx_sales_bill_items_bill_id ON sales_bill_items(sales_bill_id);

-- 4. UNIFIED PAYMENT LEDGER TABLE
CREATE TABLE IF NOT EXISTS payment_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    counterparty_type VARCHAR(50) NOT NULL CHECK (counterparty_type IN ('Supplier', 'Trade Partner', 'Client', 'Other')),
    counterparty_id UUID,
    counterparty_name VARCHAR(255) NOT NULL,
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('Paid', 'Received')),
    amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) DEFAULT 'Bank Transfer',
    payment_date DATE DEFAULT CURRENT_DATE,
    running_balance DECIMAL(15, 2) DEFAULT 0.00,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for project_id, date, and counterparty
CREATE INDEX IF NOT EXISTS idx_payment_ledger_project ON payment_ledger(project_id);
CREATE INDEX IF NOT EXISTS idx_payment_ledger_date ON payment_ledger(payment_date);

-- 5. OPTIONAL PROPERTIES AND REAL ESTATE AGENTS TABLES
CREATE TABLE IF NOT EXISTS properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_name VARCHAR(255) NOT NULL,
    location TEXT NOT NULL,
    property_type VARCHAR(100) DEFAULT 'Residential Plot',
    amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    remarks TEXT,
    image_url TEXT,
    agent_name VARCHAR(255),
    agent_company VARCHAR(255),
    agent_mobile VARCHAR(20),
    status VARCHAR(50) DEFAULT 'Available' CHECK (status IN ('Available', 'Under Agreement', 'Sold')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS policies
ALTER TABLE sales_bill_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated read sales_bill_items" ON sales_bill_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated write sales_bill_items" ON sales_bill_items FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated read payment_ledger" ON payment_ledger FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated write payment_ledger" ON payment_ledger FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated read properties" ON properties FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated write properties" ON properties FOR ALL TO authenticated USING (true);
