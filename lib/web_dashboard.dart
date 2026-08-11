import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/dashboard/data/models/dashboard_stats_model.dart';
import 'features/profile/presentation/screens/user_profile_screen.dart';

import 'features/dashboard/presentation/widgets/dashboard_kpi_cards.dart';
import 'features/dashboard/presentation/widgets/project_portfolio_performance_widget.dart';
import 'features/dashboard/presentation/widgets/project_health_widget.dart';
import 'features/dashboard/presentation/widgets/project_performance_matrix_widget.dart';
import 'features/dashboard/presentation/widgets/portfolio_progress_trend_widget.dart';
import 'features/dashboard/presentation/widgets/attention_required_widget.dart';
import 'features/dashboard/presentation/widgets/budget_utilization_widget.dart';
import 'features/dashboard/presentation/widgets/inventory_alerts_widget.dart';

class WebDashboard extends ConsumerStatefulWidget {
  const WebDashboard({super.key});

  @override
  ConsumerState<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends ConsumerState<WebDashboard> {
  Timer? _realtimeTicker;

  @override
  void initState() {
    super.initState();
    // Auto-refresh portfolio stats every 2 seconds for real-time updates without clicking reload buttons
    _realtimeTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        ref.refresh(dashboardStatsProvider);
      }
    });
  }

  @override
  void dispose() {
    _realtimeTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Portfolio Overview Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Overview',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overall Dashboard — All Projects Portfolio',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildOutlineButton(
                      context,
                      Icons.refresh,
                      'Refresh',
                      onPressed: () {
                        ref.refresh(dashboardStatsProvider);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildOutlineButton(
                      context,
                      Icons.person_outline,
                      'My Profile',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UserProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 2. KPI Cards Section ──
            const DashboardKPICards(),
            const SizedBox(height: 24),

            // ── Dynamic Construction Portfolio BI Visualizations ──
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3 & 4: Project Portfolio Performance + Project Health
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ProjectPortfolioPerformanceWidget(
                          projects: stats.portfolioProjects,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: ProjectHealthWidget(
                          projects: stats.portfolioProjects,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5. Project Performance Matrix (Scatter BI Chart)
                  ProjectPerformanceMatrixWidget(
                    projects: stats.portfolioProjects,
                  ),
                  const SizedBox(height: 24),

                  // 6. Portfolio Progress Over Time (Trend Line Chart)
                  PortfolioProgressTrendWidget(
                    trends: stats.progressTrends,
                  ),
                  const SizedBox(height: 24),

                  // 7. Attention Required (Actionable Alerts)
                  AttentionRequiredWidget(
                    alerts: stats.attentionAlerts,
                  ),
                  const SizedBox(height: 24),

                  // 8 & 9. Budget Utilization + Inventory Alerts
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: BudgetUtilizationWidget(
                          projects: stats.portfolioProjects,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: InventoryAlertsWidget(
                          alerts: stats.inventoryAlerts,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 10. Recent Activity Feed
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentActivityList(
                    context,
                    stats.recentActivities,
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unable to load dashboard data: $e',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(dashboardStatsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Formats a number in Indian currency shorthand.
  static String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
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
      case 'add':
        return Icons.add_circle_outline;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete_outline;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'progress':
        return Icons.trending_up;
      case 'expense':
        return Icons.account_balance_wallet;
      case 'bill':
        return Icons.receipt_long;
      case 'attendance':
        return Icons.how_to_reg;
      default:
        return Icons.info_outline;
    }
  }

  /// Maps activity type to a color.
  static Color _activityColor(String type) {
    switch (type) {
      case 'add':
        return AppColors.secondary;
      case 'edit':
        return AppColors.primary;
      case 'delete':
        return AppColors.error;
      case 'inventory':
        return AppColors.warning;
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

  Widget _buildOutlineButton(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 14, color: AppColors.text(context)),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.border(context)),
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
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
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
                  color: AppColors.primaryColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor(context),
                  size: 20,
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.mutedText(context),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityChart(BuildContext context, List<int> weeklyCounts) {
    final maxVal = weeklyCounts.isEmpty
        ? 1.0
        : (weeklyCounts.reduce(
            (a, b) => a > b ? a : b,
          )).toDouble().clamp(1.0, double.infinity);

    // Day labels for last 7 days
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));

    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dayIdx =
                            (weekAgo.weekday - 1 + value.toInt()) % 7;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayLabels[dayIdx],
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
    );
  }

  Widget _buildRecentActivityList(
    BuildContext context,
    List<RecentActivity> activities,
  ) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
        color: Theme.of(context).colorScheme.surface,
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
                        color: AppColors.textMain,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
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
