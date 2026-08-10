import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/dashboard_stats_model.dart';

/// Budget Utilization widget showing allocated budget vs actual spend per project
/// with INR formatting and color-coded progress bars.
class BudgetUtilizationWidget extends StatelessWidget {
  final List<PortfolioProjectItem> projects;

  const BudgetUtilizationWidget({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final activeList = projects.where((p) => p.status == 'active' || p.status == 'delayed' || p.status == 'at_risk').toList();

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
                    'BUDGET UTILIZATION',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Allocated contract budget vs actual expenditure',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                'Top ${activeList.length.clamp(0, 5)} Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          if (activeList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No active project budgets to display',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeList.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final p = activeList[index];
                return _buildBudgetItem(context, p);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(BuildContext context, PortfolioProjectItem p) {
    final util = p.budgetUtilizationPct;
    final budgetStr = CurrencyFormatter.formatINR(p.budget);
    final spentStr = CurrencyFormatter.formatINR(p.spent);

    Color barColor = const Color(0xFF4CAF50);
    if (util > 95.0) {
      barColor = AppColors.error;
    } else if (util > 85.0) {
      barColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                p.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$spentStr / $budgetStr  (${util.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (util / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
