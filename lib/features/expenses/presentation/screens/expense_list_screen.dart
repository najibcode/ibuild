import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onSelected: (value) {
              ref
                  .read(expenseControllerProvider.notifier)
                  .setCategoryFilter(value == 'all' ? null : value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'all', child: Text('All Categories')),
              ..._categories.map(
                (c) => PopupMenuItem(value: c, child: Text(c)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () =>
                ref.read(expenseControllerProvider.notifier).loadExpenses(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: PermissionGuard(
        permission: 'expense.create',
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
            );
            ref.read(expenseControllerProvider.notifier).loadExpenses();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, ExpenseListState state) {
    if (state.isLoading && state.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Error: ${state.errorMessage}',
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(expenseControllerProvider.notifier).loadExpenses(),
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
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: AppColors.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No expenses recorded.',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
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
                builder: (_) =>
                    ExpenseFormScreen(expense: state.expenses[index]),
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
        return Icons.engineering;
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
        return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(expense.category),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            expense.paymentMode.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.projectName ?? 'General',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          expense.expenseDate,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.outline),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
