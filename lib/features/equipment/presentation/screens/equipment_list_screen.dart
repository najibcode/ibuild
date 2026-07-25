import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';

class EquipmentItem {
  final String id;
  final String name;
  final String category;
  final String tagNumber;
  final String siteName;
  final String status; // Operational, In Use, Maintenance, Idle
  final double rentalCostPerDay;
  final double fuelConsumptionLitersPerDay;

  EquipmentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.tagNumber,
    required this.siteName,
    required this.status,
    required this.rentalCostPerDay,
    required this.fuelConsumptionLitersPerDay,
  });
}

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  String _searchQuery = '';
  String? _categoryFilter;

  final List<EquipmentItem> _equipmentList = [
    EquipmentItem(
      id: 'eq-1',
      name: 'JCB 3DX Super Backhoe Loader',
      category: 'Excavator',
      tagNumber: 'EQ-JCB-902',
      siteName: 'Skyline Luxury Towers',
      status: 'Operational',
      rentalCostPerDay: 4500,
      fuelConsumptionLitersPerDay: 65,
    ),
    EquipmentItem(
      id: 'eq-2',
      name: 'Schwing Stetter Concrete Pump',
      category: 'Concrete Mixer',
      tagNumber: 'EQ-CP-401',
      siteName: 'Metro Pillar Section B',
      status: 'In Use',
      rentalCostPerDay: 8000,
      fuelConsumptionLitersPerDay: 110,
    ),
    EquipmentItem(
      id: 'eq-3',
      name: 'Ashok Leyland 10-Ton Dumper Truck',
      category: 'Dump Truck',
      tagNumber: 'EQ-DT-882',
      siteName: 'Highway Overpass Site',
      status: 'Maintenance',
      rentalCostPerDay: 3200,
      fuelConsumptionLitersPerDay: 50,
    ),
    EquipmentItem(
      id: 'eq-4',
      name: 'TATA 25-Ton Mobile Crane',
      category: 'Crane',
      tagNumber: 'EQ-CR-110',
      siteName: 'Commercial Complex Phase 2',
      status: 'Operational',
      rentalCostPerDay: 12000,
      fuelConsumptionLitersPerDay: 140,
    ),
    EquipmentItem(
      id: 'eq-5',
      name: 'Kirloskar 62.5 kVA Diesel Generator',
      category: 'Generator',
      tagNumber: 'EQ-DG-505',
      siteName: 'Skyline Luxury Towers',
      status: 'Idle',
      rentalCostPerDay: 1800,
      fuelConsumptionLitersPerDay: 35,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = _equipmentList.map((e) => e.category).toSet().toList();

    final filtered = _equipmentList.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.tagNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.siteName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _categoryFilter == null || e.category.toLowerCase() == _categoryFilter!.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    final totalMachines = _equipmentList.length;
    final operationalCount = _equipmentList.where((e) => e.status == 'Operational' || e.status == 'In Use').length;
    final maintenanceCount = _equipmentList.where((e) => e.status == 'Maintenance').length;
    final totalDailyCost = _equipmentList.fold(0.0, (sum, e) => sum + e.rentalCostPerDay);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: Text(
          'Machinery & Equipment Fleet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Fleet Metric Header Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Fleet',
                    value: '$totalMachines',
                    subtitle: '$operationalCount On Site',
                    icon: Icons.agriculture_outlined,
                    color: AppColors.primaryColor(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Operational',
                    value: '$operationalCount',
                    subtitle: 'Ready / Active',
                    icon: Icons.check_circle_outline,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Under Repair',
                    value: '$maintenanceCount',
                    subtitle: 'In Workshop',
                    icon: Icons.build_outlined,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Daily Fleet Cost',
                    value: '₹${totalDailyCost.toInt()}',
                    subtitle: 'Daily Operating',
                    icon: Icons.payments_outlined,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Search & Category Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchFilterBar(
              hintText: 'Search machinery, tag no, site assignment...',
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              filterOptions: categories,
              activeFilter: _categoryFilter,
              onFilterChanged: (f) => setState(() => _categoryFilter = f),
            ),
          ),
          const SizedBox(height: 10),

          // Machinery List Cards
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No machinery matching "$_searchQuery".',
                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Machinery allocation dialog opened.')),
          );
        },
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Allocate Machinery'),
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

  Widget _buildEquipmentCard(BuildContext context, EquipmentItem item) {
    Color statusColor;
    switch (item.status) {
      case 'Operational':
      case 'In Use':
        statusColor = AppColors.secondary;
        break;
      case 'Maintenance':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.mutedText(context);
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.precision_manufacturing_outlined, color: AppColors.primaryColor(context), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tagNumber,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                      ),
                      Text(
                        item.category.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: AppColors.mutedText(context), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: AppColors.mutedText(context)),
              const SizedBox(width: 4),
              Text(
                'Assigned Site: ${item.siteName}',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCell(context, 'Daily Rental', '₹${item.rentalCostPerDay.toInt()}/day', AppColors.text(context)),
                _infoCell(context, 'Fuel Burn', '${item.fuelConsumptionLitersPerDay.toInt()} L/day', AppColors.primaryColor(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(BuildContext context, String label, String val, Color valColor) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.mutedText(context))),
      ],
    );
  }
}
