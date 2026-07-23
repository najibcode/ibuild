import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/paginated_list.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/models/inventory_item_model.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_form_screen.dart';
import 'inventory_history_screen.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key});

  static const _categories = ['Cement', 'Steel', 'Sand', 'Bricks', 'Electrical', 'Plumbing', 'Wood', 'Paint', 'Other'];

  void _showBulkPurchaseOrderModal(BuildContext context, List<InventoryItem> items) {
    final lowStockItems = items.where((i) => i.isLowStock).toList();
    final double totalPOCost = lowStockItems.fold(0.0, (sum, i) => sum + i.estimatedReorderCost);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              'Automated Purchase Requisition',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculated Reorder Requisitions for ${lowStockItems.length} Low-Stock Material${lowStockItems.length == 1 ? '' : 's'}:',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (lowStockItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text('All material stock levels are healthy! No PO required.'),
                    ],
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: lowStockItems.length,
                    itemBuilder: (ctx, i) {
                      final item = lowStockItems[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bg(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.materialName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                                Text('Supplier: ${item.supplier ?? 'Direct Distributor'}', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${item.recommendedReorderQty.toInt()} ${item.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                                ),
                                Text(
                                  '₹${item.estimatedReorderCost.toInt()}',
                                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Est. Total PO Budget:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  Text(
                    '₹${totalPOCost.toInt()}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          if (lowStockItems.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                final poText = lowStockItems
                    .map((item) => "• ${item.materialName}: +${item.recommendedReorderQty.toInt()} ${item.unit} @ ₹${item.purchasePrice}/unit (Est. ₹${item.estimatedReorderCost.toInt()}) [Supplier: ${item.supplier ?? 'N/A'}]")
                    .join("\n");
                final summaryMsg = "PURCHASE REQUISITION DRAFT:\nTotal Estimated Cost: ₹${totalPOCost.toInt()}\n\nItems Requested:\n$poText";
                
                Clipboard.setData(ClipboardData(text: summaryMsg));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied PO Requisition summary to clipboard!')),
                );
                Navigator.of(ctx).pop();
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy PO Requisition Draft'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryControllerProvider);

    // Calculate Financial Valuation & Metrics
    final double totalValuation = state.items.fold(0.0, (sum, item) => sum + item.totalValuation);
    final int lowStockCount = state.items.where((item) => item.isLowStock).length;
    final int totalItemsCount = state.items.length;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Automated Material Inventory ERP',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _showBulkPurchaseOrderModal(context, state.items),
              icon: const Icon(Icons.bolt, size: 16, color: Colors.amber),
              label: const Text('Auto-Generate PO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(inventoryControllerProvider.notifier).loadItems(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Financial Valuation & Automated Analytics Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Stock Valuation',
                    value: '₹${totalValuation.toInt()}',
                    subtitle: 'Capital Invested in Goods',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Low Stock Alerts',
                    value: '$lowStockCount Items',
                    subtitle: lowStockCount > 0 ? 'Auto PO Reorder Ready' : 'Optimal Inventory',
                    icon: Icons.warning_amber_rounded,
                    color: lowStockCount > 0 ? AppColors.error : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Stock Categories',
                    value: '$totalItemsCount Types',
                    subtitle: 'Tracked Construction Items',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchFilterBar(
              hintText: 'Search material, category, supplier...',
              onSearchChanged: (q) => ref.read(inventoryControllerProvider.notifier).setSearch(q),
              filterOptions: _categories,
              activeFilter: state.categoryFilter,
              onFilterChanged: (f) => ref.read(inventoryControllerProvider.notifier).setCategoryFilter(f),
              sortOptions: const ['Name', 'Stock', 'Price'],
              onSortChanged: (s) {
                final map = {'Name': 'material_name', 'Stock': 'available_stock', 'Price': 'purchase_price'};
                ref.read(inventoryControllerProvider.notifier).setSort(map[s] ?? 'created_at');
              },
            ),
          ),
          const SizedBox(height: 8),

          // Material Inventory List
          Expanded(
            child: PaginatedListView<InventoryItem>(
              items: state.items,
              isLoading: state.isLoading,
              hasMore: state.hasMore,
              onLoadMore: () => ref.read(inventoryControllerProvider.notifier).loadMore(),
              emptyMessage: 'No inventory items found. Tap + to add new material.',
              errorMessage: state.errorMessage,
              onRetry: () => ref.read(inventoryControllerProvider.notifier).loadItems(),
              itemBuilder: (context, item) => _InventoryCard(
                item: item,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => InventoryHistoryScreen(item: item)),
                ),
                onEdit: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InventoryFormScreen(item: item)),
                  );
                  ref.read(inventoryControllerProvider.notifier).loadItems();
                },
                onAdjustStock: (delta) {
                  ref.read(inventoryControllerProvider.notifier).adjustStock(item, delta);
                },
                onGeneratePO: () {
                  _showBulkPurchaseOrderModal(context, [item]);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: PermissionGuard(
        permission: 'inventory.create',
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InventoryFormScreen()),
            );
            ref.read(inventoryControllerProvider.notifier).loadItems();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Material'),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: AppColors.mutedText(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Function(double delta) onAdjustStock;
  final VoidCallback onGeneratePO;

  const _InventoryCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onAdjustStock,
    required this.onGeneratePO,
  });

  void _showQuickStockDialog(BuildContext context, bool isAdding) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: Row(
          children: [
            Icon(
              isAdding ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isAdding ? AppColors.secondary : AppColors.error,
            ),
            const SizedBox(width: 8),
            Text(
              isAdding ? 'Receive Stock Delivery' : 'Issue Site Consumption',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Material: ${item.materialName} (${item.unit})', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text(context))),
            Text('Current Available: ${item.availableStock.toStringAsFixed(1)} ${item.unit}', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: isAdding ? 'Quantity Received' : 'Quantity Consumed',
                suffixText: item.unit,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(controller.text);
              if (qty != null && qty > 0) {
                onAdjustStock(isAdding ? qty : -qty);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdding ? AppColors.secondary : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(isAdding ? 'Confirm Receive' : 'Confirm Issue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int runwayDays = item.stockRunwayDays;
    final Color runwayColor = runwayDays < 3
        ? AppColors.error
        : (runwayDays <= 7 ? Colors.orange : AppColors.secondary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isLowStock ? AppColors.error.withOpacity(0.5) : AppColors.border(context),
          width: item.isLowStock ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category Pill & Stock Runway Analytics Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: runwayColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: runwayColor),
                            const SizedBox(width: 4),
                            Text(
                              runwayDays > 90 ? 'Runway: 90+ Days' : 'Runway: $runwayDays Days Left',
                              style: TextStyle(color: runwayColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (item.isLowStock) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.error),
                              SizedBox(width: 4),
                              Text(
                                'LOW STOCK',
                                style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Material Name, Supplier & Financial Valuation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.materialName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Supplier: ${item.supplier ?? 'Direct Vendor'} • Rate: ₹${item.purchasePrice.toStringAsFixed(2)}/${item.unit}',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.totalValuation.toInt()}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryColor(context)),
                      ),
                      Text(
                        'Valuation',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Automated Reorder Recommendation Callout (If Low Stock)
              if (item.isLowStock) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt, size: 14, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                'Automated Reorder Recommendation',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order +${item.recommendedReorderQty.toInt()} ${item.unit} (Est. ₹${item.estimatedReorderCost.toInt()})',
                            style: TextStyle(fontSize: 11, color: AppColors.text(context), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: onGeneratePO,
                        icon: const Icon(Icons.description, size: 12),
                        label: const Text('PO Requisition', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Stock Capacity Progress & Burn Rate Indicator Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Stock (Burn Rate ~${item.estimatedDailyBurnRate.toStringAsFixed(1)} ${item.unit}/day):',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText(context), fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${item.availableStock.toStringAsFixed(1)} ${item.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.isLowStock ? AppColors.error : AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (item.availableStock / (item.minimumStock > 0 ? item.minimumStock * 2 : 100.0)).clamp(0.0, 1.0),
                      backgroundColor: AppColors.border(context),
                      valueColor: AlwaysStoppedAnimation(
                        item.isLowStock ? AppColors.error : AppColors.secondary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showQuickStockDialog(context, true),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.secondary),
                      label: const Text('+ Receive Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showQuickStockDialog(context, false),
                      icon: const Icon(Icons.remove, size: 16, color: AppColors.error),
                      label: const Text('- Issue Material', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.history, size: 20, color: AppColors.primary),
                    onPressed: onTap,
                    tooltip: 'View Stock Movement Logs',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.outline),
                    onPressed: onEdit,
                    tooltip: 'Edit Specifications',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
