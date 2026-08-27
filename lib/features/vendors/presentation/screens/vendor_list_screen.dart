import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/mobile_nav_helper.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../projects/presentation/controllers/project_dashboard_controller.dart';
import '../../../subcontractors/data/models/subcontractor_model.dart';
import '../../../subcontractors/presentation/controllers/subcontractor_controller.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const VendorListScreen({
    super.key,
    this.onBackPressed,
  });

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  String _searchQuery = '';
  String? _tradeFilter;
  String _statusFilter = 'All';

  void _showSubcontractorFormDialog(
    BuildContext context, {
    Subcontractor? existing,
  }) {
    final companyCtrl = TextEditingController(
      text: existing?.companyName ?? '',
    );
    final personCtrl = TextEditingController(
      text: existing?.contactPerson ?? '',
    );
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final siteCtrl = TextEditingController(text: existing?.siteName ?? '');
    final contractCtrl = TextEditingController(
      text: (existing?.contractValue ?? 2500000).toStringAsFixed(0),
    );
    final paidCtrl = TextEditingController(
      text: (existing?.paidAmount ?? 0).toStringAsFixed(0),
    );
    String selectedTrade = existing?.tradeSpecialization ?? 'Electrical & MEP';
    String selectedStatus = existing?.status ?? 'Active';

    final initialProjects = ref.read(projectControllerProvider).projects;
    String? selectedProjectId = existing?.projectId;
    if (selectedProjectId == null && existing?.siteNameProp != null && existing!.siteNameProp != 'Unassigned') {
      final match = initialProjects.where(
        (p) => p.name.toLowerCase() == existing.siteNameProp!.toLowerCase(),
      );
      if (match.isNotEmpty) selectedProjectId = match.first.id;
    }
    if (selectedProjectId == null && existing == null && initialProjects.isNotEmpty) {
      selectedProjectId = initialProjects.first.id;
    }

    // Ensure projects are loaded fresh
    ref.read(projectControllerProvider.notifier).loadProjects();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Consumer(
          builder: (context, dialogRef, _) {
            final projects = dialogRef
                .watch(projectControllerProvider)
                .projects;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                final siteDropdownItems = <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.public,
                          size: 16,
                          color: AppColors.mutedText(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'General (No Specific Project)',
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...projects.map(
                    (p) => DropdownMenuItem<String?>(
                      value: p.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment,
                            size: 16,
                            color: AppColors.primaryColor(context),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const DropdownMenuItem<String?>(
                    value: '__custom__',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_location_alt_outlined,
                          size: 16,
                          color: Colors.deepOrange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Other (Type Custom Site)',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];

                return AlertDialog(
                  backgroundColor: AppColors.cardBg(context),
                  title: Text(
                    existing == null
                        ? 'Register Subcontractor Vendor'
                        : 'Edit Subcontractor Details',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: companyCtrl,
                          style: TextStyle(color: AppColors.text(context)),
                          decoration: InputDecoration(
                            labelText: 'Company / Firm Name *',
                            hintText: 'e.g. Sri Laxmi Electricals',
                            labelStyle: TextStyle(
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: personCtrl,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Contact Person',
                                  hintText: 'e.g. Srinivas Rao',
                                  labelStyle: TextStyle(
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: '+91 98765...',
                                  labelStyle: TextStyle(
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Assigned Site / Project Dropdown
                        Text(
                          'ASSIGNED PROJECT SITE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mutedText(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String?>(
                          initialValue:
                              siteDropdownItems.any(
                                (i) => i.value == selectedProjectId,
                              )
                              ? selectedProjectId
                              : null,
                          dropdownColor: AppColors.cardBg(context),
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.apartment_outlined,
                              color: AppColors.primaryColor(context),
                              size: 20,
                            ),
                            hintText: 'Select active project site',
                            hintStyle: TextStyle(
                              color: AppColors.mutedText(context),
                            ),
                            labelStyle: TextStyle(
                              color: AppColors.mutedText(context),
                            ),
                          ),
                          items: siteDropdownItems,
                          onChanged: (val) {
                            setDialogState(() {
                              selectedProjectId = val;
                              if (val != '__custom__' && val != null) {
                                final match = projects.where((element) => element.id == val);
                                if (match.isNotEmpty) {
                                  siteCtrl.text = match.first.name;
                                }
                              } else if (val == null) {
                                siteCtrl.text = 'General Operations';
                              } else {
                                siteCtrl.clear();
                              }
                            });
                          },
                        ),
                        if (selectedProjectId == '__custom__') ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: siteCtrl,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: InputDecoration(
                              labelText: 'Custom Site Name',
                              hintText: 'e.g. Skyline Towers Phase 1',
                              prefixIcon: const Icon(
                                Icons.edit_location_alt_outlined,
                                size: 18,
                                color: Colors.deepOrange,
                              ),
                              labelStyle: TextStyle(
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedTrade,
                                dropdownColor: AppColors.cardBg(context),
                                decoration: InputDecoration(
                                  labelText: 'Trade Specialization',
                                  labelStyle: TextStyle(
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                                items:
                                    [
                                          'Electrical & MEP',
                                          'Steel Fabrication',
                                          'Plumbing & Drainage',
                                          'Tiling & Flooring',
                                          'Civil Work',
                                          'Painting & Finishing',
                                        ]
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              t,
                                              style: TextStyle(
                                                color: AppColors.text(context),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) =>
                                    setDialogState(() => selectedTrade = val!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                dropdownColor: AppColors.cardBg(context),
                                decoration: InputDecoration(
                                  labelText: 'Contract Status',
                                  labelStyle: TextStyle(
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                                items: ['Active', 'Completed', 'Pending']
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: TextStyle(
                                            color: AppColors.text(context),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setDialogState(() => selectedStatus = val!),
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
                                style: TextStyle(
                                  color: AppColors.text(context),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Contract Amount (₹) *',
                                  labelStyle: TextStyle(
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: paidCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Disbursed to Date (₹)',
                                  labelStyle: TextStyle(
                                    color: AppColors.mutedText(context),
                                  ),
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

                        String? targetProjectId;
                        String finalSiteName = 'General Operations';

                        if (selectedProjectId == '__custom__') {
                          finalSiteName = siteCtrl.text.trim().isEmpty ? 'Custom Site' : siteCtrl.text.trim();
                        } else if (selectedProjectId != null) {
                          targetProjectId = selectedProjectId;
                          final matched = projects.where((p) => p.id == selectedProjectId);
                          if (matched.isNotEmpty) {
                            finalSiteName = matched.first.name;
                          }
                        }

                        final newSub = Subcontractor(
                          id: existing?.id ?? '',
                          name: companyCtrl.text.trim(),
                          companyNameProp: companyCtrl.text.trim(),
                          contactPersonProp: personCtrl.text.trim().isEmpty
                              ? 'Contractor'
                              : personCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          specialization: selectedTrade,
                          projectId: targetProjectId,
                          siteNameProp: finalSiteName,
                          contractValue:
                              double.tryParse(contractCtrl.text) ?? 0.0,
                          paidAmount: double.tryParse(paidCtrl.text) ?? 0.0,
                          status: selectedStatus,
                          createdAt: existing?.createdAt ?? DateTime.now(),
                        );

                        final success = existing == null
                            ? await ref
                                  .read(
                                    subcontractorControllerProvider.notifier,
                                  )
                                  .addSubcontractor(newSub)
                            : await ref
                                  .read(
                                    subcontractorControllerProvider.notifier,
                                  )
                                  .updateSubcontractor(newSub);

                        if (targetProjectId != null) {
                          ref.invalidate(projectDashboardProvider(targetProjectId));
                        }
                        ref.invalidate(projectControllerProvider);

                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  existing == null
                                      ? 'Subcontractor registered & linked to $finalSiteName ✓'
                                      : 'Subcontractor details updated successfully ✓',
                                ),
                                backgroundColor: AppColors.secondary,
                              ),
                            );
                          } else {
                            final err =
                                ref
                                    .read(subcontractorControllerProvider)
                                    .error ??
                                'Unknown error';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save vendor: $err'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor(context),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        existing == null ? 'Register Vendor' : 'Save Changes',
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showQuickAssignProjectDialog(BuildContext context, Subcontractor vendor) {
    final projects = ref.read(projectControllerProvider).projects;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.apartment, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Assign ${vendor.companyName} to Project Site',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width < 460 ? double.maxFinite : 440,
          child: projects.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No active projects found. Please create a project first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Linking this contractor to a project will display the site name and sync their ₹${_fmt(vendor.paidAmount)} disbursed amount to the project financial tracker.',
                          style: TextStyle(fontSize: 11, color: AppColors.text(context)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...projects.map((p) {
                        final isSelected = vendor.projectId == p.id ||
                            vendor.siteName.toLowerCase() == p.name.toLowerCase();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.bg(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border(context),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                isSelected ? Icons.check : Icons.apartment,
                                color: isSelected ? Colors.white : AppColors.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.text(context),
                              ),
                            ),
                            subtitle: Text(
                              'Budget: ₹${_fmt(p.budget)} • Recorded Spent: ₹${_fmt(p.spent)}',
                              style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                            ),
                            trailing: isSelected
                                ? const Text(
                                    'Active Site',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor(context),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(dialogCtx);
                                      final ok = await ref
                                          .read(subcontractorControllerProvider.notifier)
                                          .assignProject(
                                            sub: vendor,
                                            projectId: p.id,
                                            siteName: p.name,
                                          );

                                      ref.invalidate(projectDashboardProvider(p.id));
                                      ref.invalidate(projectControllerProvider);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(ok
                                                ? 'Linked "${vendor.companyName}" to "${p.name}" & synced ₹${_fmt(vendor.paidAmount)} to project!'
                                                : 'Failed to assign project'),
                                            backgroundColor: ok
                                                ? const Color(0xFF10B981)
                                                : AppColors.error,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Assign', style: TextStyle(fontSize: 11)),
                                  ),
                            onTap: () async {
                              Navigator.pop(dialogCtx);
                              final ok = await ref
                                  .read(subcontractorControllerProvider.notifier)
                                  .assignProject(
                                    sub: vendor,
                                    projectId: p.id,
                                    siteName: p.name,
                                  );

                              ref.invalidate(projectDashboardProvider(p.id));
                              ref.invalidate(projectControllerProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Linked "${vendor.companyName}" to "${p.name}" & synced ₹${_fmt(vendor.paidAmount)} to project!'
                                        : 'Failed to assign project'),
                                    backgroundColor: ok
                                        ? const Color(0xFF10B981)
                                        : AppColors.error,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, Subcontractor vendor) {
    final grossCtrl = TextEditingController(text: '100000');
    final advanceCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController(text: 'RA Bill Clearance');
    double retentionPct = 5.0; // standard 5% retention
    double tdsPct = 2.0; // standard 2% TDS under section 194C
    bool chargeProjectExpense = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final double gross = double.tryParse(grossCtrl.text) ?? 0.0;
          final double advance = double.tryParse(advanceCtrl.text) ?? 0.0;
          final double retentionMoney = gross * (retentionPct / 100.0);
          final double tdsDeduction = gross * (tdsPct / 100.0);
          final double netPayable = (gross - retentionMoney - tdsDeduction - advance).clamp(0.0, double.infinity);

          return AlertDialog(
            backgroundColor: AppColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.secondary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'RA Bill & Retention: ${vendor.companyName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width < 540 ? double.maxFinite : 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Contract Value: ₹${_fmt(vendor.contractAmount)}', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                          Text('Already Paid: ₹${_fmt(vendor.paidAmount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Gross Work Claimed
                    TextField(
                      controller: grossCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Gross Certified Work Done (₹) *',
                        prefixIcon: Icon(Icons.payments_outlined, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Retention Deduction Selector
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Retention Money Held:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [0.0, 5.0, 10.0].map((pct) {
                            final isSel = retentionPct == pct;
                            return ChoiceChip(
                              label: Text('${pct.toInt()}%', style: TextStyle(fontSize: 10, color: isSel ? Colors.white : AppColors.text(context))),
                              selected: isSel,
                              selectedColor: Colors.deepOrange,
                              onSelected: (_) => setModalState(() => retentionPct = pct),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // TDS Deduction Selector
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TDS Deduction (Sec 194C):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [0.0, 1.0, 2.0].map((pct) {
                            final isSel = tdsPct == pct;
                            return ChoiceChip(
                              label: Text('${pct.toInt()}%', style: TextStyle(fontSize: 10, color: isSel ? Colors.white : AppColors.text(context))),
                              selected: isSel,
                              selectedColor: Colors.purple,
                              onSelected: (_) => setModalState(() => tdsPct = pct),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Advance / Material Recovery
                    TextField(
                      controller: advanceCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Advance / Material Recovery (₹)',
                        prefixIcon: Icon(Icons.remove_circle_outline, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Summary Breakdown Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gross Certified Amount:', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                              Text('₹${_fmt(gross)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('(-) Retention (${retentionPct.toInt()}%):', style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
                              Text('-₹${_fmt(retentionMoney)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepOrange)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('(-) TDS Deduction (${tdsPct.toInt()}%):', style: const TextStyle(fontSize: 12, color: Colors.purple)),
                              Text('-₹${_fmt(tdsDeduction)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple)),
                            ],
                          ),
                          if (advance > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('(-) Advance Recovery:', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                                Text('-₹${_fmt(advance)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                              ],
                            ),
                          ],
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('NET DISBURSABLE AMOUNT:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${_fmt(netPayable)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'RA Bill Clearance Notes',
                        prefixIcon: Icon(Icons.notes, size: 18),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Charge Project Expense Checkbox
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: chargeProjectExpense,
                      activeColor: AppColors.primary,
                      title: Text(
                        'Charge Net ₹${_fmt(netPayable)} to Site Project Expense',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                      ),
                      subtitle: Text(
                        'Assigned Site: ${vendor.siteName}',
                        style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
                      ),
                      onChanged: (val) => setModalState(() => chargeProjectExpense = val ?? true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final summaryText = "*IBUILD SUBCONTRACTOR RA BILL STATEMENT*\n"
                      "----------------------------------------\n"
                      "*Trade Partner:* ${vendor.companyName}\n"
                      "*Trade Specialization:* ${vendor.tradeSpecialization}\n"
                      "----------------------------------------\n"
                      "• Gross Work Claimed: INR ${_fmt(gross)}\n"
                      "• Retention Held (${retentionPct.toInt()}%): -INR ${_fmt(retentionMoney)}\n"
                      "• TDS Deducted (${tdsPct.toInt()}%): -INR ${_fmt(tdsDeduction)}\n"
                      "• Advance Recovery: -INR ${_fmt(advance)}\n"
                      "----------------------------------------\n"
                      "*NET PAYABLE AMOUNT:* INR ${_fmt(netPayable)}\n"
                      "----------------------------------------\n"
                      "*Notes:* ${notesCtrl.text}\n"
                      "_Generated via IBUILD Construction ERP_";

                  WhatsAppHelper.shareMessage(
                    context: context,
                    message: summaryText,
                    phoneNumber: vendor.phone,
                    successNotice: 'RA Bill statement prepared',
                  );
                },
                icon: const Icon(Icons.share, size: 14),
                label: const Text('Share RA Bill', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (netPayable <= 0 && gross <= 0) return;

                  final projects = ref.read(projectControllerProvider).projects;
                  String? targetProjectId = vendor.projectId;
                  if (targetProjectId == null && vendor.siteName.isNotEmpty) {
                    final match = projects.where((p) => p.name.toLowerCase() == vendor.siteName.toLowerCase());
                    if (match.isNotEmpty) targetProjectId = match.first.id;
                  }
                  if (targetProjectId == null && projects.isNotEmpty) {
                    targetProjectId = projects.first.id;
                  }

                  final targetSub = vendor.copyWith(projectId: targetProjectId);

                  if (chargeProjectExpense) {
                    await ref.read(subcontractorControllerProvider.notifier).recordPayment(
                      sub: targetSub,
                      amount: netPayable,
                      paymentMode: 'Bank Transfer',
                      remarks: 'RA Bill Payment (${vendor.tradeSpecialization}) - Net: ₹${_fmt(netPayable)}, Gross: ₹${_fmt(gross)}, Retention: ₹${_fmt(retentionMoney)}. ${notesCtrl.text.trim()}',
                    );
                    ref.invalidate(projectControllerProvider);
                  } else {
                    final updated = vendor.copyWith(
                      paidAmount: vendor.paidAmount + netPayable,
                      projectId: targetProjectId,
                    );
                    await ref.read(subcontractorControllerProvider.notifier).updateSubcontractor(updated);
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Certified & Disbursed Net ₹${_fmt(netPayable)} to ${vendor.companyName} & synced to Project Expenses ✓'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Certify & Disburse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteSubcontractor(BuildContext context, Subcontractor vendor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: const Text('Delete Subcontractor'),
        content: Text(
          'Are you sure you want to remove ${vendor.companyName} (${vendor.tradeSpecialization}) from vendor management?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref
                  .read(subcontractorControllerProvider.notifier)
                  .deleteSubcontractor(vendor.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Subcontractor ${vendor.companyName} deleted',
                      ),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subcontractorControllerProvider);
    final vendors = subState.items;

    final trades = vendors.map((v) => v.tradeSpecialization).toSet().toList();

    final filtered = vendors.where((v) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          v.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.siteName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTrade =
          _tradeFilter == null || v.tradeSpecialization == _tradeFilter;
      final matchesStatus =
          _statusFilter == 'All' ||
          v.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesTrade && matchesStatus;
    }).toList();

    final totalSubcontractors = vendors.length;
    final totalContractValue = vendors.fold<double>(
      0,
      (sum, v) => sum + v.contractAmount,
    );
    final totalPaid = vendors.fold<double>(0, (sum, v) => sum + v.paidAmount);
    final totalRetentionPending = vendors.fold<double>(
      0,
      (sum, v) => sum + v.retentionPending,
    );

    final hasBack = widget.onBackPressed != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: hasBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back',
                onPressed: () {
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: MobileNavHelper.openDrawer,
              ),
        titleSpacing: 0,
        title: Text(
          'Subcontractors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final filtered = vendors.where((v) {
                return !v.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !v.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Subcontractors & Vendors Directory',
                subtitle: 'Active trade partners, contract value & payments summary',
                headers: ['Company Name', 'Trade / Specialty', 'Contact Person', 'Phone', 'Assigned Site', 'Contract (INR)', 'Paid (INR)', 'Status'],
                data: filtered.map((v) => [
                  v.companyName,
                  v.tradeSpecialization,
                  v.contactPerson,
                  v.phone ?? 'N/A',
                  v.siteName,
                  'INR ${v.contractAmount.toStringAsFixed(2)}',
                  'INR ${v.paidAmount.toStringAsFixed(2)}',
                  v.status.toUpperCase(),
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Vendors_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final filtered = vendors.where((v) {
                return !v.createdAt.isBefore(DateTime(start.year, start.month, start.day)) &&
                       !v.createdAt.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
              }).toList();
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Vendors_Subcontractors',
                title: 'Subcontractor & Vendor Management Directory',
                headers: ['Company Name', 'Trade Specialization', 'Contact Person', 'Phone', 'Assigned Site', 'Contract Value (INR)', 'Paid Amount (INR)', 'Retention Pending (INR)', 'Status'],
                rows: filtered.map((v) => [
                  v.companyName,
                  v.tradeSpecialization,
                  v.contactPerson,
                  v.phone,
                  v.siteName,
                  v.contractAmount,
                  v.paidAmount,
                  v.retentionPending,
                  v.status.toUpperCase(),
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Vendors_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => ref
                .read(subcontractorControllerProvider.notifier)
                .loadSubcontractors(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubcontractorFormDialog(context),
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Partner'),
      ),
      body: subState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Financial Metric Summary Cards
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

                // Search & Filters Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SearchFilterBar(
                        hintText: 'Search company, contact person, site...',
                        onSearchChanged: (val) =>
                            setState(() => _searchQuery = val),
                        filterOptions: trades,
                        activeFilter: _tradeFilter,
                        onFilterChanged: (val) =>
                            setState(() => _tradeFilter = val),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text(
                              'Status Filter: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 6,
                              children: ['All', 'Active', 'Completed', 'Pending']
                                  .map((st) {
                                    final isSelected =
                                        _statusFilter.toLowerCase() ==
                                        st.toLowerCase();
                                    return ChoiceChip(
                                      label: Text(
                                        st,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.text(context),
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppColors.primaryColor(
                                        context,
                                      ),
                                      backgroundColor: AppColors.cardBg(context),
                                      onSelected: (_) =>
                                          setState(() => _statusFilter = st),
                                    );
                                  })
                                  .toList(),
                            ),
                          ],
                        ),
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
                              Icon(
                                Icons.assignment_ind_outlined,
                                size: 64,
                                color: AppColors.mutedText(
                                  context,
                                ).withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No subcontractors found.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.text(context),
                                ),
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, Subcontractor vendor) {
    final double pctPaid = vendor.contractAmount > 0
        ? (vendor.paidAmount / vendor.contractAmount)
        : 0.0;
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
                        color: AppColors.primaryColor(
                          context,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        color: AppColors.primaryColor(context),
                        size: 20,
                      ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
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
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.mutedText(context),
                    ),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showSubcontractorFormDialog(context, existing: vendor);
                      } else if (val == 'payment') {
                        _showRecordPaymentDialog(context, vendor);
                      } else if (val == 'delete') {
                        _confirmDeleteSubcontractor(context, vendor);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Subcontractor'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'payment',
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_card_outlined,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 8),
                            Text('RA Bill & Payment'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Subcontractor',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showQuickAssignProjectDialog(context, vendor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (vendor.projectId == null || vendor.siteName == 'Unassigned')
                          ? Colors.amber.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (vendor.projectId == null || vendor.siteName == 'Unassigned')
                            ? Colors.amber.shade700.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (vendor.projectId == null || vendor.siteName == 'Unassigned')
                              ? Icons.add_location_alt_outlined
                              : Icons.apartment,
                          size: 13,
                          color: (vendor.projectId == null || vendor.siteName == 'Unassigned')
                              ? Colors.amber.shade900
                              : AppColors.primaryColor(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            (vendor.projectId == null || vendor.siteName == 'Unassigned')
                                ? 'Assign Project Site +'
                                : vendor.siteName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (vendor.projectId == null || vendor.siteName == 'Unassigned')
                                  ? Colors.amber.shade900
                                  : AppColors.text(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: AppColors.mutedText(context),
                        ),
                      ],
                    ),
                  ),
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                  Text(
                    '${(pctPaid * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText(context),
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${_fmt(vendor.retentionPending)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: vendor.retentionPending > 0
                          ? AppColors.warning
                          : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showSubcontractorFormDialog(context, existing: vendor),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
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
