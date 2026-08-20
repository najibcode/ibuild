import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/role_repository.dart';
import '../models/role_model.dart';
import '../models/user_role_model.dart';

class SupabaseRoleRepository implements RoleRepository {
  final SupabaseClient _client;

  SupabaseRoleRepository(this._client);

  @override
  Future<UserRole?> fetchUserRole(String userId) async {
    try {
      // 1. Try checking user_roles table
      try {
        final response = await _client
            .from('user_roles')
            .select('user_id, role_id, roles(name, description)')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null && response['roles'] != null) {
          final role = UserRole.fromJson(response);
          if (role.roleName.isNotEmpty && role.roleName != 'unknown') {
            return role;
          }
        }
      } catch (userRolesErr) {
        debugPrint('Note: user_roles query bypassed: $userRolesErr');
      }

      // 2. Try checking profiles table for role_display / role
      String? targetRoleName;
      try {
        final profile = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profile != null) {
          final roleVal = (profile['role_display'] ?? profile['role']) as String?;
          if (roleVal != null && roleVal.isNotEmpty) {
            final raw = roleVal.toLowerCase();
            if (raw.contains('admin')) {
              targetRoleName = 'admin';
            } else if (raw.contains('supervisor')) {
              targetRoleName = 'supervisor';
            } else if (raw.contains('employee') || raw.contains('staff')) {
              targetRoleName = 'employee';
            } else if (raw.contains('owner')) {
              targetRoleName = 'owner';
            }
          }
        }
      } catch (profileErr) {
        debugPrint('Note: profiles query bypassed: $profileErr');
      }

      // 3. Fallback to auth user email and metadata
      if (targetRoleName == null) {
        final user = _client.auth.currentUser;
        if (user != null && user.id == userId) {
          final meta = user.userMetadata?['role']?.toString().toLowerCase();
          if (meta != null && meta.isNotEmpty) {
            targetRoleName = meta;
          } else {
            final email = user.email?.toLowerCase() ?? '';
            if (email.contains('admin')) {
              targetRoleName = 'admin';
            } else if (email.contains('supervisor')) {
              targetRoleName = 'supervisor';
            } else if (email.contains('employee') || email.contains('staff')) {
              targetRoleName = 'employee';
            } else {
              targetRoleName = 'owner';
            }
          }
        }
      }

      targetRoleName ??= 'owner';

      // 4. Resolve role_id from roles table and auto-persist to user_roles
      final roleRow = await _client
          .from('roles')
          .select('id, name, description')
          .eq('name', targetRoleName)
          .maybeSingle();

      if (roleRow != null && roleRow['id'] != null) {
        final roleId = roleRow['id'] as String;
        try {
          await assignRole(userId, roleId);
          await _client.from('profiles').upsert({
            'id': userId,
            'role_display': targetRoleName,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        return UserRole(
          userId: userId,
          roleId: roleId,
          roleName: roleRow['name'] as String,
          roleDescription: roleRow['description'] as String?,
        );
      }

      // Safe fallback UserRole if database roles table is empty
      return UserRole(
        userId: userId,
        roleId: 'role-$targetRoleName',
        roleName: targetRoleName,
        roleDescription: '$targetRoleName role',
      );
    } catch (e) {
      debugPrint('Failed to fetch user role: $e');
      final email = _client.auth.currentUser?.email?.toLowerCase() ?? '';
      final fallbackName = email.contains('admin')
          ? 'admin'
          : (email.contains('supervisor') ? 'supervisor' : 'owner');
      return UserRole(
        userId: userId,
        roleId: 'role-$fallbackName',
        roleName: fallbackName,
        roleDescription: '$fallbackName role',
      );
    }
  }

  @override
  Future<Set<String>> fetchPermissionsForRole(String roleId) async {
    try {
      final response = await _client
          .from('role_permissions')
          .select('permissions(key)')
          .eq('role_id', roleId);

      final Set<String> permissionKeys = {};
      for (final row in response as List) {
        final perm = row['permissions'] as Map<String, dynamic>?;
        if (perm != null && perm['key'] != null) {
          permissionKeys.add(perm['key'] as String);
        }
      }
      return permissionKeys;
    } catch (e) {
      debugPrint('Failed to fetch permissions: $e');
      return {};
    }
  }

  @override
  Future<List<Role>> fetchAllRoles() async {
    try {
      final response = await _client
          .from('roles')
          .select()
          .order('name', ascending: true);
      return (response as List).map((j) => Role.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Failed to fetch roles: $e');
      return [];
    }
  }

  @override
  Future<void> assignRole(String userId, String roleId) async {
    await _client.from('user_roles').upsert(
      {'user_id': userId, 'role_id': roleId},
      onConflict: 'user_id',
    );
  }

  @override
  Future<void> removeRole(String userId) async {
    await _client.from('user_roles').delete().eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllPermissions() async {
    try {
      final response = await _client
          .from('permissions')
          .select()
          .order('module', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Failed to fetch all permissions: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllUserRoles() async {
    try {
      final response = await _client
          .from('user_roles')
          .select('user_id, role_id, created_at, roles(name, description)');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Failed to fetch all user roles: $e');
      return [];
    }
  }
}
