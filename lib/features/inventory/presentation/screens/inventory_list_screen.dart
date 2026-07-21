import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(inventoryControllerProvider.notifier).loadItems(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.containerMargin, AppSpacing.stackSm, AppSpacing.containerMargin, 0),
            child: SearchFilterBar(
              hintText: 'Search materials...',
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
          const SizedBox(height: AppSpacing.stackSm),
          Expanded(
            child: PaginatedListView<InventoryItem>(
              items: state.items,
              isLoading: state.isLoading,
              hasMore: state.hasMore,
              onLoadMore: () => ref.read(inventoryControllerProvider.notifier).loadMore(),
              emptyMessage: 'No inventory items found.',
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
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: PermissionGuard(
        permission: 'inventory.create',
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InventoryFormScreen()),
            );
            ref.read(inventoryControllerProvider.notifier).loadItems();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _InventoryCard({required this.item, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isLowStock
                      ? AppColors.error.withOpacity(0.08)
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: item.isLowStock ? AppColors.error : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textMain)),
                        ),
                        if (item.isLowStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Text('LOW', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${item.category} • ${item.availableStock.toStringAsFixed(1)} ${item.unit}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('₹${item.purchasePrice.toStringAsFixed(2)} / ${item.unit}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.outline),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
