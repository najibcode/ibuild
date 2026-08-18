import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/project_dashboard_model.dart';
import '../controllers/project_dashboard_controller.dart';
import 'project_operations_screen.dart';
import 'project_form_screen.dart';
import 'project_detail_screen.dart';
import '../../../daily_progress/presentation/screens/daily_progress_screen.dart';
import '../../../expenses/presentation/screens/expense_form_screen.dart';
import '../../../snags/presentation/screens/snag_list_screen.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDashboardScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(projectDashboardProvider(widget.projectId));
    final projectDetailAsync =
        ref.watch(projectDetailProvider(widget.projectId));

    final effectiveName = widget.projectName.isNotEmpty
        ? widget.projectName
        : (dashAsync.valueOrNull?.projectName.isNotEmpty == true
            ? dashAsync.valueOrNull!.projectName
            : 'Project Dashboard');

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          effectiveName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              ref.invalidate(projectDashboardProvider(widget.projectId));
              ref.invalidate(projectDetailProvider(widget.projectId));
            },
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.primaryColor(context),
            ),
            tooltip: 'Edit Project Details',
            onPressed: () async {
              final currentProject = projectDetailAsync.valueOrNull;
              if (currentProject != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectFormScreen(project: currentProject),
                  ),
                );
                ref.invalidate(projectDashboardProvider(widget.projectId));
                ref.invalidate(projectDetailProvider(widget.projectId));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project details are loading...')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading project telemetry...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Unable to load dashboard data:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.refresh(projectDashboardProvider(widget.projectId)),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => _DashboardBody(stats: stats, projectId: widget.projectId),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final ProjectDashboardStats stats;
  final String projectId;

  const _DashboardBody({required this.stats, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isUltraWide = constraints.maxWidth > 1200;
        final isWide = constraints.maxWidth > 850;
        final isMedium = constraints.maxWidth > 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1800),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Project Header & Quick Actions ──
                  _SafeSection(
                    builder: () => _buildProjectHeader(context, isDark),
                  ),
                  const SizedBox(height: 20),

                  // ── Financial KPI Section ──
                  _SafeSection(
                    builder: () => _buildKPIRow(context, isWide, isMedium),
                  ),
                  const SizedBox(height: 24),

                  // ── Performance (Budget vs Actual + Project Health) ──
                  _SafeSection(
                    builder: () {
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildBudgetVsActualBar(context, isDark),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildProjectHealthSection(context, isDark),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBudgetVsActualBar(context, isDark),
                            const SizedBox(height: 16),
                            _buildProjectHealthSection(context, isDark),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── 7-Day Progress Trend Sparkline ──
                  _SafeSection(
                    builder: () => _buildProgressSparkline(context, isDark),
                  ),
                  const SizedBox(height: 24),

                  // ── Financial Analysis (Budget Donut + Expense Breakdown) ──
                  _SafeSection(
                    builder: () {
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildBudgetDonut(context, isDark),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _buildExpenseBreakdown(context, isDark),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBudgetDonut(context, isDark),
                            const SizedBox(height: 16),
                            _buildExpenseBreakdown(context, isDark),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Variance Analysis & Attention Required ──
                  _SafeSection(
                    builder: () {
                      if (isUltraWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildVarianceAnalysisCard(context, isDark),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAttentionRequiredSection(
                                context,
                                isDark,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVarianceAnalysisCard(context, isDark),
                            const SizedBox(height: 20),
                            _buildAttentionRequiredSection(context, isDark),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Summary Metrics Row ──
                  _SafeSection(
                    builder: () {
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildAttendanceCard(context, isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildChecklistCard(context, isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPaymentCard(context, isDark)),
                          ],
                        );
                      } else if (isMedium) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildAttendanceCard(context, isDark)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildChecklistCard(context, isDark)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPaymentCard(context, isDark),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildAttendanceCard(context, isDark),
                            const SizedBox(height: 16),
                            _buildChecklistCard(context, isDark),
                            const SizedBox(height: 16),
                            _buildPaymentCard(context, isDark),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Construction Stages & Milestones Tracker ──
                  _SafeSection(
                    builder: () => _buildMilestonesTrackerCard(context, isDark),
                  ),
                  const SizedBox(height: 24),

                  // ── Cashflow & Runway Forecast ──
                  _SafeSection(
                    builder: () => _buildCashflowForecastCard(context, isDark),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Activity ──
                  _SafeSection(
                    builder: () => _buildRecentActivity(context, isDark),
                  ),
                  const SizedBox(height: 24),

                  // ── Operational Module Shortcuts Grid (All 10 Modules) ──
                  _SafeSection(
                    builder: () => _buildOperationalModuleGrid(context),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PROJECT HEADER & QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProjectHeader(BuildContext context, bool isDark) {
    final statusColor = _statusColor(stats.status);
    final displayName = stats.projectName.isNotEmpty
        ? stats.projectName
        : 'Project Overview';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2744), const Color(0xFF0F1C33)]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName.substring(0, 1).toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            stats.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.displayClient,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedText(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stats.address != null && stats.address!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.mutedText(context),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                stats.address!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (stats.startDate != null)
                    _dateChip(context, 'Start', stats.startDate!),
                  if (stats.expectedCompletion != null) ...[
                    const SizedBox(height: 4),
                    _dateChip(context, 'Target Due', stats.expectedCompletion!),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.border(context).withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          // Quick Actions Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickActionButton(
                  context,
                  label: '+ Log Expense',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primaryColor(context),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpenseFormScreen(initialProjectId: projectId),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _quickActionButton(
                  context,
                  label: '+ Daily Progress',
                  icon: Icons.camera_alt_outlined,
                  color: AppColors.secondary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyProgressScreen(
                        projectId: projectId,
                        projectName: stats.projectName,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _quickActionButton(
                  context,
                  label: '+ Attendance',
                  icon: Icons.people_outline,
                  color: const Color(0xFF059669),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectOperationsScreen(
                        projectId: projectId,
                        projectName: stats.projectName,
                        initialSection: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _quickActionButton(
                  context,
                  label: '+ Quality Punch / Snag',
                  icon: Icons.bug_report_outlined,
                  color: const Color(0xFFDC2626),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SnagListScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _quickActionButton(
                  context,
                  label: '+ Drawings & Mapping',
                  icon: Icons.architecture_outlined,
                  color: const Color(0xFF0284C7),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectOperationsScreen(
                        projectId: projectId,
                        projectName: stats.projectName,
                        initialSection: 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _quickActionButton(
                  context,
                  label: 'Project Operations',
                  icon: Icons.dashboard_customize_outlined,
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectOperationsScreen(
                        projectId: projectId,
                        projectName: stats.projectName,
                        initialSection: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(BuildContext context, String label, String date) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
        ),
        Text(
          date,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.text(context),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. FINANCIAL KPI CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKPIRow(BuildContext context, bool isWide, bool isMedium) {
    final utilPct =
        stats.budgetUtilizationPct.isNaN ||
            stats.budgetUtilizationPct.isInfinite
        ? 0.0
        : stats.budgetUtilizationPct;

    final cards = [
      _KPIData(
        icon: Icons.payments_outlined,
        value: CurrencyFormatter.formatCompact(stats.budget),
        label: 'Total Budget',
        subValue: stats.budget > 0
            ? 'Total: ${CurrencyFormatter.formatFullINR(stats.budget)}'
            : '₹0 Budget allocated',
        badge: utilPct > 0 && utilPct < 1
            ? '${utilPct.toStringAsFixed(1)}%'
            : '${utilPct.toInt()}%',
        badgeColor: utilPct > 90 ? AppColors.error : AppColors.secondary,
        iconColor: AppColors.primary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
      ),
      _KPIData(
        icon: Icons.trending_up_outlined,
        value: CurrencyFormatter.formatCompact(stats.spent),
        label: 'Amount Spent',
        subValue: stats.spent > 0
            ? 'Spent: ${CurrencyFormatter.formatFullINR(stats.spent)}'
            : '₹0 recorded spent',
        iconColor: utilPct > 90 ? AppColors.error : const Color(0xFF059669),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
      ),
      _KPIData(
        icon: Icons.account_balance_outlined,
        value: CurrencyFormatter.formatCompact(stats.remainingBalance),
        label: 'Remaining Balance',
        subValue: 'Balance: ${CurrencyFormatter.formatFullINR(stats.remainingBalance)}',
        iconColor: stats.remainingBalance >= 0
            ? const Color(0xFF059669)
            : AppColors.error,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 7,
            ),
          ),
        ),
      ),
      _KPIData(
        icon: Icons.calculate_outlined,
        value: CurrencyFormatter.formatCompact(stats.estimatedCost),
        label: 'Estimated Cost',
        subValue: 'Current: ${CurrencyFormatter.formatCompact(stats.currentCost)}',
        iconColor: const Color(0xFF7C3AED),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 2,
            ),
          ),
        ),
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .expand(
              (c) => [
                Expanded(child: _buildKPICard(context, c)),
                if (c != cards.last) const SizedBox(width: 16),
              ],
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double childAspectRatio = isMedium
            ? 1.45
            : (constraints.maxWidth < 400 ? 1.25 : 1.35);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMedium ? 4 : 2,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: cards.map((c) => _buildKPICard(context, c)).toList(),
        );
      },
    );
  }

  Widget _buildKPICard(BuildContext context, _KPIData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: data.iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(data.icon, color: data.iconColor, size: 18),
                  ),
                  if (data.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (data.badgeColor ?? AppColors.secondary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        data.badge!,
                        style: TextStyle(
                          color: data.badgeColor ?? AppColors.secondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.mutedText(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 9,
                    color: AppColors.mutedText(context),
                  ),
                ],
              ),
              if (data.subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  data.subValue!,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.mutedText(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. BUDGET VS ACTUAL & PROJECT HEALTH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBudgetVsActualBar(BuildContext context, bool isDark) {
    final budget = stats.budget;
    final spent = stats.spent;
    final remaining = stats.remainingBalance;
    final maxVal = budget > 0 ? budget : (spent > 0 ? spent : 1.0);
    final spentPct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final hasHighVar = stats.hasHighVariance;

    return _DashboardCard(
      title: 'Budget vs Actual Performance',
      subtitle:
          'Spent: ${CurrencyFormatter.formatFullINR(spent)} of ${CurrencyFormatter.formatFullINR(budget)} (Balance: ${CurrencyFormatter.formatFullINR(remaining)})',
      action: TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
        icon: const Icon(Icons.arrow_forward, size: 12),
        label: const Text('View Outflows', style: TextStyle(fontSize: 11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _barRow(context, 'Total Budget', budget, maxVal, AppColors.primary),
          const SizedBox(height: 12),
          _barRow(
            context,
            'Actual Spent',
            spent,
            maxVal,
            spentPct > 0.9 ? AppColors.error : AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _barRow(
            context,
            'Remaining Balance',
            remaining > 0 ? remaining : 0,
            maxVal,
            const Color(0xFF059669),
          ),
          if (hasHighVar) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Financial Variance Warning: Budget used (${stats.budgetUtilizationPct.toInt()}%) is ahead of physical progress (${stats.computedProgress.toInt()}%).',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _barRow(
    BuildContext context,
    String label,
    double value,
    double maxVal,
    Color color,
  ) {
    final pct = maxVal > 0 ? (value / maxVal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${_fmt(value)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.border(context),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectHealthSection(BuildContext context, bool isDark) {
    final budgetHealth = stats.spent > stats.budget && stats.budget > 0
        ? ('Exceeded', AppColors.error)
        : stats.hasHighVariance
        ? ('Attention', AppColors.warning)
        : ('On Track', const Color(0xFF10B981));

    final progressHealth = stats.computedProgress >= 50
        ? ('On Track', const Color(0xFF10B981))
        : stats.computedProgress > 0
        ? ('In Progress', AppColors.secondary)
        : ('Not Recorded', AppColors.mutedText(context));

    final scheduleHealth = stats.status == 'delayed'
        ? ('Delayed', AppColors.error)
        : ('On Track', const Color(0xFF10B981));

    final paymentsHealth = stats.pendingPayments > 0
        ? ('₹${_fmt(stats.pendingPayments)} Pending', AppColors.warning)
        : ('On Track', const Color(0xFF10B981));

    return _DashboardCard(
      title: 'Project Health & Governance',
      child: Column(
        children: [
          _healthRow(
            context,
            'Budget Outflow',
            budgetHealth.$1,
            budgetHealth.$2,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectOperationsScreen(
                  projectId: projectId,
                  projectName: stats.projectName,
                  initialSection: 4,
                ),
              ),
            ),
          ),
          Divider(height: 16, color: AppColors.border(context)),
          _healthRow(
            context,
            'Physical Progress',
            progressHealth.$1,
            progressHealth.$2,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DailyProgressScreen(
                  projectId: projectId,
                  projectName: stats.projectName,
                ),
              ),
            ),
          ),
          Divider(height: 16, color: AppColors.border(context)),
          _healthRow(
            context,
            'Schedule Health',
            scheduleHealth.$1,
            scheduleHealth.$2,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectOperationsScreen(
                  projectId: projectId,
                  projectName: stats.projectName,
                  initialSection: 9,
                ),
              ),
            ),
          ),
          Divider(height: 16, color: AppColors.border(context)),
          _healthRow(
            context,
            'Payments Status',
            paymentsHealth.$1,
            paymentsHealth.$2,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectOperationsScreen(
                  projectId: projectId,
                  projectName: stats.projectName,
                  initialSection: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthRow(
    BuildContext context,
    String title,
    String status,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppColors.mutedText(context),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. ZERO-SAFE 7-DAY SITE PROGRESS SPARKLINE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressSparkline(BuildContext context, bool isDark) {
    final rawCounts = stats.weeklyProgressCounts;
    final counts = rawCounts.length == 7 ? rawCounts : List.filled(7, 0);
    final totalUpdates = counts.fold<int>(0, (sum, v) => sum + v);

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final dayLabels = List.generate(7, (i) {
      final d = weekAgo.add(Duration(days: i));
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    });

    final maxVal = counts.fold<int>(0, (max, v) => v > max ? v : max).toDouble();
    final chartMax = maxVal > 0 ? maxVal + 1.0 : 4.0;

    return _DashboardCard(
      title: '7-Day Site Activity Trend',
      subtitle: totalUpdates > 0
          ? '$totalUpdates updates recorded in the last 7 days'
          : 'No daily updates recorded this week yet',
      action: TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyProgressScreen(
              projectId: projectId,
              projectName: stats.projectName,
            ),
          ),
        ),
        icon: const Icon(Icons.add_a_photo_outlined, size: 12),
        label: const Text('Add Progress Log', style: TextStyle(fontSize: 11)),
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: chartMax > 4 ? 2 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.border(context).withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: chartMax > 4 ? 2 : 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.mutedText(context),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= dayLabels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dayLabels[idx],
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: chartMax,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  7,
                  (i) => FlSpot(i.toDouble(), counts[i].toDouble()),
                ),
                isCurved: totalUpdates > 0, // Safe: straight lines when flat 0
                curveSmoothness: 0.25,
                color: totalUpdates > 0
                    ? AppColors.primaryColor(context)
                    : AppColors.mutedText(context).withValues(alpha: 0.4),
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: totalUpdates > 0 ? 4 : 3,
                        color: totalUpdates > 0
                            ? AppColors.primaryColor(context)
                            : AppColors.border(context),
                        strokeWidth: 2,
                        strokeColor: AppColors.cardBg(context),
                      ),
                ),
                belowBarData: BarAreaData(
                  show: totalUpdates > 0,
                  color: AppColors.primaryColor(
                    context,
                  ).withValues(alpha: 0.08),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.cardBg(context),
                getTooltipItems: (spots) => spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()} updates',
                    TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. ZERO-SAFE CUSTOM BUDGET DONUT GAUGE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBudgetDonut(BuildContext context, bool isDark) {
    final rawUtil = stats.budgetUtilization;
    final utilization = (rawUtil.isNaN || rawUtil.isInfinite ? 0.0 : rawUtil).clamp(0.0, 2.0);
    final spentColor = utilization > 1.0
        ? AppColors.error
        : utilization > 0.8
        ? AppColors.warning
        : AppColors.secondary;

    final utilPctInt = (utilization * 100).toInt();

    return _DashboardCard(
      title: 'Budget Utilization',
      subtitle: stats.budget > 0
          ? '₹${_fmt(stats.spent)} of ₹${_fmt(stats.budget)} utilized'
          : '₹${_fmt(stats.spent)} spent (No budget set)',
      child: SizedBox(
        height: 200,
        child: Center(
          child: CustomPaint(
            size: const Size(180, 180),
            painter: _BudgetDonutPainter(
              progress: utilization.clamp(0.0, 1.0),
              isOverBudget: utilization > 1.0,
              trackColor: AppColors.border(context),
              progressColor: spentColor,
            ),
            child: SizedBox(
              width: 180,
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$utilPctInt%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: spentColor,
                      ),
                    ),
                    Text(
                      utilization > 1.0 ? 'Over Budget' : 'Utilized',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. EXPENSE BREAKDOWN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExpenseBreakdown(BuildContext context, bool isDark) {
    final categories = stats.expenseBreakdown.take(6).toList();
    final maxAmount = categories.isNotEmpty ? categories.first.amount : 1.0;

    return _DashboardCard(
      title: 'Expense Breakdown',
      subtitle: 'Total: ₹${_fmt(stats.totalExpenses)} across categories',
      action: TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
        icon: const Icon(Icons.arrow_forward, size: 12),
        label: const Text('View All Expenses', style: TextStyle(fontSize: 11)),
      ),
      child: categories.isEmpty
          ? SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 40,
                      color: AppColors.mutedText(
                        context,
                      ).withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No expenses recorded yet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExpenseFormScreen(initialProjectId: projectId),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Log First Expense', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: categories.map((cat) {
                final pct = maxAmount > 0 ? cat.amount / maxAmount : 0.0;
                final color = _categoryColor(cat.category);
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectOperationsScreen(
                        projectId: projectId,
                        projectName: stats.projectName,
                        initialSection: 4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.category,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${_fmt(cat.amount)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: AppColors.border(context),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. VARIANCE ANALYSIS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVarianceAnalysisCard(BuildContext context, bool isDark) {
    final utilPct = stats.budgetUtilizationPct;
    final physPct = stats.computedProgress;
    final variance = utilPct - physPct;
    final isAheadOfProgress = variance > 15.0;
    final isAheadOfBudget = variance < -15.0;

    final String interpretation = isAheadOfProgress
        ? 'Spending is ahead of physical site progress. Review pending subcontractor bills and material utilization.'
        : isAheadOfBudget
        ? 'Physical progress is progressing ahead of budget outflow. Site execution is on schedule.'
        : 'Financial outflow is broadly aligned with physical site milestone completion.';

    final Color interpretationColor = isAheadOfProgress
        ? AppColors.warning
        : isAheadOfBudget
        ? const Color(0xFF10B981)
        : AppColors.primaryColor(context);

    return _DashboardCard(
      title: 'Budget vs Physical Progress Variance',
      subtitle: 'Comparison of financial outflow to site execution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _varianceMetric(
                context,
                'Budget Used',
                '${utilPct.toInt()}%',
                AppColors.primary,
              ),
              _varianceMetric(
                context,
                'Physical Done',
                '${physPct.toInt()}%',
                const Color(0xFF10B981),
              ),
              _varianceMetric(
                context,
                'Variance',
                '${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)}%',
                variance > 15.0 ? AppColors.error : AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: interpretationColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: interpretationColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAheadOfProgress
                      ? Icons.warning_amber_rounded
                      : isAheadOfBudget
                      ? Icons.trending_up
                      : Icons.check_circle_outline,
                  color: interpretationColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    interpretation,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: interpretationColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _varianceMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. ATTENTION REQUIRED SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAttentionRequiredSection(BuildContext context, bool isDark) {
    final List<
      ({
        String title,
        String message,
        IconData icon,
        Color color,
        VoidCallback onTap,
      })
    >
    alerts = [];

    if (stats.hasHighVariance) {
      alerts.add((
        title: 'High Financial Variance',
        message:
            'Budget utilization (${stats.budgetUtilizationPct.toInt()}%) is ahead of physical progress (${stats.computedProgress.toInt()}%).',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
      ));
    }

    if (stats.spent > stats.budget && stats.budget > 0) {
      alerts.add((
        title: 'Budget Exceeded',
        message:
            'Total spent (₹${_fmt(stats.spent)}) exceeds approved project budget (₹${_fmt(stats.budget)}).',
        icon: Icons.error_outline,
        color: AppColors.error,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
      ));
    }

    if (stats.pendingPayments > 0) {
      alerts.add((
        title: 'Pending Payments',
        message:
            '₹${_fmt(stats.pendingPayments)} in customer receivables or trade balances pending.',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
      ));
    }

    if (stats.openIssuesCount > 0) {
      alerts.add((
        title: 'Quality Punch Items Open',
        message: '${stats.openIssuesCount} snag defect tickets active on site.',
        icon: Icons.bug_report_outlined,
        color: const Color(0xFFDC2626),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SnagListScreen(),
          ),
        ),
      ));
    }

    return _DashboardCard(
      title: 'Attention Required',
      subtitle: '${alerts.length} active site notifications',
      child: alerts.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'All tracked project indicators are healthy and on track.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: alerts.map((a) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: a.onTap,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: a.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(a.icon, color: a.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: a.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: a.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. ATTENDANCE CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAttendanceCard(BuildContext context, bool isDark) {
    final hasWorkers = stats.totalAssigned > 0;
    final rawPct = stats.attendancePct;
    final pct = (rawPct.isNaN || rawPct.isInfinite ? 0.0 : rawPct).clamp(
      0.0,
      100.0,
    );

    return _DashboardCard(
      title: 'Site Attendance Today',
      subtitle: 'Workers assigned to this project',
      child: Column(
        children: [
          const SizedBox(height: 8),
          if (hasWorkers) ...[
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.border(context),
                    valueColor: AlwaysStoppedAnimation(
                      pct > 75
                          ? AppColors.secondary
                          : pct > 50
                          ? AppColors.warning
                          : AppColors.error,
                    ),
                  ),
                  Text(
                    '${pct.toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${stats.workersPresent}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  TextSpan(
                    text: ' / ${stats.totalAssigned}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'workers present on site today',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 36,
                    color: AppColors.mutedText(context).withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '0 Workers Logged Today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No muster roll entries for today\'s date',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. CHECKLIST CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChecklistCard(BuildContext context, bool isDark) {
    final rawPct = stats.checklistCompletionPct;
    final pct = (rawPct.isNaN || rawPct.isInfinite ? 0.0 : rawPct).clamp(
      0.0,
      100.0,
    );

    return _DashboardCard(
      title: 'Checklist Progress',
      subtitle: '${stats.checklistCompleted}/${stats.checklistTotal} items completed',
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: AppColors.border(context),
                  valueColor: AlwaysStoppedAnimation(
                    pct >= 100
                        ? AppColors.secondary
                        : pct > 60
                        ? AppColors.primaryColor(context)
                        : AppColors.warning,
                  ),
                ),
                Text(
                  '${pct.toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${stats.checklistCompleted}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                TextSpan(
                  text: ' / ${stats.checklistTotal}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'quality inspection items passed',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. PAYMENT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentCard(BuildContext context, bool isDark) {
    return _DashboardCard(
      title: 'Payment Status',
      subtitle: 'Inward billing and customer settlements',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${_fmt(stats.totalPayments)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Total Received',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
          ),
          if (stats.pendingPayments > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '₹${_fmt(stats.pendingPayments)} pending',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. CONSTRUCTION STAGES & MILESTONES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMilestonesTrackerCard(BuildContext context, bool isDark) {
    final stages = [
      {'name': 'Site Prep & Excavation', 'status': 'Completed', 'pct': 1.0, 'dates': 'Target: 10 Jan - 28 Jan'},
      {'name': 'Substructure & Plinth Beam', 'status': 'Completed', 'pct': 1.0, 'dates': 'Target: 01 Feb - 25 Feb'},
      {'name': 'RCC Structure & Slabs (1st to 4th Floor)', 'status': 'In Progress', 'pct': 0.65, 'dates': 'Target: 01 Mar - 30 May'},
      {'name': 'Brickwork & Internal Masonry', 'status': 'In Progress', 'pct': 0.30, 'dates': 'Target: 15 Apr - 30 Jun'},
      {'name': 'MEP, Electrical & Concealed Plumbing', 'status': 'Scheduled', 'pct': 0.10, 'dates': 'Target: 01 Jun - 15 Aug'},
      {'name': 'Flooring, Painting & Final Handover', 'status': 'Upcoming', 'pct': 0.0, 'dates': 'Target: 01 Sep - 30 Oct'},
    ];

    return _DashboardCard(
      title: 'Construction Stages & Milestone Tracking',
      subtitle: 'Execution Progress by Phase',
      action: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Overall ${stats.computedProgress.toInt()}% Active',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
      ),
      child: Column(
        children: stages.map((st) {
          final isDone = st['status'] == 'Completed';
          final isInProg = st['status'] == 'In Progress';
          final double pct = st['pct'] as double;
          final color = isDone
              ? AppColors.secondary
              : (isInProg
                  ? AppColors.primaryColor(context)
                  : AppColors.mutedText(context));

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        st['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.text(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        st['status'] as String,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  st['dates'] as String,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.border(context),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 13. PROJECT CASHFLOW & RUNWAY FORECAST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCashflowForecastCard(BuildContext context, bool isDark) {
    final double budget = stats.budget;
    final double spent = stats.spent;
    final double remainingBudget = (budget - spent).clamp(0.0, double.infinity);
    final double estimatedReceivable = budget * 0.45;

    return _DashboardCard(
      title: 'Project Cashflow & Runway Forecast',
      subtitle: 'Committed Inflows vs Projected Site Outflows',
      action: Icon(
        Icons.trending_up,
        size: 18,
        color: AppColors.primaryColor(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EST. INWARD MILESTONE RECEIVABLES',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_fmt(estimatedReceivable)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        'Client Billing Stages',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.deepOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EST. REMAINING CASH TO HANDOVER',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_fmt(remainingBudget)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      Text(
                        'Labor + Material + Contractors',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.primaryColor(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cashflow Runway Status: Healthy. Inward milestone billing is projected to cover site outflows through the structural phase.',
                    style: TextStyle(fontSize: 11, color: AppColors.text(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 14. RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentActivity(BuildContext context, bool isDark) {
    return _DashboardCard(
      title: 'Recent Activity',
      subtitle: 'Chronological timeline of site events',
      child: stats.recentActivities.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_outlined,
                      size: 32,
                      color: AppColors.mutedText(context).withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activity logged for this project yet.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: stats.recentActivities.map((activity) {
                final icon = _activityIcon(activity.type);
                final color = _activityColor(activity.type);
                final timeAgo = _timeAgo(activity.timestamp);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 16, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text(context),
                              ),
                            ),
                            if (activity.subtitle.isNotEmpty)
                              Text(
                                activity.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 15. OPERATIONAL MODULE SHORTCUTS GRID (ALL 10 TILES)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOperationalModuleGrid(BuildContext context) {
    final modules = [
      (
        title: 'Attendance',
        subtitle: '${stats.workersPresent}/${stats.totalAssigned} present',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF059669),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 1,
            ),
          ),
        ),
      ),
      (
        title: 'Daily Progress',
        subtitle: 'Latest: ${stats.computedProgress.toInt()}%',
        icon: Icons.camera_alt_outlined,
        color: AppColors.primaryContainer,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyProgressScreen(
              projectId: projectId,
              projectName: stats.projectName,
            ),
          ),
        ),
      ),
      (
        title: 'Materials',
        subtitle: '${stats.materialsCount} items in stock',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 2,
            ),
          ),
        ),
      ),
      (
        title: 'Subcontractors',
        subtitle: 'Active Trade Partners',
        icon: Icons.engineering_outlined,
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 3,
            ),
          ),
        ),
      ),
      (
        title: 'Payment Status',
        subtitle: '₹${_fmt(stats.totalPayments)} Received',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF10B981),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 4,
            ),
          ),
        ),
      ),
      (
        title: 'Checklist',
        subtitle: '${stats.checklistCompleted}/${stats.checklistTotal} done',
        icon: Icons.task_alt_outlined,
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 5,
            ),
          ),
        ),
      ),
      (
        title: 'Drawings & Mapping',
        subtitle: 'Floor Plans, Blueprints & Photos',
        icon: Icons.architecture_outlined,
        color: const Color(0xFF0284C7),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 6,
            ),
          ),
        ),
      ),
      (
        title: 'Sales & Invoices',
        subtitle: 'Client RA Invoices',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFFD97706),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 7,
            ),
          ),
        ),
      ),
      (
        title: 'About Site Info',
        subtitle: 'Specifications & Scope',
        icon: Icons.info_outline,
        color: const Color(0xFF475569),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 9,
            ),
          ),
        ),
      ),
      (
        title: 'Full Site Reports',
        subtitle: 'Export PDF & Excel',
        icon: Icons.description_outlined,
        color: AppColors.primary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectOperationsScreen(
              projectId: projectId,
              projectName: stats.projectName,
              initialSection: 10,
            ),
          ),
        ),
      ),
    ];

    return _DashboardCard(
      title: 'Operational Submodules',
      subtitle: 'Direct shortcuts to project execution management',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final isMedium = constraints.maxWidth > 500;
          final crossAxisCount = isWide ? 5 : (isMedium ? 3 : 2);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isMedium ? 1.4 : 1.25,
            ),
            itemBuilder: (context, index) {
              final mod = modules[index];
              return InkWell(
                onTap: mod.onTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg(context),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: mod.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(mod.icon, color: mod.color, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mod.title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mod.subtitle,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.mutedText(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Materials':
        return const Color(0xFFF59E0B);
      case 'Equipment':
        return const Color(0xFF6366F1);
      case 'Labour':
        return const Color(0xFF059669);
      case 'Transport':
        return const Color(0xFF3B82F6);
      case 'Fuel':
        return const Color(0xFFEF4444);
      case 'Food':
        return const Color(0xFFEC4899);
      case 'Office & Admin':
        return const Color(0xFF8B5CF6);
      case 'Safety & PPE':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'add':
        return Icons.add_circle_outline;
      case 'edit':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'add':
        return AppColors.secondary;
      case 'edit':
        return AppColors.primary;
      case 'delete':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  String _fmt(double v) {
    return CurrencyFormatter.formatCompact(v, includeSymbol: false);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE DASHBOARD CARD WRAPPER
// ═════════════════════════════════════════════════════════════════════════════

class _DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onTap;
  final Widget child;

  const _DashboardCard({
    required this.title,
    this.subtitle,
    this.action,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESILIENT CUSTOM BUDGET DONUT PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _BudgetDonutPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool isOverBudget;
  final Color trackColor;
  final Color progressColor;

  _BudgetDonutPainter({
    required this.progress,
    required this.isOverBudget,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;

      final sweepAngle = (2 * math.pi * progress).clamp(0.01, 2 * math.pi);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetDonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-COMPONENT ERROR BOUNDARY HELPER
// ═════════════════════════════════════════════════════════════════════════════

class _SafeSection extends StatelessWidget {
  final Widget Function() builder;

  const _SafeSection({required this.builder});

  @override
  Widget build(BuildContext context) {
    try {
      return builder();
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Section temporarily unavailable ($e)',
                style: const TextStyle(fontSize: 11, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRIVATE KPI DATA HELPER
// ═════════════════════════════════════════════════════════════════════════════

class _KPIData {
  final IconData icon;
  final String value;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final String? subValue;
  final Color iconColor;
  final VoidCallback? onTap;

  _KPIData({
    required this.icon,
    required this.value,
    required this.label,
    this.badge,
    this.badgeColor,
    this.subValue,
    required this.iconColor,
    this.onTap,
  });
}
