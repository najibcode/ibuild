import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../../core/utils/document_number_generator.dart';
import '../../data/models/quotation_model.dart';
import '../../data/repositories/supabase_quotation_repository.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class QuotationBuilderItem {
  TextEditingController descriptionCtrl = TextEditingController();
  TextEditingController qtyCtrl = TextEditingController(text: '1');
  TextEditingController priceCtrl = TextEditingController(text: '0');
  String unit = 'sqft';

  double get total => (double.tryParse(qtyCtrl.text) ?? 0) * (double.tryParse(priceCtrl.text) ?? 0);
}

class QuotationBuilderScreen extends ConsumerStatefulWidget {
  final Quotation? quotation;
  const QuotationBuilderScreen({super.key, this.quotation});

  @override
  ConsumerState<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends ConsumerState<QuotationBuilderScreen> {
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late String _quotationNumber;
  final List<QuotationBuilderItem> _rows = [];
  bool _isSaving = false;

  final List<String> _units = ['sqft', 'cft', 'litre', 'nos', 'rft', 'lump sum'];

  @override
  void initState() {
    super.initState();
    _quotationNumber = widget.quotation?.quotationNumber ?? DocumentNumberGenerator.generateQuotationNumber();
    if (widget.quotation != null) {
      _clientNameCtrl.text = widget.quotation!.clientName;
      _clientPhoneCtrl.text = widget.quotation!.clientPhone ?? '';
      _notesCtrl.text = widget.quotation!.notes ?? '';
    } else {
      _addRow(); // default 1 row
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(QuotationBuilderItem());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows.removeAt(index);
      });
    }
  }

  double get _subtotal => _rows.fold(0.0, (sum, r) => sum + r.total);
  double get _tax => _subtotal * 0.18; // 18% GST default
  double get _grandTotal => _subtotal + _tax;

  Future<void> _save() async {
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter client name'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final activityRepo = SupabaseActivityRepository(client);
      final repo = SupabaseQuotationRepository(client, activityRepo);

      final newQuotation = Quotation(
        id: widget.quotation?.id ?? '',
        quotationNumber: _quotationNumber,
        clientName: _clientNameCtrl.text.trim(),
        clientPhone: _clientPhoneCtrl.text.trim().isEmpty ? null : _clientPhoneCtrl.text.trim(),
        subject: 'Construction Estimate',
        totalAmount: _subtotal,
        status: 'Draft',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
        items: _rows.map((r) => QuotationItem(
          particular: r.descriptionCtrl.text.trim().isEmpty ? 'Item' : r.descriptionCtrl.text.trim(),
          unit: r.unit,
          quantity: double.tryParse(r.qtyCtrl.text) ?? 1.0,
          unitRate: double.tryParse(r.priceCtrl.text) ?? 0.0,
          totalCost: r.total,
        )).toList(),
      );

      await repo.createQuotation(newQuotation);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation saved successfully'), backgroundColor: AppColors.secondary),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save quotation: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Quotation / BOQ Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Generate PDF',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generating Quotation PDF...')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share via WhatsApp / Email',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening Share Dialog...')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: _quotationNumber),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Quotation / Estimate No.',
                  helperText: 'Auto-generated anti-fraud number',
                  suffixIcon: Icon(Icons.verified_user_outlined, color: AppColors.secondary, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _clientNameCtrl,
                      decoration: const InputDecoration(labelText: 'Client / Customer Name *'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _clientPhoneCtrl,
                      decoration: const InputDecoration(labelText: 'Customer Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
                  ElevatedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Row'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: row.descriptionCtrl,
                          decoration: const InputDecoration(labelText: 'Description'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: row.unit,
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => row.unit = v ?? 'sqft'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: row.qtyCtrl,
                          decoration: const InputDecoration(labelText: 'Qty'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: row.priceCtrl,
                          decoration: const InputDecoration(labelText: 'Rate (₹)'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('₹${row.total.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        onPressed: () => _removeRow(i),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Subtotal: ₹${_subtotal.toInt()}', style: TextStyle(fontSize: 14, color: AppColors.text(context))),
                  Text('GST (18%): ₹${_tax.toInt()}', style: TextStyle(fontSize: 14, color: AppColors.mutedText(context))),
                  const SizedBox(height: 4),
                  Text('Grand Total: ₹${_grandTotal.toInt()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context))),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Terms & Conditions / Notes'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primaryColor(context),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Quotation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
