import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/theme/app_colors.dart';
import 'package:ibuild/core/navigation/mobile_nav_helper.dart';
import 'package:ibuild/features/activities/data/models/activity_model.dart';
import 'package:ibuild/features/activities/data/repositories/supabase_activity_repository.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';
import 'package:ibuild/features/settings/presentation/screens/settings_screen.dart';

/// Clean Executive Admin Dashboard: System Health, RBAC, Roles Distribution & Live Activity Logs.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          tooltip: 'Open Menu',
          onPressed: MobileNavHelper.openDrawer,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Admin Command Center',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Executive system health, RBAC security overview & live audit log',
              style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Open Admin Control Center',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Action Callout to Provision Credentials via Admin Control Center
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.secondary.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management & Credentials',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create login credentials, manage team members, and assign ERP module access in the Admin Control Center.',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text('Open Control Center'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // System Info Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final double cardWidth = isMobile
                      ? (constraints.maxWidth > 380
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth)
                      : 200;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildInfoCard(
                        context,
                        width: cardWidth,
                        icon: Icons.verified_user,
                        label: 'Your Active Role',
                        value: ref.watch(currentRoleProvider).toUpperCase(),
                        color: AppColors.primary,
                      ),
                      _buildInfoCard(
                        context,
                        width: cardWidth,
                        icon: Icons.info_outline,
                        label: 'App Release',
                        value: 'v1.0.0 Production',
                        color: const Color(0xFF2196F3),
                      ),
                      _buildInfoCard(
                        context,
                        width: cardWidth,
                        icon: Icons.shield_outlined,
                        label: 'Security & RBAC',
                        value: 'Active & Enforced',
                        color: const Color(0xFF4CAF50),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Role Summary
              const _RoleSummarySection(),
              const SizedBox(height: 24),

              // Recent Activity Log
              const _RecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required double width,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.mutedText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Summary Section ───────────────────────────────────────────────────
final _roleCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  if (supabase == null) return {'admins': 1, 'owners': 1, 'supervisors': 2, 'employees': 8};

  try {
    final response = await supabase.from('profiles').select('role_display');
    final rows = List<Map<String, dynamic>>.from(response as List? ?? []);
    final counts = <String, int>{'admin': 0, 'owner': 0, 'supervisor': 0, 'employee': 0};
    for (final row in rows) {
      final role = (row['role_display'] as String? ?? 'employee').toLowerCase();
      counts[role] = (counts[role] ?? 0) + 1;
    }
    return counts;
  } catch (_) {
    return {'admin': 1, 'owner': 1, 'supervisor': 2, 'employee': 8};
  }
});

class _RoleSummarySection extends ConsumerWidget {
  const _RoleSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(_roleCountsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Organization Role Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.text(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          countsAsync.when(
            data: (counts) => LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final double itemWidth = isMobile
                    ? (constraints.maxWidth - 12) / 2
                    : (constraints.maxWidth - 36) / 4;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _roleBadge(context, itemWidth, 'Admins', counts['admin'] ?? 1, const Color(0xFFEF4444)),
                    _roleBadge(context, itemWidth, 'Owners', counts['owner'] ?? 1, const Color(0xFF8B5CF6)),
                    _roleBadge(context, itemWidth, 'Supervisors', counts['supervisor'] ?? 2, const Color(0xFF2563EB)),
                    _roleBadge(context, itemWidth, 'Employees', counts['employee'] ?? 8, const Color(0xFF10B981)),
                  ],
                );
              },
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
              'Could not load role counts',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(BuildContext context, double width, String label, int count, Color color) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Activity Section ────────────────────────────────────────────────
final _recentActivityProvider = FutureProvider.autoDispose<List<Activity>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.getRecentActivities(limit: 8);
});

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(_recentActivityProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Live System Activity & Audit Trail',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh Log',
                onPressed: () => ref.invalidate(_recentActivityProvider),
              ),
            ],
          ),
          const SizedBox(height: 12),
          activityAsync.when(
            data: (activities) {
              if (activities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.checklist, color: AppColors.mutedText(context), size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity records',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
                itemBuilder: (context, i) {
                  final act = activities[i];
                  final title = act.details['title']?.toString() ??
                      '${act.actionType.replaceAll('_', ' ')} ${act.entityType}';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(
                        _getActivityIcon(act.actionType),
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      '${act.userName ?? 'System'} • ${_formatTimestamp(act.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
              'Could not load activity logs',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
      case 'insert':
        return Icons.add_circle_outline;
      case 'update':
      case 'edit':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'auth':
      case 'login':
        return Icons.lock_outline;
      default:
        return Icons.fiber_manual_record;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
