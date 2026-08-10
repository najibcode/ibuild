import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';
import '../../data/models/dashboard_stats_model.dart';

/// Project Portfolio Performance section displaying a compact ranked list of
/// all accessible projects with physical progress %, budget utilization %,
/// status badges, and clickable project navigation.
class ProjectPortfolioPerformanceWidget extends StatelessWidget {
  final List<PortfolioProjectItem> projects;

  const ProjectPortfolioPerformanceWidget({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROJECT PORTFOLIO PERFORMANCE',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Progress across all accessible projects',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${projects.length} Projects',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          if (projects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No portfolio projects available',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = projects[index];
                return _buildProjectRow(context, item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProjectRow(BuildContext context, PortfolioProjectItem item) {
    final statusColor = _getStatusColor(item);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(
              projectId: item.id,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Progress: ${item.physicalProgress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Spent: ${item.budgetUtilizationPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.displayStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Horizontal Progress Visualization (Physical Progress vs Budget Used)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    // Background track
                    Container(color: Colors.grey.withValues(alpha: 0.15)),
                    // Budget Used indicator
                    FractionallySizedBox(
                      widthFactor: (item.budgetUtilizationPct / 100).clamp(0.0, 1.0),
                      child: Container(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    // Physical Progress main bar
                    FractionallySizedBox(
                      widthFactor: (item.physicalProgress / 100).clamp(0.0, 1.0),
                      child: Container(color: statusColor),
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

  Color _getStatusColor(PortfolioProjectItem item) {
    if (item.status == 'completed') return const Color(0xFF4CAF50);
    if (item.status == 'delayed') return AppColors.error;
    if (item.status == 'at_risk' || item.variancePct > 15.0) return AppColors.error;
    if (item.status == 'planning') return Colors.orange;
    return const Color(0xFF2196F3);
  }
}
