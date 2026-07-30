import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/expense_model.dart';
import '../controllers/expense_controller.dart';
import '../../../../features/projects/presentation/controllers/project_controller.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late String _category;
  late String _paymentMode;
  String? _selectedProjectId;
  DateTime? _selectedDate;

  static const _categories = [
    'Labour',
    'Materials',
    'Transport',
    'Equipment',
    'Food',
    'Fuel',
    'Miscellaneous',
  ];

  static const _paymentModes = [
    'cash',
    'bank',
    'upi',
    'cheque',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    _category = widget.expense?.category ?? _categories.first;
    _paymentMode = widget.expense?.paymentMode ?? 'cash';
    _selectedProjectId = widget.expense?.projectId;
    if (widget.expense != null) {
      _selectedDate = DateTime.tryParse(widget.expense!.expenseDate);
    }
    _selectedDate ??= DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
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

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expense?.id ?? '',
        projectId: _selectedProjectId,
        expenseDate: _selectedDate!.toIso8601String().substring(0, 10),
        category: _category,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        paymentMode: _paymentMode,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final success = widget.expense == null
          ? await ref.read(expenseControllerProvider.notifier).addExpense(expense)
          : await ref.read(expenseControllerProvider.notifier).editExpense(expense);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.expense == null
                ? 'Expense recorded successfully'
                : 'Expense updated successfully'),
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
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
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
                    // Amount Field
                    Text('EXPENSE AMOUNT (₹) *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee, color: Colors.deepOrange),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter expense amount';
                        if (double.tryParse(v) == null) return 'Please enter a valid number';
                        if (double.parse(v) <= 0) return 'Amount must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Project Assignment
                    Text('ASSIGNED PROJECT SITE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedProjectId,
                      dropdownColor: AppColors.cardBg(context),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.apartment_outlined, color: AppColors.primaryColor(context)),
                        hintText: 'General Expense (No Project)',
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('General Site Expense (No specific project)', style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                        ),
                        ...projectsState.projects.map((p) {
                          return DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(p.name, style: TextStyle(color: AppColors.text(context), fontSize: 13), overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (val) => setState(() => _selectedProjectId = val),
                    ),
                    const SizedBox(height: 20),

                    // Expense Category
                    Text('EXPENSE CATEGORY *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: AppColors.cardBg(context),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_outlined, color: Colors.deepOrange),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Expense Date Pick
                    Text('EXPENSE DATE *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primaryColor(context)),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? _selectedDate!.toIso8601String().substring(0, 10)
                              : 'Select expense date',
                          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Mode Selection
                    Text('PAYMENT MODE *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentModes.map((m) {
                        final isSelected = _paymentMode.toLowerCase() == m.toLowerCase();
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            m.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppColors.text(context),
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _paymentMode = m);
                          },
                          backgroundColor: AppColors.cardBg(context),
                          selectedColor: AppColors.primaryColor(context),
                          side: BorderSide(color: isSelected ? AppColors.primaryColor(context) : AppColors.border(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Description Notes
                    Text('DESCRIPTION & REMARKS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'e.g. Purchased 50 bags of cement for site foundation work',
                        hintStyle: TextStyle(color: AppColors.mutedText(context)),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
