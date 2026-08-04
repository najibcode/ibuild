import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'core/theme/app_colors.dart';

class BudgetUtilizationMobile extends ConsumerWidget {
  final VoidCallback onBack;

  const BudgetUtilizationMobile({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headline
            Text(
              'Skyline Apartments: Budget',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text(context),
              ),
            ),
            Text(
              'Q4 Financial Overview & Outflows',
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
                            sections: [
                              PieChartSectionData(
                                color: AppColors.primaryColor(context),
                                value: 45,
                                title: '',
                                radius: 20,
                              ),
                              PieChartSectionData(
                                color: AppColors.secondary,
                                value: 30,
                                title: '',
                                radius: 20,
                              ),
                              PieChartSectionData(
                                color: Colors.deepOrange,
                                value: 15,
                                title: '',
                                radius: 20,
                              ),
                              PieChartSectionData(
                                color: AppColors.mutedText(
                                  context,
                                ).withValues(alpha: 0.3),
                                value: 10,
                                title: '',
                                radius: 20,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹2.4Cr',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem(
                        context,
                        'Materials',
                        AppColors.primaryColor(context),
                      ),
                      _buildLegendItem(context, 'Labour', AppColors.secondary),
                      _buildLegendItem(context, 'Equipment', Colors.deepOrange),
                    ],
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                children: [
                  _buildBreakdownItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primaryColor(context),
                    title: 'Raw Materials & Cement',
                    amount: '₹1,08,00,000',
                    percent: 0.45,
                    progressBarColor: AppColors.primaryColor(context),
                    showDivider: true,
                  ),
                  _buildBreakdownItem(
                    context: context,
                    icon: Icons.engineering_outlined,
                    iconColor: AppColors.secondary,
                    title: 'Subcontractor & Labour Wages',
                    amount: '₹72,00,000',
                    percent: 0.30,
                    progressBarColor: AppColors.secondary,
                    showDivider: true,
                  ),
                  _buildBreakdownItem(
                    context: context,
                    icon: Icons.construction_outlined,
                    iconColor: Colors.deepOrange,
                    title: 'Equipment, Machinery & Tools',
                    amount: '₹36,00,000',

                    percent: 0.15,
                    progressBarColor: Colors.deepOrange,
                    showDivider: true,
                  ),
                  _buildBreakdownItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.mutedText(context),
                    title: 'Site Permits & Petty Cash',
                    amount: '₹24,00,000',
                    percent: 0.10,
                    progressBarColor: AppColors.mutedText(context),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.text(context),
          ),
        ),
      ],
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
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
                  value: percent,
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
