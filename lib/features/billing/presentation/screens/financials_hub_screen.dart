import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'billing_list_screen.dart';
import '../../../quotations/presentation/screens/quotation_list_screen.dart';
import '../../../expenses/presentation/screens/expense_list_screen.dart';
import '../../../sales_bills/data/repositories/supabase_sales_bill_repository.dart';
import '../../../payments/presentation/screens/payment_ledger_screen.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../controllers/billing_controller.dart';

/// Streamlined Financial Management Hub consolidating Billing, Quotations/Estimates,
/// and Site Expenses into a single, user-friendly single-level interface.
class FinancialsHubScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const FinancialsHubScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<FinancialsHubScreen> createState() => _FinancialsHubScreenState();
}

class _FinancialsHubScreenState extends ConsumerState<FinancialsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Calculate Executive Financial Summary Metrics ──
    final billingState = ref.watch(billingControllerProvider);
    final salesBillsAsync = ref.watch(allSalesBillsProvider);
    final expensesState = ref.watch(expenseControllerProvider);
    final ledgerAsync = ref.watch(allPaymentLedgerProvider);

    final salesBills = salesBillsAsync.valueOrNull ?? [];
    final ledgerEntries = ledgerAsync.valueOrNull ?? [];

    // Money In (Sales Invoices Billed/Collected + Ledger Inflows)
    final double salesInvoicesTotal = salesBills.fold(0.0, (s, b) => s + b.totalAmount);
    final double ledgerInflow = ledgerEntries
        .where((e) => e.paymentType.toLowerCase() == 'received')
        .fold(0.0, (s, e) => s + e.amount);
    final double totalMoneyIn = salesInvoicesTotal + ledgerInflow;

    // Money Out (Vendor Bills + Site Expenses + Ledger Outflows)
    final double vendorBillsTotal = billingState.bills.fold(0.0, (s, b) => s + b.amount);
    final double siteExpensesTotal = expensesState.expenses.fold(0.0, (s, e) => s + e.amount);
    final double ledgerOutflow = ledgerEntries
        .where((e) => e.paymentType.toLowerCase() == 'paid')
        .fold(0.0, (s, e) => s + e.amount);
    final double totalMoneyOut = vendorBillsTotal + siteExpensesTotal + ledgerOutflow;

    // Net Cash Flow
    final double netCashFlow = totalMoneyIn - totalMoneyOut;

    // Pending Receivables (Sales Invoices not marked paid)
    final double pendingReceivables = salesBills
        .where((b) => b.status.toLowerCase() != 'paid' && b.status.toLowerCase() != 'completed')
        .fold(0.0, (s, b) => s + b.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Financials & Money Hub',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryColor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Executive cash flow overview and streamlined accounting',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedText(context),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh all financial records',
            onPressed: () {
              ref.read(billingControllerProvider.notifier).loadBills();
              ref.read(expenseControllerProvider.notifier).loadExpenses();
              ref.invalidate(allSalesBillsProvider);
              ref.invalidate(allPaymentLedgerProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(138),
          child: Column(
            children: [
              // Executive Finance Summary Banner
              _buildExecutiveSummaryBanner(
                context,
                totalMoneyIn: totalMoneyIn,
                totalMoneyOut: totalMoneyOut,
                netCashFlow: netCashFlow,
                pendingReceivables: pendingReceivables,
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryColor(context),
                labelColor: AppColors.primaryColor(context),
                unselectedLabelColor: AppColors.mutedText(context),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.receipt_long, size: 18),
                    text: '💳 Transactions & Ledger',
                  ),
                  Tab(
                    icon: Icon(Icons.account_balance_wallet, size: 18),
                    text: '💸 Site Expenses',
                  ),
                  Tab(
                    icon: Icon(Icons.request_quote, size: 18),
                    text: '📝 Quotations & Estimates',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Single-level Transactions & Ledger (Client Invoices, Vendor Bills, Payment Logs)
          BillingListScreen(isEmbedded: true),

          // Tab 2: Site Operational Expenses & Petty Cash
          ExpenseListScreen(isEmbedded: true),

          // Tab 3: Commercial Quotations & Cost Estimator
          QuotationListScreen(isEmbedded: true),
        ],
      ),
    );
  }

  /// Responsive Executive Financial Summary Banner displaying key cash flow indicators
  Widget _buildExecutiveSummaryBanner(
    BuildContext context, {
    required double totalMoneyIn,
    required double totalMoneyOut,
    required double netCashFlow,
    required double pendingReceivables,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          if (isMobile) {
            return Row(
              children: [
                Expanded(
                  child: _summaryTile(
                    context,
                    title: 'MONEY IN',
                    value: '₹${_fmtAmount(totalMoneyIn)}',
                    color: AppColors.secondary,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryTile(
                    context,
                    title: 'MONEY OUT',
                    value: '₹${_fmtAmount(totalMoneyOut)}',
                    color: AppColors.error,
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _summaryTile(
                    context,
                    title: 'NET CASH',
                    value: '${netCashFlow >= 0 ? '+' : ''}₹${_fmtAmount(netCashFlow)}',
                    color: netCashFlow >= 0 ? AppColors.secondary : AppColors.error,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _summaryTile(
                  context,
                  title: 'MONEY IN (INFLOW)',
                  value: '₹${_fmtAmount(totalMoneyIn)}',
                  color: AppColors.secondary,
                  icon: Icons.south_west,
                  subtitle: 'Sales & Receipts',
                ),
              ),
              const VerticalDivider(width: 16),
              Expanded(
                child: _summaryTile(
                  context,
                  title: 'MONEY OUT (OUTFLOW)',
                  value: '₹${_fmtAmount(totalMoneyOut)}',
                  color: AppColors.error,
                  icon: Icons.north_east,
                  subtitle: 'Bills & Site Costs',
                ),
              ),
              const VerticalDivider(width: 16),
              Expanded(
                child: _summaryTile(
                  context,
                  title: 'NET CASH POSITION',
                  value: '${netCashFlow >= 0 ? '+' : ''}₹${_fmtAmount(netCashFlow)}',
                  color: netCashFlow >= 0 ? AppColors.secondary : AppColors.error,
                  icon: Icons.account_balance,
                  subtitle: netCashFlow >= 0 ? 'Surplus Cash' : 'Net Outflow',
                ),
              ),
              const VerticalDivider(width: 16),
              Expanded(
                child: _summaryTile(
                  context,
                  title: 'PENDING RECEIVABLES',
                  value: '₹${_fmtAmount(pendingReceivables)}',
                  color: Colors.amber.shade800,
                  icon: Icons.pending_actions,
                  subtitle: 'Uncollected Invoices',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.text(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.mutedText(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String _fmtAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    }
    if (abs >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    }
    if (abs >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

