import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/models/expense_model.dart';
import '../controllers/expense_controller.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _paymentModeFilter = 'All';

  static const List<String> _categories = [
    'Labour',
    'Materials',
    'Transport',
    'Equipment',
    'Food',
    'Fuel',
    'Miscellaneous',
  ];

  static const List<String> _paymentModes = [
    'All',
    'Cash',
    'Bank',
    'UPI',
    'Cheque',
  ];

  IconData _getCategoryIcon(String category) {
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: const Text('Delete Expense Record'),
        content: Text('Are you sure you want to delete the expense of ₹${expense.amount.toStringAsFixed(2)} (${expense.category})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
      final success = await ref.read(expenseControllerProvider.notifier).removeExpense(expense.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense record deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete expense record'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseControllerProvider);

    // Apply payment mode filter in-memory if set
    final filteredExpenses = state.expenses.where((e) {
      if (_paymentModeFilter == 'All') return true;
      return e.paymentMode.toLowerCase() == _paymentModeFilter.toLowerCase();
    }).toList();

    // Financial Summary Metrics
    final double totalExpenseAmount = state.expenses.fold(0.0, (sum, e) => sum + e.amount);
    final double cashExpenses = state.expenses
        .where((e) => e.paymentMode.toLowerCase() == 'cash')
        .fold(0.0, (sum, e) => sum + e.amount);
    final double digitalExpenses = totalExpenseAmount - cashExpenses;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Site Outflows & Expenses',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => ref.read(expenseControllerProvider.notifier).loadExpenses(),
            tooltip: 'Refresh Expenses',
          ),
        ],
      ),
      body: Column(
        children: [
          // Financial Summary Header Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Expenses',
                    value: '₹${_fmt(totalExpenseAmount)}',
                    subtitle: '${state.expenses.length} Total Outflows',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Cash Outflows',
                    value: '₹${_fmt(cashExpenses)}',
                    subtitle: 'Petty Cash Payments',
                    icon: Icons.money_outlined,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Digital / Bank',
                    value: '₹${_fmt(digitalExpenses)}',
                    subtitle: 'UPI & Bank Transfers',
                    icon: Icons.credit_card_outlined,
                    color: AppColors.primaryColor(context),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                FilterChip(
                  selected: state.categoryFilter == null,
                  label: const Text('All Categories'),
                  onSelected: (_) => ref.read(expenseControllerProvider.notifier).setCategoryFilter(null),
                ),
                const SizedBox(width: 8),
                ..._categories.map((cat) {
                  final isSelected = state.categoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(_getCategoryIcon(cat), size: 14),
                      label: Text(cat),
                      onSelected: (selected) {
                        ref.read(expenseControllerProvider.notifier).setCategoryFilter(selected ? cat : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Search & Payment Mode Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 10),
                // Payment Mode Quick Dropdown Filter
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButton<String>(
                      value: _paymentModeFilter,
                      icon: const Icon(Icons.payment, size: 18),
                      style: TextStyle(fontSize: 13, color: AppColors.text(context), fontWeight: FontWeight.w600),
                      dropdownColor: AppColors.cardBg(context),
                      items: _paymentModes
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m == 'All' ? 'All Modes' : m),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _paymentModeFilter = val!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Expenses List Body
          Expanded(
            child: _buildBody(context, ref, state, filteredExpenses),
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
        borderRadius: BorderRadius.circular(14),
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
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedText(context),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ExpenseListState state,
    List<Expense> filteredExpenses,
  ) {
    if (state.isLoading && state.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 56, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Error: ${state.errorMessage}', style: TextStyle(color: AppColors.mutedText(context))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(expenseControllerProvider.notifier).loadExpenses(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No expenses found.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
            ),
            const SizedBox(height: 4),
            Text(
              'Click "+ Record Expense" to add operational site costs.',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredExpenses.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredExpenses.length) {
          ref.read(expenseControllerProvider.notifier).loadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final item = filteredExpenses[index];
        return _ExpenseCard(
          expense: item,
          onEdit: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseFormScreen(expense: item),
              ),
            );
            ref.read(expenseControllerProvider.notifier).loadExpenses();
          },
          onDelete: () => _confirmDelete(context, ref, item),
        );
      },
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

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
                color: Colors.deepOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_categoryIcon(expense.category), color: Colors.deepOrange, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${expense.category} Outflow Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
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
                          color: Colors.deepOrange.withValues(alpha: 0.12),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: modeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          expense.paymentMode.toUpperCase(),
                          style: TextStyle(color: modeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.primaryColor(context),
                        onPressed: onEdit,
                        tooltip: 'Edit Expense',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.error,
                        onPressed: onDelete,
                        tooltip: 'Delete Expense',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

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
                          overflow: TextOverflow.ellipsis,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 13, color: Colors.deepOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          expense.notes!,
                          style: TextStyle(fontSize: 11, color: AppColors.text(context), fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
