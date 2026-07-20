import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_history_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseInventoryRepository(this._client, this._activityRepo);

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
    // Validate
    if (item.materialName.trim().isEmpty) {
      throw ArgumentError('Material name cannot be empty.');
    }
    if (item.quantity < 0) {
      throw ArgumentError('Quantity cannot be negative.');
    }
    if (item.purchasePrice < 0) {
      throw ArgumentError('Purchase price cannot be negative.');
    }

    await _client.from('inventory').insert(item.toJson());
    
    // Log activity
    await _activityRepo.logActivity(
      actionType: 'added_inventory',
      entityType: 'Inventory',
      entityId: item.id,
      details: {'item_name': item.materialName, 'quantity': item.quantity},
    );
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    final updated = await _client
        .from('inventory')
        .update(item.toJson())
        .eq('id', item.id)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Item was not found or you do not have permission.');
    }

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'updated_inventory',
      entityType: 'Inventory',
      entityId: item.id,
      details: {'item_name': item.materialName},
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    await _client.from('inventory').delete().eq('id', id);
    
    // Log activity
    await _activityRepo.logActivity(
      actionType: 'deleted_inventory',
      entityType: 'Inventory',
      entityId: id,
    );
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
  Future<void> logInventoryChange({
    required String inventoryId,
    required String changeType,
    required double quantityChange,
    String? notes,
  }) async {
    await _client.from('inventory_history').insert({
      'inventory_id': inventoryId,
      'change_type': changeType,
      'quantity_change': quantityChange,
      'notes': notes,
    });

    // Log global activity for history change
    await _activityRepo.logActivity(
      actionType: 'inventory_$changeType',
      entityType: 'Inventory',
      entityId: inventoryId,
      details: {'quantity_change': quantityChange, 'notes': notes ?? ''},
    );
  }

  @override
  Future<void> addHistoryEntry(InventoryHistory entry) async {
    await _client.from('inventory_history').insert(entry.toJson());
  }
}
