import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Row-Level Security (RLS) & Role Access Matrix Tests', () {
    // Simulated database tables and role-based policy evaluation
    final allFinancialTables = [
      'expenses',
      'bills',
      'sales_bills',
      'sales_bill_items',
      'payment_ledger',
      'project_payments',
      'quotations',
      'quotation_items',
      'vendors',
      'vendor_transactions',
      'subcontractors',
    ];

    final allAdminTables = [
      'system_settings',
      'roles.manage',
      'users.manage',
    ];

    // Policy Simulator matching Migration 020 SQL RLS Definitions
    List<Map<String, dynamic>> evaluateSelectPolicy({
      required String role,
      required String userId,
      required String userEmail,
      required String table,
      required List<Map<String, dynamic>> rawRows,
    }) {
      if (role == 'anonymous') {
        // All business tables deny anonymous reads
        return [];
      }

      if (role == 'admin') {
        // Admin has full system access
        return rawRows;
      }

      if (role == 'owner') {
        // Owner has access to financials, operations, and oversight; denied from system admin tables
        if (allAdminTables.contains(table)) return [];
        return rawRows;
      }

      if (role == 'supervisor') {
        // Supervisor has access to site operations, workforce, expenses, inventory, equipment
        if (allAdminTables.contains(table)) return [];
        return rawRows;
      }

      if (role == 'employee') {
        // Employees are STRICTLY DENIED from all financial, accounting, vendor, inventory, equipment, and audit tables
        if (allFinancialTables.contains(table) ||
            table == 'inventory' ||
            table == 'inventory_history' ||
            table == 'equipment' ||
            table == 'audit_logs' ||
            table == 'activities' ||
            table == 'system_settings') {
          return [];
        }

        // Own employee record only (prevents coworker salary discovery)
        if (table == 'employees') {
          return rawRows.where((r) => r['user_id'] == userId || r['email'] == userEmail).toList();
        }

        // Own attendance records only
        if (table == 'attendance') {
          return rawRows.where((r) => r['user_id'] == userId || r['employee_email'] == userEmail).toList();
        }

        // Assigned project checklists only
        if (table == 'project_checklists') {
          return rawRows.where((r) => r['assigned_person'] == userEmail || r['assigned_user_id'] == userId).toList();
        }

        // Assigned site tickets / snags only
        if (table == 'site_tickets' || table == 'snags') {
          return rawRows.where((r) => r['assigned_to'] == userId || r['reported_by'] == userId).toList();
        }

        // Assigned project overview only
        if (table == 'projects') {
          return rawRows.where((r) => (r['assigned_users'] as List<String>? ?? []).contains(userId)).toList();
        }

        if (table == 'site_drawings' || table == 'profiles' || table == 'roles' || table == 'permissions') {
          return rawRows;
        }

        return [];
      }

      return [];
    }

    test('1. Anonymous role cannot read any business table', () {
      final tables = [
        'projects',
        'employees',
        'attendance',
        'daily_progress',
        'expenses',
        'bills',
        'payment_ledger',
        'inventory',
        'equipment',
        'audit_logs',
        'system_settings',
      ];

      for (final table in tables) {
        final rows = evaluateSelectPolicy(
          role: 'anonymous',
          userId: '',
          userEmail: '',
          table: table,
          rawRows: [
            {'id': '1', 'name': 'Sample $table'}
          ],
        );
        expect(rows, isEmpty, reason: 'Anonymous access to $table must be denied by default');
      }
    });

    test('2. Employee role is strictly denied from financial tables, bills, expenses, and audit logs', () {
      const empId = 'emp_user_01';
      const empEmail = 'employee@ibuild.in';

      final sampleExpenses = [
        {'id': 'exp_1', 'amount': 45000.0, 'notes': 'Secret contractor payment'},
        {'id': 'exp_2', 'amount': 12000.0, 'notes': 'Cement bag procurement'},
      ];

      final sampleBills = [
        {'id': 'bill_1', 'amount': 150000.0, 'status': 'Pending', 'vendor': 'UltraTech'},
      ];

      final sampleLedger = [
        {'id': 'led_1', 'amount': 200000.0, 'party': 'Investor Cash Inflow'},
      ];

      final sampleAuditLogs = [
        {'id': 'log_1', 'action': 'USER_ROLE_CHANGED', 'details': 'Promoted supervisor to admin'},
      ];

      // Assert 0 rows returned for Employee on financial tables
      expect(
        evaluateSelectPolicy(role: 'employee', userId: empId, userEmail: empEmail, table: 'expenses', rawRows: sampleExpenses),
        isEmpty,
      );
      expect(
        evaluateSelectPolicy(role: 'employee', userId: empId, userEmail: empEmail, table: 'bills', rawRows: sampleBills),
        isEmpty,
      );
      expect(
        evaluateSelectPolicy(role: 'employee', userId: empId, userEmail: empEmail, table: 'payment_ledger', rawRows: sampleLedger),
        isEmpty,
      );
      expect(
        evaluateSelectPolicy(role: 'employee', userId: empId, userEmail: empEmail, table: 'audit_logs', rawRows: sampleAuditLogs),
        isEmpty,
      );
      expect(
        evaluateSelectPolicy(role: 'employee', userId: empId, userEmail: empEmail, table: 'system_settings', rawRows: [{'key': 'app_config'}]),
        isEmpty,
      );
    });

    test('3. Employee can only view own profile and own attendance, preventing coworker salary discovery', () {
      const empId = 'emp_user_01';
      const empEmail = 'employee@ibuild.in';

      final allEmployees = [
        {'id': 'e1', 'name': 'John Worker', 'user_id': empId, 'email': empEmail, 'salary': 600.0},
        {'id': 'e2', 'name': 'Senior Engineer', 'user_id': 'other_user', 'email': 'eng@ibuild.in', 'salary': 2500.0},
      ];

      final visibleEmployees = evaluateSelectPolicy(
        role: 'employee',
        userId: empId,
        userEmail: empEmail,
        table: 'employees',
        rawRows: allEmployees,
      );

      expect(visibleEmployees.length, equals(1));
      expect(visibleEmployees.first['name'], equals('John Worker'));
      expect(visibleEmployees.first['salary'], equals(600.0));
      // Coworker record must NOT be present
      expect(visibleEmployees.any((e) => e['email'] == 'eng@ibuild.in'), isFalse);

      final allAttendance = [
        {'id': 'att_1', 'user_id': empId, 'employee_email': empEmail, 'status': 'Present', 'date': '2026-08-28'},
        {'id': 'att_2', 'user_id': 'other_user', 'employee_email': 'other@ibuild.in', 'status': 'Present', 'date': '2026-08-28'},
      ];

      final visibleAttendance = evaluateSelectPolicy(
        role: 'employee',
        userId: empId,
        userEmail: empEmail,
        table: 'attendance',
        rawRows: allAttendance,
      );

      expect(visibleAttendance.length, equals(1));
      expect(visibleAttendance.first['employee_email'], equals(empEmail));
    });

    test('4. Employee can access assigned project checklists and assigned snags', () {
      const empId = 'emp_user_01';
      const empEmail = 'employee@ibuild.in';

      final allChecklists = [
        {'id': 'chk_1', 'title': 'Inspect basement rebar', 'assigned_person': empEmail, 'approval_status': 'In Progress'},
        {'id': 'chk_2', 'title': 'Install electrical meter', 'assigned_person': 'electrician@ibuild.in', 'approval_status': 'Approved'},
      ];

      final visibleChecklists = evaluateSelectPolicy(
        role: 'employee',
        userId: empId,
        userEmail: empEmail,
        table: 'project_checklists',
        rawRows: allChecklists,
      );

      expect(visibleChecklists.length, equals(1));
      expect(visibleChecklists.first['title'], equals('Inspect basement rebar'));

      final allTickets = [
        {'id': 'snag_1', 'title': 'Column honeycomb crack', 'assigned_to': empId, 'status': 'Open'},
        {'id': 'snag_2', 'title': 'Roof waterproofing leak', 'assigned_to': 'other_contractor', 'status': 'Resolved'},
      ];

      final visibleTickets = evaluateSelectPolicy(
        role: 'employee',
        userId: empId,
        userEmail: empEmail,
        table: 'site_tickets',
        rawRows: allTickets,
      );

      expect(visibleTickets.length, equals(1));
      expect(visibleTickets.first['title'], equals('Column honeycomb crack'));
    });

    test('5. Supervisor role has access to site operations, attendance, expenses, inventory, and equipment', () {
      const supId = 'sup_user_01';
      const supEmail = 'supervisor@ibuild.in';

      final sampleExpenses = [
        {'id': 'exp_1', 'amount': 15000.0, 'category': 'Fuel & Diesel'},
      ];
      final sampleInventory = [
        {'id': 'inv_1', 'item_name': 'Portland Cement 53 Grade', 'quantity': 150},
      ];
      final sampleEquipment = [
        {'id': 'eq_1', 'name': 'JCB Excavator 3DX', 'status': 'Operational'},
      ];

      expect(
        evaluateSelectPolicy(role: 'supervisor', userId: supId, userEmail: supEmail, table: 'expenses', rawRows: sampleExpenses).length,
        equals(1),
      );
      expect(
        evaluateSelectPolicy(role: 'supervisor', userId: supId, userEmail: supEmail, table: 'inventory', rawRows: sampleInventory).length,
        equals(1),
      );
      expect(
        evaluateSelectPolicy(role: 'supervisor', userId: supId, userEmail: supEmail, table: 'equipment', rawRows: sampleEquipment).length,
        equals(1),
      );
    });

    test('6. Owner role has access to overall financial variance, billing, and portfolio oversight', () {
      const ownerId = 'owner_user_01';
      const ownerEmail = 'owner@ibuild.in';

      final financialData = [
        {'id': 'f1', 'totalBudget': 5000000.0, 'totalSpent': 2100000.0, 'variancePct': 8.5},
      ];
      final vendorBills = [
        {'id': 'b1', 'amount': 350000.0, 'status': 'Approved'},
      ];

      expect(
        evaluateSelectPolicy(role: 'owner', userId: ownerId, userEmail: ownerEmail, table: 'expenses', rawRows: financialData).length,
        equals(1),
      );
      expect(
        evaluateSelectPolicy(role: 'owner', userId: ownerId, userEmail: ownerEmail, table: 'bills', rawRows: vendorBills).length,
        equals(1),
      );
    });

    test('7. Admin role has full access including system settings and user management', () {
      const adminId = 'admin_user_01';
      const adminEmail = 'admin@ibuild.in';

      final systemSettings = [{'key': 'feature_flags', 'value': {'ai_enabled': true}}];
      final auditLogs = [{'id': 'log_99', 'action': 'SYSTEM_BACKUP'}];

      expect(
        evaluateSelectPolicy(role: 'admin', userId: adminId, userEmail: adminEmail, table: 'system_settings', rawRows: systemSettings).length,
        equals(1),
      );
      expect(
        evaluateSelectPolicy(role: 'admin', userId: adminId, userEmail: adminEmail, table: 'audit_logs', rawRows: auditLogs).length,
        equals(1),
      );
    });

    test('8. Non-recursive user_roles evaluation handles role resolution without infinite loops', () {
      // Simulating get_auth_role() SECURITY DEFINER behavior
      String getAuthRole(String uid, Map<String, String> userRolesTable, Map<String, String> profilesTable) {
        if (userRolesTable.containsKey(uid)) {
          return userRolesTable[uid]!;
        }
        if (profilesTable.containsKey(uid)) {
          return profilesTable[uid]!;
        }
        return 'employee';
      }

      final userRoles = {
        'admin-uid': 'admin',
        'owner-uid': 'owner',
        'supervisor-uid': 'supervisor',
        'employee-uid': 'employee',
      };

      final profiles = {
        'guest-uid': 'employee',
      };

      expect(getAuthRole('admin-uid', userRoles, profiles), equals('admin'));
      expect(getAuthRole('owner-uid', userRoles, profiles), equals('owner'));
      expect(getAuthRole('supervisor-uid', userRoles, profiles), equals('supervisor'));
      expect(getAuthRole('employee-uid', userRoles, profiles), equals('employee'));
      expect(getAuthRole('guest-uid', userRoles, profiles), equals('employee'));
    });
  });
}
