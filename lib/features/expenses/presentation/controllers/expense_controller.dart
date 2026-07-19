import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/supabase_expense_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/models/expense_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseExpenseRepository(client);
});

class ExpenseListState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? errorMessage;
  final String? projectFilter;
  final String? categoryFilter;
  final int offset;
  final bool hasMore;

  ExpenseListState({
    required this.expenses,
    required this.isLoading,
    this.errorMessage,
    this.projectFilter,
    this.categoryFilter,
    this.offset = 0,
    this.hasMore = true,
  });

  factory ExpenseListState.initial() =>
      ExpenseListState(expenses: [], isLoading: false);

  ExpenseListState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? errorMessage,
    String? projectFilter,
    String? categoryFilter,
    int? offset,
    bool? hasMore,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      projectFilter: projectFilter ?? this.projectFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ExpenseController extends StateNotifier<ExpenseListState> {
  final ExpenseRepository _repository;
  static const _pageSize = 20;

  ExpenseController(this._repository) : super(ExpenseListState.initial()) {
    loadExpenses();
  }

  Future<void> loadExpenses({bool reset = true}) async {
    if (state.isLoading) return;
    final newOffset = reset ? 0 : state.offset;
    state = state.copyWith(isLoading: true, offset: newOffset);
    if (reset) state = state.copyWith(expenses: []);

    try {
      final results = await _repository.getExpenses(
        projectId: state.projectFilter,
        categoryFilter: state.categoryFilter,
        limit: _pageSize,
        offset: newOffset,
      );
      final combined = reset ? results : [...state.expenses, ...results];
      state = state.copyWith(
        expenses: combined,
        isLoading: false,
        offset: newOffset + results.length,
        hasMore: results.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void loadMore() => loadExpenses(reset: false);

  void setProjectFilter(String? p) {
    state = state.copyWith(projectFilter: p);
    loadExpenses();
  }

  void setCategoryFilter(String? c) {
    state = state.copyWith(categoryFilter: c);
    loadExpenses();
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      await _repository.createExpense(expense);
      await loadExpenses();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editExpense(Expense expense) async {
    try {
      await _repository.updateExpense(expense);
      await loadExpenses();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final expenseControllerProvider =
    StateNotifierProvider<ExpenseController, ExpenseListState>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpenseController(repo);
});
