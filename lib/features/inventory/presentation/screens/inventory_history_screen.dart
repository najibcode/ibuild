import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/inventory_history_model.dart';
import '../controllers/inventory_controller.dart';

final inventoryHistoryProvider = FutureProvider.family<List<InventoryHistory>, String>((ref, inventoryId) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getHistory(inventoryId);
});

class InventoryHistoryScreen extends ConsumerWidget {
  final InventoryItem item;
  const InventoryHistoryScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(inventoryHistoryProvider(item.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(item.materialName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            margin: const EdgeInsets.all(AppSpacing.containerMargin),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryCol('Category', item.category),
                _summaryCol('Available', '${item.availableStock.toStringAsFixed(1)} ${item.unit}'),
                _summaryCol('Min Level', '${item.minimumStock.toStringAsFixed(1)} ${item.unit}'),
                _summaryCol('Price', '₹${item.purchasePrice.toStringAsFixed(2)}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Change History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain)),
                TextButton.icon(
                  onPressed: () => _showAddEntry(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Entry'),
                ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: AppColors.outline.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No history entries yet.', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => _HistoryTile(entry: entries[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  void _showAddEntry(BuildContext context, WidgetRef ref) {
    String changeType = 'added';
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Stock Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: changeType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'added', child: Text('Added')),
                  DropdownMenuItem(value: 'used', child: Text('Used')),
                  DropdownMenuItem(value: 'adjusted', child: Text('Adjusted')),
                  DropdownMenuItem(value: 'returned', child: Text('Returned')),
                ],
                onChanged: (v) => setModalState(() => changeType = v ?? 'added'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final qty = double.tryParse(qtyCtrl.text);
                  if (qty == null || qty <= 0) return;

                  final entry = InventoryHistory(
                    id: '',
                    inventoryId: item.id,
                    changeType: changeType,
                    quantityChange: qty,
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );

                  final repo = ref.read(inventoryRepositoryProvider);
                  await repo.addHistoryEntry(entry);
                  ref.invalidate(inventoryHistoryProvider(item.id));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final InventoryHistory entry;
  const _HistoryTile({required this.entry});

  IconData _icon() {
    switch (entry.changeType) {
      case 'added': return Icons.add_circle_outline;
      case 'used': return Icons.remove_circle_outline;
      case 'returned': return Icons.undo;
      default: return Icons.tune;
    }
  }

  Color _color() {
    switch (entry.changeType) {
      case 'added': return AppColors.secondary;
      case 'used': return AppColors.error;
      case 'returned': return AppColors.primary;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(_icon(), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.changeType.toUpperCase()} — ${entry.quantityChange.toStringAsFixed(1)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                ),
                if (entry.notes != null) ...[
                  const SizedBox(height: 3),
                  Text(entry.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          if (entry.createdAt != null)
            Text(entry.createdAt!.substring(0, 10), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
