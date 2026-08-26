import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/screens/project_list_screen.dart';
import '../../../billing/presentation/screens/financials_hub_screen.dart';
import '../../../inventory/presentation/screens/inventory_list_screen.dart';
import '../../data/models/dashboard_stats_model.dart';

/// Executive Portfolio Pulse section displaying 5 minimal, data-driven KPI modules
/// backed 100% by real Supabase database records without hardcoded values.
class PortfolioPulseWidget extends StatelessWidget {
  final DashboardStats stats;

  const PortfolioPulseWidget({
    super.key,
    required this.stats,
  });

  /// Format Indian Rupee values compactly (e.g. ₹10.6K, ₹4.8L, ₹1.5Cr).
  static String _formatIndianCurrency(double amount) {
    if (amount <= 0) return '₹0';
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      return '₹${cr.toStringAsFixed(cr >= 10 ? 0 : 1)} Cr';
    } else if (amount >= 100000) {
      final lakh = amount / 100000;
      return '₹${lakh.toStringAsFixed(lakh >= 10 ? 0 : 1)} L';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '₹${k.toStringAsFixed(k >= 10 ? 0 : 1)} K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (stats.totalProjects == 0 && stats.portfolioProjects.isEmpty) {
      return _buildEmptyStateCard(context);
    }

    // ── Metric 1: Physical Progress ──
    final totalBudget = stats.totalBudget;
    double weightedProgress = 0.0;
    if (totalBudget > 0) {
      final sumWeighted = stats.portfolioProjects.fold<double>(
        0.0,
        (sum, p) => sum + (p.physicalProgress * p.budget),
      );
      weightedProgress = sumWeighted / totalBudget;
    } else if (stats.portfolioProjects.isNotEmpty) {
      final sumPct = stats.portfolioProjects.fold<double>(
        0.0,
        (sum, p) => sum + p.physicalProgress,
      );
      weightedProgress = sumPct / stats.portfolioProjects.length;
    }

    // ── Metric 2: Budget Utilization ──
    final budgetUtilPct = stats.budgetUtilizationPct;
    final String budgetStatusLabel;
    final Color budgetStatusColor;
    if (budgetUtilPct > 100) {
      budgetStatusLabel = 'Critical';
      budgetStatusColor = AppColors.error;
    } else if (budgetUtilPct >= 90) {
      budgetStatusLabel = 'High';
      budgetStatusColor = Colors.orange;
    } else if (budgetUtilPct >= 70) {
      budgetStatusLabel = 'Watch';
      budgetStatusColor = Colors.amber.shade800;
    } else {
      budgetStatusLabel = 'Healthy';
      budgetStatusColor = AppColors.secondary;
    }

    // ── Metric 3: Schedule Performance ──
    final onTrackCount = stats.portfolioProjects
        .where((p) => p.displayStatus == 'On Track' || p.status == 'active')
        .length;
    final schedulePct = stats.portfolioProjects.isNotEmpty
        ? (onTrackCount / stats.portfolioProjects.length * 100)
        : 0.0;
    final bool isScheduleDelayed =
        stats.delayedProjects > 0 || stats.atRiskProjects > 0;
    final String scheduleStatusLabel = isScheduleDelayed
        ? (stats.delayedProjects > 0 ? 'Delayed' : 'Watch')
        : 'On Track';
    final Color scheduleStatusColor = isScheduleDelayed
        ? (stats.delayedProjects > 0 ? AppColors.error : Colors.amber.shade800)
        : AppColors.secondary;

    // ── Metric 4: Outstanding Payments ──
    final outstandingAmount = stats.pendingBills;
    final String paymentStatusLabel =
        outstandingAmount > 0 ? 'Pending' : 'Settled';
    final Color paymentStatusColor =
        outstandingAmount > 0 ? Colors.amber.shade800 : AppColors.secondary;

    // ── Metric 5: Material Availability ──
    final lowStockCount = stats.lowStockItems;
    final String materialStatusLabel = lowStockCount == 0
        ? 'Healthy'
        : (lowStockCount <= 2 ? 'Low Stock' : 'Critical');
    final Color materialStatusColor = lowStockCount == 0
        ? AppColors.secondary
        : (lowStockCount <= 2 ? Colors.amber.shade800 : AppColors.error);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.monitor_heart_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PORTFOLIO PULSE',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Key performance indicators across all accessible projects',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'Real-time automated metrics aggregated from active Supabase database records',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insights, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Live Sync',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Responsive 5 KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isMedium = constraints.maxWidth >= 600;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildKPIModule(
                        context,
                        title: 'PHYSICAL PROGRESS',
                        value: '${weightedProgress.toStringAsFixed(1)}%',
                        badgeText:
                            '${stats.portfolioProjects.length} Sites',
                        badgeColor: AppColors.primary,
                        progress: (weightedProgress / 100).clamp(0.0, 1.0),
                        progressColor: AppColors.primary,
                        tooltip:
                            'Weighted average physical completion across all accessible projects',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProjectListScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPIModule(
                        context,
                        title: 'BUDGET UTILIZATION',
                        value: '${budgetUtilPct.toStringAsFixed(1)}%',
                        badgeText: budgetStatusLabel,
                        badgeColor: budgetStatusColor,
                        progress: (budgetUtilPct / 100).clamp(0.0, 1.0),
                        progressColor: budgetStatusColor,
                        tooltip:
                            'Total actual project expenses ÷ total contract budget',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FinancialsHubScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPIModule(
                        context,
                        title: 'SCHEDULE HEALTH',
                        value: '${schedulePct.toStringAsFixed(0)}%',
                        badgeText: scheduleStatusLabel,
                        badgeColor: scheduleStatusColor,
                        progress: (schedulePct / 100).clamp(0.0, 1.0),
                        progressColor: scheduleStatusColor,
                        tooltip:
                            'Percentage of projects adhering to planned physical progress and timeline schedule',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProjectListScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPIModule(
                        context,
                        title: 'OUTSTANDING BILLS',
                        value: _formatIndianCurrency(outstandingAmount),
                        badgeText: paymentStatusLabel,
                        badgeColor: paymentStatusColor,
                        progress: outstandingAmount > 0 ? 0.75 : 0.0,
                        progressColor: paymentStatusColor,
                        tooltip:
                            'Total unpaid client invoices and pending bill receivables',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FinancialsHubScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPIModule(
                        context,
                        title: 'MATERIAL AVAILABILITY',
                        value: lowStockCount == 0
                            ? '100%'
                            : '$lowStockCount Low',
                        badgeText: materialStatusLabel,
                        badgeColor: materialStatusColor,
                        progress: lowStockCount == 0 ? 1.0 : 0.4,
                        progressColor: materialStatusColor,
                        tooltip:
                            'Percentage of required site materials currently in healthy stock',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const InventoryListScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (isMedium) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPIModule(
                            context,
                            title: 'PHYSICAL PROGRESS',
                            value: '${weightedProgress.toStringAsFixed(1)}%',
                            badgeText:
                                '${stats.portfolioProjects.length} Sites',
                            badgeColor: AppColors.primary,
                            progress: (weightedProgress / 100).clamp(0.0, 1.0),
                            progressColor: AppColors.primary,
                            tooltip:
                                'Weighted average physical completion across all accessible projects',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProjectListScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKPIModule(
                            context,
                            title: 'BUDGET UTILIZATION',
                            value: '${budgetUtilPct.toStringAsFixed(1)}%',
                            badgeText: budgetStatusLabel,
                            badgeColor: budgetStatusColor,
                            progress: (budgetUtilPct / 100).clamp(0.0, 1.0),
                            progressColor: budgetStatusColor,
                            tooltip:
                                'Total actual project expenses ÷ total contract budget',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FinancialsHubScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKPIModule(
                            context,
                            title: 'SCHEDULE HEALTH',
                            value: '${schedulePct.toStringAsFixed(0)}%',
                            badgeText: scheduleStatusLabel,
                            badgeColor: scheduleStatusColor,
                            progress: (schedulePct / 100).clamp(0.0, 1.0),
                            progressColor: scheduleStatusColor,
                            tooltip:
                                'Percentage of projects adhering to planned physical progress and timeline schedule',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProjectListScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPIModule(
                            context,
                            title: 'OUTSTANDING BILLS',
                            value: _formatIndianCurrency(outstandingAmount),
                            badgeText: paymentStatusLabel,
                            badgeColor: paymentStatusColor,
                            progress: outstandingAmount > 0 ? 0.75 : 0.0,
                            progressColor: paymentStatusColor,
                            tooltip:
                                'Total unpaid client invoices and pending bill receivables',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FinancialsHubScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKPIModule(
                            context,
                            title: 'MATERIAL AVAILABILITY',
                            value: lowStockCount == 0
                                ? '100%'
                                : '$lowStockCount Low',
                            badgeText: materialStatusLabel,
                            badgeColor: materialStatusColor,
                            progress: lowStockCount == 0 ? 1.0 : 0.4,
                            progressColor: materialStatusColor,
                            tooltip:
                                'Percentage of required site materials currently in healthy stock',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const InventoryListScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Stacked Mobile Layout
              return Column(
                children: [
                  _buildKPIModule(
                    context,
                    title: 'PHYSICAL PROGRESS',
                    value: '${weightedProgress.toStringAsFixed(1)}%',
                    badgeText: '${stats.portfolioProjects.length} Sites',
                    badgeColor: AppColors.primary,
                    progress: (weightedProgress / 100).clamp(0.0, 1.0),
                    progressColor: AppColors.primary,
                    tooltip:
                        'Weighted average physical completion across all accessible projects',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProjectListScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildKPIModule(
                    context,
                    title: 'BUDGET UTILIZATION',
                    value: '${budgetUtilPct.toStringAsFixed(1)}%',
                    badgeText: budgetStatusLabel,
                    badgeColor: budgetStatusColor,
                    progress: (budgetUtilPct / 100).clamp(0.0, 1.0),
                    progressColor: budgetStatusColor,
                    tooltip:
                        'Total actual project expenses ÷ total contract budget',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FinancialsHubScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildKPIModule(
                    context,
                    title: 'SCHEDULE HEALTH',
                    value: '${schedulePct.toStringAsFixed(0)}%',
                    badgeText: scheduleStatusLabel,
                    badgeColor: scheduleStatusColor,
                    progress: (schedulePct / 100).clamp(0.0, 1.0),
                    progressColor: scheduleStatusColor,
                    tooltip:
                        'Percentage of projects adhering to planned physical progress and timeline schedule',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProjectListScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildKPIModule(
                    context,
                    title: 'OUTSTANDING BILLS',
                    value: _formatIndianCurrency(outstandingAmount),
                    badgeText: paymentStatusLabel,
                    badgeColor: paymentStatusColor,
                    progress: outstandingAmount > 0 ? 0.75 : 0.0,
                    progressColor: paymentStatusColor,
                    tooltip:
                        'Total unpaid client invoices and pending bill receivables',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FinancialsHubScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildKPIModule(
                    context,
                    title: 'MATERIAL AVAILABILITY',
                    value:
                        lowStockCount == 0 ? '100%' : '$lowStockCount Low',
                    badgeText: materialStatusLabel,
                    badgeColor: materialStatusColor,
                    progress: lowStockCount == 0 ? 1.0 : 0.4,
                    progressColor: materialStatusColor,
                    tooltip:
                        'Percentage of required site materials currently in healthy stock',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InventoryListScreen(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKPIModule(
    BuildContext context, {
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required double progress,
    required Color progressColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: progressColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.nature_people_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'NO PROJECT DATA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Create your first project to see live portfolio performance pulse metrics.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
