import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/screens/project_form_screen.dart';
import '../../../projects/presentation/screens/project_list_screen.dart';
import '../../../expenses/presentation/screens/expense_form_screen.dart';
import '../../../reports/presentation/screens/full_report_generator_screen.dart';
import '../../../inventory/presentation/screens/inventory_list_screen.dart';

/// Compact executive Quick Actions toolbar for the Overall Portfolio Dashboard.
class QuickActionsWidget extends StatelessWidget {
  final VoidCallback? onNewProject;
  final VoidCallback? onDailyProgress;
  final VoidCallback? onExpenses;
  final VoidCallback? onReports;
  final VoidCallback? onInventory;

  const QuickActionsWidget({
    super.key,
    this.onNewProject,
    this.onDailyProgress,
    this.onExpenses,
    this.onReports,
    this.onInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _actionChip(
                context,
                icon: Icons.add_circle_outline,
                label: 'New Project',
                isPrimary: true,
                onTap: onNewProject ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProjectFormScreen(),
                        ),
                      );
                    },
              ),
              _actionChip(
                context,
                icon: Icons.assignment_outlined,
                label: 'Daily Progress',
                onTap: onDailyProgress ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProjectListScreen(),
                        ),
                      );
                    },
              ),
              _actionChip(
                context,
                icon: Icons.receipt_long_outlined,
                label: 'Expenses',
                onTap: onExpenses ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExpenseFormScreen(),
                        ),
                      );
                    },
              ),
              _actionChip(
                context,
                icon: Icons.bar_chart_outlined,
                label: 'Reports',
                onTap: onReports ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FullReportGeneratorScreen(),
                        ),
                      );
                    },
              ),
              _actionChip(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Materials',
                onTap: onInventory ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InventoryListScreen(),
                        ),
                      );
                    },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    final bgColor = isPrimary
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.08);
    final fgColor = isPrimary ? Colors.white : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
