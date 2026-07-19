# Upgrade Guide, Project Audit, & Release Protocols

This document details the project audit findings, identifies current technical debt, defines the versioning guidelines, and provides release checklists for future IBUILD ERP iterations.

---

## 1. Project Audit Report

A comprehensive audit was performed across the IBUILD codebase as of Version 1.0.0.

### A. Architectural Evaluation
*   **Strengths**: Clean separation of models, interfaces, repository implementations, and Riverpod controllers. This structure ensures adding new modules is straightforward.
*   **Weaknesses**: The root `lib/` directory is cluttered with 12 orphan layout and detail screens. These bypass feature-first boundaries.

### B. Security Posture
*   **Strengths**: Leverages Supabase Authentication securely. Configuration values are managed via `.env` files.
*   **Weaknesses**: Row-Level Security (RLS) is not fully documented in project migrations. It needs to be verified on new tables (`billing`, `expenses`) to prevent supervisors from accessing global accounting balances.

### C. Database & Supabase Integration
*   **Strengths**: Well-structured relationships between projects, inventories, and daily logs.
*   **Weaknesses**: Lack of soft-delete flags on critical business records. Deleting a project can cause cascading issues on linked inventories or bill records.

### D. Coding Standards & Lints
*   **Strengths**: Strict adherence to the `flutter_lints` rules. Strong types are used throughout models.
*   **Weaknesses**: Some hardcoded strings remain in form validator screens rather than using translation templates.

---

## 2. Technical Debt & Recommended Improvements

| Priority | Issue / Debt | Recommended Action |
|----------|--------------|--------------------|
| **High** | Orphan screens in `lib/` root. | Move files like `mobile_dashboard.dart`, `web_dashboard.dart`, and `responsive_layout.dart` into a centralized `lib/features/dashboard/` or common directory. |
| **High** | Hardcoded demo project ID. | In `MainRouterScreen`, line 138 hardcodes `projects/6661804967842142645`. Replace this with a dynamic query picking the active selection. |
| **Medium**| Redundant theme configurations. | `lib/theme.dart` duplicates color systems defined in `lib/core/theme/app_colors.dart`. Remove `lib/theme.dart` once references are verified. |
| **Medium**| Stack-based mobile navigation. | Migrate to GoRouter StatefulShellRoutes to support web routing, back-button history, and browser URL synchronization. |
| **Low**  | Mock data fallbacks. | Remove remaining simulated delays in repository classes and replace them with real Supabase queries. |

---

## 3. Version Control Strategy (Semantic Versioning)

IBUILD ERP uses [Semantic Versioning 2.0.0](https://semver.org/):
$$\text{Version Format} = \text{MAJOR}.\text{MINOR}.\text{PATCH}$$

*   **MAJOR**: Incremented for breaking changes (e.g., restructuring the database without backward compatibility).
*   **MINOR**: Incremented for new functionality (e.g., adding OCR, Portals, or Equipment tracking) without breaking existing APIs.
*   **PATCH**: Incremented for bug fixes and internal refactoring (e.g., import path corrections, lint fixes).

---

## 4. Release Verification Checklist

Every release deployment to staging/production must verify the following items:

- [ ] Run automated tests and analyze lints:
  ```bash
  flutter test
  flutter analyze
  ```
- [ ] Verify Row Level Security (RLS) policies are active for new tables.
- [ ] Confirm `.env` file does not contain production service secrets on git check-ins.
- [ ] Verify that all asset pathways in `pubspec.yaml` are correctly registered.
- [ ] Perform a clean build run for targeted platforms:
  ```bash
  flutter build apk --split-per-abi
  flutter build ios --no-codesign
  flutter build web --release
  ```
- [ ] Check migration rollback integrity in a test database instance.
