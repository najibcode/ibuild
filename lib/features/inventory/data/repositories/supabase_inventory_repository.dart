import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_history_model.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  final SupabaseClient _client;

  SupabaseInventoryRepository(this._client);

  @override
  Future<List<InventoryItem>> getItems({
    String? search,
    String? categoryFilter,
    String? sortBy,
    bool ascending = true,
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client.from('inventory').select();

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.eq('category', categoryFilter);
    }

    final orderCol = sortBy ?? 'created_at';
    query = query.order(orderCol, ascending: ascending);
    query = query.range(offset, offset + limit - 1);

    final response = await query;
    List<InventoryItem> items = (response as List).map((j) => InventoryItem.fromJson(j)).toList();

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      items = items.where((i) =>
          i.materialName.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q) ||
          (i.supplier?.toLowerCase().contains(q) ?? false)).toList();
    }

    return items;
  }

  @override
  Future<InventoryItem?> getItemById(String id) async {
    final response = await _client.from('inventory').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return InventoryItem.fromJson(response);
  }

  @override
  Future<void> createItem(InventoryItem item) async {
    await _client.from('inventory').insert(item.toJson());
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    await _client.from('inventory').update(item.toJson()).eq('id', item.id);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _client.from('inventory').delete().eq('id', id);
  }

  @override
  Future<List<InventoryItem>> getLowStockItems() async {
    final response = await _client.from('inventory').select();
    return (response as List)
        .map((j) => InventoryItem.fromJson(j))
        .where((i) => i.isLowStock)
        .toList();
  }

  @override
  Future<List<InventoryHistory>> getHistory(String inventoryId) async {
    final response = await _client
        .from('inventory_history')
        .select()
        .eq('inventory_id', inventoryId)
        .order('created_at', ascending: false);
    return (response as List).map((j) => InventoryHistory.fromJson(j)).toList();
  }

  @override
  Future<void> addHistoryEntry(InventoryHistory entry) async {
    await _client.from('inventory_history').insert(entry.toJson());
  }
}
