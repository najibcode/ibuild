import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/date_range_filter_helper.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/building_pdf_generator.dart';
import '../../data/models/bill_model.dart';
import '../../../sales_bills/data/models/sales_bill_model.dart';
import '../../../sales_bills/data/repositories/supabase_sales_bill_repository.dart';
import '../../../sales_bills/data/sales_bill_pdf_generator.dart';
import '../../../sales_bills/presentation/screens/sales_bill_builder_screen.dart';
import '../../../payments/presentation/screens/payment_ledger_screen.dart';
import '../../../payments/data/models/payment_ledger_model.dart';
import '../../../payments/data/repositories/supabase_payment_ledger_repository.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../controllers/billing_controller.dart';
import 'billing_form_screen.dart';

class BillingListScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const BillingListScreen({super.key, this.isEmbedded = true});

  @override
  ConsumerState<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends ConsumerState<BillingListScreen> {
  String _activeFilter = 'all'; // 'all', 'invoices', 'bills', 'ledger'

  void _showAddPaymentDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final partyCtrl = TextEditingController();
    String? selectedProjectId;
    String partyType = 'Client';
    String pType = 'Received';
    String pMethod = 'Bank Transfer';

    final projectState = ref.read(projectControllerProvider);
    final projects = projectState.projects;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Record Payment & Cash Flow'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Select Project *',
                  ),
                  items: projects
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDlgState(() => selectedProjectId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: partyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Payer / Payee Name *',
                    hintText: 'e.g. City Developers / Apex Hardware',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: partyType,
                  decoration: const InputDecoration(
                    labelText: 'Counterparty Type',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Client', child: Text('Client')),
                    DropdownMenuItem(
                      value: 'Supplier',
                      child: Text('Supplier / Vendor'),
                    ),
                    DropdownMenuItem(
                      value: 'Subcontractor',
                      child: Text('Subcontractor'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setDlgState(() => partyType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Description / Notes *',
                    hintText: 'e.g. Milestone 2 Advance Payment',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: pType,
                  decoration: const InputDecoration(labelText: 'Payment Flow'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Received',
                      child: Text('Received (+ Inflow)'),
                    ),
                    DropdownMenuItem(
                      value: 'Paid',
                      child: Text('Paid (- Outflow)'),
                    ),
                  ],
                  onChanged: (v) => setDlgState(() => pType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: pMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Text('Bank Transfer / NEFT'),
                    ),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI / GPay')),
                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  ],
                  onChanged: (v) => setDlgState(() => pMethod = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reference / UTR No.',
                    hintText: 'e.g. UTR-9823411',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (partyCtrl.text.trim().isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter party name and valid amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final client = ref.read(supabaseClientProvider);
                final entry = PaymentLedgerEntry(
                  id: '',
                  projectId: selectedProjectId ?? 'general',
                  counterpartyName: partyCtrl.text.trim(),
                  counterpartyType: partyType,
                  paymentType: pType,
                  amount: amount,
                  paymentMethod: pMethod,
                  paymentDate: DateTime.now(),
                  remarks: refCtrl.text.trim().isNotEmpty
                      ? '${titleCtrl.text.trim()} (Ref: ${refCtrl.text.trim()})'
                      : titleCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );

                await SupabasePaymentLedgerRepository(
                  client,
                ).recordLedgerEntry(entry);
                ref.invalidate(allPaymentLedgerProvider);
                if (ctx.mounted) Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Payment ledger transaction recorded successfully',
                    ),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingControllerProvider);
    final salesBillsAsync = ref.watch(allSalesBillsProvider);

    final double totalBilled = state.bills.fold(
      0.0,
      (sum, b) => sum + b.amount,
    );
    final double totalPaid = state.bills
        .where((b) => b.status.toLowerCase() == 'paid')
        .fold(0.0, (sum, b) => sum + b.amount);
    final double totalPending = state.bills
        .where(
          (b) =>
              b.status.toLowerCase() == 'pending' ||
              b.status.toLowerCase() == 'overdue',
        )
        .fold(0.0, (sum, b) => sum + b.amount);

    final content = Column(
      children: [
        // ── Filter Chips Bar & Quick Actions Toolbar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            border: Border(bottom: BorderSide(color: AppColors.border(context))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('all', 'All Records', Icons.apps),
                          const SizedBox(width: 6),
                          _filterChip('invoices', '📥 Money In (Sales Invoices)', Icons.point_of_sale),
                          const SizedBox(width: 6),
                          _filterChip('bills', '💸 Money Out (Vendor Bills)', Icons.receipt_long),
                          const SizedBox(width: 6),
                          _filterChip('ledger', '💳 Payment Ledger', Icons.account_balance),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DataExportActions(
                    compact: true,
                    onExportPdfWithDates: (start, end) async {
                      final filtered = DateRangeFilterHelper.filter(
                        state.bills,
                        start: start,
                        end: end,
                        getDate: (b) => b.billDate,
                      );
                      final totalBilledF = filtered.fold<double>(0, (s, b) => s + b.amount);
                      final totalPaidF = filtered.where((b) => b.status == 'paid').fold<double>(0, (s, b) => s + b.amount);
                      final totalPendingF = totalBilledF - totalPaidF;
                      final bytes = await BuildingPdfGenerator.generateReport(
                        bills: filtered,
                        totalAmount: totalBilledF,
                        totalPaid: totalPaidF,
                        totalPending: totalPendingF,
                      );
                      await PdfDownloadHelper.downloadPdf(
                        bytes: bytes,
                        filename:
                            'IBUILD_Billing_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      );
                    },
                    onExportExcelWithDates: (start, end) async {
                      final bills = DateRangeFilterHelper.filter(
                        state.bills,
                        start: start,
                        end: end,
                        getDate: (b) => b.billDate,
                      );
                      final excelBytes = ExcelGeneratorService.generateTableExcel(
                        sheetName: 'Billing_Summary',
                        title: 'Vendor Bills & Operational Billing Hub',
                        headers: [
                          'Bill Number',
                          'Vendor / Party',
                          'Category',
                          'Bill Date',
                          'Due Date',
                          'Amount (INR)',
                          'Status',
                        ],
                        rows: bills
                            .map(
                              (b) => [
                                b.billNumber,
                                b.projectName ?? 'General',
                                'Operational',
                                b.billDate,
                                b.billDate,
                                b.amount,
                                b.status.toUpperCase(),
                              ],
                            )
                            .toList(),
                      );
                      await ExcelDownloadHelper.downloadExcel(
                        bytes: excelBytes,
                        filename:
                            'IBUILD_Billing_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Action Buttons Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SalesBillBuilderScreen()),
                      );
                      ref.invalidate(allSalesBillsProvider);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Client Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BillingFormScreen()),
                      );
                      ref.read(billingControllerProvider.notifier).loadBills();
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Vendor Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddPaymentDialog(context),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Record Payment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor(context),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Active Content View ──
        Expanded(
          child: _buildActiveFilterView(
            context,
            ref,
            state,
            salesBillsAsync,
            totalBilled,
            totalPaid,
            totalPending,
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Transactions & Billing Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: content,
    );
  }

  Widget _filterChip(String id, String label, IconData icon) {
    final isSelected = _activeFilter == id;
    final primary = AppColors.primaryColor(context);
    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : AppColors.mutedText(context),
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.text(context),
      ),
      selectedColor: primary,
      backgroundColor: AppColors.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primary : AppColors.border(context),
        ),
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _activeFilter = id;
          });
        }
      },
    );
  }

  Widget _buildActiveFilterView(
    BuildContext context,
    WidgetRef ref,
    BillingListState state,
    AsyncValue<List<SalesBill>> salesBillsAsync,
    double totalBilled,
    double totalPaid,
    double totalPending,
  ) {
    switch (_activeFilter) {
      case 'invoices':
        return _buildClientSalesInvoicesTab(context, ref, salesBillsAsync);
      case 'bills':
        return _buildVendorBillsTab(
          context,
          ref,
          state,
          totalBilled,
          totalPaid,
          totalPending,
        );
      case 'ledger':
        return const PaymentLedgerScreen(isEmbedded: true);
      case 'all':
      default:
        return _buildCombinedTransactionsTab(
          context,
          ref,
          state,
          salesBillsAsync,
        );
    }
  }

  /// Combined View displaying both Client Invoices and Vendor Bills chronologically
  Widget _buildCombinedTransactionsTab(
    BuildContext context,
    WidgetRef ref,
    BillingListState state,
    AsyncValue<List<SalesBill>> salesBillsAsync,
  ) {
    final salesBills = salesBillsAsync.valueOrNull ?? [];
    final vendorBills = state.bills;

    if (salesBills.isEmpty && vendorBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No financial transactions recorded yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a Client Invoice or Vendor Bill to start tracking transactions.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SalesBillBuilderScreen()),
                );
                ref.invalidate(allSalesBillsProvider);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create First Invoice'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (salesBills.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📥 CLIENT SALES INVOICES (MONEY IN)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      letterSpacing: 0.5,
                    ),
              ),
              TextButton(
                onPressed: () => setState(() => _activeFilter = 'invoices'),
                child: const Text('View All Invoices'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...salesBills.take(5).map((sb) => _buildSalesBillCard(context, sb)),
          const SizedBox(height: 24),
        ],

        if (vendorBills.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💸 VENDOR & PURCHASE BILLS (MONEY OUT)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
              ),
              TextButton(
                onPressed: () => setState(() => _activeFilter = 'bills'),
                child: const Text('View All Vendor Bills'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...vendorBills.take(5).map((b) => _buildVendorBillCard(context, ref, b)),
        ],
      ],
    );
  }

  Widget _buildVendorBillsTab(
    BuildContext context,
    WidgetRef ref,
    BillingListState state,
    double totalBilled,
    double totalPaid,
    double totalPending,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Total Invoiced',
                  value: '₹${totalBilled.toInt()}',
                  subtitle: '${state.bills.length} Vendor Bills',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Paid Expenses',
                  value: '₹${totalPaid.toInt()}',
                  subtitle: 'Disbursements',
                  icon: Icons.check_circle_outline,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Pending Payable',
                  value: '₹${totalPending.toInt()}',
                  subtitle: 'Outstanding Bills',
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SearchFilterBar(
            hintText: 'Search by bill number, project, or notes...',
            onSearchChanged: (q) =>
                ref.read(billingControllerProvider.notifier).setSearch(q),
            filterOptions: const [
              'All',
              'Paid',
              'Pending',
              'Overdue',
              'Cancelled',
            ],
            activeFilter: state.statusFilter,
            onFilterChanged: (f) =>
                ref.read(billingControllerProvider.notifier).setStatusFilter(f),
            sortOptions: const ['Bill Date', 'Amount', 'Status'],
            onSortChanged: (s) {
              final map = {
                'Bill Date': 'bill_date',
                'Amount': 'amount',
                'Status': 'status',
              };
              ref
                  .read(billingControllerProvider.notifier)
                  .setSort(map[s] ?? 'created_at');
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody(context, ref, state)),
      ],
    );
  }

  Widget _buildClientSalesInvoicesTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SalesBill>> salesBillsAsync,
  ) {
    return salesBillsAsync.when(
      data: (bills) {
        final double totalInvoiced = bills.fold(
          0.0,
          (sum, b) => sum + b.totalAmount,
        );
        final double totalCollected = bills
            .where((b) => b.status.toLowerCase() == 'paid')
            .fold(0.0, (sum, b) => sum + b.totalAmount);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Total Sales Invoiced',
                      value: '₹${totalInvoiced.toInt()}',
                      subtitle: '${bills.length} Client Invoices',
                      icon: Icons.point_of_sale,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Revenue Collected',
                      value: '+₹${totalCollected.toInt()}',
                      subtitle: 'Client Inflow',
                      icon: Icons.check_circle,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (bills.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.point_of_sale_outlined,
                        size: 64,
                        color: AppColors.mutedText(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No client sales invoices recorded',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click "+ New Sales Invoice" above to issue client bills',
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: bills.length,
                  itemBuilder: (context, i) {
                    final b = bills[i];
                    final isPaid = b.status.toLowerCase() == 'paid';
                    return Card(
                      color: AppColors.cardBg(context),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          'INVOICE #${b.billNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        subtitle: Text(
                          'Client: ${b.clientName} • Date: ${b.createdAt.toIso8601String().split('T').first}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${b.totalAmount.toInt()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text(context),
                                  ),
                                ),
                                Text(
                                  b.status,
                                  style: TextStyle(
                                    color: isPaid
                                        ? AppColors.secondary
                                        : AppColors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 18),
                              tooltip: 'Print Invoice PDF',
                              onPressed: () async {
                                final pdfBytes =
                                    await SalesBillPdfGenerator.generatePdf(b);
                                await Printing.layoutPdf(
                                  onLayout: (_) async =>
                                      Uint8List.fromList(pdfBytes),
                                  name: 'Sales_Invoice_${b.billNumber}.pdf',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading sales invoices: $e')),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
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

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BillingListState state,
  ) {
    if (state.isLoading && state.bills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.errorMessage}',
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(billingControllerProvider.notifier).loadBills(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.mutedText(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No vendor bills recorded.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create vendor bills to track operational expenses.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.bills.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.bills.length) {
          ref.read(billingControllerProvider.notifier).loadMore();
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _BillCard(
          bill: state.bills[index],
          onEdit: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BillingFormScreen(bill: state.bills[index]),
              ),
            );
            ref.read(billingControllerProvider.notifier).loadBills();
          },
          onTogglePaid: () async {
            final newStatus = state.bills[index].status.toLowerCase() == 'paid'
                ? 'pending'
                : 'paid';
            final updated = state.bills[index].copyWith(status: newStatus);
            await ref
                .read(billingControllerProvider.notifier)
                .editBill(updated);
          },
        );
      },
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onEdit;
  final VoidCallback onTogglePaid;

  const _BillCard({
    required this.bill,
    required this.onEdit,
    required this.onTogglePaid,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.secondary;
      case 'pending':
        return AppColors.warning;
      case 'overdue':
        return AppColors.error;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(bill.status);
    final isPaid = bill.status.toLowerCase() == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.border(context),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BILL #${bill.billNumber}',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bill.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.projectName ?? 'General Project',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bill Date: ${bill.billDate}',
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        'Vendor Expense',
                        style: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Notes: ${bill.notes}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTogglePaid,
                      icon: Icon(
                        isPaid ? Icons.undo : Icons.check_circle,
                        size: 16,
                        color: isPaid ? AppColors.warning : AppColors.secondary,
                      ),
                      label: Text(
                        isPaid ? 'Mark Pending' : '✓ Mark as Paid',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPaid
                            ? AppColors.warning
                            : AppColors.secondary,
                        side: BorderSide(
                          color: isPaid
                              ? AppColors.warning
                              : AppColors.secondary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.file_download_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: () async {
                      final bytes = await BuildingPdfGenerator.generateBill(
                        bill,
                      );
                      await PdfDownloadHelper.downloadPdf(
                        bytes: bytes,
                        filename: 'Building_Invoice_${bill.billNumber}.pdf',
                      );
                    },
                    tooltip: 'Download Vendor Bill PDF',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      final invoiceText =
                          "VENDOR BILL #${bill.billNumber}\nProject: ${bill.projectName}\nDate: ${bill.billDate}\nAmount: ₹${bill.amount.toStringAsFixed(2)}\nStatus: ${bill.status.toUpperCase()}";
                      Clipboard.setData(ClipboardData(text: invoiceText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied Bill details to clipboard!'),
                        ),
                      );
                    },
                    tooltip: 'Share Bill Details',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.outline,
                    ),
                    onPressed: onEdit,
                    tooltip: 'Edit Bill',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
