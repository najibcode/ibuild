import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/expense_model.dart';
import '../controllers/expense_controller.dart';
import '../../../../features/projects/presentation/controllers/project_controller.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final Expense? expense;
  final String? initialProjectId;

  const ExpenseFormScreen({super.key, this.expense, this.initialProjectId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _expenseNameController;
  late TextEditingController _vendorController;
  late String _category;
  late String _paymentMode;
  String? _selectedProjectId;
  DateTime? _selectedDate;

  static const _categories = [
    'Materials',
    'Equipment',
    'Labour',
    'Transport',
    'Fuel',
    'Food',
    'Office & Admin',
    'Safety & PPE',
    'Miscellaneous',
  ];

  static const _paymentModes = ['cash', 'bank', 'upi', 'cheque'];

  // ── Category-Specific Helpers ──
  String _getCategoryEmoji(String cat) {
    switch (cat) {
      case 'Materials':
        return '🧱';
      case 'Equipment':
        return '🔧';
      case 'Labour':
        return '👷';
      case 'Transport':
        return '🚛';
      case 'Fuel':
        return '⛽';
      case 'Food':
        return '🍱';
      case 'Office & Admin':
        return '🏢';
      case 'Safety & PPE':
        return '🦺';
      default:
        return '📋';
    }
  }

  String _nameHint(String cat) {
    switch (cat) {
      case 'Materials':
        return 'e.g. 50 bags Ultratech Cement, 10 TMT Steel Rods';
      case 'Equipment':
        return 'e.g. Bosch Angle Grinder, Safety Harness Set';
      case 'Labour':
        return 'e.g. Mason daily wages (3 workers × 2 days)';
      case 'Transport':
        return 'e.g. Lorry hire for sand delivery, Auto fare';
      case 'Fuel':
        return 'e.g. Diesel for generator 50L, Petrol for site vehicle';
      case 'Food':
        return 'e.g. Lunch for site workers (15 pax), Tea & snacks';
      case 'Office & Admin':
        return 'e.g. Printing plans, Stationery supplies';
      case 'Safety & PPE':
        return 'e.g. Hard hats × 10, Safety shoes, Gloves';
      default:
        return 'e.g. Describe what was purchased or paid for';
    }
  }

  String _vendorHint(String cat) {
    switch (cat) {
      case 'Materials':
        return 'e.g. Ramesh Building Supplies, Kerala Cements Agency';
      case 'Equipment':
        return 'e.g. Bosch Service Centre, Stanley Hardware Shop';
      case 'Labour':
        return 'e.g. Labour contractor name, Direct worker payment';
      case 'Transport':
        return 'e.g. Sri Balaji Transport, Ola/Uber, Local auto';
      case 'Fuel':
        return 'e.g. Indian Oil Pump, HP Petrol Station';
      case 'Food':
        return 'e.g. Annapoorna Hotel, Canteen, Swiggy';
      default:
        return 'e.g. Shop name, vendor, or payee';
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Materials':
        return Icons.inventory_2_outlined;
      case 'Equipment':
        return Icons.build_outlined;
      case 'Labour':
        return Icons.engineering_outlined;
      case 'Transport':
        return Icons.local_shipping_outlined;
      case 'Fuel':
        return Icons.local_gas_station_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Office & Admin':
        return Icons.business_outlined;
      case 'Safety & PPE':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    // Parse existing notes to extract name and vendor if editing
    String existingName = '';
    String existingVendor = '';
    String existingNotes = '';
    if (widget.expense?.notes != null && widget.expense!.notes!.isNotEmpty) {
      final notes = widget.expense!.notes!;
      // Try to parse structured format: "Item: ... | Vendor: ... | Notes: ..."
      final itemMatch = RegExp(
        r'Item:\s*(.+?)(?:\s*\|\s*Vendor:|\s*\|\s*Notes:|$)',
      ).firstMatch(notes);
      final vendorMatch = RegExp(
        r'Vendor:\s*(.+?)(?:\s*\|\s*Notes:|$)',
      ).firstMatch(notes);
      final notesMatch = RegExp(r'Notes:\s*(.+)$').firstMatch(notes);
      if (itemMatch != null) {
        existingName = itemMatch.group(1)?.trim() ?? '';
        existingVendor = vendorMatch?.group(1)?.trim() ?? '';
        existingNotes = notesMatch?.group(1)?.trim() ?? '';
      } else {
        // Legacy: plain text notes
        existingNotes = notes;
      }
    }

    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _expenseNameController = TextEditingController(text: existingName);
    _vendorController = TextEditingController(text: existingVendor);
    _notesController = TextEditingController(text: existingNotes);
    _category = widget.expense?.category ?? _categories.first;
    // Normalize category if it doesn't match new list
    if (!_categories.contains(_category)) _category = 'Miscellaneous';
    _paymentMode = widget.expense?.paymentMode ?? 'cash';
    _selectedProjectId = widget.expense?.projectId ?? widget.initialProjectId;
    if (widget.expense != null) {
      _selectedDate = DateTime.tryParse(widget.expense!.expenseDate);
    }
    _selectedDate ??= DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _expenseNameController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Build structured notes from name + vendor + notes
  String? _buildStructuredNotes() {
    final name = _expenseNameController.text.trim();
    final vendor = _vendorController.text.trim();
    final notes = _notesController.text.trim();
    if (name.isEmpty && vendor.isEmpty && notes.isEmpty) return null;
    final parts = <String>[];
    if (name.isNotEmpty) parts.add('Item: $name');
    if (vendor.isNotEmpty) parts.add('Vendor: $vendor');
    if (notes.isNotEmpty) parts.add('Notes: $notes');
    return parts.join(' | ');
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expense?.id ?? '',
        projectId: _selectedProjectId,
        expenseDate: _selectedDate!.toIso8601String().substring(0, 10),
        category: _category,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        paymentMode: _paymentMode,
        notes: _buildStructuredNotes(),
      );

      final success = widget.expense == null
          ? await ref
                .read(expenseControllerProvider.notifier)
                .addExpense(expense)
          : await ref
                .read(expenseControllerProvider.notifier)
                .editExpense(expense);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expense == null
                  ? 'Expense recorded successfully'
                  : 'Expense updated successfully',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save expense record'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final projectsState = ref.watch(projectControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Expense Record' : 'Record Site Expense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Expense Category ──
                    Text(
                      'EXPENSE CATEGORY *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      dropdownColor: AppColors.cardBg(context),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          _getCategoryIcon(_category),
                          color: Colors.deepOrange,
                        ),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${_getCategoryEmoji(c)}  $c',
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 2. Expense Name / What was purchased ──
                    Text(
                      'EXPENSE NAME / ITEM DESCRIPTION *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _expenseNameController,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primaryColor(context),
                        ),
                        hintText: _nameHint(_category),
                        hintStyle: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please describe what was purchased';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Amount ──
                    Text(
                      'EXPENSE AMOUNT (₹) *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.currency_rupee,
                          color: Colors.deepOrange,
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: AppColors.mutedText(context),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter expense amount';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(v) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 4. Vendor / Shop Name ──
                    Text(
                      'VENDOR / SHOP / PAID TO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _vendorController,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primaryColor(context),
                        ),
                        hintText: _vendorHint(_category),
                        hintStyle: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 5. Project Assignment ──
                    Text(
                      'ASSIGNED PROJECT SITE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedProjectId,
                      dropdownColor: AppColors.cardBg(context),
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.apartment_outlined,
                          color: AppColors.primaryColor(context),
                        ),
                        hintText: 'General Expense (No Project)',
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.public,
                                size: 16,
                                color: AppColors.mutedText(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'General Site Expense (No specific project)',
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...projectsState.projects.map((p) {
                          return DropdownMenuItem<String?>(
                            value: p.id,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.apartment,
                                  size: 16,
                                  color: AppColors.primaryColor(context),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      color: AppColors.text(context),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedProjectId = val),
                    ),
                    const SizedBox(height: 20),

                    // ── 6. Date ──
                    Text(
                      'EXPENSE DATE *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primaryColor(context),
                          ),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                              : 'Select expense date',
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 7. Payment Mode Selection ──
                    Text(
                      'PAYMENT MODE *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentModes.map((m) {
                        final isSelected =
                            _paymentMode.toLowerCase() == m.toLowerCase();
                        final icon = m == 'cash'
                            ? Icons.money
                            : m == 'bank'
                            ? Icons.account_balance_outlined
                            : m == 'upi'
                            ? Icons.phone_android_outlined
                            : Icons.receipt_long_outlined;
                        return FilterChip(
                          selected: isSelected,
                          avatar: Icon(
                            icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryColor(context),
                          ),
                          label: Text(
                            m.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.text(context),
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _paymentMode = m);
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
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── 8. Additional Remarks ──
                    Text(
                      'ADDITIONAL REMARKS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Urgent purchase for foundation work, receipt collected',
                        hintStyle: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.notes_outlined,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save / Update Action Button
              ElevatedButton.icon(
                onPressed: _onSave,
                icon: Icon(isEditing ? Icons.save : Icons.check, size: 20),
                label: Text(
                  isEditing ? 'Update Expense Record' : 'Save Expense Record',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
