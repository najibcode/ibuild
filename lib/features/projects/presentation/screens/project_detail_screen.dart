import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';
import 'project_form_screen.dart';
import '../../../daily_progress/presentation/screens/daily_progress_screen.dart';

final projectDetailProvider = FutureProvider.family<Project?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(projectRepositoryProvider);
  return await repo.getProjectById(id);
});

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Project not found')),
          );
        }
        return _ProjectDetailBody(project: project);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _ProjectDetailBody extends ConsumerWidget {
  final Project project;
  const _ProjectDetailBody({required this.project});

  void _onArchive(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive Project'),
        content: Text(
          'Archive "${project.name}"? It will be hidden from the main list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(projectControllerProvider.notifier).archive(project.id);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (_) {
        if (context.mounted) {
          _showOperationError(context, 'Could not archive the project.');
        }
      }
    }
  }

  void _onDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Permanently delete "${project.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref
            .read(projectControllerProvider.notifier)
            .removeProject(project.id);
        if (context.mounted) Navigator.of(context).pop();
      } catch (_) {
        if (context.mounted) {
          _showOperationError(context, 'Could not delete the project.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilization = project.budgetUtilization;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectFormScreen(project: project),
                ),
              );
              ref.invalidate(projectDetailProvider(project.id));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'archive') _onArchive(context, ref);
              if (val == 'delete') _onDelete(context, ref);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'archive', child: Text('Archive')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              mainAxisSpacing: AppSpacing.stackMd,
              crossAxisSpacing: AppSpacing.stackMd,
              children: [
                StatCard(
                  icon: Icons.payments,
                  value: '₹${_fmt(project.budget)}',
                  label: 'Total Budget',
                ),
                StatCard(
                  icon: Icons.trending_up,
                  value: '₹${_fmt(project.spent)}',
                  label: 'Amount Spent',
                  badge: '${(utilization * 100).toInt()}%',
                  badgeColor: utilization > 0.9
                      ? AppColors.error
                      : AppColors.secondary,
                ),
                StatCard(
                  icon: Icons.calculate,
                  value: '₹${_fmt(project.estimatedCost)}',
                  label: 'Estimated Cost',
                ),
                StatCard(
                  icon: Icons.receipt_long,
                  value: '₹${_fmt(project.currentCost)}',
                  label: 'Current Cost',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Project Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _infoRow('Client', project.clientName ?? '-'),
                  _infoRow('Code', project.projectCode ?? '-'),
                  _infoRow('Address', project.address ?? '-'),
                  _infoRow('Start Date', project.startDate ?? '-'),
                  _infoRow(
                    'Expected Completion',
                    project.expectedCompletion ?? '-',
                  ),
                  _infoRow('Status', project.status.toUpperCase()),
                  if (project.description != null &&
                      project.description!.isNotEmpty)
                    _infoRow('Scope', project.description!),
                  if (project.notes != null && project.notes!.isNotEmpty)
                    _infoRow('Notes', project.notes!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.containerMargin),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyProgressScreen(
                      projectId: project.id,
                      projectName: project.name,
                    ),
                  ),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Daily Site Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  void _showOperationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}
