<div align="center">

# 🏗️ IBUILD ERP

### **Enterprise Construction Management & Site Operations ERP**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%26%20Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Cloudflare Workers](https://img.shields.io/badge/Cloudflare_Workers-Edge_Deployment-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)](https://ibuild.najibcode.workers.dev/#/login)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod%202.x-0553B1?style=for-the-badge)](https://riverpod.dev)
[![Excel](https://img.shields.io/badge/Export-Multi--Sheet%20Excel-107C41?style=for-the-badge&logo=microsoftexcel&logoColor=white)](https://products.office.com/excel)
[![PDF](https://img.shields.io/badge/Reporting-Vector%20PDF%20Engine-EC1C24?style=for-the-badge&logo=adobeacrobatreader&logoColor=white)](https://pub.dev/packages/pdf)
[![Tests](https://img.shields.io/badge/Tests-120%20Passed-brightgreen?style=for-the-badge)]()
[![Security](https://img.shields.io/badge/RLS-Strict%20Enforced-success?style=for-the-badge)]()

*A robust, data-first Construction ERP built for business owners, project directors, site engineers, supervisors, and field workforce.*

[🌐 Live Web Application (Cloudflare Edge)](https://ibuild.najibcode.workers.dev/#/login) • [🗄️ Database Schemas & Migrations](docs/Database_Migrations.md) • [🛡️ RBAC & Security Guide](docs/RBAC_Guide.md)

---

</div>

## 📌 Executive Overview

**IBUILD ERP** is a full-featured, cross-platform construction management system designed to streamline real-time operations, workforce accountability, inventory logistics, quality control, and financial governance across construction project sites.

Built with **Flutter** (Web, Mobile, Desktop) and backed by **Supabase PostgreSQL with Strict Row-Level Security (RLS)**, IBUILD replaces manual paperwork, disjointed spreadsheets, and WhatsApp trails with an integrated, single source of truth.

---

## 🌟 Key Functional Modules

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                    IBUILD ERP SUITE                                    │
├──────────────────────┬──────────────────────┬───────────────────┬──────────────────────┤
│ 1. Project Portfolio │ 2. Workforce & Muster│ 3. Materials & SC │ 4. Financials & GST  │
├──────────────────────┼──────────────────────┼───────────────────┼──────────────────────┤
│ 5. Heavy Machinery   │ 6. Daily Logs (DPR)  │ 7. Quality Snags  │ 8. Audit Reports     │
└──────────────────────┴──────────────────────┴───────────────────┴──────────────────────┘
```

### 📊 1. Executive & Operational Dashboards
- **Role-Tailored Perspectives**: Dedicated interfaces for **Business Owners**, **Super Administrators**, **Site Supervisors**, and **Employees**.
- **Real-Time KPIs**: Live metrics tracking Active Projects, Workforce Present, Low-Stock Material Thresholds, and Expense Outflows.
- **Budget Utilization & Progress Gauge**: Dynamic visual tracking of allocated capital vs. actual spent against physical milestone completion.
- **Attention Required Engine**: Automated detection of low inventory, over-budget projects, and pending subcontractor retention.

---

### 🏗️ 2. Project Portfolio Management
- **Site Directory**: Comprehensive registry of commercial, residential, and infrastructure sites.
- **Budget & Cost Tracking**: Live budget variance tracking, physical progress metrics, and timeline baselines.
- **Submodule Operations Hub**: 8 itemized project operational submodules (Team, Materials, Machinery, Logs, Financials, Drawings, Snags, Reports).
- **Interactive Budget vs Actual**: Visual bar comparisons and overall health indices per site with atomic trigger-based updates.

---

### 👷 3. Attendance & Muster Roll
- **Workforce Registry**: Directory of engineers, foremen, masons, carpenters, plumbers, and general laborers.
- **Single-Day Attendance Capture**: Fast morning/evening check-in/check-out with status tracking (*Present*, *Half-Day*, *Absent*, *Overtime*).
- **Wage & Allowance Engine**: Automated calculation of base daily wages (`daily_rate` / `salary`) and tea/snacks daily allowance (default ₹20/day).
- **Historical Rate Snapshotting**: Attendance records snapshot `wage_rate` and `tea_allowance` at entry time, ensuring future increments never distort historical payroll records.
- **Database Uniqueness**: Strict `UNIQUE (employee_id, date)` database constraint prevents duplicate submissions under concurrent loads.

---

### 🧱 4. Materials & Supply Chain Management
- **Real-Time Stock Depots**: Track cement bags, structural steel (TMT), sand, gravel, and bricks.
- **Transaction Ledger**: Complete audit trail of stock movements (*RECEIVED*, *ISSUED*, *ADJUSTED*).
- **Low-Stock Automation**: Threshold-triggered alerts with automated reorder quantity recommendations.
- **Project-Linked Consumption**: Assign material dispatches directly to project sites to track material cost consumption.

---

### 💳 5. Financials & Billing Hub
- **Client Invoicing**: Build GST-compliant client invoices with itemized tax breakdowns (CGST + SGST or IGST).
- **Vendor & Supplier Bills**: Record purchasing vouchers, vendor invoices, and track outstanding payables.
- **Payment Ledger**: Real-time *Money In* / *Money Out* ledger with running account balance.
- **Statement of Accounts (SOA)**: 1-click generation of party-wise financial statements and GSTR-1 tax workbooks.
- **Instant WhatsApp Dispatch**: Share payment receipts and invoice summaries directly to clients via WhatsApp API.

---

### 🤝 6. Subcontractor & Trade Partner Management
- **Specialized Trade Directory**: Manage electrical, plumbing, HVAC, masonry, and painting contractors.
- **Contract & Retention Tracking**: Monitor total contract value, cumulative disbursements, and pending retention balances.
- **Work Order Milestones**: Track trade progress and milestone approvals before releasing stage payments.

---

### 🚜 7. Equipment, Machinery & Tools Fleet
- **Multi-Category Asset Directory**: Track heavy machinery (excavators, mixers), power tools, scaffolding, and generators.
- **Dynamic Asset Tracking**: Assign equipment to specific sites or freeform locations (*"Central Yard"*, *"Lorry Tool Box"*).
- **Maintenance & Condition Logs**: Log service records, operational health, and fuel consumption rates.

---

### 📋 8. Daily Progress Reports (DPR) & Site Quality
- **Daily Site Journal**: Log workforce counts, weather conditions, equipment deployed, and activities completed.
- **Site Photo Documentation**: Cloud-synced site progress photos with timestamps.
- **Quality Checklists & Phase Groups**: Itemized verification checkpoints grouped by structural phases.
- **Site Snags & Defect Ticketing**: Open, in-progress, and resolved defect tickets with assigned contractors and photo attachments.

---

## 🛡️ Role Access Matrix & Security Governance

Row-Level Security (RLS) is strictly enforced at the PostgreSQL database level on every table:

| Role | Financials (`expenses`, `bills`, `ledger`) | Workforce & Salaries | Site Operations | System Settings & Roles |
|---|---|---|---|---|
| **Admin** | ✅ Full System Access | ✅ Full Workforce & Rates | ✅ Full System Access | ✅ Full Administrative Access |
| **Owner** | ✅ Full Financials & Billing | ✅ Full Workforce Access | ✅ Portfolio Oversight | ❌ Denied Admin Config |
| **Supervisor** | ✅ Site Expenses & Bills | ✅ Site Staff & Attendance | ✅ Full Site Ops & Logs | ❌ Denied Admin Config |
| **Employee** | ❌ **Denied (0 rows)** | ✅ **Own Record Only** | ✅ **Assigned Tasks Only** | ❌ **Denied (0 rows)** |

### Non-Recursive RBAC Engine (PostgreSQL 42P17 Prevention)
- Role verification uses `SECURITY DEFINER` helper functions (`get_auth_role()`, `is_admin()`, `is_owner()`, `is_supervisor()`, `is_employee()`, `get_auth_employee_id()`) with a fixed `SET search_path = public`.
- Evaluates role credentials from JWT claims, `public.profiles`, and `auth.users` metadata without querying `public.user_roles` inside policy definitions, eliminating recursive query loops.

---

## 🚀 Deployment & Build Configuration

The web client is deployed on **Cloudflare Workers** with Static Assets and global edge caching:

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "ibuild",
  "compatibility_date": "2026-08-17",
  "observability": {
    "enabled": true
  },
  "assets": {
    "directory": "build/web",
    "not_found_handling": "single-page-application"
  }
}
```

### Build & Deploy Commands
```bash
# 1. Run complete automated test suite (120 tests)
flutter test

# 2. Compile production Flutter web release bundle
flutter build web --release

# 3. Deploy to Cloudflare Workers Global Edge
npx wrangler deploy
```

🌐 **Live Production URL**: **[https://ibuild.najibcode.workers.dev](https://ibuild.najibcode.workers.dev)**

---

## 📄 License
Proprietary — All rights reserved © iBuild ERP.
