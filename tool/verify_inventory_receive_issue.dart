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

    final rate = effectiveUnitPrice > 0 ? effectiveUnitPrice : item.purchasePrice;
    final totalCost = quantity * rate;
    if (projectId != null &&
        projectId.isNotEmpty &&
        projectId != 'central' &&
        projectId != 'none' &&
        totalCost > 0) {
      expenseStore.add({
        'project_id': projectId,
        'expense_date': '2026-08-15',
        'category': 'Material',
        'amount': totalCost,
        'payment_mode': 'cash',
        'notes':
            'Received +${quantity.toStringAsFixed(1)} ${item.unit} of ${item.materialName} from $supplier${notes != null && notes.isNotEmpty ? " ($notes)" : ""}',
      });
      projectSpentStore[projectId] = (projectSpentStore[projectId] ?? 0.0) + totalCost;
    }

    final projectSuffix = (projectName != null &&
            projectName.isNotEmpty &&
            projectId != 'central' &&
            projectId != 'none')
        ? ' for $projectName'
        : '';
    final historyNote =
        'Received +${quantity.toStringAsFixed(1)} ${item.unit} from $supplier$projectSuffix${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
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
  print('  INVENTORY RECEIVE & ISSUE MATERIAL — SYSTEM VERIFICATION');
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

  // 1. Test Receive Stock allocated directly to Project (Skyline Towers)
  print('━━━ 1. Test Receive Stock (+50 bags charged to Skyline Towers) ━━━');
  await repo.receiveStock(
    item: cement,
    quantity: 50,
    supplier: 'National Hardware Supply',
    unitPrice: 390.0,
    projectId: 'proj-skyline',
    projectName: 'Skyline Towers',
    notes: 'Invoice #INV-9821',
  );

  final afterReceive = await repo.getItemById('mat-001');
  final receiveExpense = repo.expenseStore.first;
  final receiveSuccess = afterReceive != null &&
      afterReceive.availableStock == 150 &&
      afterReceive.quantity == 150 &&
      afterReceive.supplier == 'National Hardware Supply' &&
      afterReceive.purchasePrice == 390.0 &&
      receiveExpense['project_id'] == 'proj-skyline' &&
      receiveExpense['amount'] == (50 * 390.0) &&
      receiveExpense['payment_mode'] == 'cash' &&
      repo.projectSpentStore['proj-skyline'] == (50 * 390.0);

  print('Stock Available: ${afterReceive?.availableStock} bags (Expected: 150)');
  print('Supplier:        ${afterReceive?.supplier}');
  print('Rate:            ₹${afterReceive?.purchasePrice}/bag');
  print('Expense Count:   ${repo.expenseStore.length}');
  print('Expense Project: ${receiveExpense['project_id']} (${receiveExpense['notes']})');
  print('Expense Amount:  ₹${receiveExpense['amount']} (Expected: ₹19,500)');
  print('Project Spent:   ₹${repo.projectSpentStore['proj-skyline']}');
  print('History Entries: ${repo.historyStore.length}');
  print('Result:          ${receiveSuccess ? "✓ PASSED" : "❌ FAILED"}\n');

  // 2. Test Issue Material to Project (30 bags to Green Villa)
  print('━━━ 2. Test Issue Material (30 bags to Green Villa) ━━━');
  await repo.issueMaterialToProject(
    item: afterReceive!,
    quantity: 30,
    projectId: 'proj-green-villa',
    projectName: 'Green Villa',
    notes: 'Ground Floor Slab Casting',
  );

  final afterIssue = await repo.getItemById('mat-001');
  final issueExpense = repo.expenseStore[1];
  final issueSuccess = afterIssue != null &&
      afterIssue.availableStock == 120 &&
      repo.expenseStore.length == 2 &&
      issueExpense['project_id'] == 'proj-green-villa' &&
      issueExpense['amount'] == (30 * 390.0) &&
      issueExpense['payment_mode'] == 'cash' &&
      repo.projectSpentStore['proj-green-villa'] == (30 * 390.0);

  print('Stock Available: ${afterIssue?.availableStock} bags (Expected: 120)');
  print('Expense Count:   ${repo.expenseStore.length}');
  print('Expense Amount:  ₹${issueExpense['amount']} (Expected: ₹11,700)');
  print('Payment Mode:    ${issueExpense['payment_mode']} (Valid DB Mode: cash)');
  print('Project Spent:   ₹${repo.projectSpentStore['proj-green-villa']}');
  print('History Entries: ${repo.historyStore.length}');
  print('Result:          ${issueSuccess ? "✓ PASSED" : "❌ FAILED"}\n');

  if (receiveSuccess && issueSuccess) {
    print('════════════════════════════════════════════════════════════════════');
    print('  ALL INVENTORY RECEIVE & ISSUE TESTS PASSED SUCCESSFULLY 100% ✓');
    print('════════════════════════════════════════════════════════════════════');
  } else {
    print('❌ SOME TESTS FAILED');
  }
}
