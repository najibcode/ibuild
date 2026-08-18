import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../subcontractors/presentation/controllers/subcontractor_controller.dart';

class SnagItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final String tradeCategory;
  final String severity; // Critical, High, Medium, Low
  final String status; // Open, In Progress, Resolved, Closed
  final String? assignedSubcontractor;
  final String? projectId;
  final String? projectName;
  final String? rectificationNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  SnagItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.tradeCategory,
    required this.severity,
    required this.status,
    this.assignedSubcontractor,
    this.projectId,
    this.projectName,
    this.rectificationNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  SnagItem copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? tradeCategory,
    String? severity,
    String? status,
    String? assignedSubcontractor,
    String? projectId,
    String? projectName,
    String? rectificationNotes,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return SnagItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      tradeCategory: tradeCategory ?? this.tradeCategory,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      assignedSubcontractor: assignedSubcontractor ?? this.assignedSubcontractor,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      rectificationNotes: rectificationNotes ?? this.rectificationNotes,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class SnagListScreen extends ConsumerStatefulWidget {
  const SnagListScreen({super.key});

  @override
  ConsumerState<SnagListScreen> createState() => _SnagListScreenState();
}

class _SnagListScreenState extends ConsumerState<SnagListScreen> {
  String _filterStatus = 'All'; // All, Open, In Progress, Resolved, Closed
  String _filterSeverity = 'All'; // All, Critical, High, Medium, Low
  String? _filterProject;
  String _searchQuery = '';

  final List<SnagItem> _snags = [
    SnagItem(
      id: 'SNAG-101',
      title: 'Plaster Crack & Uneven Wall Surface',
      description: 'Hairline cracks visible on east wall. Needs re-grouting and putty touch-up before primer coat.',
      location: 'Block A - Flat 302 (Living Room)',
      tradeCategory: 'Plastering & Masonry',
      severity: 'High',
      status: 'Open',
      assignedSubcontractor: 'Granite Giriraj',
      projectName: 'TigerFalls Resort',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SnagItem(
      id: 'SNAG-102',
      title: 'Exposed Rebar on Column Base',
      description: 'Cover block slipped during concreting. Rebar exposed at base. Needs epoxy bonding and micro-concrete patching.',
      location: 'Podium 1 - Pillar C-14',
      tradeCategory: 'RCC & Structure',
      severity: 'Critical',
      status: 'In Progress',
      assignedSubcontractor: 'Apex Infra Structurals',
      projectName: 'TigerFalls Resort',
      rectificationNotes: 'Shuttering removed; epoxy coat applied, awaiting inspection.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    SnagItem(
      id: 'SNAG-103',
      title: 'Plumbing Waste Trap Misalignment',
      description: 'Waste pipe slope inadequate. Causes slow drainage in master bath floor trap.',
      location: 'Villa 12 - Master Bathroom',
      tradeCategory: 'Plumbing & Drainage',
      severity: 'Medium',
      status: 'Open',
      assignedSubcontractor: 'AquaFlow Services',
      projectName: 'Lakeview Luxury Villa',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SnagItem(
      id: 'SNAG-104',
      title: 'Safety Helmet & Harness Non-Compliance',
      description: 'Workers on 4th floor scaffolding without double-lanyard safety harness.',
      location: 'Tower B - 4th Floor Slab',
      tradeCategory: 'Safety Compliance',
      severity: 'Critical',
      status: 'Resolved',
      assignedSubcontractor: 'Granite Giriraj',
      projectName: 'TigerFalls Resort',
      rectificationNotes: 'Work halted; full PPE kits issued & safety briefing conducted.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  void _shareSnagWhatsApp(SnagItem snag) {
    final dateStr = snag.createdAt.toIso8601String().split('T').first;
    final StringBuffer msgBuffer = StringBuffer();
    msgBuffer.writeln('*IBUILD QUALITY PUNCH LIST NOTICE*');
    msgBuffer.writeln('----------------------------------------');
    msgBuffer.writeln('*Ticket ID:* #${snag.id}');
    msgBuffer.writeln('*Project Site:* ${snag.projectName ?? "Active Site"}');
    msgBuffer.writeln('*Location:* ${snag.location}');
    msgBuffer.writeln('*Trade Category:* ${snag.tradeCategory}');
    msgBuffer.writeln('*Severity:* ${snag.severity.toUpperCase()}');
    msgBuffer.writeln('*Current Status:* ${snag.status.toUpperCase()}');
    msgBuffer.writeln('*Assigned Contractor:* ${snag.assignedSubcontractor ?? "Unassigned"}');
    msgBuffer.writeln('*Date Logged:* $dateStr');
    msgBuffer.writeln('----------------------------------------');
    msgBuffer.writeln('*Defect Description:*');
    msgBuffer.writeln(snag.description);
    if (snag.rectificationNotes != null && snag.rectificationNotes!.isNotEmpty) {
      msgBuffer.writeln('\n*Rectification Notes:*');
      msgBuffer.writeln(snag.rectificationNotes!);
    }
    msgBuffer.writeln('----------------------------------------');
    msgBuffer.writeln('*Action Required:* Please inspect, rectify on site, and confirm closure.');
    msgBuffer.writeln('_Generated via IBUILD Construction ERP_');

    WhatsAppHelper.shareMessage(
      context: context,
      message: msgBuffer.toString(),
      successNotice: 'Snag notice prepared',
    );
  }

  void _showStatusSelectorMenu(BuildContext context, SnagItem snag) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Status for #${snag.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text(context),
                          ),
                        ),
                        Text(
                          snag.title,
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'SELECT NEW STATUS:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),

              // Status Option 1: Open
              _statusOptionTile(
                context,
                title: 'Open (Unresolved)',
                subtitle: 'Defect is actively pending rectification by trade partner',
                icon: Icons.error_outline,
                color: AppColors.error,
                isSelected: snag.status.toLowerCase() == 'open',
                onTap: () {
                  Navigator.pop(ctx);
                  _updateSnagStatus(snag, 'Open');
                },
              ),

              // Status Option 2: In Progress
              _statusOptionTile(
                context,
                title: 'In Progress (Rectifying)',
                subtitle: 'Contractor is actively executing fixes and repairs on site',
                icon: Icons.pending_outlined,
                color: Colors.amber.shade800,
                isSelected: snag.status.toLowerCase() == 'in progress',
                onTap: () {
                  Navigator.pop(ctx);
                  _updateSnagStatus(snag, 'In Progress');
                },
              ),

              // Status Option 3: Resolved
              _statusOptionTile(
                context,
                title: 'Resolved (Fixed on Site)',
                subtitle: 'Rectification complete; awaiting final supervisor sign-off',
                icon: Icons.check_circle_outline,
                color: Colors.teal,
                isSelected: snag.status.toLowerCase() == 'resolved',
                onTap: () {
                  Navigator.pop(ctx);
                  _showRectificationNotesDialog(context, snag, 'Resolved');
                },
              ),

              // Status Option 4: Closed
              _statusOptionTile(
                context,
                title: 'Closed (Inspected & Approved)',
                subtitle: 'Inspection passed; punch item completed and signed off',
                icon: Icons.verified_outlined,
                color: AppColors.secondary,
                isSelected: snag.status.toLowerCase() == 'closed',
                onTap: () {
                  Navigator.pop(ctx);
                  _updateSnagStatus(snag, 'Closed');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : AppColors.border(context),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
            color: isSelected ? color : AppColors.text(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
        ),
        trailing: isSelected
            ? Icon(Icons.check, color: color, size: 20)
            : const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
    );
  }

  void _updateSnagStatus(SnagItem snag, String newStatus, [String? notes]) {
    setState(() {
      final index = _snags.indexWhere((s) => s.id == snag.id);
      if (index != -1) {
        _snags[index] = snag.copyWith(
          status: newStatus,
          rectificationNotes: notes ?? snag.rectificationNotes,
          resolvedAt: (newStatus == 'Resolved' || newStatus == 'Closed') ? DateTime.now() : null,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status for #${snag.id} updated to "$newStatus" ✓'),
        backgroundColor: (newStatus == 'Resolved' || newStatus == 'Closed')
            ? AppColors.secondary
            : (newStatus == 'In Progress' ? Colors.amber.shade800 : AppColors.error),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRectificationNotesDialog(BuildContext context, SnagItem snag, String targetStatus) {
    final notesCtrl = TextEditingController(text: snag.rectificationNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.secondary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Mark as $targetStatus',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record the rectification actions taken to resolve #${snag.id}.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rectification & Verification Notes',
                  hintText: 'e.g. Putty applied, surface smoothed, inspected and approved by Site Engineer.',
                  border: OutlineInputBorder(),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _updateSnagStatus(snag, targetStatus, notesCtrl.text.trim());
            },
            icon: const Icon(Icons.check, size: 16),
            label: Text('Confirm $targetStatus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSnagDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    String category = 'Plastering & Masonry';
    String severity = 'High';
    String? selectedProject;
    String? selectedSubcontractor;

    final projects = ref.read(projectControllerProvider).projects;
    final subcontractors = ref.read(subcontractorControllerProvider).items;
    if (projects.isNotEmpty) selectedProject = projects.first.name;
    if (subcontractors.isNotEmpty) selectedSubcontractor = subcontractors.first.name;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.cardBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.report_problem_outlined, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Text(
                'Log Quality Punch Item / Defect',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record a site snag or non-conformity item for contractor rectification.',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Defect Title *',
                      hintText: 'e.g. Tile lippage in corridor',
                      prefixIcon: Icon(Icons.title, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Specific Location / Flat / Pillar *',
                      hintText: 'e.g. Flat 401 - Kitchen Counter',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProject,
                    decoration: const InputDecoration(
                      labelText: 'Project Site *',
                      prefixIcon: Icon(Icons.apartment, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    items: projects.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                    onChanged: (v) => setDlgState(() => selectedProject = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Trade Category',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Plastering & Masonry', child: Text('Plaster / Masonry')),
                            DropdownMenuItem(value: 'RCC & Structure', child: Text('RCC Structure')),
                            DropdownMenuItem(value: 'Plumbing & Drainage', child: Text('Plumbing')),
                            DropdownMenuItem(value: 'Electrical & MEP', child: Text('Electrical / MEP')),
                            DropdownMenuItem(value: 'Tiles & Flooring', child: Text('Tiling / Flooring')),
                            DropdownMenuItem(value: 'Painting & Finishing', child: Text('Painting')),
                            DropdownMenuItem(value: 'Safety Compliance', child: Text('Safety Issue')),
                          ],
                          onChanged: (v) => setDlgState(() => category = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: severity,
                          decoration: const InputDecoration(
                            labelText: 'Severity Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Critical', child: Text('Critical 🔴')),
                            DropdownMenuItem(value: 'High', child: Text('High 🟠')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium 🟡')),
                            DropdownMenuItem(value: 'Low', child: Text('Low 🟢')),
                          ],
                          onChanged: (v) => setDlgState(() => severity = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (subcontractors.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubcontractor,
                      decoration: const InputDecoration(
                        labelText: 'Assign to Subcontractor / Trade Partner',
                        prefixIcon: Icon(Icons.engineering, size: 18),
                        border: OutlineInputBorder(),
                      ),
                      items: subcontractors.map((s) => DropdownMenuItem(value: s.companyName, child: Text(s.companyName))).toList(),
                      onChanged: (v) => setDlgState(() => selectedSubcontractor = v),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Defect Description & Rectification Guidance',
                      prefixIcon: Icon(Icons.notes, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;

                final newSnag = SnagItem(
                  id: 'SNAG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? 'Inspection defect flagged on site.' : descCtrl.text.trim(),
                  location: locCtrl.text.trim().isEmpty ? 'General Site Area' : locCtrl.text.trim(),
                  tradeCategory: category,
                  severity: severity,
                  status: 'Open',
                  assignedSubcontractor: selectedSubcontractor,
                  projectName: selectedProject,
                  createdAt: DateTime.now(),
                );

                setState(() {
                  _snags.insert(0, newSnag);
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged quality snag #${newSnag.id}! ✓'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log Snag'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor(context),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSnagDialog(BuildContext context, SnagItem snag) {
    final titleCtrl = TextEditingController(text: snag.title);
    final descCtrl = TextEditingController(text: snag.description);
    final locCtrl = TextEditingController(text: snag.location);
    final notesCtrl = TextEditingController(text: snag.rectificationNotes ?? '');
    String category = snag.tradeCategory;
    String severity = snag.severity;
    String status = snag.status;
    String? selectedProject = snag.projectName;
    String? selectedSubcontractor = snag.assignedSubcontractor;

    final projects = ref.read(projectControllerProvider).projects;
    final subcontractors = ref.read(subcontractorControllerProvider).items;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.cardBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Edit Snag #${snag.id}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Defect Title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Specific Location *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: severity,
                          decoration: const InputDecoration(
                            labelText: 'Severity',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Critical', child: Text('Critical 🔴')),
                            DropdownMenuItem(value: 'High', child: Text('High 🟠')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium 🟡')),
                            DropdownMenuItem(value: 'Low', child: Text('Low 🟢')),
                          ],
                          onChanged: (v) => setDlgState(() => severity = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Open', child: Text('Open 🔴')),
                            DropdownMenuItem(value: 'In Progress', child: Text('In Progress 🟡')),
                            DropdownMenuItem(value: 'Resolved', child: Text('Resolved 🟢')),
                            DropdownMenuItem(value: 'Closed', child: Text('Closed ⚪')),
                          ],
                          onChanged: (v) => setDlgState(() => status = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Trade Category',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Plastering & Masonry', child: Text('Plaster / Masonry')),
                            DropdownMenuItem(value: 'RCC & Structure', child: Text('RCC Structure')),
                            DropdownMenuItem(value: 'Plumbing & Drainage', child: Text('Plumbing')),
                            DropdownMenuItem(value: 'Electrical & MEP', child: Text('Electrical / MEP')),
                            DropdownMenuItem(value: 'Tiles & Flooring', child: Text('Tiling / Flooring')),
                            DropdownMenuItem(value: 'Painting & Finishing', child: Text('Painting')),
                            DropdownMenuItem(value: 'Safety Compliance', child: Text('Safety Issue')),
                          ],
                          onChanged: (v) => setDlgState(() => category = v!),
                        ),
                      ),
                    ],
                  ),
                  if (projects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProject,
                      decoration: const InputDecoration(
                        labelText: 'Project Site',
                        border: OutlineInputBorder(),
                      ),
                      items: projects.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                      onChanged: (v) => setDlgState(() => selectedProject = v),
                    ),
                  ],
                  if (subcontractors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubcontractor,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Subcontractor',
                        border: OutlineInputBorder(),
                      ),
                      items: subcontractors.map((s) => DropdownMenuItem(value: s.companyName, child: Text(s.companyName))).toList(),
                      onChanged: (v) => setDlgState(() => selectedSubcontractor = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Defect Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Rectification Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete confirmation
                showDialog(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('Delete Snag Ticket?'),
                    content: Text('Are you sure you want to delete ticket #${snag.id}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(confirmCtx), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(confirmCtx);
                          Navigator.pop(ctx);
                          setState(() {
                            _snags.removeWhere((s) => s.id == snag.id);
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete Ticket'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = _snags.indexWhere((s) => s.id == snag.id);
                  if (index != -1) {
                    _snags[index] = snag.copyWith(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      severity: severity,
                      status: status,
                      tradeCategory: category,
                      projectName: selectedProject,
                      assignedSubcontractor: selectedSubcontractor,
                      rectificationNotes: notesCtrl.text.trim(),
                      resolvedAt: (status == 'Resolved' || status == 'Closed') ? DateTime.now() : null,
                    );
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Snag ticket updated ✓'), backgroundColor: AppColors.secondary),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor(context), foregroundColor: Colors.white),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSnagsPDF(List<SnagItem> snags) async {
    final pdfBytes = await GenericPdfTableGenerator.generatePdf(
      title: 'Site Quality Punch List & Defect Report',
      subtitle: 'Defect inspections, locations, and rectification statuses',
      headers: ['Ticket ID', 'Title', 'Location', 'Trade', 'Severity', 'Status', 'Contractor'],
      data: snags.map((s) => [
        s.id,
        s.title,
        s.location,
        s.tradeCategory,
        s.severity,
        s.status,
        s.assignedSubcontractor ?? 'Unassigned',
      ]).toList(),
    );

    await PdfDownloadHelper.downloadPdf(
      bytes: pdfBytes,
      filename: 'IBUILD_Snag_PunchList_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _exportSnagsExcel(List<SnagItem> snags) async {
    final excelBytes = ExcelGeneratorService.generateTableExcel(
      sheetName: 'Site Quality Snags',
      title: 'Site Quality Punch List & Defect Report',
      headers: ['Ticket ID', 'Title', 'Location', 'Trade', 'Severity', 'Status', 'Contractor', 'Description', 'Rectification Notes', 'Logged Date'],
      rows: snags.map((s) => [
        s.id,
        s.title,
        s.location,
        s.tradeCategory,
        s.severity,
        s.status,
        s.assignedSubcontractor ?? 'Unassigned',
        s.description,
        s.rectificationNotes ?? '',
        s.createdAt.toIso8601String().split('T').first,
      ]).toList(),
    );

    await ExcelDownloadHelper.downloadExcel(
      bytes: excelBytes,
      filename: 'IBUILD_Site_Snags_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectControllerProvider).projects;

    final filtered = _snags.where((s) {
      if (_filterStatus != 'All' && s.status.toLowerCase() != _filterStatus.toLowerCase()) {
        return false;
      }
      if (_filterSeverity != 'All' && s.severity.toLowerCase() != _filterSeverity.toLowerCase()) {
        return false;
      }
      if (_filterProject != null && _filterProject!.isNotEmpty && _filterProject != 'All Sites') {
        if (s.projectName != _filterProject) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = s.title.toLowerCase().contains(q);
        final matchLoc = s.location.toLowerCase().contains(q);
        final matchTrade = s.tradeCategory.toLowerCase().contains(q);
        final matchContractor = (s.assignedSubcontractor ?? '').toLowerCase().contains(q);
        final matchId = s.id.toLowerCase().contains(q);
        return matchTitle || matchLoc || matchTrade || matchContractor || matchId;
      }
      return true;
    }).toList();

    final openCount = _snags.where((s) => s.status.toLowerCase() == 'open').length;
    final inProgressCount = _snags.where((s) => s.status.toLowerCase() == 'in progress').length;
    final resolvedCount = _snags.where((s) => s.status.toLowerCase() == 'resolved' || s.status.toLowerCase() == 'closed').length;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rtl, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Quality Punch List & Snag Management',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.primaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Track defects, assign contractors, and manage site quality rectifications',
              style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
            ),
          ],
        ),
        actions: [
          DataExportActions(
            onExportPdfWithDates: (start, end) async => _exportSnagsPDF(filtered),
            onExportExcelWithDates: (start, end) async => _exportSnagsExcel(filtered),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showAddSnagDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log Snag / Defect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Explanatory Header Banner ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap any status button (e.g. OPEN, IN PROGRESS) on a card to select its next stage, or tap the card to edit defect details.',
                    style: TextStyle(fontSize: 12, color: AppColors.text(context)),
                  ),
                ),
              ],
            ),
          ),

          // ── Metrics KPI Row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 6.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Total Defects',
                    value: '${_snags.length}',
                    subtitle: 'All Sites Logged',
                    color: AppColors.primaryColor(context),
                    icon: Icons.checklist_rtl,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Open Snags',
                    value: '$openCount',
                    subtitle: 'Pending Action',
                    color: AppColors.error,
                    icon: Icons.error_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'In Progress',
                    value: '$inProgressCount',
                    subtitle: 'Rectifying',
                    color: Colors.amber.shade800,
                    icon: Icons.pending_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Resolved / Closed',
                    value: '$resolvedCount',
                    subtitle: 'Rectified Clean',
                    color: AppColors.secondary,
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
          ),

          // ── Search Bar & Project Selector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by defect title, ticket #, location, contractor...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: AppColors.cardBg(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border(context)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: DropdownButton<String>(
                    value: _filterProject ?? 'All Sites',
                    underline: const SizedBox(),
                    icon: const Icon(Icons.filter_list, size: 18),
                    items: [
                      const DropdownMenuItem(value: 'All Sites', child: Text('All Sites', style: TextStyle(fontSize: 12))),
                      ...projects.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (v) => setState(() => _filterProject = v),
                  ),
                ),
              ],
            ),
          ),

          // ── Status & Severity Filter Tabs ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: [
                const Text('STATUS: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(width: 4),
                ...['All', 'Open', 'In Progress', 'Resolved', 'Closed'].map((st) {
                  final isSel = _filterStatus.toLowerCase() == st.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(st, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : AppColors.text(context))),
                      selected: isSel,
                      selectedColor: AppColors.primaryColor(context),
                      backgroundColor: AppColors.cardBg(context),
                      side: BorderSide(color: isSel ? AppColors.primaryColor(context) : AppColors.border(context)),
                      onSelected: (_) => setState(() => _filterStatus = st),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                const Text('SEVERITY: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(width: 4),
                ...['All', 'Critical', 'High', 'Medium', 'Low'].map((sev) {
                  final isSel = _filterSeverity.toLowerCase() == sev.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(sev, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : AppColors.text(context))),
                      selected: isSel,
                      selectedColor: sev == 'Critical' ? AppColors.error : (sev == 'High' ? Colors.deepOrange : AppColors.primaryColor(context)),
                      backgroundColor: AppColors.cardBg(context),
                      side: BorderSide(color: isSel ? (sev == 'Critical' ? AppColors.error : AppColors.primaryColor(context)) : AppColors.border(context)),
                      onSelected: (_) => setState(() => _filterSeverity = sev),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Snag Cards List ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 54, color: AppColors.mutedText(context).withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No site defects found for this filter.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 4),
                        Text('Click "+ Log Snag / Defect" to register site inspections.', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final snag = filtered[i];
                      return _buildSnagCard(context, snag);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.mutedText(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 8.5, color: color, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSnagCard(BuildContext context, SnagItem snag) {
    Color sevColor;
    switch (snag.severity.toLowerCase()) {
      case 'critical':
        sevColor = AppColors.error;
        break;
      case 'high':
        sevColor = Colors.deepOrange;
        break;
      case 'medium':
        sevColor = Colors.amber.shade800;
        break;
      default:
        sevColor = AppColors.secondary;
        break;
    }

    Color statColor;
    IconData statIcon;
    switch (snag.status.toLowerCase()) {
      case 'open':
        statColor = AppColors.error;
        statIcon = Icons.error_outline;
        break;
      case 'in progress':
        statColor = Colors.amber.shade800;
        statIcon = Icons.pending_outlined;
        break;
      case 'resolved':
        statColor = Colors.teal;
        statIcon = Icons.check_circle_outline;
        break;
      case 'closed':
        statColor = AppColors.secondary;
        statIcon = Icons.verified_outlined;
        break;
      default:
        statColor = AppColors.primaryColor(context);
        statIcon = Icons.circle_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showEditSnagDialog(context, snag),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Severity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: sevColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: sevColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        snag.severity.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sevColor),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Title & Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${snag.id} — ${snag.title}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '📍 ${snag.location} • ${snag.tradeCategory}',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),

                    // Status Dropdown Trigger Button (Opens Status Selection Menu)
                    Tooltip(
                      message: 'Click to select status (Open, In Progress, Resolved, Closed)',
                      child: InkWell(
                        onTap: () => _showStatusSelectorMenu(context, snag),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statColor.withValues(alpha: 0.4), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statIcon, size: 13, color: statColor),
                              const SizedBox(width: 4),
                              Text(
                                snag.status.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statColor),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 14, color: statColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  snag.description,
                  style: TextStyle(fontSize: 12, color: AppColors.text(context)),
                ),
                if (snag.rectificationNotes != null && snag.rectificationNotes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '🛠️ Rectification: ${snag.rectificationNotes}',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.engineering_outlined, size: 14, color: AppColors.primaryColor(context)),
                        const SizedBox(width: 4),
                        Text(
                          snag.assignedSubcontractor ?? 'Unassigned Subcontractor',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryColor(context)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          tooltip: 'Edit Snag Details',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showEditSnagDialog(context, snag),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _shareSnagWhatsApp(snag),
                          icon: const Icon(Icons.share, size: 13),
                          label: const Text('WhatsApp Notice', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366)),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
