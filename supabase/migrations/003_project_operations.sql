-- ============================================================
-- MIGRATION 003: PROJECT OPERATIONAL WORKFLOWS (POJO INFRA360 EQUIVALENT)
-- Adds Extended Site Properties, Checklists, Sales Bills, and Payments
-- ============================================================

-- 1. EXTEND PROJECTS TABLE
ALTER TABLE projects ADD COLUMN IF NOT EXISTS built_up_area DECIMAL(15, 2) DEFAULT 0.00;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS flat_area DECIMAL(15, 2) DEFAULT 0.00;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS duration VARCHAR(100);
ALTER TABLE projects ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255);
ALTER TABLE projects ADD COLUMN IF NOT EXISTS customer_mobile VARCHAR(20);
ALTER TABLE projects ADD COLUMN IF NOT EXISTS customer_email VARCHAR(255);
ALTER TABLE projects ADD COLUMN IF NOT EXISTS customer_dob DATE;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS customer_address TEXT;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. PROJECT CHECKLISTS TABLE
CREATE TABLE IF NOT EXISTS project_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'General Inspection',
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for project_id
CREATE INDEX IF NOT EXISTS idx_project_checklists_project_id ON project_checklists(project_id);

-- 3. SALES BILLS TABLE
CREATE TABLE IF NOT EXISTS sales_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    bill_number VARCHAR(50) UNIQUE NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(15, 2) DEFAULT 0.00,
    total_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'Unpaid' CHECK (status IN ('Paid', 'Unpaid', 'Partially Paid', 'Overdue')),
    due_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for project_id & date
CREATE INDEX IF NOT EXISTS idx_sales_bills_project_id ON sales_bills(project_id);
CREATE INDEX IF NOT EXISTS idx_sales_bills_due_date ON sales_bills(due_date);

-- 4. PROJECT PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS project_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    payment_type VARCHAR(20) DEFAULT 'Received' CHECK (payment_type IN ('Received', 'Paid')),
    amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) DEFAULT 'Bank Transfer',
    reference_no VARCHAR(100),
    payment_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for project_id & date
CREATE INDEX IF NOT EXISTS idx_project_payments_project_id ON project_payments(project_id);
CREATE INDEX IF NOT EXISTS idx_project_payments_date ON project_payments(payment_date);

-- 5. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE project_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_payments ENABLE ROW LEVEL SECURITY;

-- 6. AUTHENTICATED USER POLICIES
CREATE POLICY "Authenticated users read project_checklists" ON project_checklists FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users write project_checklists" ON project_checklists FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated users read sales_bills" ON sales_bills FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users write sales_bills" ON sales_bills FOR ALL TO authenticated USING (true);

CREATE POLICY "Authenticated users read project_payments" ON project_payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users write project_payments" ON project_payments FOR ALL TO authenticated USING (true);
