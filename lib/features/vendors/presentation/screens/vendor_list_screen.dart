import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../subcontractors/data/models/subcontractor_model.dart';
import '../../../subcontractors/presentation/controllers/subcontractor_controller.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  String _searchQuery = '';
  String? _tradeFilter;

  void _showAddSubcontractorDialog(BuildContext context) {
    final companyCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final siteCtrl = TextEditingController();
    final contractCtrl = TextEditingController(text: '2500000');
    final paidCtrl = TextEditingController(text: '1000000');
    String selectedTrade = 'Electrical & MEP';
    String selectedStatus = 'Active';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg(context),
              title: Text('Register Subcontractor Vendor', style: TextStyle(color: AppColors.text(context))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: companyCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Company / Firm Name',
                        hintText: 'e.g. Sri Laxmi Electricals',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: personCtrl,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Contact Person',
                              hintText: 'e.g. Srinivas Rao',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '+91 98765...',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: siteCtrl,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: 'Assigned Site Name',
                        hintText: 'e.g. Skyline Towers Phase 1',
                        labelStyle: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedTrade,
                            dropdownColor: AppColors.cardBg(context),
                            decoration: InputDecoration(
                              labelText: 'Trade Specialization',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                            items: ['Electrical & MEP', 'Steel Fabrication', 'Plumbing & Drainage', 'Tiling & Flooring', 'Civil Work']
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) => setDialogState(() => selectedTrade = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            dropdownColor: AppColors.cardBg(context),
                            decoration: InputDecoration(
                              labelText: 'Contract Status',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                            items: ['Active', 'Completed', 'Pending']
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s, style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) => setDialogState(() => selectedStatus = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: contractCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Contract Amount (₹)',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: paidCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Amount Paid (₹)',
                              labelStyle: TextStyle(color: AppColors.mutedText(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (companyCtrl.text.trim().isEmpty) return;
                    final newSub = Subcontractor(
                      id: '',
                      name: companyCtrl.text.trim(),
                      companyNameProp: companyCtrl.text.trim(),
                      contactPersonProp: personCtrl.text.trim().isEmpty ? 'Contractor' : personCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      specialization: selectedTrade,
                      siteNameProp: siteCtrl.text.trim().isEmpty ? 'Main Site' : siteCtrl.text.trim(),
                      contractValue: double.tryParse(contractCtrl.text) ?? 0.0,
                      paidAmount: double.tryParse(paidCtrl.text) ?? 0.0,
                      status: selectedStatus,
                      createdAt: DateTime.now(),
                    );

                    await ref.read(subcontractorControllerProvider.notifier).addSubcontractor(newSub);
                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subcontractor vendor registered successfully')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor(context),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register Vendor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subcontractorControllerProvider);
    final vendors = subState.items;

    final trades = vendors.map((v) => v.tradeSpecialization).toSet().toList();

    final filtered = vendors.where((v) {
      final matchesSearch = _searchQuery.isEmpty ||
          v.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.siteName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTrade = _tradeFilter == null || v.tradeSpecialization == _tradeFilter;
      return matchesSearch && matchesTrade;
    }).toList();

    final totalSubcontractors = vendors.length;
    final totalContractValue = vendors.fold<double>(0, (sum, v) => sum + v.contractAmount);
    final totalPaid = vendors.fold<double>(0, (sum, v) => sum + v.paidAmount);
    final totalRetentionPending = vendors.fold<double>(0, (sum, v) => sum + v.retentionPending);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Subcontractor & Vendor Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddSubcontractorDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Partner'),
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
            onPressed: () => ref.read(subcontractorControllerProvider.notifier).loadSubcontractors(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubcontractorDialog(context),
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Partner'),
      ),
      body: subState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Financial Metric Summary Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              title: 'Subcontractors',
                              value: '$totalSubcontractors Firms',
                              subtitle: 'Active Contracts',
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
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
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
                              value: '₹${_fmt(totalRetentionPending)}',
                              subtitle: 'Retention Due',
                              icon: Icons.pending_actions_outlined,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search & Trade Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SearchFilterBar(
                        hintText: 'Search company, contact person, site...',
                        onSearchChanged: (val) => setState(() => _searchQuery = val),
                        filterOptions: trades,
                        activeFilter: _tradeFilter,
                        onFilterChanged: (val) => setState(() => _tradeFilter = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Vendor Subcontractor Directory List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_ind_outlined, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'No subcontractors found.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                              ),
                            ],
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
        onPressed: () => _showAddSubcontractorDialog(context),
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedText(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, Subcontractor vendor) {
    final double pctPaid = vendor.contractAmount > 0 ? (vendor.paidAmount / vendor.contractAmount) : 0.0;
    Color statusColor = vendor.status.toLowerCase() == 'completed'
        ? AppColors.secondary
        : AppColors.primaryColor(context);

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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.business_outlined, color: AppColors.primaryColor(context), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.companyName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${vendor.contactPerson} • ${vendor.phone ?? "-"}',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  vendor.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Trade & Site Tags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vendor.tradeSpecialization,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: AppColors.mutedText(context)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        vendor.siteName,
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Contract vs Paid Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disbursed: ₹${_fmt(vendor.paidAmount)} of ₹${_fmt(vendor.contractAmount)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                  ),
                  Text(
                    '${(pctPaid * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pctPaid.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.border(context),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Retention Pending:',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              Text(
                '₹${_fmt(vendor.retentionPending)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: vendor.retentionPending > 0 ? AppColors.warning : AppColors.secondary,
                ),
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
