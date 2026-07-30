import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../attendance/presentation/controllers/attendance_controller.dart';
import '../../data/pdf_report_generator.dart';

class FullReportGeneratorScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const FullReportGeneratorScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<FullReportGeneratorScreen> createState() => _FullReportGeneratorScreenState();
}

class _FullReportGeneratorScreenState extends ConsumerState<FullReportGeneratorScreen> {
  String? _selectedProjectId; // null means 'All Projects'
  String _selectedReportType = 'Full Operational Audit';
  bool _includeExpenses = true;
  bool _includeInventory = true;
  bool _includeAttendance = true;

  static const List<String> _reportTypes = [
    'Full Operational Audit',
    'Budget vs Outflow Report',
    'Material Inventory & Dispatches',
    'Attendance & Daily Wage Summary',
  ];

  String _generateFormattedReportText() {
    final projectState = ref.read(projectControllerProvider);
    final expenseState = ref.read(expenseControllerProvider);
    final inventoryState = ref.read(inventoryControllerProvider);
    final attendanceState = ref.read(attendanceControllerProvider);

    final projects = _selectedProjectId == null || _selectedProjectId == 'all'
        ? projectState.projects
        : projectState.projects.where((p) => p.id == _selectedProjectId).toList();

    final projectName = projects.isEmpty
        ? 'All Enterprise Sites'
        : (projects.length == 1 ? projects.first.name : '${projects.length} Selected Projects');

    final double totalBudget = projects.fold(0.0, (sum, p) => sum + p.budget);
    final double totalSpent = projects.fold(0.0, (sum, p) => sum + p.spent);

    final expenses = expenseState.expenses.where((e) {
      if (_selectedProjectId == null || _selectedProjectId == 'all') return true;
      return e.projectId == _selectedProjectId;
    }).toList();
    final double totalExpensesAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final inventory = inventoryState.items;
    final double totalValuation = inventory.fold(0.0, (sum, i) => sum + i.totalValuation);
    final int lowStockCount = inventory.where((i) => i.isLowStock).length;

    final attendanceRecords = attendanceState.attendanceList;

    final buffer = StringBuffer();
    buffer.writeln("==================================================");
    buffer.writeln("IBUILD ERP - AUDIT & OPERATIONAL REPORT");
    buffer.writeln("Report Type: $_selectedReportType");
    buffer.writeln("Scope: $projectName");
    buffer.writeln("Generated On: ${DateTime.now().toString().substring(0, 16)}");
    buffer.writeln("==================================================\n");

    buffer.writeln("1. FINANCIAL & PORTFOLIO EXECUTIVE SUMMARY");
    buffer.writeln("--------------------------------------------------");
    buffer.writeln("• Total Allocated Budget: ₹${totalBudget.toStringAsFixed(2)}");
    buffer.writeln("• Total Capital Spent:    ₹${totalSpent.toStringAsFixed(2)}");
    buffer.writeln("• Overall Utilization:   ${totalBudget > 0 ? (totalSpent / totalBudget * 100).toStringAsFixed(1) : 0}%");
    buffer.writeln("• Logged Site Outflows:  ₹${totalExpensesAmount.toStringAsFixed(2)} (${expenses.length} records)\n");

    if (_includeExpenses && expenses.isNotEmpty) {
      buffer.writeln("2. SITE EXPENSE OUTFLOW LOGS");
      buffer.writeln("--------------------------------------------------");
      for (final e in expenses.take(15)) {
        buffer.writeln("• ${e.expenseDate} | [${e.category.toUpperCase()}] ₹${e.amount.toStringAsFixed(2)} (${e.paymentMode.toUpperCase()}) - ${e.projectName ?? 'General'}");
      }
      buffer.writeln();
    }

    if (_includeInventory && inventory.isNotEmpty) {
      buffer.writeln("3. MATERIAL INVENTORY & STOCK VALUATION");
      buffer.writeln("--------------------------------------------------");
      buffer.writeln("• Total Stock Valuation: ₹${totalValuation.toStringAsFixed(2)}");
      buffer.writeln("• Low Stock Alert Count: $lowStockCount items requiring reorder\n");
      for (final item in inventory.take(15)) {
        buffer.writeln("• ${item.materialName} (${item.category}): ${item.availableStock.toStringAsFixed(1)} ${item.unit} @ ₹${item.purchasePrice}/${item.unit} | Status: ${item.isLowStock ? 'LOW STOCK' : 'Healthy'}");
      }
      buffer.writeln();
    }

    if (_includeAttendance && attendanceRecords.isNotEmpty) {
      buffer.writeln("4. WORKER ATTENDANCE & WAGE SUMMARY");
      buffer.writeln("--------------------------------------------------");
      buffer.writeln("• Total Logged Shifts: ${attendanceRecords.length} worker entries");
      for (final a in attendanceRecords.take(10)) {
        buffer.writeln("• Date: ${a.date} | Worker: ${a.employeeName ?? 'Worker'} | Status: ${a.status.toUpperCase()} | Site: ${a.projectName ?? 'General'}");
      }
      buffer.writeln();
    }

    buffer.writeln("==================================================");
    buffer.writeln("END OF REPORT - CONFIDENTIAL IBUILD ERP AUDIT");
    buffer.writeln("==================================================");

    return buffer.toString();
  }

  String _generateCsvData() {
    final expenseState = ref.read(expenseControllerProvider);
    final inventoryState = ref.read(inventoryControllerProvider);

    final buffer = StringBuffer();

    // Expenses CSV Section
    buffer.writeln("--- EXPENSES DATA ---");
    buffer.writeln("ID,Expense Date,Category,Amount,Payment Mode,Project Site,Notes");
    for (final e in expenseState.expenses) {
      final safeNotes = (e.notes ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      buffer.writeln("${e.id},${e.expenseDate},${e.category},${e.amount},${e.paymentMode},${e.projectName ?? 'General'},$safeNotes");
    }

    buffer.writeln();
    // Inventory CSV Section
    buffer.writeln("--- MATERIAL INVENTORY DATA ---");
    buffer.writeln("ID,Material Name,Category,Available Stock,Unit,Purchase Price,Total Valuation,Low Stock Alert");
    for (final item in inventoryState.items) {
      buffer.writeln("${item.id},${item.materialName},${item.category},${item.availableStock},${item.unit},${item.purchasePrice},${item.totalValuation},${item.isLowStock}");
    }

    return buffer.toString();
  }

  void _showReportPreviewModal(BuildContext context) {
    final reportText = _generateFormattedReportText();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, color: Colors.deepOrange, size: 22),
            const SizedBox(width: 8),
            Text(
              'Audit Report Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: SelectableText(
                reportText,
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.text(context), height: 1.4),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied full Audit Report to clipboard! Ready to save/print.')),
              );
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Text'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text(context),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportPdf(context);
            },
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Export as PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],

      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final csvContent = _generateCsvData();
    Clipboard.setData(ClipboardData(text: csvContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exported CSV Dataset! Copied raw CSV table to clipboard.'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final projectState = ref.read(projectControllerProvider);
    final expenseState = ref.read(expenseControllerProvider);
    final inventoryState = ref.read(inventoryControllerProvider);
    final attendanceState = ref.read(attendanceControllerProvider);

    try {
      final pdfBytes = await PdfReportGenerator.generateReport(
        reportType: _selectedReportType,
        projects: projectState.projects,
        expenses: expenseState.expenses,
        inventoryItems: inventoryState.items,
        attendanceRecords: attendanceState.attendanceList,
        includeExpenses: _includeExpenses,
        includeInventory: _includeInventory,
        includeAttendance: _includeAttendance,
        selectedProjectId: _selectedProjectId,
      );

      final fileName = 'IBUILD_Audit_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: fileName,
        );
      } catch (_) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: fileName,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF Report generated successfully! Saved to downloads.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectControllerProvider);
    final projects = projectState.projects;

    final Widget bodyContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assessment_outlined, size: 28, color: AppColors.primaryColor(context)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PDF & CSV Operational Report Exporter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
                      Text('Generate enterprise audit reports directly from live database', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Select Project (Default: All Projects)
            Text('PROJECT SCOPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedProjectId,
              dropdownColor: AppColors.cardBg(context),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.apartment_outlined, color: AppColors.primaryColor(context)),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Projects / Full Company Summary (Default)', style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                ...projects.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name, style: TextStyle(color: AppColors.text(context), fontSize: 13)))),
              ],
              onChanged: (v) => setState(() => _selectedProjectId = v),
            ),
            const SizedBox(height: 20),

            // Report Type Selection
            Text('REPORT CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReportType,
              dropdownColor: AppColors.cardBg(context),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.table_chart_outlined, color: AppColors.primaryColor(context)),
              ),
              items: _reportTypes.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: AppColors.text(context), fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedReportType = v ?? _reportTypes.first),
            ),
            const SizedBox(height: 24),

            // Section Toggles
            Text('REPORT SECTIONS TO INCLUDE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Expenses & Financial Outflow History'),
              subtitle: const Text('Includes petty cash, vendor payments, and category totals'),
              value: _includeExpenses,
              onChanged: (v) => setState(() => _includeExpenses = v ?? true),
            ),
            CheckboxListTile(
              title: const Text('Inventory & Material Dispatches'),
              subtitle: const Text('Includes stock valuation and low stock reorder alerts'),
              value: _includeInventory,
              onChanged: (v) => setState(() => _includeInventory = v ?? true),
            ),
            CheckboxListTile(
              title: const Text('Worker Attendance & Daily Wage Log'),
              subtitle: const Text('Includes shift counts and daily wage tallies'),
              value: _includeAttendance,
              onChanged: (v) => setState(() => _includeAttendance = v ?? true),
            ),
            const SizedBox(height: 32),

            // Export Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportPdf(context),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export as PDF Document', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(220, 52),
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showReportPreviewModal(context),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview Text Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(180, 52),
                    side: BorderSide(color: AppColors.primaryColor(context)),
                    foregroundColor: AppColors.primaryColor(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportCsv(context),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Export CSV Dataset', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(180, 52),
                    side: BorderSide(color: AppColors.border(context)),
                    foregroundColor: AppColors.text(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );


    if (!widget.showAppBar) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Reports & Audit Exporter',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
        ),
      ),
      body: bodyContent,
    );
  }
}
