import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/dashboard/presentation/controllers/homepage_widgets_provider.dart';
import 'features/dashboard/presentation/widgets/duolingo_widgets.dart';
import 'features/dashboard/presentation/widgets/customize_dashboard_modal.dart';
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
    ref.invalidate(dashboardStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activeWidgets = ref.watch(homepageWidgetsProvider).where((w) => w.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

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
                    ElevatedButton.icon(
                      onPressed: () => CustomizeDashboardModal.show(context),
                      icon: const Icon(Icons.dashboard_customize_rounded, size: 18, color: Colors.white),
                      label: const Text('Widget Options', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor(context),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 8),
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

            // ── 3. Render Active Customizable Widgets ──
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final widgetCfg in activeWidgets) ...[
                    _buildCustomWidget(context, widgetCfg.type, stats),
                    const SizedBox(height: 20),
                  ],

                  // Attention Required Alerts Section (if any alerts)
                  if (stats.attentionAlerts.isNotEmpty) ...[
                    AttentionRequiredWidget(alerts: stats.attentionAlerts),
                    const SizedBox(height: 24),
                  ],

                  // Project Performance List + Project Health Donut Chart
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
        return PortfolioPulseWidget(stats: stats);
      case DashboardWidgetType.projectHealth:
        return ProjectHealthWidget(projects: stats.portfolioProjects);
    }
  }
}
