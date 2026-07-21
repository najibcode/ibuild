import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';
import 'package:ibuild/features/rbac/data/repositories/supabase_role_repository.dart';
import 'package:ibuild/features/rbac/domain/repositories/role_repository.dart';
import 'package:ibuild/features/rbac/data/models/user_role_model.dart';

// ── Repository Provider ──────────────────────────────────────────────────────

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseRoleRepository(client);
});

// ── User Role Provider (cached, fetched once after login) ────────────────────

final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  final repo = ref.watch(roleRepositoryProvider);
  return await repo.fetchUserRole(user.id);
});

// ── User Permissions Provider (Set<String>, cached) ──────────────────────────

final userPermissionsProvider = FutureProvider<Set<String>>((ref) async {
  final userRole = await ref.watch(userRoleProvider.future);
  if (userRole == null) return {};

  final repo = ref.watch(roleRepositoryProvider);
  return await repo.fetchPermissionsForRole(userRole.roleId);
});

// ── Quick Permission Check ──────────────────────────────────────────────────

/// Usage: ref.watch(hasPermissionProvider('employee.delete'))
final hasPermissionProvider = Provider.family<bool, String>((ref, permKey) {
  final permsAsync = ref.watch(userPermissionsProvider);
  final perms = permsAsync.valueOrNull ?? {};
  return perms.contains(permKey);
});

// ── Current Role Name ───────────────────────────────────────────────────────

/// Returns the current user's role name: 'admin', 'owner', 'supervisor', or 'unknown'
final currentRoleProvider = Provider<String>((ref) {
  final userRoleAsync = ref.watch(userRoleProvider);
  return userRoleAsync.valueOrNull?.roleName ?? 'unknown';
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
