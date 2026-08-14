import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/expenses/presentation/controllers/expense_controller.dart';

class BudgetUtilizationMobile extends ConsumerWidget {
  final VoidCallback onBack;

  const BudgetUtilizationMobile({super.key, required this.onBack});

  /// Format amount in Indian style: ₹1.2L, ₹45.3L, ₹2.4Cr etc.
  static String _fmtIndian(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toInt()}';
  }

  /// Format amount as full Indian rupee string: ₹1,08,00,000
  static String _fmtFull(double amount) {
    final intPart = amount.toInt();
    if (intPart < 1000) return '₹$intPart';
    final str = intPart.toString();
    final len = str.length;
    final last3 = str.substring(len - 3);
    String remaining = str.substring(0, len - 3);
    final buffer = StringBuffer();
    while (remaining.length > 2) {
      buffer.write('${remaining.substring(0, remaining.length - 2)},');
      remaining = remaining.substring(remaining.length - 2);
    }
    return '₹${buffer.toString()}$remaining,$last3';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final expenseState = ref.watch(expenseControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor(context)),
          onPressed: onBack,
        ),
        title: Text(
          'Budget & Expenses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load budget data',
                    style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$e', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
              ],
            ),
          ),
        ),
        data: (stats) {
          // Compute category totals from live expense data
          final expenses = expenseState.expenses;
          final Map<String, double> categoryTotals = {};
          for (final exp in expenses) {
            final cat = exp.category.isEmpty ? 'Other' : exp.category;
            categoryTotals[cat] = (categoryTotals[cat] ?? 0) + exp.amount;
          }

          // Build sorted list of (category, amount) descending
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Category UI mapping (icon + color)
          const categoryMeta = <String, ({IconData icon, Color color})>{
            'material': (icon: Icons.inventory_2_outlined, color: Color(0xFF1976D2)),
            'materials': (icon: Icons.inventory_2_outlined, color: Color(0xFF1976D2)),
            'labour': (icon: Icons.engineering_outlined, color: Color(0xFF00BFA5)),
            'labor': (icon: Icons.engineering_outlined, color: Color(0xFF00BFA5)),
            'equipment': (icon: Icons.construction_outlined, color: Color(0xFFFF5722)),
            'transport': (icon: Icons.local_shipping_outlined, color: Color(0xFFFFA726)),
            'fuel': (icon: Icons.local_gas_station_outlined, color: Color(0xFFEF5350)),
            'food': (icon: Icons.restaurant_outlined, color: Color(0xFF66BB6A)),
            'site_expense': (icon: Icons.receipt_long_outlined, color: Color(0xFF9E9E9E)),
            'petty_cash': (icon: Icons.receipt_long_outlined, color: Color(0xFF9E9E9E)),
            'permits': (icon: Icons.description_outlined, color: Color(0xFF78909C)),
          };

          // Fallback colors for unmapped categories
          const fallbackColors = [
            Color(0xFF7E57C2), Color(0xFFEC407A), Color(0xFF26C6DA),
            Color(0xFFD4E157), Color(0xFF8D6E63),
          ];

          final totalSpent = stats.totalSpent;
          final totalBudget = stats.totalBudget;

          // Build pie chart sections from real data
          final List<PieChartSectionData> pieSections = [];
          final List<_CategoryBreakdownData> breakdownItems = [];

          if (sortedCategories.isEmpty) {
            // No expense data — show a single "No Data" section
            pieSections.add(PieChartSectionData(
              color: AppColors.mutedText(context).withValues(alpha: 0.3),
              value: 1,
              title: '',
              radius: 20,
            ));
          } else {
            int fallbackIdx = 0;
            for (final entry in sortedCategories) {
              final catKey = entry.key.toLowerCase().replaceAll(' ', '_');
              final meta = categoryMeta[catKey];
              final color = meta?.color ?? fallbackColors[fallbackIdx++ % fallbackColors.length];
              final icon = meta?.icon ?? Icons.category_outlined;
              final pct = totalSpent > 0 ? entry.value / totalSpent : 0.0;

              pieSections.add(PieChartSectionData(
                color: color,
                value: entry.value,
                title: '',
                radius: 20,
              ));

              breakdownItems.add(_CategoryBreakdownData(
                icon: icon,
                iconColor: color,
                title: _capitalizeCategory(entry.key),
                amount: entry.value,
                percent: pct,
                progressBarColor: color,
              ));
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text(
                  'Portfolio Budget Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Budget: ${_fmtIndian(totalBudget)} • Spent: ${_fmtIndian(totalSpent)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Budget Chart Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 65,
                                sections: pieSections,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _fmtIndian(totalSpent),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                ),
                                Text(
                                  'TOTAL SPENT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.mutedText(context),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (totalBudget > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${stats.budgetUtilizationPct.toStringAsFixed(0)}% used',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: stats.budgetUtilizationPct > 90
                                          ? AppColors.error
                                          : AppColors.mutedText(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Dynamic legend from top 3 categories
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: breakdownItems.take(3).map((item) =>
                          _buildLegendItem(context, item.title, item.iconColor),
                        ).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Category Breakdown Section Header
                Text(
                  'EXPENSE CATEGORY BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedText(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Breakdown Card List
                if (breakdownItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Center(
                      child: Text(
                        'No expense data recorded yet.',
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < breakdownItems.length; i++)
                          _buildBreakdownItem(
                            context: context,
                            icon: breakdownItems[i].icon,
                            iconColor: breakdownItems[i].iconColor,
                            title: breakdownItems[i].title,
                            amount: _fmtFull(breakdownItems[i].amount),
                            percent: breakdownItems[i].percent,
                            progressBarColor: breakdownItems[i].progressBarColor,
                            showDivider: i < breakdownItems.length - 1,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _capitalizeCategory(String s) {
    if (s.isEmpty) return s;
    return s.replaceAll('_', ' ').split(' ').map((w) =>
      w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}'
    ).join(' ');
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.text(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required double percent,
    required Color progressBarColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      Text(
                        '${(percent * 100).toInt()}% of total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  backgroundColor: AppColors.border(context),
                  valueColor: AlwaysStoppedAnimation(progressBarColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.border(context),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

/// Internal model for category breakdown items
class _CategoryBreakdownData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final double amount;
  final double percent;
  final Color progressBarColor;

  const _CategoryBreakdownData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.percent,
    required this.progressBarColor,
  });
}
