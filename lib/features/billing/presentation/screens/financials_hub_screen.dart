import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'billing_list_screen.dart';
import '../../../quotations/presentation/screens/quotation_list_screen.dart';
import '../../../expenses/presentation/screens/expense_list_screen.dart';

/// Unified Financial Management Hub consolidating Billing, Quotations/Estimates,
/// and Site Expenses into a single, beginner-friendly streamlined interface.
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
  bool _showExplanationBanner = true;

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
              'Unified view of Client Billing, Proposals, and Site Expenses',
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
            icon: Icon(
              _showExplanationBanner ? Icons.help_outline : Icons.help,
              color: AppColors.primaryColor(context),
              size: 20,
            ),
            tooltip: 'Toggle plain-English helper guide',
            onPressed: () {
              setState(() {
                _showExplanationBanner = !_showExplanationBanner;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showExplanationBanner ? 135 : 48),
          child: Column(
            children: [
              if (_showExplanationBanner) _buildHelperBanner(context),
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
                    text: 'Invoices & Billing (Money In)',
                  ),
                  Tab(
                    icon: Icon(Icons.request_quote, size: 18),
                    text: 'Quotations & Estimates (Proposals)',
                  ),
                  Tab(
                    icon: Icon(Icons.account_balance_wallet, size: 18),
                    text: 'Expenses & Costs (Money Out)',
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
          // Sub-Tab 1: Billing & Invoices
          BillingListScreen(),

          // Sub-Tab 2: Quotations & Commercial Estimates
          QuotationListScreen(isEmbedded: true),

          // Sub-Tab 3: Site Expenses & Petty Cash Outflow
          ExpenseListScreen(isEmbedded: true),
        ],
      ),
    );
  }

  /// Beginner-friendly explanation banner clarifying financial terms for new users.
  Widget _buildHelperBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'QUICK FINANCIAL GUIDE FOR NEW USERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _showExplanationBanner = false),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _guideChip(
                context,
                badge: '1. Invoices & Billing',
                badgeColor: AppColors.secondary,
                description: 'Money collected from clients for finished work.',
              ),
              _guideChip(
                context,
                badge: '2. Quotations',
                badgeColor: AppColors.primary,
                description: 'Price proposals sent to clients before starting work.',
              ),
              _guideChip(
                context,
                badge: '3. Expenses',
                badgeColor: AppColors.warning,
                description: 'Money paid for materials, wages, fuel, and site costs.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guideChip(
    BuildContext context, {
    required String badge,
    required Color badgeColor,
    required String description,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.text(context),
          ),
        ),
      ],
    );
  }
}
