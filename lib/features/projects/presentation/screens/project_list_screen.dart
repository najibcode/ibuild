import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/paginated_list.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/date_range_filter_helper.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';
import 'project_form_screen.dart';
import 'project_operations_screen.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: Text(
          'Projects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final projects = DateRangeFilterHelper.filter(
                state.projects,
                start: start,
                end: end,
                getDate: (p) => p.createdAt,
              );
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Projects Portfolio Report',
                subtitle: 'Summary of active enterprise sites & budget allocations',
                headers: ['Project Name', 'Client', 'Status', 'Allocated Budget (INR)', 'Spent (INR)', 'Utilization'],
                data: projects.map((p) => [
                  p.name,
                  p.clientName ?? 'N/A',
                  p.status.toUpperCase(),
                  'INR ${p.budget.toStringAsFixed(2)}',
                  'INR ${p.spent.toStringAsFixed(2)}',
                  '${(p.budgetUtilization * 100).toStringAsFixed(1)}%'
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Projects_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final projects = DateRangeFilterHelper.filter(
                state.projects,
                start: start,
                end: end,
                getDate: (p) => p.createdAt,
              );
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Projects',
                title: 'Projects Directory & Budget Outflow',
                headers: ['Project Name', 'Client Name', 'Status', 'Budget (INR)', 'Spent (INR)', 'Utilization %'],
                rows: projects.map((p) => [
                  p.name,
                  p.clientName ?? 'N/A',
                  p.status.toUpperCase(),
                  p.budget,
                  p.spent,
                  (p.budgetUtilization * 100).toStringAsFixed(1)
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Projects_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.primaryColor(context)),
            tooltip: 'New Project',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () =>
                ref.read(projectControllerProvider.notifier).loadProjects(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProjectFormScreen())),
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.stackSm,
              AppSpacing.containerMargin,
              0,
            ),
            child: SearchFilterBar(
              hintText: 'Search projects...',
              onSearchChanged: (q) =>
                  ref.read(projectControllerProvider.notifier).setSearch(q),
              filterOptions: const [
                'active',
                'inactive',
                'planning',
                'completed',
                'delayed',
              ],
              activeFilter: state.statusFilter,
              onFilterChanged: (f) => ref
                  .read(projectControllerProvider.notifier)
                  .setStatusFilter(f),
              sortOptions: const ['Name', 'Budget', 'Date'],
              onSortChanged: (s) {
                final map = {
                  'Name': 'name',
                  'Budget': 'budget',
                  'Date': 'created_at',
                };
                ref
                    .read(projectControllerProvider.notifier)
                    .setSort(map[s] ?? 'created_at');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Expanded(
            child: PaginatedListView<Project>(
              items: state.projects,
              isLoading: state.isLoading,
              hasMore: state.hasMore,
              onLoadMore: () =>
                  ref.read(projectControllerProvider.notifier).loadMore(),
              emptyMessage: 'No projects found. Create one!',
              errorMessage: state.errorMessage,
              onRetry: () =>
                  ref.read(projectControllerProvider.notifier).loadProjects(),
              itemBuilder: (context, project) => _ProjectCard(
                project: project,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectOperationsScreen(
                      projectId: project.id,
                      projectName: project.name,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
      case 'active':
        return AppColors.secondary;
      case 'completed':
        return AppColors.primary;
      case 'delayed':
        return AppColors.error;
      default:
        return AppColors.warning;
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.text(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      project.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (project.clientName != null) ...[
                const SizedBox(height: 4),
                Text(
                  project.clientName!,
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Budget progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Budget: ₹${_formatAmount(project.budget)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(utilization * 100).toInt()}% used',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: utilization > 0.9
                          ? AppColors.error
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: utilization.clamp(0.0, 1.0),
                  backgroundColor: AppColors.border(context),
                  valueColor: AlwaysStoppedAnimation(
                    utilization > 0.9
                        ? AppColors.error
                        : AppColors.primaryColor(context),
                  ),
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
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
