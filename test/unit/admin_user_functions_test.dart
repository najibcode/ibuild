import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/admin/data/models/admin_user_model.dart';
import 'package:ibuild/features/admin/data/models/erp_function_model.dart';

void main() {
  group('ErpFunctionRegistry Tests', () {
    test('allFunctions should return all 12 defined operational functions', () {
      final all = ErpFunctionRegistry.allFunctions;
      expect(all.length, equals(12));

      final keys = all.map((f) => f.key).toSet();
      expect(keys.contains('projects'), isTrue);
      expect(keys.contains('daily_progress'), isTrue);
      expect(keys.contains('attendance'), isTrue);
      expect(keys.contains('snags'), isTrue);
      expect(keys.contains('inventory'), isTrue);
      expect(keys.contains('equipment'), isTrue);
      expect(keys.contains('vendors'), isTrue);
      expect(keys.contains('employees'), isTrue);
      expect(keys.contains('billing'), isTrue);
      expect(keys.contains('expenses'), isTrue);
      expect(keys.contains('reports'), isTrue);
      expect(keys.contains('settings'), isTrue);
    });

    test('default functions per role are tailored accurately', () {
      final adminFns = ErpFunctionRegistry.getDefaultFunctionKeysForRole('admin');
      expect(adminFns.length, equals(12));

      final ownerFns = ErpFunctionRegistry.getDefaultFunctionKeysForRole('owner');
      expect(ownerFns.contains('settings'), isFalse);
      expect(ownerFns.contains('billing'), isTrue);
      expect(ownerFns.contains('projects'), isTrue);

      final supervisorFns = ErpFunctionRegistry.getDefaultFunctionKeysForRole('supervisor');
      expect(supervisorFns.contains('daily_progress'), isTrue);
      expect(supervisorFns.contains('attendance'), isTrue);
      expect(supervisorFns.contains('snags'), isTrue);
      expect(supervisorFns.contains('inventory'), isTrue);
      expect(supervisorFns.contains('billing'), isFalse); // supervisor doesn't have billing by default

      final employeeFns = ErpFunctionRegistry.getDefaultFunctionKeysForRole('employee');
      expect(employeeFns.contains('attendance'), isTrue);
      expect(employeeFns.contains('billing'), isFalse);
    });

    test('functionKeysToPermissions maps keys to granular permissions', () {
      final perms = ErpFunctionRegistry.functionKeysToPermissions(['projects', 'attendance']);
      expect(perms.contains('dashboard.view'), isTrue);
      expect(perms.contains('project.view'), isTrue);
      expect(perms.contains('project.create'), isTrue);
      expect(perms.contains('attendance.view'), isTrue);
      expect(perms.contains('attendance.create'), isTrue);
      expect(perms.contains('billing.view'), isFalse);
    });

    test('permissionsToFunctionKeys correctly infers active functions', () {
      final keys = ErpFunctionRegistry.permissionsToFunctionKeys([
        'project.view',
        'attendance.view',
        'snags.update',
      ]);
      expect(keys.contains('projects'), isTrue);
      expect(keys.contains('attendance'), isTrue);
      expect(keys.contains('snags'), isTrue);
      expect(keys.contains('billing'), isFalse);
    });
  });

  group('AdminUserEntry with Custom Permissions Tests', () {
    test('AdminUserEntry infers default functions when customPermissions is empty', () {
      final user = AdminUserEntry(
        userId: 'u1',
        email: 'supervisor1@ibuild.in',
        fullName: 'Rajesh Supervisor',
        phone: '+91 9876543210',
        companyName: 'IBUILD',
        roleName: 'supervisor',
        roleId: 'r1',
        isDisabled: false,
      );

      expect(user.activeFunctionKeys.contains('daily_progress'), isTrue);
      expect(user.activeFunctionKeys.contains('snags'), isTrue);
      expect(user.activeFunctionKeys.contains('billing'), isFalse);
      expect(user.activeFunctionItems.isNotEmpty, isTrue);
    });

    test('AdminUserEntry respects customPermissions when assigned', () {
      // Supervisor granted special custom permission for billing & inventory
      final user = AdminUserEntry(
        userId: 'u2',
        email: 'custom_supervisor@ibuild.in',
        fullName: 'Anil Senior Supervisor',
        phone: '+91 9876543211',
        companyName: 'IBUILD',
        roleName: 'supervisor',
        roleId: 'r1',
        isDisabled: false,
        customPermissions: [
          'project.view',
          'billing.view',
          'billing.create',
          'inventory.view',
        ],
      );

      expect(user.activeFunctionKeys.contains('billing'), isTrue);
      expect(user.activeFunctionKeys.contains('projects'), isTrue);
      expect(user.activeFunctionKeys.contains('inventory'), isTrue);
      expect(user.activeFunctionKeys.contains('settings'), isFalse);
    });

    test('AdminUserEntry.fromMap extracts custom_permissions properly', () {
      final user = AdminUserEntry.fromMap(
        profileMap: {
          'id': 'usr_101',
          'full_name': 'Kavita Engineer',
          'role_display': 'owner',
          'custom_permissions': ['project.view', 'expense.view', 'reports.export'],
        },
      );

      expect(user.userId, equals('usr_101'));
      expect(user.fullName, equals('Kavita Engineer'));
      expect(user.customPermissions.length, equals(3));
      expect(user.activeFunctionKeys.contains('projects'), isTrue);
      expect(user.activeFunctionKeys.contains('expenses'), isTrue);
      expect(user.activeFunctionKeys.contains('reports'), isTrue);
    });
  });
}
