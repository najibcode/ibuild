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

    // Auto-update project spent if linked to a project
    if (expense.projectId != null && expense.projectId!.isNotEmpty) {
      await _incrementProjectSpent(expense.projectId!, expense.amount);
    }

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
    // Fetch expense before deleting to get project_id and amount for rollback
    final existing = await _client
        .from('expenses')
        .select('project_id, amount')
        .eq('id', id)
        .maybeSingle();

    await _client.from('expenses').delete().eq('id', id);

    // Auto-decrement project spent if linked
    if (existing != null) {
      final projectId = existing['project_id'] as String?;
      final amount = (existing['amount'] as num?)?.toDouble() ?? 0.0;
      if (projectId != null && projectId.isNotEmpty && amount > 0) {
        await _decrementProjectSpent(projectId, amount);
      }
    }

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'deleted_expense',
      entityType: 'Expense',
      entityId: id,
    );
  }

  // ── Helpers: auto-sync project spent ──────────────────────────────────────

  Future<void> _incrementProjectSpent(String projectId, double amount) async {
    try {
      final row = await _client
          .from('projects')
          .select('spent')
          .eq('id', projectId)
          .maybeSingle();
      if (row != null) {
        final currentSpent = (row['spent'] as num?)?.toDouble() ?? 0.0;
        await _client
            .from('projects')
            .update({'spent': currentSpent + amount})
            .eq('id', projectId);
      }
    } catch (_) {
      // Fail silently — don't break the expense creation
    }
  }

  Future<void> _decrementProjectSpent(String projectId, double amount) async {
    try {
      final row = await _client
          .from('projects')
          .select('spent')
          .eq('id', projectId)
          .maybeSingle();
      if (row != null) {
        final currentSpent = (row['spent'] as num?)?.toDouble() ?? 0.0;
        final newSpent = (currentSpent - amount).clamp(0.0, double.infinity);
        await _client
            .from('projects')
            .update({'spent': newSpent})
            .eq('id', projectId);
      }
    } catch (_) {
      // Fail silently
    }
  }
}
