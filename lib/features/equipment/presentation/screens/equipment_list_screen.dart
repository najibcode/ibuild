import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
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
    final projects = ref.read(projectControllerProvider).projects;

    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final tagCtrl = TextEditingController(text: existingItem?.tagNumber ?? '');
    final siteCtrl = TextEditingController(text: existingItem?.siteName ?? '');
    final rentalCtrl = TextEditingController(
      text: existingItem != null ? existingItem.rentalCostPerDay.toStringAsFixed(0) : '0',
    );
    final fuelCtrl = TextEditingController(
      text: existingItem != null ? existingItem.fuelConsumptionLitersPerDay.toStringAsFixed(0) : '0',
    );
    final notesCtrl = TextEditingController(text: existingItem?.notes ?? '');
    String selectedCategory = existingItem?.category ?? _categories.first;
    String selectedStatus = existingItem?.status ?? 'Operational';
    String? selectedProjectId = existingItem?.projectId;

    // Options for location search dropdown
    final projectNames = projects.map((p) => p.name).toList();
    final defaultLocations = ['Lorry / Vehicle Tool Box', 'Main Warehouse', 'Central Pool'];
    final locationOptions = <String>{...projectNames, ...defaultLocations}.toList();

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
                      existingItem == null ? 'Register Equipment / Tool' : 'Edit Equipment / Tool',
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
                    // Category Selection
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

                    // Equipment Name
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Item Name *',
                        hintText: 'e.g. Bosch Heavy Duty Drill Machine',
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

                    // Searchable Location / Project Field (Search Dropdown + Custom Typing)
                    Text(
                      'LOCATION / ASSIGNED SITE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    RawAutocomplete<String>(
                      textEditingController: siteCtrl,
                      focusNode: FocusNode(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return locationOptions;
                        }
                        return locationOptions.where((option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setDialogState(() {
                          siteCtrl.text = selection;
                          final matchedProject = projects.where((p) => p.name.toLowerCase() == selection.toLowerCase()).firstOrNull;
                          selectedProjectId = matchedProject?.id;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: InputDecoration(
                            labelText: 'Location / Site Name',
                            hintText: 'Type to search project (e.g. RVS) or type custom spot...',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryColor(context)),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      controller.clear();
                                      setDialogState(() => selectedProjectId = null);
                                    },
                                  )
                                : const Icon(Icons.arrow_drop_down, size: 22),
                            labelStyle: TextStyle(color: AppColors.mutedText(context)),
                          ),
                          onChanged: (val) {
                            final matchedProject = projects.where((p) => p.name.toLowerCase() == val.toLowerCase()).firstOrNull;
                            setDialogState(() {
                              selectedProjectId = matchedProject?.id;
                            });
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: AppColors.cardBg(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 180, maxWidth: 320),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border(context)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  final isProject = projectNames.contains(option);
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      isProject ? Icons.apartment : Icons.place_outlined,
                                      size: 18,
                                      color: isProject ? AppColors.primaryColor(context) : AppColors.secondary,
                                    ),
                                    title: Text(
                                      option,
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                        fontWeight: isProject ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: isProject
                                        ? Text('Registered Project Site', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)))
                                        : null,
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),

                    // Location Quick Suggestion Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: locationOptions.take(4).map((loc) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(loc, style: const TextStyle(fontSize: 11)),
                          avatar: const Icon(Icons.place, size: 12),
                          onPressed: () {
                            setDialogState(() {
                              siteCtrl.text = loc;
                              final matchedProject = projects.where((p) => p.name.toLowerCase() == loc.toLowerCase()).firstOrNull;
                              selectedProjectId = matchedProject?.id;
                            });
                          },
                        );
                      }).toList(),
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
                              labelText: 'Daily Value / Rate (₹)',
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

                    // Notes / Remarks
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Usage / Maintenance Notes',
                        hintText: 'e.g. Carried in lorry for vehicle maintenance & site work',
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
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an item name')),
                      );
                      return;
                    }

                    final item = EquipmentItem(
                      id: existingItem?.id ?? '',
                      name: nameCtrl.text.trim(),
                      category: selectedCategory,
                      tagNumber: tagCtrl.text.trim().isEmpty
                          ? 'EQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                          : tagCtrl.text.trim(),
                      siteName: siteCtrl.text.trim().isEmpty ? 'Main Site' : siteCtrl.text.trim(),
                      projectId: selectedProjectId,
                      status: selectedStatus,
                      rentalCostPerDay: double.tryParse(rentalCtrl.text) ?? 0.0,
                      fuelConsumptionLitersPerDay: double.tryParse(fuelCtrl.text) ?? 0.0,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      createdAt: existingItem?.createdAt ?? DateTime.now(),
                    );

                    final bool success;
                    if (existingItem == null) {
                      success = await ref.read(equipmentControllerProvider.notifier).addEquipment(item);
                    } else {
                      success = await ref.read(equipmentControllerProvider.notifier).updateEquipment(item);
                    }

                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(existingItem == null
                                ? 'Item registered successfully'
                                : 'Item updated successfully'),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      } else {
                        final err = ref.read(equipmentControllerProvider).error ?? 'Operation failed';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save to backend: $err'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
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

  void _confirmDelete(BuildContext context, EquipmentItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Equipment / Tool'),
        content: Text('Are you sure you want to delete "${item.name}" from the database?'),
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
      final success = await ref.read(equipmentControllerProvider.notifier).deleteEquipment(item.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully from database')),
          );
        } else {
          final err = ref.read(equipmentControllerProvider).error ?? 'Delete failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $err'), backgroundColor: AppColors.error),
          );
        }
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
          : eqState.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Backend Connection Error',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          eqState.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(equipmentControllerProvider.notifier).loadEquipment(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  ),
                )
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
                                    'Click "+ Add Equipment / Tool" to register items in Supabase.',
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
