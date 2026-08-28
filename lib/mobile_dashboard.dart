import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/navigation/mobile_nav_helper.dart';
import 'core/utils/avatar_helper.dart';
import 'core/services/push_notification_service.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/activities/data/repositories/supabase_activity_repository.dart';
import 'core/widgets/notifications_dropdown.dart';
import 'core/widgets/offline_sync_indicator.dart';

import 'features/dashboard/presentation/widgets/dashboard_kpi_cards.dart';
import 'features/dashboard/presentation/widgets/project_portfolio_performance_widget.dart';
import 'features/dashboard/presentation/widgets/project_health_widget.dart';
import 'features/dashboard/presentation/widgets/attention_required_widget.dart';
import 'features/dashboard/presentation/widgets/portfolio_pulse_widget.dart';

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
            padding: EdgeInsets.only(right: 6),
            child: Center(
              child: OfflineSyncIndicator(isCompact: true),
            ),
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

            // 2. Dynamic Construction Portfolio Visualizations & Pulse
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portfolio Pulse Section
                  PortfolioPulseWidget(stats: stats),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Attention Required Alerts
                  AttentionRequiredWidget(
                    alerts: stats.attentionAlerts,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Project Portfolio Performance List
                  ProjectPortfolioPerformanceWidget(
                    projects: stats.portfolioProjects,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Project Health Donut Chart
                  ProjectHealthWidget(
                    projects: stats.portfolioProjects,
                  ),
                ],
              ),
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
}
