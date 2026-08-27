import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseExpenseRepository implements ExpenseRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseExpenseRepository(this._client, this._activityRepo);

  @override
  Future<List<Expense>> getExpenses({
    String? projectId,
    String? categoryFilter,
    String? sortBy,
    bool ascending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client.from('expenses').select('*, projects(name)');

    if (projectId != null && projectId.isNotEmpty) {
      query = query.eq('project_id', projectId);
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.eq('category', categoryFilter);
    }

    final orderCol = sortBy ?? 'created_at';
    query = query.order(orderCol, ascending: ascending);
    query = query.range(offset, offset + limit - 1);

    final response = await query;
    return (response as List).map((j) => Expense.fromJson(j)).toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final response = await _client
        .from('expenses')
        .select('*, projects(name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Expense.fromJson(response);
  }

  @override
  Future<void> createExpense(Expense expense) async {
    // Validate
    if (expense.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }
    if (expense.category.trim().isEmpty) {
      throw ArgumentError('Expense category cannot be empty.');
    }

    await _client.from('expenses').insert(expense.toJson());

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'created_expense',
      entityType: 'Expense',
      entityId: expense.id,
      details: {
        'category': expense.category,
        'amount': expense.amount,
        'payment_mode': expense.paymentMode,
      },
    );
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _client.from('expenses').update(expense.toJson()).eq('id', expense.id);

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'updated_expense',
      entityType: 'Expense',
      entityId: expense.id,
      details: {
        'category': expense.category,
        'amount': expense.amount,
      },
    );
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'deleted_expense',
      entityType: 'Expense',
      entityId: id,
    );
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(String startDate, String endDate) async {
    try {
      final response = await _client
          .from('expenses')
          .select('*, projects(name)')
          .gte('expense_date', startDate)
          .lte('expense_date', endDate)
          .order('expense_date', ascending: false);
      return (response as List).map((j) => Expense.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }
}
