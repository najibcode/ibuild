import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/profile/presentation/screens/user_profile_screen.dart';

import 'features/dashboard/presentation/widgets/dashboard_kpi_cards.dart';
import 'features/dashboard/presentation/widgets/project_portfolio_performance_widget.dart';
import 'features/dashboard/presentation/widgets/project_health_widget.dart';
import 'features/dashboard/presentation/widgets/attention_required_widget.dart';
import 'features/dashboard/presentation/widgets/portfolio_pulse_widget.dart';

class WebDashboard extends ConsumerStatefulWidget {
  const WebDashboard({super.key});

  @override
  ConsumerState<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends ConsumerState<WebDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshAnimCtrl;

  @override
  void initState() {
    super.initState();
    _refreshAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _refreshAnimCtrl.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    _refreshAnimCtrl.forward(from: 0.0);
    ref.refresh(dashboardStatsProvider);
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
                    const Text(
                      'All Projects Portfolio Control Center',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _handleRefresh,
                      icon: RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0).animate(_refreshAnimCtrl),
                        child: const Icon(Icons.refresh, size: 18),
                      ),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.border(context)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('My Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.border(context)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 2. Executive KPI Cards Section ──
            const DashboardKPICards(),
            const SizedBox(height: 24),

            // ── 3. Main Portfolio Analytics, Pulse & Alerts ──
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Portfolio Pulse Section
                  PortfolioPulseWidget(stats: stats),
                  const SizedBox(height: 24),

                  // B. Attention Required Alerts Section
                  AttentionRequiredWidget(
                    alerts: stats.attentionAlerts,
                  ),
                  const SizedBox(height: 24),

                  // B. Project Performance List + Project Health Donut Chart
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 850) {
                        return Row(
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
                        );
                      } else {
                        return Column(
                          children: [
                            ProjectPortfolioPerformanceWidget(
                              projects: stats.portfolioProjects,
                            ),
                            const SizedBox(height: 20),
                            ProjectHealthWidget(
                              projects: stats.portfolioProjects,
                            ),
                          ],
                        );
                      }
                    },
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
                      onPressed: _handleRefresh,
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

}
