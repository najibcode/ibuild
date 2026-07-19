import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/expense_model.dart';

class SupabaseExpenseRepository implements ExpenseRepository {
  final SupabaseClient _client;

  SupabaseExpenseRepository(this._client);

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
    await _client.from('expenses').insert(expense.toJson());
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _client.from('expenses').update(expense.toJson()).eq('id', expense.id);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }
}
