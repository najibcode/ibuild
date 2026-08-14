import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../data/models/equipment_model.dart';
import '../controllers/equipment_controller.dart';

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() =>
      _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  String _searchQuery = '';
  String? _categoryFilter;

  static const List<String> _categories = [
    'Vehicles & Transport',
    'Heavy Machinery',
    'Power Tools & Machines',
    'Ladders & Climbing',
    'Hand Tools & Site Gear',
    'Generators & Power Units',
  ];

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Vehicles':
      case 'Vehicles & Transport':
        return '🚛';
      case 'Power Tools & Machines':
        return '🛠️';
      case 'Ladders & Climbing':
        return '🪜';
      case 'Hand Tools & Site Gear':
        return '🧰';
      case 'Generators & Power Units':
        return '⚡';
      case 'Heavy Machinery':
      default:
        return '🚜';
    }
  }

  // Track fuel type selection for Vehicles & Transport
  String _fuelTypeNotifier = 'Diesel';

  // ─── Category-Aware Dynamic Field Config ───

  String _nameLabel(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'Vehicle Name / Model *';
      case 'Heavy Machinery':
        return 'Machine Name / Model *';
      case 'Power Tools & Machines':
        return 'Tool / Machine Name *';
      case 'Ladders & Climbing':
        return 'Ladder / Scaffold Name *';
      case 'Generators & Power Units':
        return 'Generator / Power Unit Name *';
      case 'Hand Tools & Site Gear':
        return 'Tool / Gear Name *';
      default:
        return 'Item Name *';
    }
  }

  String _nameHint(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'e.g. Tata 407 Lorry, Mahindra Bolero Pickup';
      case 'Heavy Machinery':
        return 'e.g. JCB 3DX Backhoe Loader, Caterpillar Excavator';
      case 'Power Tools & Machines':
        return 'e.g. Bosch Heavy Duty Drill, Hilti Rotary Hammer';
      case 'Ladders & Climbing':
        return 'e.g. 12ft Aluminium Extension Ladder';
      case 'Generators & Power Units':
        return 'e.g. Kirloskar 5kVA Silent Generator';
      case 'Hand Tools & Site Gear':
        return 'e.g. Measuring Tape 30m, Spirit Level Set';
      default:
        return 'e.g. Equipment item name';
    }
  }

  String _tagLabel(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'Vehicle Reg. No. *';
      case 'Heavy Machinery':
        return 'Machine Serial #';
      case 'Power Tools & Machines':
        return 'Tool Serial / Code #';
      case 'Ladders & Climbing':
        return 'Ladder Tag / ID';
      case 'Generators & Power Units':
        return 'Generator Serial #';
      case 'Hand Tools & Site Gear':
        return 'Tool Code / ID';
      default:
        return 'Tag / Serial #';
    }
  }

  String _tagHint(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'e.g. KL-07-AB-1234';
      case 'Heavy Machinery':
        return 'e.g. JCB-3DX-2024-001';
      case 'Power Tools & Machines':
        return 'e.g. PT-DRL-101';
      case 'Ladders & Climbing':
        return 'e.g. LD-ALU-12FT-01';
      case 'Generators & Power Units':
        return 'e.g. GEN-5KVA-001';
      case 'Hand Tools & Site Gear':
        return 'e.g. HT-TAPE-001';
      default:
        return 'e.g. EQ-001';
    }
  }

  List<String> _statusOptions(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return [
          'Operational',
          'In Use / On Road',
          'Maintenance / Service',
          'Parked / Idle',
          'Breakdown',
        ];
      case 'Heavy Machinery':
        return ['Operational', 'In Use', 'Maintenance', 'Idle', 'Breakdown'];
      case 'Power Tools & Machines':
        return ['Operational', 'In Use', 'Repair', 'Idle', 'Damaged'];
      case 'Ladders & Climbing':
        return ['Operational', 'In Use', 'Inspection Due', 'Damaged'];
      case 'Generators & Power Units':
        return ['Operational', 'Running', 'Maintenance', 'Idle', 'Fuel Empty'];
      case 'Hand Tools & Site Gear':
        return ['Available', 'In Use', 'Lost', 'Damaged'];
      default:
        return ['Operational', 'In Use', 'Maintenance', 'Idle'];
    }
  }

  String _costLabel(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'Daily Rental / Running Cost (₹)';
      case 'Heavy Machinery':
        return 'Hourly / Daily Hire Rate (₹)';
      case 'Generators & Power Units':
        return 'Daily Running Cost (₹)';
      default:
        return 'Daily Value / Rate (₹)';
    }
  }

  bool _showFuelField(String cat) {
    return cat == 'Vehicles & Transport' ||
        cat == 'Heavy Machinery' ||
        cat == 'Generators & Power Units';
  }

  String _fuelLabel(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'Mileage / Fuel (L/day)';
      case 'Heavy Machinery':
        return 'Fuel Usage (L/hr)';
      case 'Generators & Power Units':
        return 'Fuel Usage (L/hr)';
      default:
        return 'Fuel (L/day)';
    }
  }

  String _fuelHint(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'e.g. 15';
      case 'Heavy Machinery':
        return 'e.g. 8';
      case 'Generators & Power Units':
        return 'e.g. 2.5';
      default:
        return '0 for manual tools';
    }
  }

  String _locationSectionLabel(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'PARKING / ASSIGNED SITE';
      case 'Heavy Machinery':
        return 'DEPLOYED SITE / LOCATION';
      case 'Generators & Power Units':
        return 'GENERATOR LOCATION / SITE';
      default:
        return 'LOCATION / ASSIGNED SITE';
    }
  }

  String _locationFieldLabel(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'Parking Bay / Assigned Site';
      case 'Heavy Machinery':
        return 'Deployed Site / Project';
      default:
        return 'Location / Site Name';
    }
  }

  String _locationHint(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'e.g. Parking Bay 3, Skyline Project Site';
      case 'Heavy Machinery':
        return 'e.g. Foundation Pit Section A, Tower Block 2';
      default:
        return 'Type ANY custom location (e.g. Lorry 04 Tool Box, Bay 3, etc.)...';
    }
  }

  String _notesLabel(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'Vehicle Notes / Service Info';
      case 'Heavy Machinery':
        return 'Operator Notes / Service History';
      case 'Power Tools & Machines':
        return 'Tool Condition / Maintenance Notes';
      case 'Generators & Power Units':
        return 'Runtime Hours / Service Notes';
      default:
        return 'Usage / Maintenance Notes';
    }
  }

  String _notesHint(String cat) {
    switch (cat) {
      case 'Vehicles & Transport':
        return 'e.g. Last serviced 15 Jan, next service at 45000 km';
      case 'Heavy Machinery':
        return 'e.g. Operated by Raju, 2500 hrs runtime, next service at 3000 hrs';
      case 'Power Tools & Machines':
        return 'e.g. Blade replaced on 10 Jan, carbons checked';
      case 'Generators & Power Units':
        return 'e.g. 1200 hrs runtime, oil change due at 1500 hrs';
      case 'Ladders & Climbing':
        return 'e.g. Inspected 01 Jan, good condition, rubber feet replaced';
      case 'Hand Tools & Site Gear':
        return 'e.g. Set of 12, 2 missing, stored in red toolbox';
      default:
        return 'e.g. Any relevant notes about usage or maintenance';
    }
  }

  /// Build category-specific extra fields (e.g. Fuel Type for Vehicles)
  List<Widget> _buildCategorySpecificFields(
    BuildContext context,
    String cat,
    void Function(void Function()) setDialogState, {
    required String fuelTypeNotifier,
  }) {
    switch (cat) {
      case 'Vehicles & Transport':
        return [
          // Fuel Type selector
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'FUEL TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['Diesel', 'Petrol', 'CNG', 'Electric'].map((fuel) {
              final isSelected = _fuelTypeNotifier == fuel;
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                selected: isSelected,
                label: Text(
                  fuel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.text(context),
                  ),
                ),
                avatar: Icon(
                  fuel == 'Diesel'
                      ? Icons.local_gas_station
                      : fuel == 'Petrol'
                      ? Icons.local_gas_station_outlined
                      : fuel == 'CNG'
                      ? Icons.propane_tank_outlined
                      : Icons.ev_station_outlined,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : AppColors.primaryColor(context),
                ),
                selectedColor: AppColors.primaryColor(context),
                backgroundColor: AppColors.cardBg(context),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryColor(context)
                      : AppColors.border(context),
                ),
                onSelected: (_) =>
                    setDialogState(() => _fuelTypeNotifier = fuel),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ];

      case 'Heavy Machinery':
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'POWER SOURCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['Diesel', 'Electric', 'Hydraulic'].map((src) {
              final isSelected = _fuelTypeNotifier == src;
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                selected: isSelected,
                label: Text(
                  src,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.text(context),
                  ),
                ),
                selectedColor: AppColors.primaryColor(context),
                backgroundColor: AppColors.cardBg(context),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryColor(context)
                      : AppColors.border(context),
                ),
                onSelected: (_) =>
                    setDialogState(() => _fuelTypeNotifier = src),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ];

      case 'Power Tools & Machines':
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'POWER TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                [
                  'Corded Electric',
                  'Battery / Cordless',
                  'Pneumatic (Air)',
                  'Petrol Engine',
                ].map((src) {
                  final isSelected = _fuelTypeNotifier == src;
                  return ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    selected: isSelected,
                    label: Text(
                      src,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : AppColors.text(context),
                      ),
                    ),
                    selectedColor: AppColors.primaryColor(context),
                    backgroundColor: AppColors.cardBg(context),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryColor(context)
                          : AppColors.border(context),
                    ),
                    onSelected: (_) =>
                        setDialogState(() => _fuelTypeNotifier = src),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
        ];

      case 'Generators & Power Units':
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'FUEL TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['Diesel', 'Petrol', 'Solar / Hybrid'].map((fuel) {
              final isSelected = _fuelTypeNotifier == fuel;
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                selected: isSelected,
                label: Text(
                  fuel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.text(context),
                  ),
                ),
                selectedColor: AppColors.primaryColor(context),
                backgroundColor: AppColors.cardBg(context),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryColor(context)
                      : AppColors.border(context),
                ),
                onSelected: (_) =>
                    setDialogState(() => _fuelTypeNotifier = fuel),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ];

      case 'Ladders & Climbing':
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'MATERIAL TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                [
                  'Aluminium',
                  'Steel / Iron',
                  'Fiberglass',
                  'Bamboo / Wood',
                ].map((mat) {
                  final isSelected = _fuelTypeNotifier == mat;
                  return ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    selected: isSelected,
                    label: Text(
                      mat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : AppColors.text(context),
                      ),
                    ),
                    selectedColor: AppColors.primaryColor(context),
                    backgroundColor: AppColors.cardBg(context),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryColor(context)
                          : AppColors.border(context),
                    ),
                    onSelected: (_) =>
                        setDialogState(() => _fuelTypeNotifier = mat),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
        ];

      default:
        return [];
    }
  }

  dynamic _findProjectByName(List<dynamic> projects, String query) {
    for (final p in projects) {
      if (p.name.toString().toLowerCase() == query.toLowerCase()) return p;
    }
    return null;
  }

  void _showEquipmentFormDialog(
    BuildContext context, {
    EquipmentItem? existingItem,
  }) {
    final projects = ref.read(projectControllerProvider).projects;

    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final tagCtrl = TextEditingController(text: existingItem?.tagNumber ?? '');
    final siteCtrl = TextEditingController(text: existingItem?.siteName ?? '');
    final rentalCtrl = TextEditingController(
      text: existingItem != null
          ? existingItem.rentalCostPerDay.toStringAsFixed(0)
          : '0',
    );
    final fuelCtrl = TextEditingController(
      text: existingItem != null
          ? existingItem.fuelConsumptionLitersPerDay.toStringAsFixed(0)
          : '0',
    );
    final notesCtrl = TextEditingController(text: existingItem?.notes ?? '');
    String selectedCategory = existingItem?.category ?? _categories.first;
    String selectedStatus = existingItem?.status ?? 'Operational';
    String? selectedProjectId = existingItem?.projectId;

    // Options for location search dropdown
    final projectNames = projects.map((p) => p.name).toList();
    final defaultLocations = [
      'Lorry / Vehicle Tool Box',
      'Main Warehouse',
      'Central Pool',
    ];
    final locationOptions = <String>{
      ...projectNames,
      ...defaultLocations,
    }.toList();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg(context),
              title: Row(
                children: [
                  Text(
                    _getCategoryEmoji(selectedCategory),
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      existingItem == null
                          ? 'Register Equipment / Tool'
                          : 'Edit Equipment / Tool',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.text(context),
                        fontWeight: FontWeight.bold,
                      ),
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
                      initialValue: _categories.contains(selectedCategory)
                          ? selectedCategory
                          : _categories.first,
                      dropdownColor: AppColors.cardBg(context),
                      decoration: InputDecoration(
                        labelText: 'Category / Group',
                        labelStyle: TextStyle(
                          color: AppColors.mutedText(context),
                        ),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${_getCategoryEmoji(c)}  $c',
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategory = val!;
                          // Reset status to first valid option for new category
                          if (!_statusOptions(
                            selectedCategory,
                          ).contains(selectedStatus)) {
                            selectedStatus = _statusOptions(
                              selectedCategory,
                            ).first;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Equipment Name
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: _nameLabel(selectedCategory),
                        hintText: _nameHint(selectedCategory),
                        labelStyle: TextStyle(
                          color: AppColors.mutedText(context),
                        ),
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
                              labelText: _tagLabel(selectedCategory),
                              hintText: _tagHint(selectedCategory),
                              labelStyle: TextStyle(
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                _statusOptions(
                                  selectedCategory,
                                ).contains(selectedStatus)
                                ? selectedStatus
                                : _statusOptions(selectedCategory).first,
                            dropdownColor: AppColors.cardBg(context),
                            decoration: InputDecoration(
                              labelText: 'Status',
                              labelStyle: TextStyle(
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            items: _statusOptions(selectedCategory)
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedStatus = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Category-Specific Extra Fields ──
                    ..._buildCategorySpecificFields(
                      context,
                      selectedCategory,
                      setDialogState,
                      fuelTypeNotifier: _fuelTypeNotifier,
                    ),

                    // Searchable / Custom Location Field with Dynamic Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _locationSectionLabel(selectedCategory),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mutedText(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (selectedProjectId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor(
                                context,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 10,
                                  color: AppColors.primaryColor(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Linked to Project',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: siteCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: _locationFieldLabel(selectedCategory),
                        hintText: _locationHint(selectedCategory),
                        prefixIcon: Icon(
                          selectedProjectId != null
                              ? Icons.apartment
                              : siteCtrl.text.toLowerCase().contains('lorry') ||
                                    siteCtrl.text.toLowerCase().contains(
                                      'vehicle',
                                    ) ||
                                    siteCtrl.text.toLowerCase().contains(
                                      'truck',
                                    )
                              ? Icons.local_shipping_outlined
                              : siteCtrl.text.toLowerCase().contains(
                                      'warehouse',
                                    ) ||
                                    siteCtrl.text.toLowerCase().contains(
                                      'store',
                                    )
                              ? Icons.storefront_outlined
                              : siteCtrl.text.toLowerCase().contains('pool') ||
                                    siteCtrl.text.toLowerCase().contains(
                                      'central',
                                    )
                              ? Icons.hub_outlined
                              : Icons.location_on_outlined,
                          size: 20,
                          color: AppColors.primaryColor(context),
                        ),
                        suffixIcon: siteCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setDialogState(() {
                                    siteCtrl.clear();
                                    selectedProjectId = null;
                                  });
                                },
                              )
                            : null,
                        labelStyle: TextStyle(
                          color: AppColors.mutedText(context),
                        ),
                      ),
                      onChanged: (val) {
                        final matchedProject = _findProjectByName(
                          projects,
                          val,
                        );
                        setDialogState(() {
                          selectedProjectId = matchedProject?.id;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Quick Location Presets & Project Chips
                    Text(
                      'Tap to quick-select Project or Location Preset:',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.mutedText(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: locationOptions.map((loc) {
                        final isProject = projectNames.contains(loc);
                        final isSelected = siteCtrl.text == loc;
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          selected: isSelected,
                          label: Text(
                            loc,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.text(context),
                            ),
                          ),
                          avatar: Icon(
                            isProject
                                ? Icons.apartment
                                : loc.toLowerCase().contains('lorry') ||
                                      loc.toLowerCase().contains('vehicle')
                                ? Icons.local_shipping
                                : Icons.place,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor(context),
                          ),
                          selectedColor: AppColors.primaryColor(context),
                          backgroundColor: AppColors.cardBg(context),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryColor(context)
                                : AppColors.border(context),
                          ),
                          onSelected: (selected) {
                            setDialogState(() {
                              siteCtrl.text = selected ? loc : '';
                              final matchedProject = _findProjectByName(
                                projects,
                                siteCtrl.text,
                              );
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
                              labelText: _costLabel(selectedCategory),
                              labelStyle: TextStyle(
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ),
                        ),
                        if (_showFuelField(selectedCategory)) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: fuelCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: AppColors.text(context)),
                              decoration: InputDecoration(
                                labelText: _fuelLabel(selectedCategory),
                                hintText: _fuelHint(selectedCategory),
                                labelStyle: TextStyle(
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes / Remarks
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: _notesLabel(selectedCategory),
                        hintText: _notesHint(selectedCategory),
                        labelStyle: TextStyle(
                          color: AppColors.mutedText(context),
                        ),
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
                        const SnackBar(
                          content: Text('Please enter an item name'),
                        ),
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
                      siteName: siteCtrl.text.trim().isEmpty
                          ? 'Main Site'
                          : siteCtrl.text.trim(),
                      projectId: selectedProjectId,
                      status: selectedStatus,
                      rentalCostPerDay: double.tryParse(rentalCtrl.text) ?? 0.0,
                      fuelConsumptionLitersPerDay:
                          double.tryParse(fuelCtrl.text) ?? 0.0,
                      notes: notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : null,
                      createdAt: existingItem?.createdAt ?? DateTime.now(),
                    );

                    final bool success;
                    if (existingItem == null) {
                      success = await ref
                          .read(equipmentControllerProvider.notifier)
                          .addEquipment(item);
                    } else {
                      success = await ref
                          .read(equipmentControllerProvider.notifier)
                          .updateEquipment(item);
                    }

                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              existingItem == null
                                  ? 'Item registered successfully'
                                  : 'Item updated successfully',
                            ),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      } else {
                        final err =
                            ref.read(equipmentControllerProvider).error ??
                            'Operation failed';
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
                  child: Text(
                    existingItem == null ? 'Save Entry' : 'Update Entry',
                  ),
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
        content: Text(
          'Are you sure you want to delete "${item.name}" from the database?',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(equipmentControllerProvider.notifier)
          .deleteEquipment(item.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully from database'),
            ),
          );
        } else {
          final err =
              ref.read(equipmentControllerProvider).error ?? 'Delete failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $err'),
              backgroundColor: AppColors.error,
            ),
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
      final matchesSearch =
          _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.tagNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.siteName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _categoryFilter == null || e.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    final totalFleet = equipmentList.length;
    final operational = equipmentList
        .where((e) => e.status == 'Operational' || e.status == 'In Use')
        .length;
    final powerToolsCount = equipmentList
        .where((e) => e.category == 'Power Tools & Machines')
        .length;
    final laddersCount = equipmentList
        .where((e) => e.category == 'Ladders & Climbing')
        .length;
    final totalDailyCost = equipmentList.fold<double>(
      0,
      (sum, e) => sum + e.rentalCostPerDay,
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Equipment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final filtered = equipmentList.where((e) {
                return !e.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !e.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Equipment, Machinery & Tools Report',
                subtitle: 'Site deployment & machinery asset inventory',
                headers: ['Asset Tag', 'Equipment Name', 'Category', 'Assigned Site', 'Rental Rate (INR/day)', 'Status'],
                data: filtered.map((e) => [
                  e.tagNumber,
                  e.name,
                  e.category,
                  e.siteName,
                  'INR ${e.rentalCostPerDay.toStringAsFixed(2)}',
                  e.status.toUpperCase(),
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Equipment_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final filtered = equipmentList.where((e) {
                return !e.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !e.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Equipment_Assets',
                title: 'Equipment, Machinery & Tools Directory',
                headers: ['Asset Tag', 'Equipment Name', 'Category', 'Serial Number', 'Assigned Site', 'Rental Cost / Day (INR)', 'Condition', 'Status'],
                rows: filtered.map((e) => [
                  e.tagNumber,
                  e.name,
                  e.category,
                  e.tagNumber,
                  e.siteName,
                  e.rentalCostPerDay,
                  e.notes ?? 'Good',
                  e.status.toUpperCase(),
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Equipment_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () =>
                ref.read(equipmentControllerProvider.notifier).loadEquipment(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEquipmentFormDialog(context),
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment'),
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
                    const Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Backend Connection Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eqState.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(equipmentControllerProvider.notifier)
                          .loadEquipment(),
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
                              subtitle:
                                  '$powerToolsCount Drills/Tools, $laddersCount Ladders',
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
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: _categoryFilter == null,
                          label: Text(
                            'All Items',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _categoryFilter == null
                                  ? Colors.white
                                  : AppColors.text(context),
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _categoryFilter = null),
                          backgroundColor: AppColors.cardBg(context),
                          selectedColor: AppColors.primaryColor(context),
                          side: BorderSide(
                            color: _categoryFilter == null
                                ? AppColors.primaryColor(context)
                                : AppColors.border(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ),
                      ..._categories.map((cat) {
                        final isSelected = _categoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              '${_getCategoryEmoji(cat)} $cat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.text(context),
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _categoryFilter = selected ? cat : null;
                              });
                            },
                            backgroundColor: AppColors.cardBg(context),
                            selectedColor: AppColors.primaryColor(context),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryColor(context)
                                  : AppColors.border(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                    hintText:
                        'Search drilling machines, ladders, trucks, tag #...',
                    onSearchChanged: (val) =>
                        setState(() => _searchQuery = val),
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
                              Icon(
                                Icons.construction,
                                size: 64,
                                color: AppColors.mutedText(
                                  context,
                                ).withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No equipment or tools found.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Click "+ Add Equipment / Tool" to register items in Supabase.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText(context),
                                ),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText(context),
                  ),
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

    final catEmoji = _getCategoryEmoji(item.category);

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
                        color: AppColors.primaryColor(
                          context,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        catEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
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
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText(context),
                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
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
                    onPressed: () =>
                        _showEquipmentFormDialog(context, existingItem: item),
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
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: AppColors.primaryColor(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.text(context),
                        fontStyle: FontStyle.italic,
                      ),
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
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.mutedText(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.siteName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '₹${_fmt(item.rentalCostPerDay)}/day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                  if (item.fuelConsumptionLitersPerDay > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${item.fuelConsumptionLitersPerDay.toInt()} L/day',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText(context),
                      ),
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
