import '../../data/models/inventory_item_model.dart';
import '../../data/models/inventory_history_model.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getItems({
    String? search,
    String? categoryFilter,
    String? sortBy,
    bool ascending = true,
    int limit = 20,
    int offset = 0,
  });
  Future<InventoryItem?> getItemById(String id);
  Future<void> createItem(InventoryItem item);
  Future<void> updateItem(InventoryItem item);
  Future<void> deleteItem(String id);
  Future<List<InventoryItem>> getLowStockItems();
  Future<List<InventoryHistory>> getHistory(String inventoryId);
  Future<void> addHistoryEntry(InventoryHistory entry);
}
