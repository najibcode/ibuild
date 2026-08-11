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
    
    // Log activity & broadcast notifications
    await _activityRepo.logSiteActivityAndNotify(
      actionType: 'inventory_added',
      entityType: 'Inventory',
      entityId: item.id,
      title: 'New Stock Added: ${item.materialName} (${item.quantity} ${item.unit})',
      details: {'item_name': item.materialName, 'quantity': item.quantity, 'unit': item.unit},
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

    // Log activity & broadcast notifications
    await _activityRepo.logSiteActivityAndNotify(
      actionType: 'inventory_updated',
      entityType: 'Inventory',
      entityId: item.id,
      title: 'Stock Updated: ${item.materialName} (${item.quantity} ${item.unit})',
      details: {'item_name': item.materialName, 'quantity': item.quantity},
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    await _client.from('inventory').delete().eq('id', id);
    
    // Log activity & broadcast notifications
    await _activityRepo.logSiteActivityAndNotify(
      actionType: 'inventory_deleted',
      entityType: 'Inventory',
      entityId: id,
      title: 'Stock Item Removed from Inventory',
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

  @override
  Future<void> receiveStock({
    required InventoryItem item,
    required double quantity,
    required String supplier,
    double? unitPrice,
    String? notes,
  }) async {
    final effectiveUnitPrice = unitPrice ?? item.purchasePrice;
    final newStock = (item.availableStock + quantity).clamp(0.0, 999999.0);
    final updatedItem = item.copyWith(
      availableStock: newStock,
      supplier: supplier.isNotEmpty ? supplier : item.supplier,
      purchasePrice:
          effectiveUnitPrice > 0 ? effectiveUnitPrice : item.purchasePrice,
    );

    // 1. Update inventory record
    await updateItem(updatedItem);

    // 2. Log history entry
    final historyNote =
        'Received +${quantity.toStringAsFixed(1)} ${item.unit} from $supplier${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
    await logInventoryChange(
      inventoryId: item.id,
      changeType: 'received',
      quantityChange: quantity,
      notes: historyNote,
    );

    // 3. Log site activity & notify
    await _activityRepo.logSiteActivityAndNotify(
      actionType: 'inventory_received',
      entityType: 'Inventory',
      entityId: item.id,
      title:
          'Stock Received: +${quantity.toStringAsFixed(1)} ${item.unit} of ${item.materialName}',
      details: {
        'supplier': supplier,
        'quantity': quantity,
        'unit': item.unit,
        'material': item.materialName,
      },
    );
  }

  @override
  Future<void> issueMaterialToProject({
    required InventoryItem item,
    required double quantity,
    required String projectId,
    required String projectName,
    String? notes,
  }) async {
    final newStock = (item.availableStock - quantity).clamp(0.0, 999999.0);
    final updatedItem = item.copyWith(availableStock: newStock);

    // 1. Update inventory record
    await updateItem(updatedItem);

    // 2. Calculate expense cost
    final totalCost = quantity * item.purchasePrice;

    // 3. Insert Expense entry automatically into Supabase expenses table for selected project!
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await _client.from('expenses').insert({
      'project_id': projectId,
      'expense_date': todayStr,
      'category': 'Material',
      'amount': totalCost,
      'payment_mode': 'inventory',
      'notes':
          'Issued ${quantity.toStringAsFixed(1)} ${item.unit} of ${item.materialName} from Central Stock${notes != null && notes.isNotEmpty ? " ($notes)" : ""}',
    });

    // 4. Log history entry
    final historyNote =
        'Issued -${quantity.toStringAsFixed(1)} ${item.unit} to $projectName${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
    await logInventoryChange(
      inventoryId: item.id,
      changeType: 'issued',
      quantityChange: -quantity,
      notes: historyNote,
    );

    // 5. Log site activity & notify
    await _activityRepo.logSiteActivityAndNotify(
      actionType: 'inventory_issued',
      entityType: 'Inventory',
      entityId: item.id,
      projectId: projectId,
      title:
          'Material Issued: ${quantity.toStringAsFixed(1)} ${item.unit} to $projectName',
      details: {
        'project_name': projectName,
        'quantity': quantity,
        'total_cost': totalCost,
        'material': item.materialName,
      },
    );
  }
}
