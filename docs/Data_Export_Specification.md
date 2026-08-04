# Data Export Specification (PDF & Excel .xlsx)

This document defines the schema standards, column structures, and export behaviors for generating downloadable **PDF documents** and **Excel (.xlsx) spreadsheets** across all modules in IBUILD ERP.

---

## 1. Export Design Principles

1. **Dual Format Requirement**: Every list screen, detail screen, and audit view must support both PDF (`.pdf`) and Excel (`.xlsx`) downloads.
2. **Cross-Platform Compatibility**: Downloads work seamlessly on Web (direct browser trigger via Blob/Anchor) and Mobile/Desktop (native file share/save dialogs).
3. **Consistent Styling**:
   - **Excel (.xlsx)**: Styled headers with navy fill (`#1E3A8A`), bold white text, cell borders, auto-adjusted column widths, and bottom summary rows for numeric totals.
   - **PDF (.pdf)**: Formal header badge ("IBUILD CONSTRUCTIONS"), report metadata (scope, date, filter criteria), structured tabular layout, and signature/footer sections.
4. **Localization & Formatting**:
   - Currency: Displayed as `INR X,XX,XXX.XX` or numeric values without glyph errors.
   - Dates: Formatted as `YYYY-MM-DD`.

---

## 2. Module Export Schemas

### A. Financial & Billing Modules

#### 1. Sales Bills
- **Excel Sheet**: `Sales_Bills`
- **Columns**: `Bill Number`, `Client Name`, `Project Name`, `Bill Date`, `Due Date`, `Subtotal (INR)`, `Tax Amount (INR)`, `Total Amount (INR)`, `Status`

#### 2. Client & Contractor Billing
- **Excel Sheet**: `Billing_Summary`
- **Columns**: `Invoice Number`, `Party Name`, `Type`, `Date`, `Total Amount (INR)`, `Paid Amount (INR)`, `Balance Due (INR)`, `Status`

#### 3. Quotations
- **Excel Sheet**: `Quotations`
- **Columns**: `Quote Number`, `Client Name`, `Project Name`, `Date`, `Valid Until`, `Total Amount (INR)`, `Status`

#### 4. Expenses
- **Excel Sheet**: `Site_Expenses`
- **Columns**: `ID`, `Expense Date`, `Category`, `Amount (INR)`, `Payment Mode`, `Project Site`, `Recorded By`, `Notes`

#### 5. Payment Ledger
- **Excel Sheet**: `Payment_Ledger`
- **Columns**: `Transaction ID`, `Date`, `Party Name`, `Type`, `Amount (INR)`, `Payment Mode`, `Reference No`, `Notes`

---

### B. Workforce & Operations Modules

#### 6. Employees Directory
- **Excel Sheet**: `Employees`
- **Columns**: `Employee ID`, `Name`, `Role / Designation`, `Phone`, `Daily Wage / Salary (INR)`, `Status`

#### 7. Attendance Logs
- **Excel Sheet**: `Attendance_Logs`
- **Columns**: `Log Date`, `Employee Name`, `Project Site`, `Morning Shift`, `Evening Shift`, `Total Shift Count`, `Daily Wage (INR)`

#### 8. Projects Portfolio
- **Excel Sheet**: `Projects`
- **Columns**: `Project Code`, `Project Name`, `Location`, `Start Date`, `Target Date`, `Allocated Budget (INR)`, `Total Outflow (INR)`, `Progress %`, `Status`

#### 9. Daily Progress Reports
- **Excel Sheet**: `Daily_Progress`
- **Columns**: `Date`, `Project Site`, `Supervisor`, `Work Summary`, `Worker Count`, `Weather Conditions`, `Key Issues`

---

### C. Site Resources & Inventory

#### 10. Material Inventory
- **Excel Sheet**: `Inventory_Stock`
- **Columns**: `Item Code`, `Material Name`, `Category`, `Available Stock`, `Unit`, `Purchase Price (INR)`, `Total Valuation (INR)`, `Low Stock Alert`

#### 11. Subcontractors
- **Excel Sheet**: `Subcontractors`
- **Columns**: `Subcontractor Name`, `Trade / Work Type`, `Contact Person`, `Phone`, `Contract Value (INR)`, `Amount Paid (INR)`, `Status`

#### 12. Vendors Directory
- **Excel Sheet**: `Vendors`
- **Columns**: `Vendor Name`, `Category / Supplies`, `Contact Person`, `Phone`, `GSTIN`, `Outstanding Payable (INR)`

#### 13. Equipment & Machinery
- **Excel Sheet**: `Equipment`
- **Columns**: `Asset ID`, `Equipment Name`, `Category`, `Serial Number`, `Assigned Site`, `Hourly Rate (INR)`, `Status`

---

### D. Quality, Compliance & Miscellaneous

#### 14. Checklists & Inspections
- **Excel Sheet**: `Site_Checklists`
- **Columns**: `Checklist ID`, `Title`, `Project Site`, `Inspector`, `Inspection Date`, `Total Items`, `Passed Items`, `Status`

#### 15. Property Units
- **Excel Sheet**: `Properties`
- **Columns**: `Property ID`, `Property Name`, `Unit Number`, `Type`, `Area (Sq Ft)`, `Price (INR)`, `Status`

#### 16. Support & Site Tickets
- **Excel Sheet**: `Tickets`
- **Columns**: `Ticket ID`, `Title`, `Priority`, `Category`, `Project Site`, `Assigned To`, `Created Date`, `Status`

#### 17. Drawings & Blueprints
- **Excel Sheet**: `Drawings`
- **Columns**: `Drawing ID`, `Title`, `Discipline`, `Version`, `Project Site`, `Upload Date`, `Status`

#### 18. Site Activities Log
- **Excel Sheet**: `Activities`
- **Columns**: `Activity ID`, `Timestamp`, `User`, `Module`, `Description`, `Project Site`

---

## 3. Implementation Stack & Shared Helpers

- **PDF Engine**: `pdf` and `printing` packages (`pw.Document`, `pw.Table`).
- **Excel Engine**: `excel` package (`Excel.createExcel()`, `Sheet.appendRow()`, `CellStyle`).
- **Download Helper**: Cross-platform Web/Mobile `ExcelDownloadHelper` and `PdfDownloadHelper`.
