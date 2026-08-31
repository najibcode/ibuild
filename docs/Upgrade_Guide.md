# Upgrade Guide, Project Audit, & Release Protocols

This document details the project audit findings, security status, test execution results, and release checklists for **IBUILD ERP**.

---

## 1. Project Audit & Security Status

A comprehensive audit was performed across the IBUILD codebase for the production release:

### A. Security Posture & Hardening
* **Row-Level Security (RLS)**: Strictly enforced across all 22+ PostgreSQL tables via Migration 020. Deny-by-default architecture prevents unauthorized data access.
* **Employee Isolation**: Field employee accounts return **0 rows** on sensitive financial tables (`expenses`, `bills`, `sales_bills`, `payment_ledger`, `audit_logs`, `system_settings`), with access strictly restricted to own attendance and assigned tasks.
* **Anti-Recursion RBAC (PostgreSQL 42P17)**: Non-recursive `SECURITY DEFINER` helper functions (`get_auth_role()`, `is_admin()`, `is_owner()`, `is_supervisor()`, `is_employee()`) prevent cyclic query evaluation on `user_roles`.
* **Compact JWTs**: Authentication tokens are kept below 1 KB (~884–999 bytes) with avatar URL validation rejecting base64/data URI payloads.
* **CORS & Headers**: Restricted to authorized production origin `https://ibuild.najibcode.workers.dev` with only `GET, POST, PATCH, DELETE, OPTIONS` methods permitted. Blocked `TRACE` and `CONNECT`.

### B. Database Integrity & Concurrency
* **Atomic Spend Calculations**: Trigger `update_project_spent_atomic()` automatically recalculates `projects.spent` upon expense insert/update/delete.
* **Attendance Deduplication**: Database unique constraint `UNIQUE (employee_id, date)` blocks duplicate check-in submissions under concurrent conditions.
* **Historical Rate Immutability**: `trg_snapshot_attendance_wages` captures wage rates at entry time.

### C. Testing & QA Coverage
* **120 Automated Tests Passing** across 33 test suites.
* Key audit test suites:
  - `test/features/audit/rls_role_access_matrix_test.dart` (Multi-role access matrix)
  - `test/features/audit/live_auth_and_api_verification_test.dart` (Live authentication and token size verification)
  - `test/features/audit/production_readiness_audit_test.dart` (CORS, CSP, atomic spend sums, and attendance unique keys)

---

## 2. Release Verification Checklist

Every release deployment to production must verify the following items:

- [x] Run automated test suite:
  ```bash
  flutter test
  ```
- [x] Analyze Dart/Flutter code for zero analyzer errors:
  ```bash
  flutter analyze
  ```
- [x] Verify Row-Level Security (RLS) policies are active on all tables in Supabase.
- [x] Confirm no demo credentials or secrets exist in the production JavaScript bundle.
- [x] Compile production Flutter web release bundle:
  ```bash
  flutter build web --release
  ```
- [x] Deploy to Cloudflare Workers Static Assets:
  ```bash
  npx wrangler deploy
  ```
- [x] Verify live deployment status returns `HTTP 200 OK` at [https://ibuild.najibcode.workers.dev](https://ibuild.najibcode.workers.dev).
