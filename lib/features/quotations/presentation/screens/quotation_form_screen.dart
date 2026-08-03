import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/document_number_generator.dart';
import '../../data/models/quotation_model.dart';
import '../controllers/quotation_controller.dart';
import '../../../../features/projects/presentation/controllers/project_controller.dart';

class QuotationFormScreen extends ConsumerStatefulWidget {
  final Quotation? quotation;

  const QuotationFormScreen({super.key, this.quotation});

  @override
  ConsumerState<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quotationNumberCtrl;
  late TextEditingController _clientNameCtrl;
  late TextEditingController _clientPhoneCtrl;
  late TextEditingController _subjectCtrl;
  late TextEditingController _notesCtrl;
  late String _status;
  String? _selectedProjectId;
  DateTime? _validUntilDate;

  final List<Map<String, dynamic>> _itemRows = [];

  static const List<String> _units = ['Sqft', 'Rft', 'Bags', 'Nos', 'Kg', 'Ton', 'Trip', 'Lump Sum'];

  @override
  void initState() {
    super.initState();
    final q = widget.quotation;
    _quotationNumberCtrl = TextEditingController(text: q?.quotationNumber ?? DocumentNumberGenerator.generateQuotationNumber());
    _clientNameCtrl = TextEditingController(text: q?.clientName ?? '');
    _clientPhoneCtrl = TextEditingController(text: q?.clientPhone ?? '');
    _subjectCtrl = TextEditingController(text: q?.subject ?? 'Construction Project Estimate');
    _notesCtrl = TextEditingController(text: q?.notes ?? '');
    _status = q?.status ?? 'draft';
    _selectedProjectId = q?.projectId;

    if (q != null && q.validUntil != null) {
      _validUntilDate = DateTime.tryParse(q.validUntil!);
    }

    if (q != null && q.items.isNotEmpty) {
      for (final item in q.items) {
        _itemRows.add({
          'particular': TextEditingController(text: item.particular),
          'unit': item.unit,
          'qty': TextEditingController(text: item.quantity.toString()),
          'rate': TextEditingController(text: item.unitRate.toString()),
        });
      }
    } else {
      // Add initial default estimation row
      _addEmptyItemRow(particular: 'Civil Concrete & Foundation Work', qty: '1000', rate: '150');
    }
  }

  void _addEmptyItemRow({String particular = '', String qty = '', String rate = ''}) {
    setState(() {
      _itemRows.add({
        'particular': TextEditingController(text: particular),
        'unit': 'Sqft',
        'qty': TextEditingController(text: qty),
        'rate': TextEditingController(text: rate),
      });
    });
  }

  void _removeItemRow(int index) {
    if (_itemRows.length > 1) {
      setState(() {
        _itemRows[index]['particular'].dispose();
        _itemRows[index]['qty'].dispose();
        _itemRows[index]['rate'].dispose();
        _itemRows.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _quotationNumberCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    for (final row in _itemRows) {
      row['particular'].dispose();
      row['qty'].dispose();
      row['rate'].dispose();
    }
    super.dispose();
  }

  double _calculateTotalAmount() {
    double sum = 0.0;
    for (final row in _itemRows) {
      final qty = double.tryParse(row['qty'].text) ?? 0.0;
      final rate = double.tryParse(row['rate'].text) ?? 0.0;
      sum += (qty * rate);
    }
    return sum;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntilDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _validUntilDate = picked);
    }
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      List<QuotationItem> items = [];
      for (final row in _itemRows) {
        final p = row['particular'].text.trim();
        final u = row['unit'] as String;
        final q = double.tryParse(row['qty'].text) ?? 0.0;
        final r = double.tryParse(row['rate'].text) ?? 0.0;
        if (p.isNotEmpty && q > 0) {
          items.add(QuotationItem(
            particular: p,
            unit: u,
            quantity: q,
            unitRate: r,
          ));
        }
      }

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one valid estimation item'), backgroundColor: AppColors.error),
        );
        return;
      }

      final quotation = Quotation(
        id: widget.quotation?.id ?? '',
        projectId: _selectedProjectId,
        quotationNumber: _quotationNumberCtrl.text.trim(),
        clientName: _clientNameCtrl.text.trim(),
        clientPhone: _clientPhoneCtrl.text.trim().isEmpty ? null : _clientPhoneCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        status: _status,
        items: items,
        totalAmount: _calculateTotalAmount(),
        validUntil: _validUntilDate?.toIso8601String().substring(0, 10),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      final success = widget.quotation == null
          ? await ref.read(quotationControllerProvider.notifier).addQuotation(quotation)
          : await ref.read(quotationControllerProvider.notifier).editQuotation(quotation);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quotation == null ? 'Quotation estimate created successfully' : 'Quotation estimate updated successfully'),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else if (mounted) {
        final err = ref.read(quotationControllerProvider).errorMessage ?? 'Failed to save quotation';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.quotation != null;
    final projectsState = ref.watch(projectControllerProvider);
    final grandTotal = _calculateTotalAmount();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Quotation Estimate' : 'New Client Quotation',
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
              // Client & Project Information Card
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
                    Text('CLIENT & ESTIMATE DETAILS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _quotationNumberCtrl,
                      readOnly: true,
                      style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Quotation / Estimate No.',
                        helperText: 'Auto-generated anti-fraud estimate number',
                        prefixIcon: Icon(Icons.receipt_long_outlined, color: AppColors.primaryColor(context)),
                        suffixIcon: const Icon(Icons.verified_user_outlined, color: AppColors.secondary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _clientNameCtrl,
                      style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Client Name *',
                        hintText: 'e.g. Ramesh Kumar',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryColor(context)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter client name' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _clientPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '+91 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryColor(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _selectedProjectId,
                            dropdownColor: AppColors.cardBg(context),
                            decoration: InputDecoration(
                              labelText: 'Project Site',
                              prefixIcon: Icon(Icons.apartment_outlined, color: AppColors.primaryColor(context)),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('General Client Quote', style: TextStyle(color: AppColors.text(context), fontSize: 13)),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _subjectCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Quotation Title / Subject *',
                        hintText: 'e.g. 3BHK Residential Construction Estimate',
                        prefixIcon: Icon(Icons.title, color: AppColors.primaryColor(context)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter quotation subject' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            dropdownColor: AppColors.cardBg(context),
                            decoration: const InputDecoration(labelText: 'Quote Status'),
                            items: const [
                              DropdownMenuItem(value: 'draft', child: Text('🟡 Draft')),
                              DropdownMenuItem(value: 'sent', child: Text('🟦 Sent to Client')),
                              DropdownMenuItem(value: 'approved', child: Text('🟢 Approved')),
                              DropdownMenuItem(value: 'rejected', child: Text('🔴 Rejected')),
                            ],
                            onChanged: (val) => setState(() => _status = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Valid Until Date',
                                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                              ),
                              child: Text(
                                _validUntilDate != null
                                    ? _validUntilDate!.toIso8601String().substring(0, 10)
                                    : 'Select valid date',
                                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Itemized Estimation Rows Builder Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ITEMIZED ESTIMATION PARTICULARS',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                        TextButton.icon(
                          onPressed: () => _addEmptyItemRow(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Particular'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _itemRows.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final row = _itemRows[index];
                        final qty = double.tryParse(row['qty'].text) ?? 0.0;
                        final rate = double.tryParse(row['rate'].text) ?? 0.0;
                        final rowTotal = qty * rate;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: row['particular'],
                                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Particular Description #${index + 1}',
                                      hintText: 'e.g. Concrete Slab RCC Work',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButtonHideUnderline(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border(context)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<String>(
                                      value: row['unit'],
                                      dropdownColor: AppColors.cardBg(context),
                                      style: TextStyle(fontSize: 12, color: AppColors.text(context), fontWeight: FontWeight.bold),
                                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                      onChanged: (val) => setState(() => row['unit'] = val!),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                  onPressed: () => _removeItemRow(index),
                                  tooltip: 'Remove Row',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: row['qty'],
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Quantity', hintText: '0', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: row['rate'],
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Unit Rate (₹)', hintText: '0', isDense: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor(context).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '₹${rowTotal.toStringAsFixed(0)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryColor(context)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Running Total Summary Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor(context).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GRAND ESTIMATED TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '₹${grandTotal.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Remarks & Terms
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
                    Text('REMARKS & TERMS OF PAYMENT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Advance 30% upon booking, 50% on RCC slab, 20% on completion.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Action Button
              ElevatedButton.icon(
                onPressed: _onSave,
                icon: Icon(isEditing ? Icons.save : Icons.check_circle, size: 20),
                label: Text(
                  isEditing ? 'Update Quotation Estimate' : 'Save & Build Quotation',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor(context),
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
