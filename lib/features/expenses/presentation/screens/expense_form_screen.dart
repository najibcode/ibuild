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
    _amountController =
        TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _notesController =
        TextEditingController(text: widget.expense?.notes ?? '');
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
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
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
            content: Text(widget.expense == null
                ? 'Expense recorded successfully'
                : 'Expense updated successfully'),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation failed'),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Record Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Selector (Optional)
                    const Text('Project (Optional)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        hintText: 'General expense',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('General (no project)'),
                        ),
                        ...projectsState.projects.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name,
                                overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedProjectId = val),
                    ),
                    const SizedBox(height: 20),

                    // Expense Date
                    const Text('Date',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          suffixIcon:
                              Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? _selectedDate!
                                  .toIso8601String()
                                  .substring(0, 10)
                              : 'Select date',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? AppColors.textMain
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    const Text('Category',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                            value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Amount
                    const Text('Amount',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(hintText: '₹'),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Payment Mode
                    const Text('Payment Mode',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _paymentMode,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: _paymentModes.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child:
                              Text(m[0].toUpperCase() + m.substring(1)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _paymentMode = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    const Text('Notes (Optional)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Additional notes...'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.defaultValue),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Expense' : 'Save Expense',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
