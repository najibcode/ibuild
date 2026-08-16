import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../projects/presentation/screens/project_form_screen.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../controllers/dashboard_controller.dart';

/// Comprehensive KPI Cards Grid for the IBUILD Overall Dashboard.
/// Displays 6 dynamic metrics from Supabase with responsive layouts,
/// INR currency formatting, skeleton loading, error retry, and empty states.
class DashboardKPICards extends ConsumerWidget {
  final VoidCallback? onTapTotalProjects;
  final VoidCallback? onTapActiveProjects;
  final VoidCallback? onTapCompletedProjects;
  final VoidCallback? onTapAtRiskProjects;
  final VoidCallback? onTapTotalProjectValue;
  final VoidCallback? onTapTotalSpent;

  const DashboardKPICards({
    super.key,
    this.onTapTotalProjects,
    this.onTapActiveProjects,
    this.onTapCompletedProjects,
    this.onTapAtRiskProjects,
    this.onTapTotalProjectValue,
    this.onTapTotalSpent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildDataView(context, ref, stats),
      loading: () => _buildLoadingSkeleton(context),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );
  }

  Widget _buildDataView(BuildContext context, WidgetRef ref, DashboardStats stats) {
    if (stats.totalProjects == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmptyState(context),
          const SizedBox(height: 16),
          _buildResponsiveGrid(context, stats),
        ],
      );
    }

    return _buildResponsiveGrid(context, stats);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_business, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No projects yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create your first project to start tracking your construction portfolio.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProjectFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(
            'Unable to load dashboard data.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please check your connection and try again.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: crossAxisCount >= 6 ? 1.6 : 1.7,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) => _skeletonCard(context),
        );
      },
    );
  }

  Widget _skeletonCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 70,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Container(
            width: 90,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 80,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 720) return 3;
    if (width >= 450) return 2;
    return 2;
  }

  Widget _buildResponsiveGrid(BuildContext context, DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final cards = _buildCardList(context, stats);

        final double aspectRatio = crossAxisCount >= 6
            ? 1.55
            : (crossAxisCount == 3
                ? 1.55
                : (constraints.maxWidth < 400 ? 1.18 : 1.25));

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  List<Widget> _buildCardList(BuildContext context, DashboardStats stats) {
    final valueText = CurrencyFormatter.formatINR(stats.totalProjectValue);
    final spentText = CurrencyFormatter.formatINR(stats.totalSpent);

    return [
      // KPI 1 — Total Projects
      _kpiCard(
        context,
        label: 'Total Projects',
        value: '${stats.totalProjects}',
        subtitle: 'Portfolio total',
        icon: Icons.domain,
        iconColor: AppColors.primary,
        onTap: onTapTotalProjects,
        semanticsLabel: 'Total Projects: ${stats.totalProjects}',
      ),

      // KPI 2 — Active Projects
      _kpiCard(
        context,
        label: 'Active Projects',
        value: '${stats.activeProjects}',
        subtitle: 'In progress',
        icon: Icons.architecture,
        iconColor: const Color(0xFF2196F3),
        onTap: onTapActiveProjects,
        semanticsLabel: 'Active Projects: ${stats.activeProjects}',
      ),

      // KPI 3 — Completed
      _kpiCard(
        context,
        label: 'Completed',
        value: '${stats.completedProjects}',
        subtitle: 'Successfully delivered',
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF4CAF50),
        onTap: onTapCompletedProjects,
        semanticsLabel: 'Completed Projects: ${stats.completedProjects}',
      ),

      // KPI 4 — At Risk
      _kpiCard(
        context,
        label: 'At Risk',
        value: '${stats.atRiskProjects}',
        subtitle: stats.atRiskProjects > 0 ? 'Requires attention' : 'All on track',
        icon: Icons.warning_amber_rounded,
        iconColor: stats.atRiskProjects > 0 ? AppColors.error : const Color(0xFF4CAF50),
        onTap: onTapAtRiskProjects,
        semanticsLabel: 'At Risk Projects: ${stats.atRiskProjects}',
      ),

      // KPI 5 — Total Project Value
      _kpiCard(
        context,
        label: 'Total Project Value',
        value: valueText,
        subtitle: 'Across ${stats.totalProjects} projects',
        icon: Icons.account_balance_wallet,
        iconColor: AppColors.primary,
        onTap: onTapTotalProjectValue,
        semanticsLabel: 'Total Project Value: $valueText',
      ),

      // KPI 6 — Total Spent
      _kpiCard(
        context,
        label: 'Total Spent',
        value: spentText,
        subtitle: 'Across all accessible projects',
        icon: Icons.payments,
        iconColor: AppColors.primary,
        onTap: onTapTotalSpent,
        semanticsLabel: 'Total Spent: $spentText',
      ),
    ];
  }

  Widget _kpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    required String semanticsLabel,
  }) {
    final isClickable = onTap != null;

    return Semantics(
      label: semanticsLabel,
      button: isClickable,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(icon, color: iconColor, size: 20),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                          height: 1.1,
                        ),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
