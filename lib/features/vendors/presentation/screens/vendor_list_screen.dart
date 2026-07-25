import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';

class VendorSubcontractor {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String tradeSpecialization;
  final String siteName;
  final double contractAmount;
  final double paidAmount;
  final String status; // Active, Completed, Pending

  VendorSubcontractor({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.tradeSpecialization,
    required this.siteName,
    required this.contractAmount,
    required this.paidAmount,
    required this.status,
  });

  double get retentionPending => contractAmount - paidAmount;
}

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  String _searchQuery = '';
  String? _tradeFilter;

  final List<VendorSubcontractor> _vendors = [
    VendorSubcontractor(
      id: 'sub-1',
      companyName: 'Sri Laxmi Electricals & Heavy Wiring',
      contactPerson: 'Srinivas Rao',
      phone: '+91 98765 43210',
      tradeSpecialization: 'Electrical & MEP',
      siteName: 'Skyline Luxury Towers',
      contractAmount: 4500000,
      paidAmount: 3200000,
      status: 'Active',
    ),
    VendorSubcontractor(
      id: 'sub-2',
      companyName: 'Deccan Steel Fabricators & Rebar Works',
      contactPerson: 'Venkatesh Kumar',
      phone: '+91 91234 56789',
      tradeSpecialization: 'Steel Fabrication',
      siteName: 'Metro Pillar Section B',
      contractAmount: 8200000,
      paidAmount: 6800000,
      status: 'Active',
    ),
    VendorSubcontractor(
      id: 'sub-3',
      companyName: 'Bharathi Sanitary & Plumbing Solutions',
      contactPerson: 'K. Bharath',
      phone: '+91 99887 76655',
      tradeSpecialization: 'Plumbing & Drainage',
      siteName: 'Commercial Complex Phase 2',
      contractAmount: 2800000,
      paidAmount: 2800000,
      status: 'Completed',
    ),
    VendorSubcontractor(
      id: 'sub-4',
      companyName: 'Royal Marble & Granites Contractor',
      contactPerson: 'Mohammed Ali',
      phone: '+91 94411 22334',
      tradeSpecialization: 'Tiling & Flooring',
      siteName: 'Skyline Luxury Towers',
      contractAmount: 3600000,
      paidAmount: 1800000,
      status: 'Active',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final trades = _vendors.map((v) => v.tradeSpecialization).toSet().toList();

    final filtered = _vendors.where((v) {
      final matchesSearch = _searchQuery.isEmpty ||
          v.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.siteName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTrade = _tradeFilter == null || v.tradeSpecialization.toLowerCase() == _tradeFilter!.toLowerCase();
      return matchesSearch && matchesTrade;
    }).toList();

    final totalContractValue = _vendors.fold(0.0, (sum, v) => sum + v.contractAmount);
    final totalPaid = _vendors.fold(0.0, (sum, v) => sum + v.paidAmount);
    final totalPendingRetention = totalContractValue - totalPaid;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: Text(
          'Subcontractors & Vendor Directory',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Financial Metrics Header Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Total Subcontractors',
                    value: '${_vendors.length}',
                    subtitle: 'Contracted Vendors',
                    icon: Icons.assignment_ind_outlined,
                    color: AppColors.primaryColor(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Contract Value',
                    value: '₹${_fmt(totalContractValue)}',
                    subtitle: 'Total Value',
                    icon: Icons.account_balance_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Paid Out',
                    value: '₹${_fmt(totalPaid)}',
                    subtitle: 'Disbursed',
                    icon: Icons.payments_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pending Retention',
                    value: '₹${_fmt(totalPendingRetention)}',
                    subtitle: 'Balance Payable',
                    icon: Icons.pending_outlined,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Search & Trade Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchFilterBar(
              hintText: 'Search subcontractor, contact, site...',
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              filterOptions: trades,
              activeFilter: _tradeFilter,
              onFilterChanged: (t) => setState(() => _tradeFilter = t),
            ),
          ),
          const SizedBox(height: 10),

          // Subcontractor Item List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No subcontractors matching "$_searchQuery".',
                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final vendor = filtered[index];
                      return _buildVendorCard(context, vendor);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New subcontractor onboarding form opened.')),
          );
        },
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add Subcontractor'),
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

  Widget _buildVendorCard(BuildContext context, VendorSubcontractor v) {
    final isActive = v.status.toLowerCase() == 'active';
    final primaryCol = AppColors.primaryColor(context);
    final paidPercent = (v.paidAmount / v.contractAmount).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryCol.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v.tradeSpecialization.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryCol),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.secondary.withValues(alpha: 0.12)
                      : AppColors.mutedText(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  v.status.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? AppColors.secondary : AppColors.mutedText(context),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            v.companyName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact: ${v.contactPerson} • ${v.phone}',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
          ),
          Text(
            'Site Assignment: ${v.siteName}',
            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 12),

          // Payment Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contract Value: ₹${_fmt(v.contractAmount)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              Text(
                '${(paidPercent * 100).toInt()}% Disbursed',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPercent,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation(AppColors.secondary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ₹${_fmt(v.paidAmount)}',
                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
              ),
              Text(
                'Retention Pending: ₹${_fmt(v.retentionPending)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
