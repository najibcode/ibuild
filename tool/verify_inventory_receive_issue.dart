import '../lib/features/inventory/data/models/inventory_item_model.dart';
import '../lib/features/inventory/domain/repositories/inventory_repository.dart';
import '../lib/features/inventory/data/models/inventory_history_model.dart';

class FakeInventoryRepository implements InventoryRepository {
  final Map<String, InventoryItem> itemStore = {};
  final List<Map<String, dynamic>> historyStore = [];
  final List<Map<String, dynamic>> expenseStore = [];
  final Map<String, double> projectSpentStore = {};

  @override
  Future<List<InventoryItem>> getItems({
    String? search,
    String? categoryFilter,
    String? sortBy,
    bool ascending = true,
    int limit = 20,
    int offset = 0,
  }) async {
    return itemStore.values.toList();
  }

  @override
  Future<InventoryItem?> getItemById(String id) async {
    return itemStore[id];
  }

  @override
  Future<void> createItem(InventoryItem item) async {
    itemStore[item.id] = item;
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    itemStore[item.id] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    itemStore.remove(id);
  }

  @override
  Future<List<InventoryItem>> getLowStockItems() async {
    return itemStore.values.where((i) => i.isLowStock).toList();
  }

  @override
  Future<List<InventoryHistory>> getHistory(String inventoryId) async {
    return historyStore
        .where((h) => h['inventory_id'] == inventoryId)
        .map((h) => InventoryHistory(
              id: h['id'] ?? '',
              inventoryId: h['inventory_id'],
              changeType: h['change_type'],
              quantityChange: h['quantity_change'],
              notes: h['notes'],
            ))
        .toList();
  }

  @override
  Future<List<InventoryHistory>> getAllHistory({String? startDate, String? endDate}) async {
    return historyStore
        .map((h) => InventoryHistory(
              id: h['id'] ?? '',
              inventoryId: h['inventory_id'],
              changeType: h['change_type'],
              quantityChange: h['quantity_change'],
              notes: h['notes'],
            ))
        .toList();
  }

  @override
  Future<void> logInventoryChange({
    required String inventoryId,
    required String changeType,
    required double quantityChange,
    String? notes,
  }) async {
    historyStore.add({
      'inventory_id': inventoryId,
      'change_type': changeType,
      'quantity_change': quantityChange,
      'notes': notes,
    });
  }

  @override
  Future<void> addHistoryEntry(InventoryHistory entry) async {
    historyStore.add(entry.toJson());
  }

  @override
  Future<void> receiveStock({
    required InventoryItem item,
    required double quantity,
    required String supplier,
    double? unitPrice,
    String? projectId,
    String? projectName,
    String? notes,
  }) async {
    final effectiveUnitPrice = unitPrice ?? item.purchasePrice;
    final newStock = (item.availableStock + quantity).clamp(0.0, 999999.0);
    final newQty = (item.quantity + quantity).clamp(0.0, 999999.0);
    final updatedItem = item.copyWith(
      availableStock: newStock,
      quantity: newQty,
      supplier: supplier.isNotEmpty ? supplier : item.supplier,
      purchasePrice:
          effectiveUnitPrice > 0 ? effectiveUnitPrice : item.purchasePrice,
    );

    await updateItem(updatedItem);

    final historyNote =
        'Received +${quantity.toStringAsFixed(1)} ${item.unit} from $supplier${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
    await logInventoryChange(
      inventoryId: item.id,
      changeType: 'added',
      quantityChange: quantity,
      notes: historyNote,
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

    await updateItem(updatedItem);

    final totalCost = quantity * item.purchasePrice;
    if (projectId.isNotEmpty && projectId != 'general' && totalCost > 0) {
      expenseStore.add({
        'project_id': projectId,
        'expense_date': '2026-08-15',
        'category': 'Material',
        'amount': totalCost,
        'payment_mode': 'cash',
        'notes':
            'Issued ${quantity.toStringAsFixed(1)} ${item.unit} of ${item.materialName} from Central Stock${notes != null && notes.isNotEmpty ? " ($notes)" : ""}',
      });
      projectSpentStore[projectId] = (projectSpentStore[projectId] ?? 0.0) + totalCost;
    }

    final historyNote =
        'Issued -${quantity.toStringAsFixed(1)} ${item.unit} to $projectName${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
    await logInventoryChange(
      inventoryId: item.id,
      changeType: 'used',
      quantityChange: -quantity,
      notes: historyNote,
    );
  }
}

void main() async {
  print('════════════════════════════════════════════════════════════════════');
  print('  INVENTORY RECEIVE & ISSUE MATERIAL — CLEAN WORKFLOW VERIFICATION');
  print('════════════════════════════════════════════════════════════════════\n');

  final repo = FakeInventoryRepository();

  final cement = InventoryItem(
    id: 'mat-001',
    materialName: 'Ultratech PPC Cement',
    category: 'Cement',
    supplier: 'Ultratech Depot',
    quantity: 100,
    unit: 'bags',
    purchasePrice: 380.0,
    availableStock: 100,
    minimumStock: 20,
  );

  await repo.createItem(cement);

  // 1. Test Receive Stock into Central Warehouse
  print('━━━ 1. Test Receive Stock (+50 bags received from supplier) ━━━');
  await repo.receiveStock(
    item: cement,
    quantity: 50,
    supplier: 'National Hardware Supply',
    unitPrice: 390.0,
    notes: 'Invoice #NHS-8821',
  );

  final itemAfterReceive = await repo.getItemById('mat-001');
  print(' Available Stock after Receive: ${itemAfterReceive?.availableStock} bags (Expected: 150.0)');
  print(' Total Stock after Receive:     ${itemAfterReceive?.quantity} bags (Expected: 150.0)');
  print(' Updated Purchase Rate:         ₹${itemAfterReceive?.purchasePrice}/bag (Expected: 390.0)');
  print(' Project Expenses Created:      ${repo.expenseStore.length} (Expected: 0 - Central stock replenishment)');

  // 2. Test Issue Material to Site (Skyline Towers)
  print('\n━━━ 2. Test Issue Material (-30 bags issued to Skyline Towers) ━━━');
  await repo.issueMaterialToProject(
    item: itemAfterReceive!,
    quantity: 30,
    projectId: 'proj-skyline',
    projectName: 'Skyline Towers',
    notes: 'Ground floor slab casting',
  );

  final itemAfterIssue = await repo.getItemById('mat-001');
  print(' Available Stock after Issue:   ${itemAfterIssue?.availableStock} bags (Expected: 120.0)');
  print(' Expenses Created for Project:  ${repo.expenseStore.length} (Expected: 1)');
  print(' Project Spent (Skyline Towers): ₹${repo.projectSpentStore['proj-skyline']} (Expected: 11700.0)');
  print(' Expense Details:               ${repo.expenseStore.first}');

  // 3. Verify Inventory Movement History
  print('\n━━━ 3. Verify Inventory Movement History ━━━');
  final history = await repo.getHistory('mat-001');
  for (var i = 0; i < history.length; i++) {
    final h = history[i];
    print(' [$i] ChangeType: ${h.changeType.padRight(6)} | Qty: ${h.quantityChange > 0 ? "+${h.quantityChange}" : h.quantityChange} | Notes: ${h.notes}');
  }

  final checksPass = itemAfterIssue?.availableStock == 120.0 &&
      repo.expenseStore.length == 1 &&
      repo.expenseStore.first['amount'] == 11700.0 &&
      repo.projectSpentStore['proj-skyline'] == 11700.0 &&
      history.length == 2;

  print('\n════════════════════════════════════════════════════════════════════');
  print('Verification Status: ${checksPass ? "✓ ALL CHECKS PASSED (100%)" : "❌ FAILED"}');
  print('════════════════════════════════════════════════════════════════════');
}
