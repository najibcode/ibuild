import 'package:flutter/material.dart';

/// Represents a single modular operational function in IBUILD ERP.
class ErpFunctionItem {
  final String key;
  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> permissions;

  const ErpFunctionItem({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.color,
    required this.permissions,
  });
}

/// Category grouping for ERP functions in the admin matrix.
class ErpFunctionGroup {
  final String category;
  final IconData icon;
  final Color color;
  final List<ErpFunctionItem> items;

  const ErpFunctionGroup({
    required this.category,
    required this.icon,
    required this.color,
    required this.items,
  });
}

/// Registry of all operational functions available in IBUILD ERP.
class ErpFunctionRegistry {
  static const List<ErpFunctionGroup> groups = [
    // ── Group 1: Construction Site Operations ──
    ErpFunctionGroup(
      category: 'SITE OPERATIONS',
      icon: Icons.architecture,
      color: Color(0xFF2196F3),
      items: [
        ErpFunctionItem(
          key: 'projects',
          label: 'Projects & Sites Management',
          shortLabel: 'Projects',
          description: 'Access site plans, project status, milestones, drawings & BOQ',
          icon: Icons.architecture_outlined,
          color: Color(0xFF2196F3),
          permissions: [
            'project.view',
            'project.create',
            'project.update',
            'project.delete',
          ],
        ),
        ErpFunctionItem(
          key: 'daily_progress',
          label: 'Daily Site Progress (DPR)',
          shortLabel: 'Daily DPR',
          description: 'Submit work logs, photo evidence, obstacle notes & weather logs',
          icon: Icons.assignment_outlined,
          color: Color(0xFF00BCD4),
          permissions: [
            'daily_progress.view',
            'daily_progress.create',
            'daily_progress.update',
          ],
        ),
        ErpFunctionItem(
          key: 'attendance',
          label: 'Attendance & Labor Muster',
          shortLabel: 'Attendance',
          description: 'Punch in/out workers, daily site muster roll & wage records',
          icon: Icons.pending_actions_outlined,
          color: Color(0xFF4CAF50),
          permissions: [
            'attendance.view',
            'attendance.create',
            'attendance.update',
          ],
        ),
        ErpFunctionItem(
          key: 'snags',
          label: 'Site Snags & Quality Punch List',
          shortLabel: 'Site Snags',
          description: 'Inspect defects, assign rectification tasks & sign-off approvals',
          icon: Icons.checklist_rtl_outlined,
          color: Color(0xFFFF9800),
          permissions: [
            'snags.view',
            'snags.create',
            'snags.update',
          ],
        ),
      ],
    ),

    // ── Group 2: Supply Chain & Asset Tracking ──
    ErpFunctionGroup(
      category: 'SUPPLY CHAIN & ASSETS',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF9C27B0),
      items: [
        ErpFunctionItem(
          key: 'inventory',
          label: 'Inventory & Materials Store',
          shortLabel: 'Inventory',
          description: 'Material inward/outward, cement/steel stock & reorder alerts',
          icon: Icons.inventory_2_outlined,
          color: Color(0xFF9C27B0),
          permissions: [
            'inventory.view',
            'inventory.create',
            'inventory.update',
            'inventory.delete',
          ],
        ),
        ErpFunctionItem(
          key: 'equipment',
          label: 'Machinery & Heavy Equipment',
          shortLabel: 'Equipment',
          description: 'Excavators, mixers, crane usage logs, diesel & maintenance tracking',
          icon: Icons.construction_outlined,
          color: Color(0xFF795548),
          permissions: [
            'equipment.view',
            'equipment.create',
            'equipment.update',
          ],
        ),
        ErpFunctionItem(
          key: 'vendors',
          label: 'Subcontractors & Trade Partners',
          shortLabel: 'Subcontractors',
          description: 'Trade contracts, subcontractor ledgers & work order progress',
          icon: Icons.assignment_ind_outlined,
          color: Color(0xFF607D8B),
          permissions: [
            'vendors.view',
            'vendors.create',
            'vendors.update',
          ],
        ),
        ErpFunctionItem(
          key: 'employees',
          label: 'Employees & Staff Directory',
          shortLabel: 'Employees',
          description: 'Staff directory, Aadhaar KYC, wage calculations & profiles',
          icon: Icons.people_outline,
          color: Color(0xFF3F51B5),
          permissions: [
            'employee.view',
            'employee.create',
            'employee.update',
            'employee.delete',
          ],
        ),
      ],
    ),

    // ── Group 3: Financials & Analytics ──
    ErpFunctionGroup(
      category: 'COMMERCIAL & FINANCIALS',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF009688),
      items: [
        ErpFunctionItem(
          key: 'billing',
          label: 'Client Billing & Tax Invoicing',
          shortLabel: 'Billing',
          description: 'GST tax invoices, client receivables & payment certificates',
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF009688),
          permissions: [
            'billing.view',
            'billing.create',
            'billing.update',
            'billing.delete',
          ],
        ),
        ErpFunctionItem(
          key: 'expenses',
          label: 'Expenses & Site Petty Cash',
          shortLabel: 'Expenses',
          description: 'Tea/snack allowances, fuel bills, vendor payouts & claims',
          icon: Icons.receipt_long_outlined,
          color: Color(0xFFE91E63),
          permissions: [
            'expense.view',
            'expense.create',
            'expense.update',
            'expense.delete',
          ],
        ),
        ErpFunctionItem(
          key: 'reports',
          label: 'Executive Reports & Data Export',
          shortLabel: 'Reports',
          description: 'Audit PDFs, Excel data export, profit & loss summaries',
          icon: Icons.assessment_outlined,
          color: Color(0xFF673AB7),
          permissions: [
            'reports.view',
            'reports.export',
          ],
        ),
      ],
    ),

    // ── Group 4: Administration & System ──
    ErpFunctionGroup(
      category: 'ADMINISTRATION & SECURITY',
      icon: Icons.admin_panel_settings_outlined,
      color: Color(0xFFF44336),
      items: [
        ErpFunctionItem(
          key: 'settings',
          label: 'System Administration & RBAC',
          shortLabel: 'System Admin',
          description: 'User credential provisioning, audit logs & system setup',
          icon: Icons.admin_panel_settings_outlined,
          color: Color(0xFFF44336),
          permissions: [
            'settings.manage',
            'users.manage',
            'roles.manage',
            'system.manage',
          ],
        ),
      ],
    ),
  ];

  /// Flat list of all available ERP function items.
  static List<ErpFunctionItem> get allFunctions =>
      groups.expand((g) => g.items).toList();

  /// Map of function key to ErpFunctionItem.
  static Map<String, ErpFunctionItem> get functionMap => {
        for (final f in allFunctions) f.key: f,
      };

  /// Returns the default function keys for a given role name.
  static List<String> getDefaultFunctionKeysForRole(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return allFunctions.map((f) => f.key).toList();
      case 'owner':
        return allFunctions
            .where((f) => f.key != 'settings')
            .map((f) => f.key)
            .toList();
      case 'supervisor':
        return [
          'projects',
          'daily_progress',
          'attendance',
          'snags',
          'inventory',
          'equipment',
          'expenses',
          'reports',
        ];
      case 'employee':
      default:
        return [
          'attendance',
          'daily_progress',
        ];
    }
  }

  /// Converts a list of function keys into their associated permission keys.
  static List<String> functionKeysToPermissions(List<String> functionKeys) {
    final Set<String> perms = {'dashboard.view'};
    for (final key in functionKeys) {
      final item = functionMap[key];
      if (item != null) {
        perms.addAll(item.permissions);
      }
    }
    return perms.toList();
  }

  /// Infers function keys from a raw list of permission keys.
  static List<String> permissionsToFunctionKeys(List<String> permissions) {
    final permSet = Set<String>.from(permissions);
    final List<String> matchedKeys = [];
    for (final item in allFunctions) {
      // If at least the primary/view permission is present, consider function active
      if (item.permissions.any((p) => permSet.contains(p))) {
        matchedKeys.add(item.key);
      }
    }
    return matchedKeys;
  }
}
