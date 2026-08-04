import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../data/models/expense_model.dart';
import '../controllers/expense_controller.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  static const List<String> _categories = [
    'Labour',
    'Materials',
    'Transport',
    'Equipment',
    'Food',
    'Fuel',
    'Miscellaneous',
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

  Future<void> _openAddForm() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExpenseFormScreen()));
    ref.read(expenseControllerProvider.notifier).loadExpenses();
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: const Text('Delete Expense Record'),
        content: Text(
          'Are you sure you want to delete the expense of ₹${expense.amount.toStringAsFixed(2)} (${expense.category})?',
        ),
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
      final success = await ref
          .read(expenseControllerProvider.notifier)
          .removeExpense(expense.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense record deleted successfully'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete expense record'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseControllerProvider);

    final double totalExpenseAmount = state.expenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Expenses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdf: () async {
              final expenses = state.expenses;
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Site Expenses Outflow History',
                subtitle: 'Log of operational outflows and petty cash transactions',
                headers: ['ID', 'Date', 'Category', 'Amount (INR)', 'Mode', 'Project Site', 'Notes'],
                data: expenses.map((e) => [
                  e.id.substring(0, 8),
                  e.expenseDate,
                  e.category,
                  'INR ${e.amount.toStringAsFixed(2)}',
                  e.paymentMode.toUpperCase(),
                  e.projectName ?? 'General',
                  e.notes ?? '',
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Expenses_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcel: () async {
              final expenses = state.expenses;
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Expenses',
                title: 'Site Expenses & Financial Outflows',
                headers: ['Expense ID', 'Date', 'Category', 'Amount (INR)', 'Payment Mode', 'Project Site', 'Notes'],
                rows: expenses.map((e) => [
                  e.id,
                  e.expenseDate,
                  e.category,
                  e.amount,
                  e.paymentMode.toUpperCase(),
                  e.projectName ?? 'General',
                  e.notes ?? '',
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Expenses_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _openAddForm,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.primaryColor(context),
            onPressed: () =>
                ref.read(expenseControllerProvider.notifier).loadExpenses(),
            tooltip: 'Refresh Expenses',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: Column(
        children: [
          // Single Summary Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.deepOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL OUTFLOWS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mutedText(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${totalExpenseAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor(
                        context,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.expenses.length} Records',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Single Clean Category Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: state.categoryFilter == null,
                    label: Text(
                      'All Expenses',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: state.categoryFilter == null
                            ? Colors.white
                            : AppColors.text(context),
                      ),
                    ),
                    onSelected: (_) => ref
                        .read(expenseControllerProvider.notifier)
                        .setCategoryFilter(null),
                    backgroundColor: AppColors.cardBg(context),
                    selectedColor: AppColors.primaryColor(context),
                    side: BorderSide(
                      color: state.categoryFilter == null
                          ? AppColors.primaryColor(context)
                          : AppColors.border(context),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                ),
                ..._categories.map((cat) {
                  final isSelected = state.categoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(
                        _getCategoryIcon(cat),
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : AppColors.mutedText(context),
                      ),
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.text(context),
                        ),
                      ),
                      onSelected: (selected) {
                        ref
                            .read(expenseControllerProvider.notifier)
                            .setCategoryFilter(selected ? cat : null);
                      },
                      backgroundColor: AppColors.cardBg(context),
                      selectedColor: AppColors.primaryColor(context),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryColor(context)
                            : AppColors.border(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Expense List Body
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ExpenseListState state,
  ) {
    if (state.isLoading && state.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading expenses: ${state.errorMessage}',
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(expenseControllerProvider.notifier).loadExpenses(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.mutedText(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the "+ Record Expense" button to add your first expense',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

        final item = state.expenses[index];
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category Icon & Name + Amount + Edit/Delete Actions
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.category.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.text(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Date: ${expense.expenseDate}',
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '-₹${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppColors.primaryColor(context),
                      onPressed: onEdit,
                      tooltip: 'Edit Record',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.error,
                      onPressed: onDelete,
                      tooltip: 'Delete Record',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Project Site Name
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: AppColors.mutedText(context),
                ),
                const SizedBox(width: 4),
                Text(
                  expense.projectName ?? 'General Site Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    expense.paymentMode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),

            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${expense.notes}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText(context),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
