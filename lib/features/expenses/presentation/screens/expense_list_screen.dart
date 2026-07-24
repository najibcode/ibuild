import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/models/expense_model.dart';
import '../controllers/expense_controller.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  static const _categories = [
    'Labour',
    'Materials',
    'Transport',
    'Equipment',
    'Food',
    'Fuel',
    'Miscellaneous',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseControllerProvider);

    // Calculate Financial Summary Metrics for Operational Outflows (Expenses)
    final double totalExpenseAmount = state.expenses.fold(0.0, (sum, e) => sum + e.amount);
    final double cashExpenses = state.expenses.where((e) => e.paymentMode.toLowerCase() == 'cash').fold(0.0, (sum, e) => sum + e.amount);
    final double digitalExpenses = totalExpenseAmount - cashExpenses;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Site Outflows & Expenses (Cost)',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(expenseControllerProvider.notifier).loadExpenses(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Financial Summary Header Cards (Operational Expenditures)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Expenses',
                    value: '₹${totalExpenseAmount.toInt()}',
                    subtitle: '${state.expenses.length} Logged Outflows',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Cash Payments',
                    value: '₹${cashExpenses.toInt()}',
                    subtitle: 'Petty Cash Outflows',
                    icon: Icons.money_outlined,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Bank / Digital',
                    value: '₹${digitalExpenses.toInt()}',
                    subtitle: 'UPI & Bank Transfers',
                    icon: Icons.credit_card_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Search & Category Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchFilterBar(
              hintText: 'Search expense, payee, notes...',
              onSearchChanged: (q) => ref.read(expenseControllerProvider.notifier).setSearch(q),
              filterOptions: _categories,
              activeFilter: state.categoryFilter,
              onFilterChanged: (f) => ref.read(expenseControllerProvider.notifier).setCategoryFilter(f),
              sortOptions: const ['Date', 'Amount', 'Category'],
              onSortChanged: (s) {
                final map = {'Date': 'expense_date', 'Amount': 'amount', 'Category': 'category'};
                ref.read(expenseControllerProvider.notifier).setSort(map[s] ?? 'created_at');
              },
            ),
          ),
          const SizedBox(height: 8),

          // Expense Outflow List
          Expanded(
            child: _buildBody(context, ref, state),
          ),
        ],
      ),
      floatingActionButton: PermissionGuard(
        permission: 'expense.create',
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
            );
            ref.read(expenseControllerProvider.notifier).loadExpenses();
          },
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Record Expense'),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: AppColors.mutedText(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ExpenseListState state) {
    if (state.isLoading && state.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Error: ${state.errorMessage}', style: TextStyle(color: AppColors.mutedText(context))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(expenseControllerProvider.notifier).loadExpenses(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.mutedText(context).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No expenses recorded.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
            const SizedBox(height: 4),
            Text('Record site operational costs, vendor payments, and wages.', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.expenses.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.expenses.length) {
          ref.read(expenseControllerProvider.notifier).loadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _ExpenseCard(
          expense: state.expenses[index],
          onEdit: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseFormScreen(expense: state.expenses[index]),
              ),
            );
            ref.read(expenseControllerProvider.notifier).loadExpenses();
          },
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;

  const _ExpenseCard({required this.expense, required this.onEdit});

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'labour':
        return Icons.engineering_outlined;
      case 'materials':
        return Icons.inventory_2_outlined;
      case 'transport':
        return Icons.local_shipping_outlined;
      case 'equipment':
        return Icons.build_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'fuel':
        return Icons.local_gas_station_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _paymentModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return Colors.amber.shade800;
      case 'bank':
      case 'upi':
        return AppColors.primary;
      case 'cheque':
        return Colors.purple;
      default:
        return AppColors.secondary;
    }
  }

  void _showExpenseDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_categoryIcon(expense.category), color: Colors.deepOrange, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              '${expense.category} Outflow Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(context, 'Expense Amount', '₹${expense.amount.toStringAsFixed(2)}', isBold: true, valueColor: Colors.deepOrange),
            _infoRow(context, 'Project Site', expense.projectName ?? 'General Site'),
            _infoRow(context, 'Payment Mode', expense.paymentMode.toUpperCase()),
            _infoRow(context, 'Expense Date', expense.expenseDate),
            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
              const Divider(height: 20),
              Text('Description & Remarks:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context))),
              const SizedBox(height: 4),
              Text(expense.notes!, style: TextStyle(fontSize: 13, color: AppColors.text(context), height: 1.3)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              onEdit();
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = _paymentModeColor(expense.paymentMode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: () => _showExpenseDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon, Name & Payment Mode Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _categoryIcon(expense.category),
                          color: Colors.deepOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        expense.category.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.text(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: modeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      expense.paymentMode.toUpperCase(),
                      style: TextStyle(color: modeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Project Name & Financial Outflow Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.projectName ?? 'General Site Expense',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Expense Date: ${expense.expenseDate}',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-₹${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange),
                      ),
                      Text(
                        'Outflow Cost',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${expense.notes}',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showExpenseDetails(context),
                    icon: const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    label: const Text('View Outflow Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.outline),
                    onPressed: onEdit,
                    tooltip: 'Edit Expense Record',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
