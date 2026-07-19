import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/bill_model.dart';
import '../controllers/billing_controller.dart';
import '../../../../features/projects/presentation/controllers/project_controller.dart';

class BillingFormScreen extends ConsumerStatefulWidget {
  final Bill? bill;

  const BillingFormScreen({super.key, this.bill});

  @override
  ConsumerState<BillingFormScreen> createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends ConsumerState<BillingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _billNumberController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late String _status;
  String? _selectedProjectId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _billNumberController =
        TextEditingController(text: widget.bill?.billNumber ?? '');
    _amountController =
        TextEditingController(text: widget.bill?.amount.toString() ?? '');
    _notesController =
        TextEditingController(text: widget.bill?.notes ?? '');
    _status = widget.bill?.status ?? 'pending';
    _selectedProjectId = widget.bill?.projectId;
    if (widget.bill != null) {
      _selectedDate = DateTime.tryParse(widget.bill!.billDate);
    }
    _selectedDate ??= DateTime.now();
  }

  @override
  void dispose() {
    _billNumberController.dispose();
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
      if (_selectedProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a project'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final bill = Bill(
        id: widget.bill?.id ?? '',
        projectId: _selectedProjectId!,
        billNumber: _billNumberController.text.trim(),
        billDate: _selectedDate!.toIso8601String().substring(0, 10),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final success = widget.bill == null
          ? await ref
              .read(billingControllerProvider.notifier)
              .addBill(bill)
          : await ref
              .read(billingControllerProvider.notifier)
              .editBill(bill);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.bill == null
                ? 'Bill added successfully'
                : 'Bill updated successfully'),
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
    final isEditing = widget.bill != null;
    final projectsState = ref.watch(projectControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Bill' : 'Add Bill'),
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
                    // Project Selector
                    const Text('Project',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        hintText: 'Select a project',
                      ),
                      items: projectsState.projects.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name,
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedProjectId = val),
                      validator: (v) =>
                          v == null ? 'Please select a project' : null,
                    ),
                    const SizedBox(height: 20),

                    // Bill Number
                    const Text('Bill Number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _billNumberController,
                      decoration: const InputDecoration(
                          hintText: 'e.g. INV-001'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please enter bill number'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Bill Date
                    const Text('Bill Date',
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

                    // Status
                    const Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(
                            value: 'overdue', child: Text('Overdue')),
                        DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Cancelled')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
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
                  isEditing ? 'Update Bill' : 'Save Bill',
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
