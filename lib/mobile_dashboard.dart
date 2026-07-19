import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';

class MobileDashboard extends ConsumerWidget {
  final VoidCallback onViewProjects;
  final VoidCallback onViewTrack;
  final VoidCallback onViewSupply;

  const MobileDashboard({
    super.key,
    required this.onViewProjects,
    required this.onViewTrack,
    required this.onViewSupply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCCZjuOoP8-6MOOMrALPsgiKEd5USwzMqGfIaIQWjWcvyG4adhn7Hcd5dQ8vVX7OqxycfYIMrY7aditONBZI9t468aYqVhsEQDG_r5OIiIvjo_2bFixKxk8eDAuWUuM7KVoIFpcC8DseRW1Toy89Ts3N78FWfKk_VT04Vus7TmwDYc8DMTF_yK6QQgeCCZ8NgqJeIjl_Y7typ63ZU7hi5XS9hj94bf6FUL5y5AyukSNdjhtqLpykWALhbglsHhiqjW-wTOlwRK3vhc',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Good morning,',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                Text(
                  'Master Admin',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.containerMargin),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: AppColors.primary),
                  onPressed: () {},
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.stackMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.25,
                mainAxisSpacing: AppSpacing.stackMd,
                crossAxisSpacing: AppSpacing.stackMd,
                children: [
                  _buildKPICard(
                    context: context,
                    icon: Icons.architecture,
                    value: '${stats.activeProjects}',
                    label: 'Active Projects',
                    badgeText: '+${stats.activeProjects} Active',
                    badgeColor: AppColors.secondary,
                    onTap: onViewProjects,
                  ),
                  _buildKPICard(
                    context: context,
                    icon: Icons.group,
                    value: '${stats.employeesPresent}',
                    label: 'Workers Present',
                    badgeText: 'Active Today',
                    badgeColor: AppColors.secondary,
                    onTap: () {},
                  ),
                  _buildKPICard(
                    context: context,
                    icon: Icons.pending_actions,
                    value: '${stats.lowStockItems}',
                    label: 'Low Stock Materials',
                    badgeText: stats.lowStockItems > 0 ? 'Action Required' : 'All Stock OK',
                    badgeColor: stats.lowStockItems > 0 ? AppColors.error : AppColors.secondary,
                    onTap: onViewSupply,
                  ),
                  _buildBudgetKPICard(
                    context: context,
                    icon: Icons.payments,
                    value: stats.monthlyExpense >= 100000
                        ? '₹${(stats.monthlyExpense / 100000).toStringAsFixed(1)}L'
                        : '₹${stats.monthlyExpense.toStringAsFixed(0)}',
                    label: 'Total Expenses',
                    progress: stats.monthlyExpense > 0
                        ? (stats.monthlyExpense / 2000000.0).clamp(0.0, 1.0)
                        : 0.0,
                    onTap: onViewTrack,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // Project Velocity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Operational Metrics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: onViewTrack,
                    child: const Text('View details'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Container(
                height: 180,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 10,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: [
                      _makeBarGroup(0, stats.activeProjects.toDouble().clamp(0.0, 10.0), false),
                      _makeBarGroup(1, stats.completedProjects.toDouble().clamp(0.0, 10.0), false),
                      _makeBarGroup(2, stats.totalProjects.toDouble().clamp(0.0, 10.0), false),
                      _makeBarGroup(3, (stats.employeesPresent / 10.0).clamp(0.0, 10.0), false),
                      _makeBarGroup(4, stats.lowStockItems.toDouble().clamp(0.0, 10.0), false),
                      _makeBarGroup(5, (stats.pendingBills / 100000.0).clamp(0.0, 10.0), false),
                      _makeBarGroup(6, (stats.monthlyExpense / 200000.0).clamp(0.0, 10.0), true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // Recent Activity Section
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildActivityItem(
                    icon: Icons.check_circle,
                    iconColor: AppColors.secondary,
                    bgColor: const Color(0x1F10B981),
                    title: 'Materials Delivered',
                    time: '2m ago',
                    subtitle: 'Concrete slab order #492 arrived at Sector 7-G.',
                    tags: ['Completed', 'Logistics'],
                    onTap: onViewSupply,
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  _buildActivityItem(
                    icon: Icons.warning,
                    iconColor: AppColors.warning,
                    bgColor: const Color(0x1FFFDD5F),
                    title: 'Labor Shortage Alert',
                    time: '1h ago',
                    subtitle: 'Site B reporting 15% lower attendance than scheduled.',
                    tags: ['Critical', 'HR'],
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  _buildActivityItem(
                    icon: Icons.description,
                    iconColor: AppColors.primary,
                    bgColor: const Color(0x1FDDE1FF),
                    title: 'New Plan Uploaded',
                    time: '3h ago',
                    subtitle: 'Architect updated the electrical schematics for Phase 2.',
                    tags: ['Update', 'Design'],
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading dashboard stats: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: const Icon(Icons.add),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, bool isActive) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isActive ? AppColors.primary : AppColors.primaryContainer.withOpacity(0.2),
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetKPICard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required double progress,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String time,
    required String subtitle,
    required List<String> tags,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: tags.map((tag) {
                      final bool isHighlight = tag == 'Completed' || tag == 'Critical';
                      final Color tagColor = isHighlight
                          ? (tag == 'Critical' ? AppColors.error : AppColors.secondary)
                          : AppColors.textMuted;
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: tagColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
