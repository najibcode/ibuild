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

  void _showAddEquipmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    final siteCtrl = TextEditingController();
    final rentalCtrl = TextEditingController(text: '3500');
    final fuelCtrl = TextEditingController(text: '50');
    String selectedCategory = 'Excavator';
    String selectedStatus = 'Operational';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg(context),
              title: Text('Register Heavy Machinery', style: TextStyle(color: AppColors.text(context))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Machinery Name',
                        hintText: 'e.g. JCB 3DX Backhoe',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Tag / Serial Number',
                        hintText: 'e.g. EQ-JCB-909',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: siteCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Assigned Site Name',
                        hintText: 'e.g. Skyline Towers Phase 1',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            dropdownColor: AppColors.cardBg(context),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                            items: ['Excavator', 'Concrete Mixer', 'Dump Truck', 'Crane', 'Generator']
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) => setDialogState(() => selectedCategory = val!),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rentalCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Rental Rate (₹/day)',
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
                              labelText: 'Fuel (Liters/day)',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                      ],
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
                    final newItem = EquipmentItem(
                      id: '',
                      name: nameCtrl.text.trim(),
                      category: selectedCategory,
                      tagNumber: tagCtrl.text.trim().isEmpty ? 'EQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}' : tagCtrl.text.trim(),
                      siteName: siteCtrl.text.trim().isEmpty ? 'Main Site' : siteCtrl.text.trim(),
                      status: selectedStatus,
                      rentalCostPerDay: double.tryParse(rentalCtrl.text) ?? 0.0,
                      fuelConsumptionLitersPerDay: double.tryParse(fuelCtrl.text) ?? 0.0,
                      createdAt: DateTime.now(),
                    );

                    await ref.read(equipmentControllerProvider.notifier).addEquipment(newItem);
                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Machinery equipment added successfully')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor(context),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register Fleet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(equipmentControllerProvider);
    final equipmentList = eqState.items;

    final categories = equipmentList.map((e) => e.category).toSet().toList();

    final filtered = equipmentList.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.tagNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.siteName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == null || e.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    final totalFleet = equipmentList.length;
    final operational = equipmentList.where((e) => e.status == 'Operational' || e.status == 'In Use').length;
    final maintenance = equipmentList.where((e) => e.status == 'Maintenance').length;
    final totalDailyRentalCost = equipmentList.fold<double>(0, (sum, e) => sum + e.rentalCostPerDay);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Machinery & Heavy Equipment Fleet',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => ref.read(equipmentControllerProvider.notifier).loadEquipment(),
          ),
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primaryColor(context)),
            onPressed: () => _showAddEquipmentDialog(context),
          ),
        ],
      ),
      body: eqState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Metrics Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Total Fleet',
                              value: '$totalFleet Units',
                              subtitle: 'Registered',
                              icon: Icons.agriculture_outlined,
                              color: AppColors.primaryColor(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Operational',
                              value: '$operational / $totalFleet',
                              subtitle: 'Active On Site',
                              icon: Icons.check_circle_outline,
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
                              title: 'In Repair',
                              value: '$maintenance Units',
                              subtitle: 'Maintenance',
                              icon: Icons.build_outlined,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Daily Rental',
                              value: '₹${_fmt(totalDailyRentalCost)}',
                              subtitle: 'Fleet Cost/Day',
                              icon: Icons.payments_outlined,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search & Category Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SearchFilterBar(
                        hintText: 'Search machinery name, tag #, site...',
                        onSearchChanged: (val) => setState(() => _searchQuery = val),
                        filterOptions: categories,
                        activeFilter: _categoryFilter,
                        onFilterChanged: (val) => setState(() => _categoryFilter = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Fleet List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.agriculture_outlined, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No machinery found.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
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
        onPressed: () => _showAddEquipmentDialog(context),
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Machinery'),
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
      padding: const EdgeInsets.all(14),
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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedText(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                      child: Icon(Icons.agriculture_outlined, color: AppColors.primaryColor(context), size: 20),
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
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
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
                  const SizedBox(width: 12),
                  Text(
                    '${item.fuelConsumptionLitersPerDay.toInt()} L/day',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                  ),
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
