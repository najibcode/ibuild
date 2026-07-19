import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/dashboard/data/models/dashboard_stats_model.dart';

class WebDashboard extends ConsumerWidget {
  const WebDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Portfolio Overview Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Overview',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats.activeProjects} active projects across all sites.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildOutlineButton(Icons.refresh, 'Refresh', onPressed: () {
                        ref.invalidate(dashboardStatsProvider);
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── KPI Cards Grid ──
              Row(
                children: [
                  // Card 1: Total Budget
                  Expanded(
                    child: _buildKPICard(
                      context: context,
                      icon: Icons.payments,
                      value: '₹${_formatCurrency(stats.totalBudget)}',
                      label: 'Total Budget',
                      trend: '${stats.budgetUtilizationPct.toStringAsFixed(1)}% utilized',
                      trendColor: stats.budgetUtilizationPct > 90
                          ? AppColors.error
                          : AppColors.secondary,
                      subtitle: 'Spent ₹${_formatCurrency(stats.totalSpent)}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Card 2: Workers Present
                  Expanded(
                    child: _buildKPICard(
                      context: context,
                      icon: Icons.group,
                      value: '${stats.employeesPresent}',
                      label: 'Workers Present',
                      trend: '${stats.attendancePct.toStringAsFixed(0)}% attendance',
                      trendColor: stats.attendancePct >= 80
                          ? AppColors.secondary
                          : AppColors.warning,
                      subtitle: 'of ${stats.totalEmployees} total employees',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Card 3: Delayed Projects
                  Expanded(
                    child: _buildKPICard(
                      context: context,
                      icon: Icons.pending_actions,
                      value: '${stats.delayedProjects}',
                      label: 'Delayed Projects',
                      trend: stats.delayedProjects > 0 ? 'Needs Attention' : 'All On Track',
                      trendColor: stats.delayedProjects > 0
                          ? AppColors.error
                          : AppColors.secondary,
                      subtitle: '${stats.activeProjects} active projects',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Card 4: Active Projects
                  Expanded(
                    child: _buildKPICard(
                      context: context,
                      icon: Icons.architecture,
                      value: '${stats.activeProjects}',
                      label: 'Active Projects',
                      trend: '${stats.completedProjects} completed',
                      trendColor: AppColors.secondary,
                      subtitle: '${stats.planningProjects} in planning',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Financial Summary Row ──
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      context: context,
                      icon: Icons.account_balance_wallet,
                      value: '₹${_formatCurrency(stats.monthlyExpense)}',
                      label: 'This Month Expenses',
                      trend: stats.pendingBills > 0
                          ? '₹${_formatCurrency(stats.pendingBills)} pending'
                          : 'All cleared',
                      trendColor: stats.pendingBills > 0
                          ? AppColors.warning
                          : AppColors.secondary,
                      subtitle: 'Pending bills amount',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKPICard(
                      context: context,
                      icon: Icons.inventory_2,
                      value: '${stats.lowStockItems}',
                      label: 'Low Stock Items',
                      trend: stats.lowStockItems > 0 ? 'Restock Needed' : 'Stock OK',
                      trendColor: stats.lowStockItems > 0
                          ? AppColors.error
                          : AppColors.secondary,
                      subtitle: 'Items below minimum threshold',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Empty spacers to maintain 4-column grid
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 32),

              // ── Double Column Section ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Velocity Chart + Quick Access
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Site Activity (Last 7 Days)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildVelocityChart(context, stats.weeklyProgressCounts),
                        const SizedBox(height: 32),
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickAccessCard(context, stats.latestProject),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Column: Recent Activity
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecentActivityList(context, stats.recentActivities),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load dashboard: $e',
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Formats a number in Indian currency shorthand.
  static String _formatCurrency(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  /// Returns a human-readable time-ago string.
  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Maps activity type to an icon.
  static IconData _activityIcon(String type) {
    switch (type) {
      case 'expense':
        return Icons.account_balance_wallet;
      case 'bill':
        return Icons.receipt_long;
      case 'progress':
        return Icons.trending_up;
      case 'attendance':
        return Icons.how_to_reg;
      default:
        return Icons.info;
    }
  }

  /// Maps activity type to a color.
  static Color _activityColor(String type) {
    switch (type) {
      case 'expense':
        return AppColors.warning;
      case 'bill':
        return AppColors.primary;
      case 'progress':
        return AppColors.secondary;
      case 'attendance':
        return AppColors.primary;
      default:
        return AppColors.textMuted;
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildOutlineButton(IconData icon, String label,
      {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 14, color: AppColors.textMain),
      label: Text(
        label,
        style: const TextStyle(
            color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildKPICard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required String trend,
    required Color trendColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                        color: trendColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityChart(BuildContext context, List<int> weeklyCounts) {
    final maxVal = weeklyCounts.isEmpty
        ? 1.0
        : (weeklyCounts.reduce((a, b) => a > b ? a : b)).toDouble().clamp(1.0, double.infinity);

    // Day labels for last 7 days
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));

    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: weeklyCounts.every((c) => c == 0)
          ? const Center(
              child: Text(
                'No site progress logged in the last 7 days',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIdx, rod, rodIdx) {
                      final dayIdx = (weekAgo.weekday - 1 + group.x) % 7;
                      return BarTooltipItem(
                        '${dayLabels[dayIdx]}: ${rod.toY.toInt()} entries',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dayIdx = (weekAgo.weekday - 1 + value.toInt()) % 7;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabels[dayIdx],
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(7, (i) {
                  final isToday = i == 6;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyCounts[i].toDouble(),
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primaryContainer.withValues(alpha: 0.3),
                        width: 28,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }),
              ),
            ),
    );
  }

  Widget _buildQuickAccessCard(
      BuildContext context, QuickAccessProject? project) {
    if (project == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textMuted),
            SizedBox(width: 12),
            Text(
              'No active projects yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final utilPct = project.budget > 0
        ? (project.spent / project.budget * 100).toStringAsFixed(0)
        : '0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.apartment, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_capitalize(project.status)} • ₹${_formatCurrency(project.budget)} budget • $utilPct% utilized',
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(
      BuildContext context, List<RecentActivity> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.inbox, color: AppColors.textMuted, size: 32),
                SizedBox(height: 8),
                Text(
                  'No recent activity',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          for (int i = 0; i < activities.length; i++) ...[
            _buildActivityItem(
              icon: _activityIcon(activities[i].type),
              iconColor: _activityColor(activities[i].type),
              title: activities[i].title,
              time: _timeAgo(activities[i].timestamp),
              subtitle: activities[i].subtitle,
            ),
            if (i < activities.length - 1)
              const Divider(color: AppColors.borderSubtle, height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textMain),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
