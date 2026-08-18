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
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';
import 'project_form_screen.dart';
import 'project_dashboard_screen.dart';

class ProjectListScreen extends ConsumerWidget {
  final VoidCallback? onBackPressed;

  const ProjectListScreen({
    super.key,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectControllerProvider);
    final hasBack = onBackPressed != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: hasBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back',
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open navigation menu',
                  onPressed: () => Scaffold.maybeOf(ctx)?.openDrawer(),
                ),
              ),
        titleSpacing: 0,
        title: Text(
          'Projects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
          overflow: TextOverflow.ellipsis,
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
                subtitle:
                    'Summary of active enterprise sites & budget allocations',
                headers: [
                  'Project Name',
                  'Client',
                  'Status',
                  'Budget',
                  'Spent',
                  'Progress',
                  'Due Date',
                ],
                data: projects
                    .map(
                      (p) => [
                        p.name,
                        p.clientName ?? 'N/A',
                        p.status.toUpperCase(),
                        CurrencyFormatter.formatINR(p.budget),
                        CurrencyFormatter.formatINR(p.spent),
                        '${p.computedProgress.toInt()}%',
                        p.formattedDueDate,
                      ],
                    )
                    .toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename:
                    'IBUILD_Projects_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                headers: [
                  'Project Name',
                  'Client Name',
                  'Status',
                  'Budget (INR)',
                  'Spent (INR)',
                  'Progress %',
                  'Due Date',
                ],
                rows: projects
                    .map(
                      (p) => [
                        p.name,
                        p.clientName ?? 'N/A',
                        p.status.toUpperCase(),
                        p.budget,
                        p.spent,
                        p.computedProgress.toInt(),
                        p.formattedDueDate,
                      ],
                    )
                    .toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename:
                    'IBUILD_Projects_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            tooltip: 'Refresh Projects',
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
              hintText: 'Search projects by name or client...',
              onSearchChanged: (q) =>
                  ref.read(projectControllerProvider.notifier).setSearch(q),
              filterOptions: const [
                'active',
                'planning',
                'completed',
                'delayed',
                'at_risk',
              ],
              activeFilter: state.statusFilter,
              onFilterChanged: (f) => ref
                  .read(projectControllerProvider.notifier)
                  .setStatusFilter(f),
              sortOptions: const [
                'Recently Updated',
                'Project Name',
                'Budget',
                'Progress',
                'Due Date',
                'Status',
              ],
              onSortChanged: (s) {
                final map = {
                  'Recently Updated': 'recently_updated',
                  'Project Name': 'name',
                  'Budget': 'budget',
                  'Progress': 'progress',
                  'Due Date': 'due_date',
                  'Status': 'status',
                };
                ref
                    .read(projectControllerProvider.notifier)
                    .setSort(map[s] ?? 'recently_updated');
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
              emptyMessage:
                  'No projects found. Tap "+ New Project" to get started.',
              errorMessage: state.errorMessage,
              onRetry: () =>
                  ref.read(projectControllerProvider.notifier).loadProjects(),
              itemBuilder: (context, project) => _ProjectCard(
                project: project,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectDashboardScreen(
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

  Color _statusColor(String status, bool isAtRisk) {
    if (isAtRisk && status != 'completed') {
      return AppColors.warning;
    }
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.secondary;
      case 'completed':
        return const Color(0xFF10B981);
      case 'delayed':
        return AppColors.error;
      case 'at_risk':
        return AppColors.warning;
      case 'planning':
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAtRisk = project.isAtRisk;
    final statusCol = _statusColor(project.status, isAtRisk);
    final utilizationPct = project.budget > 0
        ? (project.spent / project.budget * 100).clamp(0.0, 200.0)
        : 0.0;
    final progressPct = project.computedProgress;
    final bool hasRecordedProgress =
        project.physicalProgress != null || project.status == 'completed';

    final String displayStatusText =
        (isAtRisk &&
            project.status != 'completed' &&
            project.status != 'delayed')
        ? 'AT RISK'
        : project.status.toUpperCase().replaceAll('_', ' ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Title & Status Badge ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project.clientName != null &&
                            project.clientName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            project.clientName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusCol.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: statusCol.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusCol,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          displayStatusText,
                          style: TextStyle(
                            color: statusCol,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Key Metrics Grid: Budget | Spent | Progress | Due Date ──
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      label: 'Budget',
                      value: CurrencyFormatter.formatINR(project.budget),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      label: 'Spent',
                      value: CurrencyFormatter.formatINR(project.spent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      label: 'Progress',
                      value: hasRecordedProgress
                          ? '${progressPct.toStringAsFixed(1)}%'
                          : '—',
                      valueColor: AppColors.primaryColor(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricItem(
                      context,
                      label: 'Due Date',
                      value: project.formattedDueDate,
                      badge: project.isOverdue
                          ? Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '⚠ ${project.daysOverdue}d overdue',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Construction Physical Progress Bar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Physical Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                  Text(
                    hasRecordedProgress
                        ? '${progressPct.toStringAsFixed(1)}%'
                        : '—',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hasRecordedProgress
                      ? (progressPct / 100).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: AppColors.border(context),
                  valueColor: AlwaysStoppedAnimation(
                    progressPct >= 100
                        ? const Color(0xFF10B981)
                        : AppColors.primaryColor(context),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: AppColors.border(context)),
              const SizedBox(height: 10),

              // ── Footer: Budget Used % | Updated By | View Project ──
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          project.budget > 0
                              ? 'Budget Used: ${utilizationPct.toStringAsFixed(1)}%'
                              : 'Budget Used: —',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: utilizationPct > 90
                                ? AppColors.error
                                : AppColors.text(context),
                          ),
                        ),
                        if (project.lastUpdatedBy != null) ...[
                          Text(
                            '•  Updated by: ${project.lastUpdatedBy}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ] else ...[
                          Text(
                            '•  Updated: ${project.formattedLastUpdated}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Text(
                      'View Project',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor(context),
                      ),
                    ),
                    label: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    Widget? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedText(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.text(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        ?badge,
      ],
    );
  }
}
