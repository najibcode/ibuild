import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';
import 'package:ibuild/features/admin/data/models/admin_user_model.dart';
import 'package:ibuild/features/admin/data/models/audit_log_model.dart';
import 'package:ibuild/features/admin/data/repositories/admin_repository.dart';

/// Repository Provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminRepository(client);
});

/// All Users Provider
final adminUsersProvider = FutureProvider<List<AdminUserEntry>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.fetchAllUsers();
});

/// Search Query Provider for Users
final adminUserSearchQueryProvider = StateProvider<String>((ref) => '');

/// Role Filter Provider for Users ('all', 'admin', 'owner', 'supervisor', 'employee')
final adminUserRoleFilterProvider = StateProvider<String>((ref) => 'all');

/// Filtered Users Provider
final filteredAdminUsersProvider = Provider<List<AdminUserEntry>>((ref) {
  final usersAsync = ref.watch(adminUsersProvider);
  final users = usersAsync.valueOrNull ?? [];
  final query = ref.watch(adminUserSearchQueryProvider).trim().toLowerCase();
  final roleFilter = ref.watch(adminUserRoleFilterProvider).toLowerCase();

  return users.where((u) {
    // Role filter
    if (roleFilter != 'all' && u.roleName.toLowerCase() != roleFilter) {
      return false;
    }
    // Search query filter
    if (query.isNotEmpty) {
      final nameMatch = u.fullName.toLowerCase().contains(query);
      final emailMatch = u.email.toLowerCase().contains(query);
      final companyMatch = u.companyName.toLowerCase().contains(query);
      final phoneMatch = u.phone.toLowerCase().contains(query);
      return nameMatch || emailMatch || companyMatch || phoneMatch;
    }
    return true;
  }).toList();
});

/// Audit Log Action Filter Provider
final auditLogActionFilterProvider = StateProvider<String>((ref) => 'all');

/// Audit Logs Provider
final auditLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(auditLogActionFilterProvider);
  return await repo.fetchAuditLogs(limit: 60, actionFilter: filter);
});

/// System Health Provider
final systemHealthProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.fetchSystemHealth();
});
