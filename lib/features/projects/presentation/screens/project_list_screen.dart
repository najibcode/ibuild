import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/paginated_list.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: const Text('Projects', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(projectControllerProvider.notifier).loadProjects(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin, AppSpacing.stackSm, AppSpacing.containerMargin, 0,
            ),
            child: SearchFilterBar(
              hintText: 'Search projects...',
              onSearchChanged: (q) => ref.read(projectControllerProvider.notifier).setSearch(q),
              filterOptions: const ['planning', 'active', 'completed', 'delayed'],
              activeFilter: state.statusFilter,
              onFilterChanged: (f) => ref.read(projectControllerProvider.notifier).setStatusFilter(f),
              sortOptions: const ['Name', 'Budget', 'Date'],
              onSortChanged: (s) {
                final map = {'Name': 'name', 'Budget': 'budget', 'Date': 'created_at'};
                ref.read(projectControllerProvider.notifier).setSort(map[s] ?? 'created_at');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Expanded(
            child: PaginatedListView<Project>(
              items: state.projects,
              isLoading: state.isLoading,
              hasMore: state.hasMore,
              onLoadMore: () => ref.read(projectControllerProvider.notifier).loadMore(),
              emptyMessage: 'No projects found. Create one!',
              errorMessage: state.errorMessage,
              onRetry: () => ref.read(projectControllerProvider.notifier).loadProjects(),
              itemBuilder: (context, project) => _ProjectCard(
                project: project,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppColors.secondary;
      case 'completed': return AppColors.primary;
      case 'delayed': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(project.status);
    final utilization = project.budgetUtilization;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      project.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (project.clientName != null) ...[
                const SizedBox(height: 4),
                Text(project.clientName!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              // Budget progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget: ₹${_formatAmount(project.budget)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('${(utilization * 100).toInt()}% used', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: utilization > 0.9 ? AppColors.error : AppColors.secondary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: utilization.clamp(0.0, 1.0),
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(utilization > 0.9 ? AppColors.error : AppColors.primary),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
