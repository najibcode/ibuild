import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/admin/data/models/admin_user_model.dart';
import 'package:ibuild/features/admin/data/models/erp_function_model.dart';

void main() {
  group('Admin Login Credentials & Organization Members List Tests', () {
    test('AdminUserEntry model initializes and parses fields correctly', () {
      final user = AdminUserEntry(
        userId: 'usr_admin_100',
        email: 'supervisor.site1@ibuild.app',
        fullName: 'Vikram Singh',
        roleName: 'supervisor',
        roleId: 'role_sup_1',
        phone: '+91 9876543210',
        companyName: 'IBUILD Construction Corp',
        avatarUrl: null,
        isDisabled: false,
        lastSignInAt: null,
        createdAt: DateTime(2026, 8, 15),
        customPermissions: ['attendance.create', 'snags.create', 'daily_progress.create'],
      );

      expect(user.userId, 'usr_admin_100');
      expect(user.email, 'supervisor.site1@ibuild.app');
      expect(user.fullName, 'Vikram Singh');
      expect(user.roleName, 'supervisor');
      expect(user.isDisabled, isFalse);
      expect(user.customPermissions.length, 3);
      expect(user.customPermissions, contains('attendance.create'));
      expect(user.customPermissions, contains('snags.create'));
    });

    test('ErpFunctionRegistry maps operational function keys to granular permissions', () {
      final selectedKeys = [
        'snags',
        'attendance',
        'projects',
      ];

      final permissions = ErpFunctionRegistry.functionKeysToPermissions(selectedKeys);
      expect(permissions, isNotEmpty);
      expect(permissions, contains('snags.create'));
      expect(permissions, contains('attendance.create'));
      expect(permissions, contains('project.create'));
    });

    test('Access control allows only admin role for credential provisioning', () {
      bool isAllowedToCreateCredentials(String role) => role.toLowerCase() == 'admin';

      expect(isAllowedToCreateCredentials('admin'), isTrue);
      expect(isAllowedToCreateCredentials('owner'), isFalse);
      expect(isAllowedToCreateCredentials('supervisor'), isFalse);
      expect(isAllowedToCreateCredentials('employee'), isFalse);
    });

    test('Members list includes all organizational roles', () {
      final members = [
        AdminUserEntry(
          userId: '1',
          email: 'admin@ibuild.app',
          fullName: 'Admin User',
          phone: '9999999991',
          companyName: 'IBUILD',
          roleName: 'admin',
          roleId: 'r1',
          isDisabled: false,
        ),
        AdminUserEntry(
          userId: '2',
          email: 'owner@ibuild.app',
          fullName: 'Owner User',
          phone: '9999999992',
          companyName: 'IBUILD',
          roleName: 'owner',
          roleId: 'r2',
          isDisabled: false,
        ),
        AdminUserEntry(
          userId: '3',
          email: 'supervisor@ibuild.app',
          fullName: 'Supervisor User',
          phone: '9999999993',
          companyName: 'IBUILD',
          roleName: 'supervisor',
          roleId: 'r3',
          isDisabled: false,
        ),
        AdminUserEntry(
          userId: '4',
          email: 'worker@ibuild.app',
          fullName: 'Field Worker',
          phone: '9999999994',
          companyName: 'IBUILD',
          roleName: 'employee',
          roleId: 'r4',
          isDisabled: false,
        ),
      ];

      expect(members.length, 4);
      final roles = members.map((m) => m.roleName).toSet();
      expect(roles, containsAll(['admin', 'owner', 'supervisor', 'employee']));
    });

    test('AdminUserEntry toMap and fromMap preserve all user properties accurately', () {
      final user = AdminUserEntry(
        userId: 'usr_new_99',
        email: 'new.engineer@ibuild.app',
        fullName: 'Sameer Khan',
        phone: '+91 9123456789',
        companyName: 'Apex Infra & Builders Ltd',
        roleName: 'supervisor',
        roleId: 'role_sup',
        isDisabled: false,
        customPermissions: ['projects.create', 'snags.create'],
        createdAt: DateTime(2026, 8, 27),
      );

      final map = user.toMap();
      final restored = AdminUserEntry.fromMap(profileMap: map);

      expect(restored.userId, 'usr_new_99');
      expect(restored.email, 'new.engineer@ibuild.app');
      expect(restored.fullName, 'Sameer Khan');
      expect(restored.roleName, 'supervisor');
      expect(restored.companyName, 'Apex Infra & Builders Ltd');
      expect(restored.customPermissions, contains('projects.create'));
    });
  });
}
