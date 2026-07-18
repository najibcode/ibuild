import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/supabase_inventory_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/models/inventory_item_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseInventoryRepository(client);
});

class InventoryListState {
  final List<InventoryItem> items;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? categoryFilter;
  final String sortBy;
  final bool ascending;
  final int offset;
  final bool hasMore;

  InventoryListState({
    required this.items,
    required this.isLoading,
    this.errorMessage,
    this.searchQuery = '',
    this.categoryFilter,
    this.sortBy = 'created_at',
    this.ascending = false,
    this.offset = 0,
    this.hasMore = true,
  });

  factory InventoryListState.initial() => InventoryListState(items: [], isLoading: false);

  InventoryListState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? categoryFilter,
    String? sortBy,
    bool? ascending,
    int? offset,
    bool? hasMore,
  }) {
    return InventoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class InventoryController extends StateNotifier<InventoryListState> {
  final InventoryRepository _repository;
  static const _pageSize = 20;

  InventoryController(this._repository) : super(InventoryListState.initial()) {
    loadItems();
  }

  Future<void> loadItems({bool reset = true}) async {
    if (state.isLoading) return;
    final newOffset = reset ? 0 : state.offset;
    state = state.copyWith(isLoading: true, offset: newOffset);
    if (reset) state = state.copyWith(items: []);

    try {
      final results = await _repository.getItems(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categoryFilter: state.categoryFilter,
        sortBy: state.sortBy,
        ascending: state.ascending,
        limit: _pageSize,
        offset: newOffset,
      );
      final combined = reset ? results : [...state.items, ...results];
      state = state.copyWith(
        items: combined,
        isLoading: false,
        offset: newOffset + results.length,
        hasMore: results.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void loadMore() => loadItems(reset: false);
  void setSearch(String q) { state = state.copyWith(searchQuery: q); loadItems(); }
  void setCategoryFilter(String? c) { state = state.copyWith(categoryFilter: c); loadItems(); }
  void setSort(String s) { state = state.copyWith(sortBy: s, ascending: !state.ascending); loadItems(); }

  Future<bool> addItem(InventoryItem item) async {
    try { await _repository.createItem(item); await loadItems(); return true; } catch (_) { return false; }
  }

  Future<bool> editItem(InventoryItem item) async {
    try { await _repository.updateItem(item); await loadItems(); return true; } catch (_) { return false; }
  }

  Future<bool> removeItem(String id) async {
    try { await _repository.deleteItem(id); await loadItems(); return true; } catch (_) { return false; }
  }
}

final inventoryControllerProvider =
    StateNotifierProvider<InventoryController, InventoryListState>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return InventoryController(repo);
});

final lowStockProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getLowStockItems();
});
