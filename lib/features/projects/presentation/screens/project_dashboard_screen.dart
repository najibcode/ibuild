import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/project_dashboard_model.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';
import '../controllers/project_dashboard_controller.dart';
import 'project_operations_screen.dart';
import 'project_form_screen.dart';
import 'project_detail_screen.dart';
import '../../../daily_progress/presentation/screens/daily_progress_screen.dart';

class ProjectDashboardScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const ProjectDashboardScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(projectDashboardProvider(projectId));
    final projectDetailAsync = ref.watch(projectDetailProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          projectName,
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
              ref.invalidate(projectDashboardProvider(projectId));
              ref.invalidate(projectDetailProvider(projectId));
            },
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppColors.primaryColor(context)),
            tooltip: 'Edit Project',
            onPressed: () async {
              final currentProject = projectDetailAsync.valueOrNull;
              if (currentProject != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectFormScreen(project: currentProject),
                  ),
                );
                ref.invalidate(projectDashboardProvider(projectId));
                ref.invalidate(projectDetailProvider(projectId));
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
              Text('Loading project dashboard...'),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error loading dashboard: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(projectDashboardProvider(projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => _DashboardBody(stats: stats, projectId: projectId),
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
        final isWide = constraints.maxWidth > 800;
        final isMedium = constraints.maxWidth > 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Project Header ──
                _buildProjectHeader(context, isDark),
                const SizedBox(height: 24),

                // ── KPI Cards ──
                _buildKPIRow(context, isWide, isMedium),
                const SizedBox(height: 24),

                // ── Charts Row ──
                if (isWide)
                  Row(
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
                  )
                else ...[
                  _buildBudgetDonut(context, isDark),
                  const SizedBox(height: 16),
                  _buildExpenseBreakdown(context, isDark),
                ],
                const SizedBox(height: 24),

                // ── Progress Sparkline ──
                _buildProgressSparkline(context, isDark),
                const SizedBox(height: 24),

                // ── Summary Cards Row ──
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAttendanceCard(context, isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildChecklistCard(context, isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPaymentCard(context, isDark)),
                    ],
                  )
                else ...[
                  if (isMedium)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildAttendanceCard(context, isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildChecklistCard(context, isDark)),
                      ],
                    )
                  else ...[
                    _buildAttendanceCard(context, isDark),
                    const SizedBox(height: 16),
                    _buildChecklistCard(context, isDark),
                  ],
                  const SizedBox(height: 16),
                  _buildPaymentCard(context, isDark),
                ],
                const SizedBox(height: 24),

                // ── Recent Activity ──
                _buildRecentActivity(context, isDark),
                const SizedBox(height: 24),

                // ── Quick Actions ──
                _buildQuickActions(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECT HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProjectHeader(BuildContext context, bool isDark) {
    final statusColor = _statusColor(stats.status);
    final displayName = stats.projectName.isNotEmpty
        ? stats.projectName
        : 'Project Overview';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A2744),
                  const Color(0xFF0F1C33),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.secondary.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          // Project avatar / icon
          Container(
            width: 56,
            height: 56,
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        stats.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
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
                    fontSize: 14,
                    color: AppColors.mutedText(context),
                  ),
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
                              fontSize: 12,
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
          // Date info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (stats.startDate != null)
                _dateChip(context, 'Start', stats.startDate!),
              if (stats.expectedCompletion != null) ...[
                const SizedBox(height: 4),
                _dateChip(context, 'Due', stats.expectedCompletion!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateChip(BuildContext context, String label, String date) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mutedText(context),
          ),
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
  // KPI CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKPIRow(BuildContext context, bool isWide, bool isMedium) {
    final utilPct = stats.budgetUtilizationPct.isNaN || stats.budgetUtilizationPct.isInfinite
        ? 0.0
        : stats.budgetUtilizationPct;

    final cards = [
      _KPIData(
        icon: Icons.payments_outlined,
        value: '₹${_fmt(stats.budget)}',
        label: 'Total Budget',
        badge: '${utilPct.toInt()}%',
        badgeColor: utilPct > 90
            ? AppColors.error
            : AppColors.secondary,
        iconColor: AppColors.primary,
      ),
      _KPIData(
        icon: Icons.trending_up_outlined,
        value: '₹${_fmt(stats.spent)}',
        label: 'Amount Spent',
        iconColor: utilPct > 90
            ? AppColors.error
            : const Color(0xFF059669),
      ),
      _KPIData(
        icon: Icons.account_balance_outlined,
        value: '₹${_fmt(stats.remainingBalance)}',
        label: 'Remaining Balance',
        iconColor: stats.remainingBalance >= 0
            ? const Color(0xFF059669)
            : AppColors.error,
      ),
      _KPIData(
        icon: Icons.calculate_outlined,
        value: '₹${_fmt(stats.estimatedCost)}',
        label: 'Estimated Cost',
        subValue: 'Current: ₹${_fmt(stats.currentCost)}',
        iconColor: const Color(0xFF7C3AED),
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .expand((c) => [
                  Expanded(child: _buildKPICard(context, c)),
                  if (c != cards.last) const SizedBox(width: 16),
                ])
            .toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMedium ? 4 : 2,
      childAspectRatio: isMedium ? 1.3 : 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: cards.map((c) => _buildKPICard(context, c)).toList(),
    );
  }

  Widget _buildKPICard(BuildContext context, _KPIData data) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 20),
              ),
              if (data.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedText(context),
            ),
          ),
          if (data.subValue != null) ...[
            const SizedBox(height: 2),
            Text(
              data.subValue!,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.mutedText(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUDGET DONUT CHART
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBudgetDonut(BuildContext context, bool isDark) {
    final rawUtil = stats.budgetUtilization;
    final utilization = (rawUtil.isNaN || rawUtil.isInfinite ? 0.0 : rawUtil).clamp(0.0, 1.0);
    final remaining = (1.0 - utilization).clamp(0.0, 1.0);
    final spentColor = utilization > 0.9
        ? AppColors.error
        : utilization > 0.7
            ? AppColors.warning
            : AppColors.secondary;

    final utilPctInt = (utilization * 100).toInt();

    return _DashboardCard(
      title: 'Budget Utilization',
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 60,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    value: utilization > 0 ? utilization * 100 : 0.001,
                    color: spentColor,
                    radius: 24,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: remaining > 0 ? remaining * 100 : 0.001,
                    color: AppColors.border(context),
                    radius: 20,
                    showTitle: false,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$utilPctInt%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: spentColor,
                  ),
                ),
                Text(
                  'utilized',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPENSE BREAKDOWN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExpenseBreakdown(BuildContext context, bool isDark) {
    final categories = stats.expenseBreakdown.take(6).toList();
    final maxAmount =
        categories.isNotEmpty ? categories.first.amount : 1.0;

    return _DashboardCard(
      title: 'Expense Breakdown',
      subtitle: 'Total: ₹${_fmt(stats.totalExpenses)}',
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
                      color: AppColors.mutedText(context).withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No expenses recorded yet',
                      style: TextStyle(color: AppColors.mutedText(context)),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: categories.map((cat) {
                final pct = maxAmount > 0 ? cat.amount / maxAmount : 0.0;
                final color = _categoryColor(cat.category);
                return Padding(
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
                );
              }).toList(),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7-DAY PROGRESS SPARKLINE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressSparkline(BuildContext context, bool isDark) {
    final rawCounts = stats.weeklyProgressCounts;
    final counts = rawCounts.length == 7 ? rawCounts : List.filled(7, 0);

    final maxVal = counts.fold<int>(0, (max, v) => v > max ? v : max).toDouble();
    final chartMax = maxVal > 0 ? maxVal + 1.0 : 5.0;
    final totalUpdates = counts.fold<int>(0, (sum, v) => sum + v);

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final dayLabels = List.generate(7, (i) {
      final d = weekAgo.add(Duration(days: i));
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    });

    return _DashboardCard(
      title: '7-Day Site Progress',
      subtitle: '$totalUpdates total updates this week',
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
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
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0 || value < 0) {
                      return const SizedBox.shrink();
                    }
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
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.primaryColor(context),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primaryColor(context),
                    strokeWidth: 2,
                    strokeColor: AppColors.cardBg(context),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primaryColor(context).withValues(alpha: 0.08),
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
  // ATTENDANCE CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAttendanceCard(BuildContext context, bool isDark) {
    final rawPct = stats.attendancePct;
    final pct = (rawPct.isNaN || rawPct.isInfinite ? 0.0 : rawPct).clamp(0.0, 100.0);

    return _DashboardCard(
      title: 'Today\'s Attendance',
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
            'workers present today',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECKLIST CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChecklistCard(BuildContext context, bool isDark) {
    final rawPct = stats.checklistCompletionPct;
    final pct = (rawPct.isNaN || rawPct.isInfinite ? 0.0 : rawPct).clamp(0.0, 100.0);

    return _DashboardCard(
      title: 'Checklist Progress',
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
                  value: pct / 100,
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
            'items completed',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentCard(BuildContext context, bool isDark) {
    return _DashboardCard(
      title: 'Payment Status',
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
            'received',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedText(context),
            ),
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
  // RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentActivity(BuildContext context, bool isDark) {
    return _DashboardCard(
      title: 'Recent Activity',
      child: stats.recentActivities.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent activity for this project.',
                  style: TextStyle(color: AppColors.mutedText(context)),
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
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionButton(
              context,
              Icons.hub_outlined,
              'Operations Hub',
              AppColors.secondary,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectOperationsScreen(
                    projectId: projectId,
                    projectName: stats.projectName,
                  ),
                ),
              ),
            ),
            _actionButton(
              context,
              Icons.camera_alt_outlined,
              'Daily Progress',
              AppColors.primaryContainer,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DailyProgressScreen(
                    projectId: projectId,
                    projectName: stats.projectName,
                  ),
                ),
              ),
            ),
            _actionButton(
              context,
              Icons.receipt_long_outlined,
              'Sales & Invoices',
              const Color(0xFF7C3AED),
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectOperationsScreen(
                    projectId: projectId,
                    projectName: stats.projectName,
                    initialSection: 7,
                  ),
                ),
              ),
            ),
            _actionButton(
              context,
              Icons.description_outlined,
              'Full Report',
              Colors.deepOrange,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectOperationsScreen(
                    projectId: projectId,
                    projectName: stats.projectName,
                    initialSection: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

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
    if (v.isNaN || v.isInfinite) return '0';
    if (v < 0) return '-₹${_fmt(-v).replaceAll('₹', '')}';
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE DASHBOARD CARD WRAPPER
// ═════════════════════════════════════════════════════════════════════════════

class _DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _DashboardCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
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

  _KPIData({
    required this.icon,
    required this.value,
    required this.label,
    this.badge,
    this.badgeColor,
    this.subValue,
    required this.iconColor,
  });
}
