import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/theme/app_colors.dart';
import 'package:ibuild/features/activities/data/repositories/supabase_activity_repository.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';

/// Admin dashboard showing system statistics: users by role, recent activity, app health.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Admin Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'System overview and user management',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // System Info Cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildInfoCard(
                  context,
                  icon: Icons.verified_user,
                  label: 'Your Role',
                  value: ref.watch(currentRoleProvider).toUpperCase(),
                  color: AppColors.primary,
                ),
                _buildInfoCard(
                  context,
                  icon: Icons.info_outline,
                  label: 'App Version',
                  value: 'v1.0.0',
                  color: const Color(0xFF2196F3),
                ),
                _buildInfoCard(
                  context,
                  icon: Icons.shield_outlined,
                  label: 'RBAC Status',
                  value: 'Active',
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Role Summary
            _RoleSummarySection(),
            const SizedBox(height: 24),

            // Recent Activity Log
            _RecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Shows count of users per role.
class _RoleSummarySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUserCountsByRole(client),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.group, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Users by Role',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasData && snapshot.data!.isNotEmpty)
                ...snapshot.data!.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _roleColor(item['role_name'] as String),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              (item['role_name'] as String).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '${item['count']} user(s)',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  'No user role data available',
                  style: TextStyle(color: AppColors.textMuted),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserCountsByRole(
      dynamic client) async {
    try {
      final response = await client
          .from('user_roles')
          .select('role_id, roles(name)');

      final Map<String, int> counts = {};
      for (final row in response as List) {
        final roleName =
            (row['roles'] as Map<String, dynamic>?)?['name'] as String? ??
                'unknown';
        counts[roleName] = (counts[roleName] ?? 0) + 1;
      }

      return counts.entries
          .map((e) => {'role_name': e.key, 'count': e.value})
          .toList();
    } catch (_) {
      return [];
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFF44336);
      case 'owner':
        return const Color(0xFF2196F3);
      case 'supervisor':
        return const Color(0xFF4CAF50);
      default:
        return AppColors.outline;
    }
  }
}

/// Shows the last 10 system-wide activities.
class _RecentActivitySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityRepo = ref.watch(activityRepositoryProvider);

    return FutureBuilder(
      future: activityRepo.getRecentActivities(limit: 10),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'System Activity Log',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasData && snapshot.data!.isNotEmpty)
                ...snapshot.data!.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${activity.actionType} — ${activity.entityType}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          _timeAgo(activity.createdAt),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  'No activity logged yet',
                  style: TextStyle(color: AppColors.textMuted),
                ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
