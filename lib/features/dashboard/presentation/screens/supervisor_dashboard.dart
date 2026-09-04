import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/theme/app_colors.dart';
import 'package:ibuild/core/navigation/mobile_nav_helper.dart';
import 'package:ibuild/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:ibuild/features/dashboard/presentation/controllers/homepage_widgets_provider.dart';
import 'package:ibuild/features/dashboard/presentation/widgets/duolingo_widgets.dart';
import 'package:ibuild/features/dashboard/presentation/widgets/customize_dashboard_modal.dart';
import 'package:ibuild/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:ibuild/features/profile/presentation/screens/user_profile_screen.dart';

/// Dashboard shown to users with the 'supervisor' role.
/// Focuses on daily operations: attendance, inventory alerts, and project progress.
class SupervisorDashboard extends ConsumerWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activeWidgets = ref.watch(homepageWidgetsProvider).where((w) => w.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: MobileNavHelper.buildLeading(context),
        titleSpacing: MediaQuery.of(context).size.width < 800 ? 0 : 16,
        title: const Text(
          'Supervisor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined, color: AppColors.primary, size: 22),
            tooltip: 'Widget Options',
            onPressed: () => CustomizeDashboardModal.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Your daily operations overview',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UserProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text('My Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Stats Row
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
                      _buildStatCard(
                        context,
                        width: cardWidth,
                        icon: Icons.architecture,
                        label: 'Active Projects',
                        value: '${stats.activeProjects}',
                        color: AppColors.primary,
                      ),
                      _buildStatCard(
                        context,
                        width: cardWidth,
                        icon: Icons.people,
                        label: "Today's Attendance",
                        value: '${stats.employeesPresent}/${stats.totalEmployees}',
                        color: AppColors.secondary,
                      ),
                      _buildStatCard(
                        context,
                        width: cardWidth,
                        icon: Icons.inventory_2,
                        label: 'Low Stock Alerts',
                        value: '${stats.lowStockItems}',
                        color: stats.lowStockItems > 0
                            ? const Color(0xFFF44336)
                            : const Color(0xFF4CAF50),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const InventoryListScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Customizable Dashboard Widgets Header & Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.widgets_outlined,
                        size: 16,
                        color: AppColors.primaryColor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DASHBOARD WIDGETS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryColor(context),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => CustomizeDashboardModal.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryColor(context).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dashboard_customize_outlined,
                            size: 14,
                            color: AppColors.primaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Widget Options',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customizable Executive Widgets
              ...activeWidgets.map((cfg) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildCustomWidget(context, cfg.type, stats),
              )),

              // Recent Activity Section
              Container(
                padding: const EdgeInsets.all(20),
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
                        const Icon(
                          Icons.update,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (stats.recentActivities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No recent activity',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ...stats.recentActivities
                          .take(5)
                          .map(
                            (activity) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _activityColor(activity.type),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          activity.subtitle,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    double width = 200,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'add':
        return const Color(0xFF4CAF50);
      case 'edit':
        return const Color(0xFF2196F3);
      case 'delete':
        return const Color(0xFFF44336);
      default:
        return AppColors.outline;
    }
  }

  Widget _buildCustomWidget(
    BuildContext context,
    DashboardWidgetType type,
    dynamic stats,
  ) {
    switch (type) {
      case DashboardWidgetType.dailyStreak:
        return const DuolingoStreakWidget(streakDays: 14);
      case DashboardWidgetType.dailyQuests:
        return const DuolingoDailyQuestsWidget();
      case DashboardWidgetType.powerActions:
        return const DuolingoPowerActionsWidget();
      case DashboardWidgetType.safetyShield:
        return const DuolingoSafetyShieldWidget(safeDays: 64, safetyScore: 98.8);
      case DashboardWidgetType.materialRadar:
        return const DuolingoMaterialRadarWidget();
      case DashboardWidgetType.portfolioPulse:
        return const SizedBox.shrink();
      case DashboardWidgetType.projectHealth:
        return const SizedBox.shrink();
    }
  }
}
