-- Migration 008: Add tea_snack_allowance to employee table
-- Baseline daily tea and snacks budget per employee in INR (default ₹20.00)

ALTER TABLE employee 
ADD COLUMN IF NOT EXISTS tea_snack_allowance NUMERIC(10, 2) DEFAULT 20.00;

COMMENT ON COLUMN employee.tea_snack_allowance IS 'Daily tea and snacks expense budget per employee in INR';
