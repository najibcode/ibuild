import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/mobile_nav_helper.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/paginated_list.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/date_range_filter_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/models/inventory_item_model.dart';
import '../controllers/inventory_controller.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import 'inventory_form_screen.dart';
import 'inventory_history_screen.dart';

class InventoryListScreen extends ConsumerWidget {
  final VoidCallback? onBackPressed;

  const InventoryListScreen({
    super.key,
    this.onBackPressed,
  });

  static const _categories = [
    'Cement',
    'Steel',
    'Sand',
    'Bricks',
    'Electrical',
    'Plumbing',
    'Wood',
    'Paint',
    'Other',
  ];

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'cement':
        return '🏗️';
      case 'steel':
        return '🔩';
      case 'sand':
        return '⏳';
      case 'bricks':
        return '🧱';
      case 'electrical':
        return '⚡';
      case 'plumbing':
        return '🔧';
      case 'paint':
        return '🎨';
      case 'wood':
        return '🪵';
      default:
        return '📦';
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, InventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: const Text('Delete Material Record'),
        content: Text('Are you sure you want to delete "${item.materialName}" (${item.category})? This will remove all associated stock metrics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Material'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(inventoryControllerProvider.notifier).removeItem(item.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material record deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete material record'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

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
          width: MediaQuery.of(context).size.width < 500 ? double.maxFinite : 480,
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
                    color: AppColors.secondary.withValues(alpha: 0.1),
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
          if (lowStockItems.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () {
                final poText = lowStockItems
                    .map((item) => "• *${item.materialName}*: +${item.recommendedReorderQty.toInt()} ${item.unit} @ INR ${item.purchasePrice}/unit (Est: INR ${item.estimatedReorderCost.toInt()}) [Supplier: ${item.supplier ?? 'Direct Distributor'}]")
                    .join("\n");
                final summaryMsg = "*IBUILD PURCHASE ORDER / REQUISITION*\n"
                    "----------------------------------------\n"
                    "*Total Estimated Value:* INR ${totalPOCost.toInt()}\n"
                    "----------------------------------------\n"
                    "*Items Required:*\n$poText\n"
                    "----------------------------------------\n"
                    "_Generated via IBUILD Construction ERP_";

                WhatsAppHelper.shareMessage(
                  context: context,
                  message: summaryMsg,
                  successNotice: 'Purchase order prepared',
                );
              },
              icon: const Icon(Icons.share, size: 14),
              label: const Text('Share PO to WhatsApp', style: TextStyle(fontSize: 12)),
            ),
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
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Copy Draft', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showInterSiteTransferDialog(BuildContext context, WidgetRef ref, {InventoryItem? preselectedItem}) {
    final items = ref.read(inventoryControllerProvider).items;
    final projects = ref.read(projectControllerProvider).projects;

    InventoryItem? selectedItem = preselectedItem ?? (items.isNotEmpty ? items.first : null);
    String fromSite = 'Central Yard / Warehouse';
    String? toProjectId = projects.isNotEmpty ? projects.first.id : null;
    String? toProjectName = projects.isNotEmpty ? projects.first.name : 'Site Project';
    final qtyCtrl = TextEditingController(text: '10');
    final vehicleCtrl = TextEditingController(text: 'KA-04-E-4921');
    final driverCtrl = TextEditingController(text: 'Ramesh (Lorry Driver)');
    final notesCtrl = TextEditingController(text: 'Site material transfer');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final double qty = double.tryParse(qtyCtrl.text) ?? 0.0;
          final double available = selectedItem?.availableStock ?? 0.0;
          final bool isOver = qty > available && available > 0;

          return AlertDialog(
            backgroundColor: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Inter-Site Stock Transfer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width < 520 ? double.maxFinite : 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer materials from warehouse or site to another project with dispatch gate-pass.',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                    const SizedBox(height: 14),

                    // Material Selector
                    DropdownButtonFormField<InventoryItem>(
                      value: selectedItem,
                      decoration: const InputDecoration(
                        labelText: 'Select Material to Transfer *',
                        prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                        border: OutlineInputBorder(),
                      ),
                      items: items.map((it) => DropdownMenuItem(
                        value: it,
                        child: Text('${it.materialName} (Avail: ${it.availableStock.toInt()} ${it.unit})'),
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedItem = val),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: fromSite,
                            decoration: const InputDecoration(
                              labelText: 'From (Origin) *',
                              prefixIcon: Icon(Icons.warehouse_outlined, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(value: 'Central Yard / Warehouse', child: Text('Central Yard')),
                              ...projects.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                            ],
                            onChanged: (val) => setModalState(() => fromSite = val ?? 'Central Yard / Warehouse'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18, color: AppColors.mutedText(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toProjectId,
                            decoration: const InputDecoration(
                              labelText: 'To (Destination) *',
                              prefixIcon: Icon(Icons.apartment, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                            onChanged: (val) {
                              setModalState(() {
                                toProjectId = val;
                                final match = projects.where((p) => p.id == val);
                                if (match.isNotEmpty) toProjectName = match.first.name;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Quantity (${selectedItem?.unit ?? 'Units'}) *',
                              prefixIcon: const Icon(Icons.numbers, size: 18),
                              errorText: isOver ? 'Exceeds stock (${available.toInt()})' : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: vehicleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle / Lorry No.',
                              prefixIcon: Icon(Icons.directions_car, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: driverCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Driver / Supervisor Name',
                        prefixIcon: Icon(Icons.person_pin, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Transfer Purpose / Requisition Notes',
                        prefixIcon: Icon(Icons.notes, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Gate Pass Preview Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DISPATCH GATE-PASS SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedText(context))),
                          const SizedBox(height: 4),
                          Text(
                            '• Transfer: ${qty.toInt()} ${selectedItem?.unit ?? ''} ${selectedItem?.materialName ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text('• Route: $fromSite ➔ $toProjectName', style: const TextStyle(fontSize: 12)),
                          Text('• Transport: ${vehicleCtrl.text} (${driverCtrl.text})', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final matName = selectedItem?.materialName ?? 'Material';
                  final unit = selectedItem?.unit ?? 'Units';
                  final challanNo = 'GP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                  final passMsg = "*IBUILD SITE DISPATCH & GATE-PASS*\n"
                      "----------------------------------------\n"
                      "*Challan No:* #$challanNo\n"
                      "*Material:* $matName\n"
                      "*Transfer Qty:* ${qty.toInt()} $unit\n"
                      "----------------------------------------\n"
                      "*Origin Site:* $fromSite\n"
                      "*Destination Site:* $toProjectName\n"
                      "*Vehicle No:* ${vehicleCtrl.text}\n"
                      "*Driver Contact:* ${driverCtrl.text}\n"
                      "*Dispatch Notes:* ${notesCtrl.text}\n"
                      "----------------------------------------\n"
                      "_Authorized by IBUILD Site Operations_";

                  WhatsAppHelper.shareMessage(
                    context: context,
                    message: passMsg,
                    successNotice: 'Gate-pass prepared',
                  );
                },
                icon: const Icon(Icons.share, size: 14),
                label: const Text('Share Gate-Pass', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (selectedItem == null || qty <= 0) return;

                  // 1. Deduct stock from inventory
                  await ref.read(inventoryControllerProvider.notifier).adjustStock(selectedItem!, -qty);

                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dispatched ${qty.toInt()} ${selectedItem!.unit} to $toProjectName! ✓'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Dispatch Transfer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor(context),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryControllerProvider);

    // Financial Valuation & Metrics
    final double totalValuation = state.items.fold(0.0, (sum, item) => sum + item.totalValuation);
    final int lowStockCount = state.items.where((item) => item.isLowStock).length;
    final int totalItemsCount = state.items.length;

    final hasBack = onBackPressed != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: MobileNavHelper.buildLeading(
          context,
          hasBack: hasBack,
          onBackPressed: onBackPressed,
        ),
        titleSpacing: (hasBack || MediaQuery.of(context).size.width < 800) ? 0 : 16,
        title: Text(
          'Inventory',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final items = DateRangeFilterHelper.filter(
                state.items,
                start: start,
                end: end,
                getDate: (item) => item.createdAt,
              );
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Material Inventory Stock Report',
                subtitle: 'Valuation & Low Stock Reorder Status',
                headers: ['Item ID', 'Material Name', 'Category', 'Available Stock', 'Price (INR)', 'Total Valuation', 'Status'],
                data: items.map((item) => [
                  item.id.substring(0, 8),
                  item.materialName,
                  item.category,
                  '${item.availableStock} ${item.unit}',
                  'INR ${item.purchasePrice.toStringAsFixed(2)}',
                  'INR ${item.totalValuation.toStringAsFixed(2)}',
                  item.isLowStock ? 'LOW STOCK' : 'Healthy',
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Inventory_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final items = DateRangeFilterHelper.filter(
                state.items,
                start: start,
                end: end,
                getDate: (item) => item.createdAt,
              );
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Inventory',
                title: 'Material Inventory Stock Directory',
                headers: ['Item ID', 'Material Name', 'Category', 'Available Stock', 'Unit', 'Purchase Price (INR)', 'Total Valuation (INR)', 'Low Stock Alert'],
                rows: items.map((item) => [
                  item.id,
                  item.materialName,
                  item.category,
                  item.availableStock,
                  item.unit,
                  item.purchasePrice,
                  item.totalValuation,
                  item.isLowStock ? 'YES' : 'NO',
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Inventory_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
            tooltip: 'Inter-Site Stock Transfer',
            onPressed: () => _showInterSiteTransferDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amber),
            tooltip: 'Auto-Generate PO',
            onPressed: () => _showBulkPurchaseOrderModal(context, state.items),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => ref.read(inventoryControllerProvider.notifier).loadItems(),
            tooltip: 'Refresh Inventory',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Summary Metric Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Stock Valuation',
                    value: '₹${_fmtValuation(totalValuation)}',
                    subtitle: 'Capital Invested',
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
                    subtitle: lowStockCount > 0 ? 'Reorder Needed' : 'Stock Healthy',
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
                    subtitle: 'Tracked Items',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primaryColor(context),
                  ),
                ),
              ],
            ),
          ),

          // Interactive 1-Tap Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => ref.read(inventoryControllerProvider.notifier).setCategoryFilter(null),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: state.categoryFilter == null ? AppColors.primaryColor(context) : AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.categoryFilter == null ? AppColors.primaryColor(context) : AppColors.border(context),
                        ),
                      ),
                      child: Text(
                        'All Materials',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: state.categoryFilter == null ? Colors.white : AppColors.text(context),
                        ),
                      ),
                    ),
                  ),
                ),
                ..._categories.map((cat) {
                  final isSelected = state.categoryFilter == cat;
                  final emoji = _getCategoryEmoji(cat);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        ref.read(inventoryControllerProvider.notifier).setCategoryFilter(isSelected ? null : cat);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryColor(context) : AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryColor(context) : AppColors.border(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.text(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),


          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SearchFilterBar(
              hintText: 'Search material, category, supplier...',
              onSearchChanged: (q) => ref.read(inventoryControllerProvider.notifier).setSearch(q),
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
              emptyMessage: 'No inventory items found. Tap "+ Add Material" to add a new record.',
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
                onDelete: () => _confirmDelete(context, ref, item),
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
          backgroundColor: AppColors.primaryColor(context),
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
        borderRadius: BorderRadius.circular(14),
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
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _fmtValuation(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _InventoryCard extends ConsumerWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(double delta) onAdjustStock;
  final VoidCallback onGeneratePO;

  const _InventoryCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjustStock,
    required this.onGeneratePO,
  });

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cement':
        return Icons.layers_outlined;
      case 'steel':
        return Icons.hardware_outlined;
      case 'sand':
        return Icons.grain_outlined;
      case 'bricks':
        return Icons.foundation_outlined;
      case 'electrical':
        return Icons.bolt_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      case 'paint':
        return Icons.format_paint_outlined;
      case 'wood':
        return Icons.carpenter_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  void _showReceiveStockModal(BuildContext context, WidgetRef ref) {
    final qtyController = TextEditingController();
    final supplierController = TextEditingController(text: item.supplier ?? '');
    final priceController =
        TextEditingController(text: item.purchasePrice.toStringAsFixed(2));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text(
              'Receive Stock Delivery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width < 460 ? double.maxFinite : 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.materialName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.text(context),
                              ),
                            ),
                            Text(
                              'Current Available: ${item.availableStock.toStringAsFixed(1)} ${item.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Supplier
                TextField(
                  controller: supplierController,
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: const InputDecoration(
                    labelText: 'Received From / Supplier *',
                    hintText: 'e.g. Ultratech Cement Depot, Hardware Store',
                    prefixIcon: Icon(Icons.storefront_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Quantity Received
                TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: InputDecoration(
                    labelText: 'Quantity Received *',
                    suffixText: item.unit,
                    prefixIcon: const Icon(Icons.add_box_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Purchase Price per Unit
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Rate per Unit (\u20B9)',
                    prefixText: '\u20B9 ',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes / Ref
                TextField(
                  controller: notesController,
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: const InputDecoration(
                    labelText: 'Delivery Notes / Invoice Ref (Optional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final rawSupplier = supplierController.text.trim();
              final supplier = rawSupplier.isNotEmpty
                  ? rawSupplier
                  : (item.supplier?.isNotEmpty == true
                      ? item.supplier!
                      : 'Vendor Delivery');
              final qty = double.tryParse(qtyController.text);
              final unitPrice = double.tryParse(priceController.text);

              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity received'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final success = await ref
                  .read(inventoryControllerProvider.notifier)
                  .receiveStock(
                    item: item,
                    quantity: qty,
                    supplier: supplier,
                    unitPrice: unitPrice,
                    notes: notesController.text.trim(),
                  );

              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Received +${qty.toStringAsFixed(1)} ${item.unit} of ${item.materialName} from $supplier into stock',
                      ),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to record stock delivery'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirm Receive Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }



  void _showIssueMaterialModal(BuildContext context, WidgetRef ref) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    double liveExpenseAmount = 0.0;

    final projectState = ref.read(projectControllerProvider);
    final projects = projectState.projects;

    String? selectedProjectId = projects.isNotEmpty ? projects.first.id : 'general';
    String? selectedProjectName = projects.isNotEmpty ? projects.first.name : 'General Site';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          void updateExpenseAmount(String val) {
            final qty = double.tryParse(val) ?? 0.0;
            setState(() {
              liveExpenseAmount = qty * item.purchasePrice;
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Issue Material to Site Project',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width < 460 ? double.maxFinite : 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.materialName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.text(context),
                                  ),
                                ),
                                Text(
                                  'Available: ${item.availableStock.toStringAsFixed(1)} ${item.unit} • Rate: \u20B9${item.purchasePrice.toStringAsFixed(2)}/${item.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select Project Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedProjectId,
                      dropdownColor: AppColors.cardBg(context),
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: const InputDecoration(
                        labelText: 'Select Target Site Project *',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        if (projects.isEmpty)
                          const DropdownMenuItem<String>(
                            value: 'general',
                            child: Text('General / Non-Project Site'),
                          ),
                        ...projects.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              p.name,
                              style: TextStyle(color: AppColors.text(context)),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          if (val == 'general') {
                            setState(() {
                              selectedProjectId = 'general';
                              selectedProjectName = 'General Site';
                            });
                          } else {
                            final p = projects.firstWhere(
                              (proj) => proj.id == val,
                            );
                            setState(() {
                              selectedProjectId = p.id;
                              selectedProjectName = p.name;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quantity to Issue
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      style: TextStyle(color: AppColors.text(context)),
                      onChanged: updateExpenseAmount,
                      decoration: InputDecoration(
                        labelText: 'Quantity to Issue *',
                        suffixText: item.unit,
                        prefixIcon: const Icon(Icons.remove_circle_outline),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Auto-Calculated Expense Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Automated Project Expense Charging:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\u20B9${liveExpenseAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  selectedProjectId != 'general'
                                      ? 'Will be recorded as Material Expense for ${selectedProjectName ?? "selected project"}'
                                      : 'Will update inventory stock levels',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Purpose Notes
                    TextField(
                      controller: notesController,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: const InputDecoration(
                        labelText: 'Issue Purpose / Notes (Optional)',
                        hintText: 'e.g. Ground Floor Slab Casting',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (selectedProjectId == null ||
                      selectedProjectName == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a valid project'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  final qty = double.tryParse(qtyController.text);
                  if (qty == null || qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid quantity to issue'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  if (qty > item.availableStock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot issue $qty ${item.unit}. Only ${item.availableStock} ${item.unit} available in stock!',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  final success = await ref
                      .read(inventoryControllerProvider.notifier)
                      .issueMaterialToProject(
                        item: item,
                        quantity: qty,
                        projectId: selectedProjectId!,
                        projectName: selectedProjectName!,
                        notes: notesController.text.trim(),
                      );

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            selectedProjectId != 'general'
                                ? 'Issued ${qty.toStringAsFixed(1)} ${item.unit} of ${item.materialName} to $selectedProjectName. Recorded \u20B9${(qty * item.purchasePrice).toStringAsFixed(0)} material expense.'
                                : 'Issued ${qty.toStringAsFixed(1)} ${item.unit} of ${item.materialName}. Stock updated ✓',
                          ),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to issue material'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Issue & Charge Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          color: item.isLowStock
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.border(context),
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
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor(
                            context,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _categoryIcon(item.category),
                          size: 16,
                          color: AppColors.primaryColor(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor(
                            context,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primaryColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: runwayColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: runwayColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  runwayDays > 90
                                      ? 'Runway: 90+ Days'
                                      : 'Runway: $runwayDays Days Left',
                                  style: TextStyle(
                                    color: runwayColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.isLowStock) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 12,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LOW STOCK',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    onPressed: onDelete,
                    tooltip: 'Delete Material Record',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Material Name & Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.materialName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Supplier: ${item.supplier ?? 'Direct Vendor'} • Rate: \u20B9${item.purchasePrice.toStringAsFixed(2)}/${item.unit}',
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '\u20B9${item.totalValuation >= 100000 ? '${(item.totalValuation / 100000).toStringAsFixed(2)} L' : item.totalValuation.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryColor(context),
                          ),
                        ),
                      ),
                      Text(
                        'Valuation',
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Low Stock Callout
              if (item.isLowStock) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bolt, size: 14, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'Automated Reorder Recommendation',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Order +${item.recommendedReorderQty.toInt()} ${item.unit} (Est. \u20B9${item.estimatedReorderCost.toInt()})',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.text(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onGeneratePO,
                        icon: const Icon(Icons.description, size: 12),
                        label: const Text(
                          'PO Requisition',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Available Stock Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Available Stock (Burn Rate ~${item.estimatedDailyBurnRate.toStringAsFixed(1)} ${item.unit}/day):',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${item.availableStock.toStringAsFixed(1)} ${item.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.isLowStock
                                ? AppColors.error
                                : AppColors.text(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (item.availableStock /
                                  (item.minimumStock > 0
                                      ? item.minimumStock * 2
                                      : 100.0))
                              .clamp(0.0, 1.0),
                      backgroundColor: AppColors.border(context),
                      valueColor: AlwaysStoppedAnimation(
                        item.isLowStock
                            ? AppColors.error
                            : AppColors.secondary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReceiveStockModal(context, ref),
                      icon: const Icon(
                        Icons.add,
                        size: 15,
                      ),
                      label: const Text(
                        'Receive Stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showIssueMaterialModal(context, ref),
                      icon: const Icon(
                        Icons.remove,
                        size: 15,
                      ),
                      label: const Text(
                        'Issue Material',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.history,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: onTap,
                    tooltip: 'View Stock Movement Logs',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.outline,
                    ),
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
