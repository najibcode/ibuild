import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/navigation/mobile_nav_helper.dart';
import 'core/utils/avatar_helper.dart';
import 'core/services/push_notification_service.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/dashboard/presentation/controllers/homepage_widgets_provider.dart';
import 'features/dashboard/presentation/widgets/duolingo_widgets.dart';
import 'features/dashboard/presentation/widgets/customize_dashboard_modal.dart';
import 'features/activities/data/repositories/supabase_activity_repository.dart';
import 'core/widgets/notifications_dropdown.dart';
import 'core/widgets/offline_sync_indicator.dart';
import 'core/services/home_widget_sync_service.dart';

import 'features/dashboard/presentation/widgets/dashboard_kpi_cards.dart';
import 'features/dashboard/presentation/widgets/project_portfolio_performance_widget.dart';
import 'features/dashboard/presentation/widgets/project_health_widget.dart';
import 'features/dashboard/presentation/widgets/attention_required_widget.dart';
import 'features/dashboard/presentation/widgets/portfolio_pulse_widget.dart';
import 'features/dashboard/data/models/dashboard_stats_model.dart';

import 'features/auth/presentation/controllers/auth_controller.dart';

class MobileDashboard extends ConsumerWidget {
  final VoidCallback onViewProjects;
  final VoidCallback onViewTrack;
  final VoidCallback onViewSupply;
  final VoidCallback? onMenuPressed;

  const MobileDashboard({
    super.key,
    required this.onViewProjects,
    required this.onViewTrack,
    required this.onViewSupply,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mount push notification realtime listener on mobile dashboard
    ref.read(pushNotificationServiceProvider).initializeRealtimeListener(context);

    final statsAsync = ref.watch(dashboardStatsProvider);
    final authState = ref.watch(authControllerProvider);
    final activeWidgets = ref.watch(homepageWidgetsProvider).where((w) => w.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final profile = authState.profile;

    final displayName = profile?['full_name'] as String? ??
        (authState.user?.email?.split('@').first ?? 'Business Owner');
    final avatarUrl = RoleAvatarHelper.getAvatarUrl(
      customAvatarUrl: profile?['avatar_url'] as String?,
      role: profile?['role'] as String?,
      email: authState.user?.email,
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: MobileNavHelper.buildLeading(
          context,
          onBackPressed: null,
        ),
        titleSpacing: MediaQuery.of(context).size.width < 800 ? 0 : 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                  ? NetworkImage(avatarUrl)
                  : null,
              onBackgroundImageError: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                  ? (exception, stackTrace) {}
                  : null,
              child: (avatarUrl.isEmpty || !avatarUrl.startsWith('http'))
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome,',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(
              child: OfflineSyncIndicator(isCompact: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined, color: AppColors.primary, size: 22),
            tooltip: 'Widget Options',
            onPressed: () => CustomizeDashboardModal.show(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.containerMargin),
            child: Consumer(
              builder: (context, ref, _) {
                final unreadAsync = ref.watch(unreadNotificationsCountProvider);
                final count = unreadAsync.valueOrNull ?? 0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (ctx) => Container(
                            height: MediaQuery.of(ctx).size.height * 0.65,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Site Activity Notifications',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppColors.text(ctx),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const Expanded(child: NotificationsDropdown()),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerMargin,
          vertical: AppSpacing.stackMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dynamic Executive KPI Cards Grid
            DashboardKPICards(
              onTapTotalProjects: onViewProjects,
              onTapActiveProjects: onViewProjects,
              onTapCompletedProjects: onViewProjects,
              onTapAtRiskProjects: onViewProjects,
              onTapTotalProjectValue: onViewProjects,
              onTapTotalSpent: onViewTrack,
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // 2. Render Active Customizable Widgets with Header & Options
            statsAsync.when(
              data: (stats) {
                // Sync live metrics to Android Home Screen Widget (AppWidget)
                HomeWidgetSyncService.syncDashboardStats(stats);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header with prominent Widget Options button
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
                    const SizedBox(height: AppSpacing.stackSm),

                    // Fallback when no widgets are active
                    if (activeWidgets.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.dashboard_customize_outlined,
                              size: 36,
                              color: AppColors.primaryColor(context).withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No Active Widgets',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customize your homepage to add streaks, quick actions, safety metrics, and live radars.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => CustomizeDashboardModal.show(context),
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: const Text('Configure Widgets'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor(context),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                    ],

                    for (final widgetCfg in activeWidgets) ...[
                      _buildCustomWidget(
                        context,
                        widgetCfg.type,
                        stats,
                        onViewProjects: onViewProjects,
                        onViewTrack: onViewTrack,
                        onViewSupply: onViewSupply,
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                    ],

                    // Attention Required Alerts (always displayed if alerts present)
                    if (stats.attentionAlerts.isNotEmpty) ...[
                      AttentionRequiredWidget(alerts: stats.attentionAlerts),
                      const SizedBox(height: AppSpacing.sectionGap),
                    ],

                    // Project Portfolio Performance List
                    ProjectPortfolioPerformanceWidget(projects: stats.portfolioProjects),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Unable to load dashboard data: $e',
                  style: const TextStyle(color: AppColors.textMuted),
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
    DashboardStats stats, {
    required VoidCallback onViewProjects,
    required VoidCallback onViewTrack,
    required VoidCallback onViewSupply,
  }) {
    switch (type) {
      case DashboardWidgetType.dailyStreak:
        return DuolingoStreakWidget(
          streakDays: 14,
          onTap: onViewTrack,
        );
      case DashboardWidgetType.dailyQuests:
        return const DuolingoDailyQuestsWidget();
      case DashboardWidgetType.powerActions:
        return DuolingoPowerActionsWidget(
          onAttendance: onViewTrack,
          onDailyProgress: onViewTrack,
          onSnags: onViewProjects,
          onExpenses: onViewTrack,
        );
      case DashboardWidgetType.safetyShield:
        return const DuolingoSafetyShieldWidget(
          safeDays: 64,
          safetyScore: 98.8,
        );
      case DashboardWidgetType.materialRadar:
        return DuolingoMaterialRadarWidget(
          onRestockTap: onViewSupply,
        );
      case DashboardWidgetType.portfolioPulse:
        return PortfolioPulseWidget(stats: stats);
      case DashboardWidgetType.projectHealth:
        return ProjectHealthWidget(projects: stats.portfolioProjects);
    }
  }
}
