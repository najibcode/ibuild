import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/controllers/project_controller.dart';

class FullReportGeneratorScreen extends ConsumerStatefulWidget {
  const FullReportGeneratorScreen({super.key});

  @override
  ConsumerState<FullReportGeneratorScreen> createState() => _FullReportGeneratorScreenState();
}

class _FullReportGeneratorScreenState extends ConsumerState<FullReportGeneratorScreen> {
  String? _selectedProjectId;
  String _selectedReportType = 'Full Operational Summary';
  bool _includeExpenses = true;
  bool _includeInventory = true;
  bool _includeChecklists = true;
  bool _includeTickets = true;

  final List<String> _reportTypes = [
    'Full Operational Summary',
    'Budget vs Expenses Audit',
    'Supplier & Trade Partner Balances',
    'Attendance & Wage Log',
    'Site Checklist Completion',
    'Tickets & Issue Status',
  ];

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectControllerProvider);
    final projects = projectState.projects;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Reports & Audit Generator'),
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
              Row(
                children: [
                  const Icon(Icons.assessment_outlined, size: 32, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PDF & Excel Report Exporter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
                      const Text('Export audit reports generated dynamically from Supabase database', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(labelText: 'Select Project / Site *'),
                items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: const InputDecoration(labelText: 'Report Type *'),
                items: _reportTypes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _selectedReportType = v ?? _reportTypes.first),
              ),
              const SizedBox(height: 24),
              Text('REPORT SECTIONS TO INCLUDE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Expenses & Payment History'),
                value: _includeExpenses,
                onChanged: (v) => setState(() => _includeExpenses = v ?? true),
              ),
              CheckboxListTile(
                title: const Text('Inventory & Material Dispatches'),
                value: _includeInventory,
                onChanged: (v) => setState(() => _includeInventory = v ?? true),
              ),
              CheckboxListTile(
                title: const Text('Site Quality & Safety Checklists'),
                value: _includeChecklists,
                onChanged: (v) => setState(() => _includeChecklists = v ?? true),
              ),
              CheckboxListTile(
                title: const Text('Open Tickets & Issue Log'),
                value: _includeTickets,
                onChanged: (v) => setState(() => _includeTickets = v ?? true),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedProjectId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a project'), backgroundColor: AppColors.error),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generating PDF Report...'), backgroundColor: AppColors.secondary),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppColors.primaryColor(context),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_selectedProjectId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a project'), backgroundColor: AppColors.error),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exporting CSV/Excel Dataset...'), backgroundColor: AppColors.secondary),
                        );
                      },
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('Export CSV'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
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
