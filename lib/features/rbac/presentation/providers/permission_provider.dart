import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';
import 'package:ibuild/features/rbac/data/repositories/supabase_role_repository.dart';
import 'package:ibuild/features/rbac/domain/repositories/role_repository.dart';
import 'package:ibuild/features/rbac/data/models/user_role_model.dart';
import 'package:ibuild/features/rbac/data/models/role_model.dart';

// ── Repository Provider ──────────────────────────────────────────────────────

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRoleRepository(client);
});

// ── Role Override Provider (Allows instant role switching / demo role login) ──

final selectedRoleOverrideProvider = StateProvider<String?>((ref) => null);

// ── User Role Provider (cached, fetched once after login) ────────────────────

final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  final repo = ref.watch(roleRepositoryProvider);
  return await repo.fetchUserRole(user.id);
});

// ── Current Role Name ───────────────────────────────────────────────────────

/// Returns the active user's role name: 'admin', 'owner', 'supervisor', or 'unknown'
final currentRoleProvider = Provider<String>((ref) {
  final override = ref.watch(selectedRoleOverrideProvider);
  if (override != null && override.isNotEmpty) {
    return override.toLowerCase();
  }

  final userRoleAsync = ref.watch(userRoleProvider);
  return userRoleAsync.valueOrNull?.roleName.toLowerCase() ?? 'unknown';
});

// ── User Permissions Provider (Set<String>, cached) ──────────────────────────

final userPermissionsProvider = FutureProvider<Set<String>>((ref) async {
  final roleName = ref.watch(currentRoleProvider);
  if (roleName == 'unknown') return {};

  try {
    final repo = ref.watch(roleRepositoryProvider);
    final allRoles = await repo.fetchAllRoles();
    final matchedRole = allRoles.firstWhere(
      (r) => r.name.toLowerCase() == roleName,
      orElse: () => Role(id: '', name: roleName),
    );

    if (matchedRole.id.isNotEmpty) {
      final dbPerms = await repo.fetchPermissionsForRole(matchedRole.id);
      if (dbPerms.isNotEmpty) return dbPerms;
    }
  } catch (_) {}

  // Fallback to default permission matrix for the role
  return _defaultPermissionsForRole(roleName);
});

// ── Quick Permission Check ──────────────────────────────────────────────────

final hasPermissionProvider = Provider.family<bool, String>((ref, permKey) {
  final permsAsync = ref.watch(userPermissionsProvider);
  final perms = permsAsync.valueOrNull ?? {};
  return perms.contains(permKey);
});

// ── Role Boolean Helpers ────────────────────────────────────────────────────

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == 'admin';
});

final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == 'owner';
});

final isSupervisorProvider = Provider<bool>((ref) {
  return ref.watch(currentRoleProvider) == 'supervisor';
});

// ── Default Permission Matrix Helper ────────────────────────────────────────

Set<String> _defaultPermissionsForRole(String roleName) {
  switch (roleName.toLowerCase()) {
    case 'admin':
      return {
        'dashboard.view',
        'project.view',
        'project.create',
        'project.update',
        'project.delete',
        'employee.view',
        'employee.create',
        'employee.update',
        'employee.delete',
        'attendance.view',
        'attendance.create',
        'attendance.update',
        'inventory.view',
        'inventory.create',
        'inventory.update',
        'inventory.delete',
        'billing.view',
        'billing.create',
        'billing.update',
        'billing.delete',
        'expense.view',
        'expense.create',
        'expense.update',
        'expense.delete',
        'reports.view',
        'reports.export',
        'daily_progress.view',
        'daily_progress.create',
        'daily_progress.update',
        'settings.manage',
        'users.manage',
        'roles.manage',
        'system.manage',
      };
    case 'owner':
      return {
        'dashboard.view',
        'project.view',
        'project.create',
        'project.update',
        'project.delete',
        'employee.view',
        'employee.create',
        'employee.update',
        'employee.delete',
        'attendance.view',
        'attendance.create',
        'attendance.update',
        'inventory.view',
        'inventory.create',
        'inventory.update',
        'inventory.delete',
        'billing.view',
        'billing.create',
        'billing.update',
        'billing.delete',
        'expense.view',
        'expense.create',
        'expense.update',
        'expense.delete',
        'reports.view',
        'reports.export',
        'daily_progress.view',
        'daily_progress.create',
        'daily_progress.update',
      };
    case 'supervisor':
      return {
        'dashboard.view',
        'project.view',
        'project.update',
        'employee.view',
        'attendance.view',
        'attendance.create',
        'attendance.update',
        'inventory.view',
        'inventory.create',
        'inventory.update',
        'expense.view',
        'expense.create',
        'reports.view',
        'daily_progress.view',
        'daily_progress.create',
        'daily_progress.update',
      };
    default:
      return {};
  }
}
