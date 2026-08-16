import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../data/repositories/supabase_inventory_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/models/inventory_item_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  return SupabaseInventoryRepository(client, activityRepo);
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
    bool clearError = false,
    String? searchQuery,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    String? sortBy,
    bool? ascending,
    int? offset,
    bool? hasMore,
  }) {
    return InventoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class InventoryController extends StateNotifier<InventoryListState> {
  final InventoryRepository _repository;
  final Ref? _ref;
  static const _pageSize = 20;

  InventoryController(this._repository, [this._ref]) : super(InventoryListState.initial()) {
    loadItems();
  }

  void _invalidateConnectedProviders() {
    if (_ref != null) {
      _ref.invalidate(lowStockProvider);
      _ref.invalidate(recentActivitiesProvider);
      _ref.invalidate(unreadNotificationsCountProvider);
    }
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
  void setCategoryFilter(String? c) { state = state.copyWith(categoryFilter: c, clearCategoryFilter: c == null); loadItems(); }
  void setSort(String s) { state = state.copyWith(sortBy: s, ascending: !state.ascending); loadItems(); }

  Future<bool> addItem(InventoryItem item) async {
    try {
      await _repository.createItem(item);
      await loadItems();
      _invalidateConnectedProviders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editItem(InventoryItem item) async {
    try {
      await _repository.updateItem(item);
      await loadItems();
      _invalidateConnectedProviders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> adjustStock(InventoryItem item, double delta) async {
    final newStock = (item.availableStock + delta).clamp(0.0, 999999.0);
    final updated = item.copyWith(availableStock: newStock);
    try {
      await _repository.updateItem(updated);

      // Log the stock movement as an inventory_history entry
      final changeType = delta > 0 ? 'added' : 'used';
      final absQty = delta.abs();
      final notes = delta > 0
          ? 'Received +${absQty.toStringAsFixed(1)} ${item.unit} via quick action'
          : 'Issued -${absQty.toStringAsFixed(1)} ${item.unit} via quick action';
      await _repository.logInventoryChange(
        inventoryId: item.id,
        changeType: changeType,
        quantityChange: absQty,
        notes: notes,
      );

      await loadItems();
      _invalidateConnectedProviders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> receiveStock({
    required InventoryItem item,
    required double quantity,
    required String supplier,
    double? unitPrice,
    String? projectId,
    String? projectName,
    String? notes,
  }) async {
    try {
      await _repository.receiveStock(
        item: item,
        quantity: quantity,
        supplier: supplier,
        unitPrice: unitPrice,
        projectId: projectId,
        projectName: projectName,
        notes: notes,
      );
      await loadItems();
      _invalidateConnectedProviders();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> issueMaterialToProject({
    required InventoryItem item,
    required double quantity,
    required String projectId,
    required String projectName,
    String? notes,
  }) async {
    try {
      await _repository.issueMaterialToProject(
        item: item,
        quantity: quantity,
        projectId: projectId,
        projectName: projectName,
        notes: notes,
      );
      await loadItems();
      _invalidateConnectedProviders();
      if (_ref != null) {
        try {
          _ref.read(expenseControllerProvider.notifier).loadExpenses();
          _ref.read(projectControllerProvider.notifier).loadProjects();
          _ref.invalidate(dashboardStatsProvider);
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeItem(String id) async {
    try {
      await _repository.deleteItem(id);
      await loadItems();
      _invalidateConnectedProviders();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final inventoryControllerProvider =
    StateNotifierProvider<InventoryController, InventoryListState>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return InventoryController(repo, ref);
});


final lowStockProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getLowStockItems();
});
