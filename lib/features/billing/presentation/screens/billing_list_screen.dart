import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/building_pdf_generator.dart';
import '../../data/models/bill_model.dart';
import '../../../sales_bills/presentation/screens/sales_bill_builder_screen.dart';
import '../../../payments/presentation/screens/payment_ledger_screen.dart';
import '../controllers/billing_controller.dart';
import 'billing_form_screen.dart';

class BillingListScreen extends ConsumerWidget {
  const BillingListScreen({super.key});

  static const _statuses = ['pending', 'paid', 'overdue', 'cancelled'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingControllerProvider);

    // Calculate Financial Summary Metrics for Client Billing (Revenue Inflow)
    final double totalBilled = state.bills.fold(0.0, (sum, b) => sum + b.amount);
    final double totalPaid = state.bills.where((b) => b.status.toLowerCase() == 'paid').fold(0.0, (sum, b) => sum + b.amount);
    final double totalPending = state.bills.where((b) => b.status.toLowerCase() == 'pending' || b.status.toLowerCase() == 'overdue').fold(0.0, (sum, b) => sum + b.amount);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          titleSpacing: 16,
          title: const Text(
            'Billing & Financial Hub',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryColor(context),
            unselectedLabelColor: AppColors.mutedText(context),
            indicatorColor: AppColors.primaryColor(context),
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Vendor & Operational Bills'),
              Tab(icon: Icon(Icons.point_of_sale, size: 18), text: 'Client Sales Invoices'),
              Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Payment Ledger & Cash Flow'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.file_download_outlined, color: AppColors.primaryColor(context)),
              tooltip: 'Download Building Billing Summary PDF',
              onPressed: () async {
                if (state.bills.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No building bills to export.')),
                  );
                  return;
                }
                final bytes = await BuildingPdfGenerator.generateReport(
                  bills: state.bills,
                  totalAmount: totalBilled,
                  totalPaid: totalPaid,
                  totalPending: totalPending,
                );
                await PdfDownloadHelper.downloadPdf(
                  bytes: bytes,
                  filename: 'IBUILD_Building_Billing_Report.pdf',
                );
              },
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BillingFormScreen()),
                );
                ref.read(billingControllerProvider.notifier).loadBills();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
              onPressed: () => ref.read(billingControllerProvider.notifier).loadBills(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Vendor & Operational Bills
            Column(
              children: [
                // Financial Summary Header Cards (Client Receivables & Revenue)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Invoiced',
                    value: '₹${totalBilled.toInt()}',
                    subtitle: '${state.bills.length} Client Bills',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Collected (Paid)',
                    value: '+₹${totalPaid.toInt()}',
                    subtitle: 'Revenue Received',
                    icon: Icons.check_circle_outline,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pending Due',
                    value: '₹${totalPending.toInt()}',
                    subtitle: 'Client Receivables',
                    icon: Icons.pending_actions,
                    color: totalPending > 0 ? AppColors.warning : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Search & Status Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchFilterBar(
              hintText: 'Search bill #, project, notes...',
              onSearchChanged: (q) => ref.read(billingControllerProvider.notifier).setSearch(q),
              filterOptions: _statuses,
              activeFilter: state.statusFilter,
              onFilterChanged: (f) => ref.read(billingControllerProvider.notifier).setStatusFilter(f),
              sortOptions: const ['Bill Date', 'Amount', 'Status'],
              onSortChanged: (s) {
                final map = {'Bill Date': 'bill_date', 'Amount': 'amount', 'Status': 'status'};
                ref.read(billingControllerProvider.notifier).setSort(map[s] ?? 'created_at');
              },
            ),
          ),
          const SizedBox(height: 8),

          // Invoice List
          Expanded(
            child: _buildBody(context, ref, state),
          ),
        ],
      ),

      // Tab 2: Client Sales Invoices
      const SalesBillBuilderScreen(),

      // Tab 3: Payment Ledger & Cash Flow
      const PaymentLedgerScreen(),
    ],
  ),
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

  Widget _buildBody(BuildContext context, WidgetRef ref, BillingListState state) {
    if (state.isLoading && state.bills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Error: ${state.errorMessage}', style: TextStyle(color: AppColors.mutedText(context))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(billingControllerProvider.notifier).loadBills(),
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
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.mutedText(context).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No client bills recorded.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
            const SizedBox(height: 4),
            Text('Create client invoices to track sales revenue and receivables.', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
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
            final newStatus = state.bills[index].status.toLowerCase() == 'paid' ? 'pending' : 'paid';
            final updated = state.bills[index].copyWith(status: newStatus);
            await ref.read(billingControllerProvider.notifier).editBill(updated);
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

  const _BillCard({required this.bill, required this.onEdit, required this.onTogglePaid});

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
        border: Border.all(color: isPaid ? AppColors.secondary.withOpacity(0.3) : AppColors.border(context)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Invoice Badge & Status Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'BILL #${bill.billNumber}',
                          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bill.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Project Name & Financial Revenue Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.projectName ?? 'General Project',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bill Date: ${bill.billDate}',
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.secondary),
                      ),
                      Text(
                        'Client Invoice',
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Notes: ${bill.notes}',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 14),

              // Action Buttons Row
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPaid ? AppColors.warning : AppColors.secondary,
                        side: BorderSide(color: isPaid ? AppColors.warning : AppColors.secondary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined, size: 20, color: AppColors.primary),
                    onPressed: () async {
                      final bytes = await BuildingPdfGenerator.generateBill(bill);
                      await PdfDownloadHelper.downloadPdf(
                        bytes: bytes,
                        filename: 'Building_Invoice_${bill.billNumber}.pdf',
                      );
                    },
                    tooltip: 'Download Building Invoice PDF',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.primary),
                    onPressed: () {
                      final invoiceText = "CLIENT INVOICE #${bill.billNumber}\nProject: ${bill.projectName}\nDate: ${bill.billDate}\nAmount: ₹${bill.amount.toStringAsFixed(2)}\nStatus: ${bill.status.toUpperCase()}";
                      Clipboard.setData(ClipboardData(text: invoiceText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied Invoice details to clipboard!')),
                      );
                    },
                    tooltip: 'Share Invoice Details',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.outline),
                    onPressed: onEdit,
                    tooltip: 'Edit Invoice',
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
