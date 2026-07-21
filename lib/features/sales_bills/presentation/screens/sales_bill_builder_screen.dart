import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/sales_bill_model.dart';
import '../../data/repositories/supabase_sales_bill_repository.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/controllers/project_controller.dart';

class SalesBillBuilderItem {
  TextEditingController particularCtrl = TextEditingController();
  TextEditingController qtyCtrl = TextEditingController(text: '1');
  TextEditingController priceCtrl = TextEditingController(text: '0');
  String unit = 'Pcs';

  double get total => (double.tryParse(qtyCtrl.text) ?? 0) * (double.tryParse(priceCtrl.text) ?? 0);
}

class SalesBillBuilderScreen extends ConsumerStatefulWidget {
  const SalesBillBuilderScreen({super.key});

  @override
  ConsumerState<SalesBillBuilderScreen> createState() => _SalesBillBuilderScreenState();
}

class _SalesBillBuilderScreenState extends ConsumerState<SalesBillBuilderScreen> {
  final _clientNameCtrl = TextEditingController();
  final _billNumberCtrl = TextEditingController();
  String? _selectedProjectId;
  final List<SalesBillBuilderItem> _rows = [];
  bool _isSaving = false;
  String _status = 'Unpaid';

  @override
  void initState() {
    super.initState();
    _billNumberCtrl.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _addRow();
  }

  void _addRow() {
    setState(() {
      _rows.add(SalesBillBuilderItem());
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
  double get _tax => _subtotal * 0.18;
  double get _grandTotal => _subtotal + _tax;

  Future<void> _save() async {
    if (_clientNameCtrl.text.trim().isEmpty || _selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select project and enter client name'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = SupabaseSalesBillRepository(client);

      final bill = SalesBill(
        id: '',
        projectId: _selectedProjectId!,
        billNumber: _billNumberCtrl.text.trim(),
        clientName: _clientNameCtrl.text.trim(),
        amount: _subtotal,
        taxAmount: _tax,
        totalAmount: _grandTotal,
        status: _status,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );

      await repo.createSalesBill(bill);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sales bill created successfully'), backgroundColor: AppColors.secondary),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create sales bill: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectControllerProvider);
    final projects = projectState.projects;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Sales Bill Invoice Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generating Sales Bill PDF...')),
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
              Text('Invoice Header', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(labelText: 'Select Project *'),
                items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _clientNameCtrl,
                      decoration: const InputDecoration(labelText: 'Client Name *'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _billNumberCtrl,
                      decoration: const InputDecoration(labelText: 'Invoice / Bill No.'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Invoice Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
                  ElevatedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Particular'),
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
                          controller: row.particularCtrl,
                          decoration: const InputDecoration(labelText: 'Particular / Work Description'),
                          onChanged: (_) => setState(() {}),
                        ),
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
                  Text('Total Bill Amount: ₹${_grandTotal.toInt()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context))),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Payment Status'),
                items: const [
                  DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                  DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'Unpaid'),
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
                    : const Text('Save Sales Bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
