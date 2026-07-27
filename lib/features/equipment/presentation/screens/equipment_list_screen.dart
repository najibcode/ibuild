import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../data/models/equipment_model.dart';
import '../controllers/equipment_controller.dart';

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  String _searchQuery = '';
  String? _categoryFilter;

  static const List<String> _categories = [
    'Heavy Machinery',
    'Power Tools & Machines',
    'Ladders & Climbing',
    'Hand Tools & Site Gear',
    'Generators & Power Units',
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Power Tools & Machines':
        return Icons.construction;
      case 'Ladders & Climbing':
        return Icons.stairs;
      case 'Hand Tools & Site Gear':
        return Icons.handyman_outlined;
      case 'Generators & Power Units':
        return Icons.bolt_outlined;
      case 'Heavy Machinery':
      default:
        return Icons.agriculture_outlined;
    }
  }

  void _showEquipmentFormDialog(BuildContext context, {EquipmentItem? existingItem}) {
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final tagCtrl = TextEditingController(text: existingItem?.tagNumber ?? '');
    final siteCtrl = TextEditingController(text: existingItem?.siteName ?? '');
    final rentalCtrl = TextEditingController(
      text: existingItem != null ? existingItem.rentalCostPerDay.toInt().toString() : '250',
    );
    final fuelCtrl = TextEditingController(
      text: existingItem != null ? existingItem.fuelConsumptionLitersPerDay.toInt().toString() : '0',
    );
    final notesCtrl = TextEditingController(text: existingItem?.notes ?? '');
    String selectedCategory = existingItem?.category ?? 'Power Tools & Machines';
    String selectedStatus = existingItem?.status ?? 'Operational';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg(context),
              title: Row(
                children: [
                  Icon(
                    _getCategoryIcon(selectedCategory),
                    color: AppColors.primaryColor(context),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      existingItem == null ? 'Register Equipment & Tools' : 'Edit Equipment / Tool',
                      style: TextStyle(fontSize: 18, color: AppColors.text(context), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Presets helper for new entries
                    if (existingItem == null) ...[
                      Text(
                        'QUICK ITEM PRESETS:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _presetChip('Drill Machine', 'Power Tools & Machines', 'TL-DRL-101', 'Lorry / Tool Box', '250', '0', 'Carried in lorry for site & vehicle work', nameCtrl, tagCtrl, siteCtrl, rentalCtrl, fuelCtrl, notesCtrl, setDialogState, (c) => selectedCategory = c),
                          _presetChip('Aluminum Ladder', 'Ladders & Climbing', 'LD-12F-04', 'Skyline Phase 1', '150', '0', '12ft heavy duty extension ladder', nameCtrl, tagCtrl, siteCtrl, rentalCtrl, fuelCtrl, notesCtrl, setDialogState, (c) => selectedCategory = c),
                          _presetChip('3-Step Stool', 'Ladders & Climbing', 'ST-03S-09', 'Main Warehouse', '80', '0', 'Large reinforced step stool', nameCtrl, tagCtrl, siteCtrl, rentalCtrl, fuelCtrl, notesCtrl, setDialogState, (c) => selectedCategory = c),
                          _presetChip('JCB Excavator', 'Heavy Machinery', 'EQ-JCB-909', 'Sunrise Towers', '4500', '45', 'Heavy excavator bucket', nameCtrl, tagCtrl, siteCtrl, rentalCtrl, fuelCtrl, notesCtrl, setDialogState, (c) => selectedCategory = c),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 10),
                    ],

                    // Category Selection Dropdown
                    DropdownButtonFormField<String>(
                      value: _categories.contains(selectedCategory) ? selectedCategory : _categories.first,
                      dropdownColor: AppColors.cardBg(context),
                      decoration: InputDecoration(
                        labelText: 'Category / Group',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),

                    // Equipment / Tool Name
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'e.g. Bosch Heavy Drill Machine, 12ft Ladder, Large Stool',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagCtrl,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Tag / Serial #',
                              hintText: 'e.g. TL-DRL-101',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            dropdownColor: AppColors.cardBg(context),
                            decoration: InputDecoration(
                              labelText: 'Status',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                            items: ['Operational', 'In Use', 'Maintenance', 'Idle']
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) => setDialogState(() => selectedStatus = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Site / Storage Location
                    TextField(
                      controller: siteCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Assigned Site / Location',
                        hintText: 'e.g. Lorry Tool Box, Skyline Towers, Main Warehouse',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rentalCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Cost / Value (₹/day)',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: fuelCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Fuel (L/day)',
                              hintText: '0 for manual tools',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes / Usage description
                    TextField(
                      controller: notesCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Usage / Storage Notes',
                        hintText: 'e.g. Kept in lorry for vehicle maintenance & drilling',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final item = EquipmentItem(
                      id: existingItem?.id ?? '',
                      name: nameCtrl.text.trim(),
                      category: selectedCategory,
                      tagNumber: tagCtrl.text.trim().isEmpty
                          ? 'EQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                          : tagCtrl.text.trim(),
                      siteName: siteCtrl.text.trim().isEmpty ? 'Main Site' : siteCtrl.text.trim(),
                      status: selectedStatus,
                      rentalCostPerDay: double.tryParse(rentalCtrl.text) ?? 0.0,
                      fuelConsumptionLitersPerDay: double.tryParse(fuelCtrl.text) ?? 0.0,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      createdAt: existingItem?.createdAt ?? DateTime.now(),
                    );

                    if (existingItem == null) {
                      await ref.read(equipmentControllerProvider.notifier).addEquipment(item);
                    } else {
                      await ref.read(equipmentControllerProvider.notifier).updateEquipment(item);
                    }

                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existingItem == null
                              ? 'Equipment / Tool registered successfully'
                              : 'Equipment / Tool updated successfully'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor(context),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(existingItem == null ? 'Save Entry' : 'Update Entry'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _presetChip(
    String label,
    String category,
    String tag,
    String site,
    String rental,
    String fuel,
    String notes,
    TextEditingController nameCtrl,
    TextEditingController tagCtrl,
    TextEditingController siteCtrl,
    TextEditingController rentalCtrl,
    TextEditingController fuelCtrl,
    TextEditingController notesCtrl,
    StateSetter setDialogState,
    Function(String) setCat,
  ) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      avatar: Icon(_getCategoryIcon(category), size: 14),
      onPressed: () {
        setDialogState(() {
          nameCtrl.text = label;
          tagCtrl.text = tag;
          siteCtrl.text = site;
          rentalCtrl.text = rental;
          fuelCtrl.text = fuel;
          notesCtrl.text = notes;
          setCat(category);
        });
      },
    );
  }

  void _confirmDelete(BuildContext context, EquipmentItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Equipment / Tool'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(equipmentControllerProvider.notifier).deleteEquipment(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(equipmentControllerProvider);
    final equipmentList = eqState.items;

    final filtered = equipmentList.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.tagNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.siteName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == null || e.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    final totalFleet = equipmentList.length;
    final operational = equipmentList.where((e) => e.status == 'Operational' || e.status == 'In Use').length;
    final powerToolsCount = equipmentList.where((e) => e.category == 'Power Tools & Machines').length;
    final laddersCount = equipmentList.where((e) => e.category == 'Ladders & Climbing').length;
    final totalDailyCost = equipmentList.fold<double>(0, (sum, e) => sum + e.rentalCostPerDay);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Equipment, Machinery & Tools',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => ref.read(equipmentControllerProvider.notifier).loadEquipment(),
          ),
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primaryColor(context)),
            onPressed: () => _showEquipmentFormDialog(context),
          ),
        ],
      ),
      body: eqState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Total Fleet & Tools',
                              value: '$totalFleet Items',
                              subtitle: '$operational Active / In Use',
                              icon: Icons.construction,
                              color: AppColors.primaryColor(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Tools & Ladders',
                              value: '${powerToolsCount + laddersCount}',
                              subtitle: '$powerToolsCount Drills/Tools, $laddersCount Ladders',
                              icon: Icons.stairs,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Operational Status',
                              value: '$operational / $totalFleet',
                              subtitle: 'Ready for Site Duty',
                              icon: Icons.check_circle_outline,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Daily Fleet Cost',
                              value: '₹${_fmt(totalDailyCost)}',
                              subtitle: 'Per Day Asset Value',
                              icon: Icons.payments_outlined,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Category Quick Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _categoryFilter == null,
                        label: const Text('All Items'),
                        onSelected: (_) => setState(() => _categoryFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map((cat) {
                        final isSelected = _categoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            avatar: Icon(_getCategoryIcon(cat), size: 14),
                            label: Text(cat),
                            onSelected: (selected) {
                              setState(() {
                                _categoryFilter = selected ? cat : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SearchFilterBar(
                    hintText: 'Search drilling machines, ladders, trucks, tag #...',
                    onSearchChanged: (val) => setState(() => _searchQuery = val),
                    filterOptions: _categories,
                    activeFilter: _categoryFilter,
                    onFilterChanged: (val) => setState(() => _categoryFilter = val),
                  ),
                ),
                const SizedBox(height: 12),

                // Equipment Directory List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.construction, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No equipment or tools found.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add drilling machines, ladders, step stools, or heavy machines.',
                                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildEquipmentCard(context, item);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEquipmentFormDialog(context),
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment / Tool'),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedText(context),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, EquipmentItem item) {
    Color statusColor;
    switch (item.status.toLowerCase()) {
      case 'operational':
      case 'in use':
        statusColor = AppColors.secondary;
        break;
      case 'maintenance':
        statusColor = AppColors.warning;
        break;
      case 'idle':
      default:
        statusColor = AppColors.mutedText(context);
        break;
    }

    final catIcon = _getCategoryIcon(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(catIcon, color: AppColors.primaryColor(context), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tag: ${item.tagNumber} • ${item.category}',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primaryColor(context),
                    onPressed: () => _showEquipmentFormDialog(context, existingItem: item),
                    tooltip: 'Edit Item',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    onPressed: () => _confirmDelete(context, item),
                    tooltip: 'Delete Item',
                  ),
                ],
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: AppColors.primaryColor(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: TextStyle(fontSize: 11, color: AppColors.text(context), fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.mutedText(context)),
                  const SizedBox(width: 4),
                  Text(
                    item.siteName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '₹${_fmt(item.rentalCostPerDay)}/day',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                  ),
                  if (item.fuelConsumptionLitersPerDay > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${item.fuelConsumptionLitersPerDay.toInt()} L/day',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
