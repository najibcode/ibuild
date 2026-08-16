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
  final DateTime createdAt;

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
    required this.createdAt,
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SnagListScreen extends ConsumerStatefulWidget {
  const SnagListScreen({super.key});

  @override
  ConsumerState<SnagListScreen> createState() => _SnagListScreenState();
}

class _SnagListScreenState extends ConsumerState<SnagListScreen> {
  String _filterStatus = 'All'; // All, Open, In Progress, Resolved
  String? _filterProject;
  String _searchQuery = '';

  final List<SnagItem> _snags = [
    SnagItem(
      id: 'SNAG-101',
      title: 'Plaster Crack & Uneven Surface',
      description: 'Hairline cracks visible on east wall. Needs re-grouting and putty touch-up.',
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
      title: 'Exposed Rebar on Column Edge',
      description: 'Cover block slipped during concreting. Rebar exposed at base. Needs epoxy bonding.',
      location: 'Podium 1 - Pillar C-14',
      tradeCategory: 'RCC & Structure',
      severity: 'Critical',
      status: 'In Progress',
      assignedSubcontractor: 'Apex Infra Structurals',
      projectName: 'TigerFalls Resort',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    SnagItem(
      id: 'SNAG-103',
      title: 'Plumbing Trap Misalignment',
      description: 'Waste pipe slope inadequate. Causes slow drainage in master bath.',
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
      description: 'Workers on 4th floor scaffolding without double-lanyard harness.',
      location: 'Tower B - 4th Floor Slab',
      tradeCategory: 'Safety Compliance',
      severity: 'Critical',
      status: 'Resolved',
      assignedSubcontractor: 'Granite Giriraj',
      projectName: 'TigerFalls Resort',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  void _shareSnagWhatsApp(SnagItem snag) {
    final dateStr = snag.createdAt.toIso8601String().split('T').first;
    final msg = "⚠️ *SITE SNAG / DEFECT NOTICE — IBUILD ERP*\n"
        "🆔 *Ticket:* ${snag.id}\n"
        "🏢 *Site:* ${snag.projectName ?? 'Active Site'}\n"
        "📍 *Location:* ${snag.location}\n"
        "🛠️ *Category:* ${snag.tradeCategory}\n"
        "🚨 *Severity:* ${snag.severity.toUpperCase()}\n"
        "👤 *Assigned Trade:* ${snag.assignedSubcontractor ?? 'Unassigned'}\n"
        "📅 *Date Logged:* $dateStr\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "📝 *Defect Description:*\n${snag.description}\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "📌 *Action Required:* Please rectify and share photographic proof of closure.\n"
        "_Generated via IBUILD Site Quality Hub_";

    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}");
    try {
      canLaunchUrl(url).then((ok) {
        if (ok) launchUrl(url, mode: LaunchMode.externalApplication);
      });
    } catch (_) {}

    Clipboard.setData(ClipboardData(text: msg));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Snag Notice copied & opened in WhatsApp! ✓'),
        backgroundColor: Color(0xFF25D366),
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
                'Log Site Defect / Snag',
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
                    content: Text('Logged site snag #${newSnag.id}! ✓'),
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

  void _cycleStatus(SnagItem snag) {
    String nextStatus;
    switch (snag.status.toLowerCase()) {
      case 'open':
        nextStatus = 'In Progress';
        break;
      case 'in progress':
        nextStatus = 'Resolved';
        break;
      case 'resolved':
        nextStatus = 'Closed';
        break;
      default:
        nextStatus = 'Open';
        break;
    }

    setState(() {
      final index = _snags.indexWhere((s) => s.id == snag.id);
      if (index != -1) {
        _snags[index] = snag.copyWith(status: nextStatus);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated #${snag.id} status to "$nextStatus"'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _snags.where((s) {
      if (_filterStatus != 'All' && s.status.toLowerCase() != _filterStatus.toLowerCase()) {
        return false;
      }
      if (_filterProject != null && s.projectName != _filterProject) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return s.title.toLowerCase().contains(q) ||
            s.location.toLowerCase().contains(q) ||
            s.tradeCategory.toLowerCase().contains(q) ||
            (s.assignedSubcontractor?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    final int openCount = _snags.where((s) => s.status.toLowerCase() == 'open').length;
    final int inProgressCount = _snags.where((s) => s.status.toLowerCase() == 'in progress').length;
    final int resolvedCount = _snags.where((s) => s.status.toLowerCase() == 'resolved' || s.status.toLowerCase() == 'closed').length;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Site Snags & Quality Punch List',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdf: () async {
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'IBUILD SITE QUALITY & DEFECT PUNCH LIST',
                subtitle: 'Active Snags, Defects & Quality Punch Points',
                headers: ['ID', 'Title', 'Location', 'Category', 'Severity', 'Trade Partner', 'Status'],
                data: _snags
                    .map((s) => [
                          s.id,
                          s.title,
                          s.location,
                          s.tradeCategory,
                          s.severity,
                          s.assignedSubcontractor ?? 'Unassigned',
                          s.status,
                        ])
                    .toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Snag_List_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            onExportExcel: () async {
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Site Snags',
                title: 'IBUILD Site Quality & Snagging Punch List',
                headers: ['ID', 'Title', 'Description', 'Location', 'Category', 'Severity', 'Subcontractor', 'Project', 'Status', 'Date'],
                rows: _snags
                    .map((s) => [
                          s.id,
                          s.title,
                          s.description,
                          s.location,
                          s.tradeCategory,
                          s.severity,
                          s.assignedSubcontractor ?? 'Unassigned',
                          s.projectName ?? '',
                          s.status,
                          s.createdAt.toIso8601String().split('T').first,
                        ])
                    .toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Snags_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSnagDialog,
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: const Text('Log Snag / Defect'),
      ),
      body: Column(
        children: [
          // KPI Metric Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Total Defects',
                    value: '${_snags.length}',
                    subtitle: 'Site Punch List',
                    color: AppColors.primaryColor(context),
                    icon: Icons.checklist,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Open Issues',
                    value: '$openCount',
                    subtitle: 'Action Required',
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
                    title: 'Resolved',
                    value: '$resolvedCount',
                    subtitle: 'Closed Clean',
                    color: AppColors.secondary,
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar & Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search snags, location, contractor...',
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

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: ['All', 'Open', 'In Progress', 'Resolved'].map((st) {
                final isSel = _filterStatus.toLowerCase() == st.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(st, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : AppColors.text(context))),
                    selected: isSel,
                    selectedColor: AppColors.primaryColor(context),
                    backgroundColor: AppColors.cardBg(context),
                    side: BorderSide(color: isSel ? AppColors.primaryColor(context) : AppColors.border(context)),
                    onSelected: (_) => setState(() => _filterStatus = st),
                  ),
                );
              }).toList(),
            ),
          ),

          // Snag Cards List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 54, color: AppColors.mutedText(context).withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No site snags found for this filter.',
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
    switch (snag.status.toLowerCase()) {
      case 'open':
        statColor = AppColors.error;
        break;
      case 'in progress':
        statColor = Colors.amber.shade800;
        break;
      case 'resolved':
      case 'closed':
        statColor = AppColors.secondary;
        break;
      default:
        statColor = AppColors.primaryColor(context);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snag.title,
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
              InkWell(
                onTap: () => _cycleStatus(snag),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snag.status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statColor),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_drop_down, size: 14, color: statColor),
                    ],
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
    );
  }
}
