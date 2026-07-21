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
      final response = await _client
          .from('user_roles')
          .select('user_id, role_id, roles(name, description)')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        final user = _client.auth.currentUser;
        if (user != null && user.email != null) {
          final email = user.email!.toLowerCase();
          String targetRoleName = 'owner';
          if (email.contains('admin')) {
            targetRoleName = 'admin';
          } else if (email.contains('supervisor')) {
            targetRoleName = 'supervisor';
          } else if (email.contains('owner')) {
            targetRoleName = 'owner';
          }

          final roleRow = await _client
              .from('roles')
              .select('id')
              .eq('name', targetRoleName)
              .maybeSingle();

          if (roleRow != null && roleRow['id'] != null) {
            try {
              await assignRole(userId, roleRow['id'] as String);
              final retry = await _client
                  .from('user_roles')
                  .select('user_id, role_id, roles(name, description)')
                  .eq('user_id', userId)
                  .maybeSingle();
              if (retry != null) return UserRole.fromJson(retry);
            } catch (assignErr) {
              debugPrint('Failed to auto-assign role: $assignErr');
            }
          }
        }
        return null;
      }
      return UserRole.fromJson(response);
    } catch (e) {
      debugPrint('Failed to fetch user role: $e');
      return null;
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
}
