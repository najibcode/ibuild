import '../../data/models/expense_model.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    String? projectId,
    String? categoryFilter,
    String? sortBy,
    bool ascending = false,
    int limit = 20,
    int offset = 0,
  });
  Future<Expense?> getExpenseById(String id);
  Future<void> createExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}
