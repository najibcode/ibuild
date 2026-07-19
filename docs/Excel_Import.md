# Excel & CSV Ingestion Specifications

This document defines the schemas, column expectations, validation criteria, import sequences, and rollback protocols for bulk-importing spreadsheets in Future Phases.

---

## 1. Import Sequences & Relational Dependencies

To maintain referential integrity in Supabase, imports must run in a strict dependency sequence:

```
[Level 1: Core Entities]  ──>  [Level 2: Projects & Employees]  ──>  [Level 3: Daily Logs & Finance]
       (Profiles)                 (Projects, Employees)             (Attendance, Inventory, 
                                                                     Expenses, Bills, Salaries)
```

1.  **Profiles**: Must exist first (supervisors, owners).
2.  **Projects / Employees**: Import secondary, referencing supervisor IDs.
3.  **Daily Logs / Financials**: Import last, linking to existing `project_id` or `employee_id` keys.

---

## 2. Spreadsheet Column Schemas

### A. Employee Directory Sheet
*   **Filename Suggestion**: `employees_import.xlsx`
*   **Columns**:

| Column Name | Data Type | Requirement | Validation Rules |
|-------------|-----------|-------------|------------------|
| `name` | String | Required | 3-100 characters, alphabet only. |
| `phone` | String | Required | Exactly 10 digits (digits only). Unique. |
| `role` | String | Required | Must match: `supervisor`, `labor`, `mason`. |
| `salary` | Decimal | Required | Non-negative numeric value. |
| `status` | String | Required | Must match: `active`, `suspended`, `terminated`. |

### B. Attendance Sheet
*   **Filename Suggestion**: `attendance_import.xlsx`
*   **Columns**:

| Column Name | Data Type | Requirement | Validation Rules |
|-------------|-----------|-------------|------------------|
| `employee_phone`| String | Required | Used to look up `employee_id`. |
| `date` | Date | Required | YYYY-MM-DD format. |
| `morning_status`| String | Required | `present`, `absent`, `half_day`. |
| `evening_status`| String | Required | `present`, `absent`, `half_day`. |

### C. Expenses Sheet
*   **Filename Suggestion**: `expenses_import.xlsx`
*   **Columns**:

| Column Name | Data Type | Requirement | Validation Rules |
|-------------|-----------|-------------|------------------|
| `project_code` | String | Optional | Match `project_code` to resolve `project_id`. |
| `expense_date` | Date | Required | YYYY-MM-DD format. |
| `category` | String | Required | Must match: `Labour`, `Materials`, `Transport`, etc. |
| `amount` | Decimal | Required | Greater than zero. |
| `payment_mode` | String | Required | Must match: `cash`, `bank`, `upi`, `cheque`. |
| `notes` | String | Optional | Max 500 characters. |

---

## 3. Mapping & Validation Engine Strategy

1.  **Pre-Import Parsing**: Convert spreadsheet rows to standard JSON structures.
2.  **Relational Lookup Resolution**:
    *   Find primary keys using unique natural keys (e.g. resolve `employee_id` using the employee's `phone` number; resolve `project_id` using `project_code`).
3.  **Row-Level Validations**: Run programmatic rules on each row object before writing to database.

---

## 4. Error Handling & Rollback Protocol

To avoid partial imports (e.g. importing 50 employee records but failing on row 51, leaving the database out of sync), imports use the **All-or-Nothing Transaction Pattern**:

```sql
BEGIN;

-- Run imports sequentially
-- 1. Insert employees
-- 2. Insert attendance logs

-- If any row fails validation:
ROLLBACK;
```

### User Feedback Flow
*   **Validation Dashboard**: If errors occur, the UI displays a list of rows that failed validation (e.g. "Row 14: Phone number is already registered").
*   **Partial Import Prevention**: The import fails completely, prompting the user to correct the highlighted errors in their spreadsheet and try again.
