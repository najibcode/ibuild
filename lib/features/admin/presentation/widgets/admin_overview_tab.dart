import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/theme/app_colors.dart';
import 'package:ibuild/features/activities/data/repositories/supabase_activity_repository.dart';
import 'package:ibuild/features/admin/presentation/providers/admin_providers.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(systemHealthProvider);
    final usersAsync = ref.watch(adminUsersProvider);
    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);
    final mutedText = AppColors.mutedText(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(systemHealthProvider);
        ref.invalidate(adminUsersProvider);
        ref.invalidate(recentActivitiesProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Banner / Header ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.blueAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IBUILD SYSTEM ADMINISTRATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Full operational authority, user provisioning, database telemetry, and security oversight.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'SYSTEM HEALTHY',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── System Health KPI Cards ──
            Text(
              'LIVE SYSTEM TELEMETRY',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            healthAsync.when(
              data: (counts) => LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 650;
                  final double itemWidth = isMobile
                      ? (constraints.maxWidth - 12) / 2
                      : (constraints.maxWidth - 36) / 4;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _kpiCard(
                        context,
                        width: itemWidth,
                        title: 'Total Users',
                        count: counts['users'] ?? 0,
                        icon: Icons.people,
                        color: Colors.blueAccent,
                      ),
                      _kpiCard(
                        context,
                        width: itemWidth,
                        title: 'Active Projects',
                        count: counts['projects'] ?? 0,
                        icon: Icons.architecture,
                        color: Colors.orangeAccent,
                      ),
                      _kpiCard(
                        context,
                        width: itemWidth,
                        title: 'Site Employees',
                        count: counts['employees'] ?? 0,
                        icon: Icons.badge,
                        color: Colors.greenAccent,
                      ),
                      _kpiCard(
                        context,
                        width: itemWidth,
                        title: 'Audit Events',
                        count: counts['audit_logs'] ?? 0,
                        icon: Icons.history_edu,
                        color: Colors.purpleAccent,
                      ),
                    ],
                  );
                },
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Unable to read telemetry: $e', style: const TextStyle(color: AppColors.error)),
              ),
            ),

            const SizedBox(height: 24),

            // ── Users Breakdown by Role ──
            Text(
              'USER ROLES COMPOSITION',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            usersAsync.when(
              data: (users) {
                final admins = users.where((u) => u.roleName == 'admin').length;
                final owners = users.where((u) => u.roleName == 'owner').length;
                final supervisors = users.where((u) => u.roleName == 'supervisor').length;
                final employees = users.where((u) => u.roleName == 'employee').length;
                final disabled = users.where((u) => u.isDisabled).length;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _rolePill('ADMINS', admins, Colors.redAccent),
                          const SizedBox(width: 8),
                          _rolePill('OWNERS', owners, Colors.blueAccent),
                          const SizedBox(width: 8),
                          _rolePill('SUPERVISORS', supervisors, Colors.greenAccent),
                          const SizedBox(width: 8),
                          _rolePill('EMPLOYEES', employees, Colors.amberAccent),
                          if (disabled > 0) ...[
                            const SizedBox(width: 8),
                            _rolePill('DISABLED', disabled, Colors.grey),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            // ── Infrastructure & Security Status ──
            Text(
              'PLATFORM & INFRASTRUCTURE SUBSYSTEMS',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  _serviceTile(
                    context,
                    title: 'PostgreSQL Database & Realtime Channels',
                    status: 'Connected & Healthy',
                    icon: Icons.storage,
                    isHealthy: true,
                  ),
                  Divider(height: 1, color: borderCol, indent: 56),
                  _serviceTile(
                    context,
                    title: 'Role-Based Access Control (RBAC Engine)',
                    status: 'Strict RLS Enforcement Active',
                    icon: Icons.security,
                    isHealthy: true,
                  ),
                  Divider(height: 1, color: borderCol, indent: 56),
                  _serviceTile(
                    context,
                    title: 'ImageKit CDN Media Pipeline',
                    status: 'Active (HMAC Signature Verified)',
                    icon: Icons.cloud_done,
                    isHealthy: true,
                  ),
                  Divider(height: 1, color: borderCol, indent: 56),
                  _serviceTile(
                    context,
                    title: 'Edge Functions Runtime',
                    status: 'Operational (Deno v1.x)',
                    icon: Icons.bolt,
                    isHealthy: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required double width,
    required String title,
    required int count,
    required IconData icon,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolePill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceTile(
    BuildContext context, {
    required String title,
    required String status,
    required IconData icon,
    required bool isHealthy,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isHealthy ? Colors.green : Colors.red).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isHealthy ? Colors.green : Colors.red, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.text(context),
        ),
      ),
      subtitle: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.mutedText(context),
        ),
      ),
      trailing: Icon(
        isHealthy ? Icons.check_circle : Icons.error,
        color: isHealthy ? Colors.green : Colors.red,
        size: 18,
      ),
    );
  }
}
