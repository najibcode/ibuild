import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../projects/data/models/project_model.dart';
import '../../expenses/data/models/expense_model.dart';
import '../../inventory/data/models/inventory_item_model.dart';
import '../../attendance/data/models/attendance_model.dart';

/// Professional PDF report generator for IBUILD ERP.
///
/// Produces a structured, branded audit document with company header,
/// project details, financial summaries, inventory valuations, and
/// attendance logs — formatted for executive review.
class PdfReportGenerator {
  static const String _companyName = 'IBUILD';
  static const String _companyTagline = 'Able Construction';
  static const PdfColor _primaryBlue = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor _darkBlue = PdfColor.fromInt(0xFF0D47A1);
  static const PdfColor _lightBlue = PdfColor.fromInt(0xFFE3F2FD);
  static const PdfColor _accentOrange = PdfColor.fromInt(0xFFE65100);
  static const PdfColor _grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor _grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor _green = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _red = PdfColor.fromInt(0xFFC62828);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _rowBg = PdfColor.fromInt(0xFFF5F5F5);

  /// Generates a complete PDF report as raw bytes.
  static Future<Uint8List> generateReport({
    required String reportType,
    required List<Project> projects,
    required List<Expense> expenses,
    required List<InventoryItem> inventoryItems,
    required List<Attendance> attendanceRecords,
    required bool includeExpenses,
    required bool includeInventory,
    required bool includeAttendance,
    String? selectedProjectId,
  }) async {
    final pdf = pw.Document(
      title: 'IBUILD ERP - $reportType',
      author: _companyName,
      creator: 'IBUILD ERP Report Engine',
      subject: reportType,
    );

    final now = DateTime.now();
    final dateFormatted = DateFormat('dd MMMM yyyy').format(now);
    final timeFormatted = DateFormat('hh:mm:ss a').format(now);
    final timestampFormatted = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);

    // Filter projects based on selection
    final filteredProjects = selectedProjectId == null || selectedProjectId == 'all'
        ? projects
        : projects.where((p) => p.id == selectedProjectId).toList();

    final projectScopeName = filteredProjects.isEmpty
        ? 'All Enterprise Sites'
        : (filteredProjects.length == 1 ? filteredProjects.first.name : '${filteredProjects.length} Selected Projects');

    // Aggregate financial data
    final double totalBudget = filteredProjects.fold(0.0, (sum, p) => sum + p.budget);
    final double totalSpent = filteredProjects.fold(0.0, (sum, p) => sum + p.spent);
    final double utilization = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0;

    // Filter expenses by project
    final filteredExpenses = expenses.where((e) {
      if (selectedProjectId == null || selectedProjectId == 'all') return true;
      return e.projectId == selectedProjectId;
    }).toList();
    final double totalExpensesAmount = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final double totalInventoryValuation = inventoryItems.fold(0.0, (sum, i) => sum + i.totalValuation);
    final int lowStockCount = inventoryItems.where((i) => i.isLowStock).length;

    // Fonts
    final headerFont = pw.Font.helveticaBold();
    final bodyFont = pw.Font.helvetica();
    final italicFont = pw.Font.helveticaOblique();

    // Build PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPageHeader(context, headerFont, bodyFont, dateFormatted, timeFormatted),
        footer: (context) => _buildPageFooter(context, bodyFont, italicFont, timestampFormatted),
        build: (context) => [
          // Report Title Bar
          _buildReportTitleBar(reportType, projectScopeName, headerFont, bodyFont),
          pw.SizedBox(height: 20),

          // Executive Financial Summary (always shown)
          _buildSectionTitle('Financial & Portfolio Executive Summary', headerFont),
          pw.SizedBox(height: 8),
          _buildFinancialSummaryTable(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            utilization: utilization,
            totalExpenses: totalExpensesAmount,
            expenseCount: filteredExpenses.length,
            projectCount: filteredProjects.length,
            headerFont: headerFont,
            bodyFont: bodyFont,
          ),
          pw.SizedBox(height: 12),

          // Project Details Table
          if (filteredProjects.isNotEmpty) ...[
            _buildSectionTitle('Project Details', headerFont),
            pw.SizedBox(height: 8),
            _buildProjectDetailsTable(filteredProjects, headerFont, bodyFont),
            pw.SizedBox(height: 16),
          ],

          // Expense Section
          if (includeExpenses && filteredExpenses.isNotEmpty) ...[
            _buildSectionTitle('Site Expense Outflow Ledger', headerFont),
            pw.SizedBox(height: 8),
            _buildExpenseTable(filteredExpenses, headerFont, bodyFont),
            pw.SizedBox(height: 16),
          ],

          // Inventory Section
          if (includeInventory && inventoryItems.isNotEmpty) ...[
            _buildSectionTitle('Material Inventory & Stock Valuation', headerFont),
            pw.SizedBox(height: 8),
            _buildInventorySummaryRow(totalInventoryValuation, lowStockCount, inventoryItems.length, bodyFont, headerFont),
            pw.SizedBox(height: 8),
            _buildInventoryTable(inventoryItems, headerFont, bodyFont),
            pw.SizedBox(height: 16),
          ],

          // Attendance Section
          if (includeAttendance && attendanceRecords.isNotEmpty) ...[
            _buildSectionTitle('Worker Attendance & Shift Log', headerFont),
            pw.SizedBox(height: 8),
            _buildAttendanceTable(attendanceRecords, headerFont, bodyFont),
            pw.SizedBox(height: 16),
          ],

          // Report Closure
          pw.SizedBox(height: 24),
          _buildReportClosure(headerFont, bodyFont, italicFont, timestampFormatted),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── PAGE HEADER ────────────────────────────────────────────────────
  static pw.Widget _buildPageHeader(
    pw.Context context,
    pw.Font headerFont,
    pw.Font bodyFont,
    String date,
    String time,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primaryBlue, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _companyName,
                style: pw.TextStyle(
                  font: headerFont,
                  fontSize: 24,
                  color: _darkBlue,
                  letterSpacing: 3,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _companyTagline,
                style: pw.TextStyle(
                  font: bodyFont,
                  fontSize: 10,
                  color: _grey600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                date,
                style: pw.TextStyle(font: headerFont, fontSize: 10, color: _darkBlue),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                time,
                style: pw.TextStyle(font: bodyFont, fontSize: 9, color: _grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PAGE FOOTER ────────────────────────────────────────────────────
  static pw.Widget _buildPageFooter(
    pw.Context context,
    pw.Font bodyFont,
    pw.Font italicFont,
    String timestamp,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _grey200, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CONFIDENTIAL — IBUILD ERP Internal Report',
            style: pw.TextStyle(font: italicFont, fontSize: 7, color: _grey600),
          ),
          pw.Text(
            'Generated: $timestamp  |  Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: bodyFont, fontSize: 7, color: _grey600),
          ),
        ],
      ),
    );
  }

  // ─── REPORT TITLE BAR ──────────────────────────────────────────────
  static pw.Widget _buildReportTitleBar(
    String reportType,
    String projectScope,
    pw.Font headerFont,
    pw.Font bodyFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: pw.BoxDecoration(
        color: _darkBlue,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                reportType.toUpperCase(),
                style: pw.TextStyle(font: headerFont, fontSize: 14, color: _white, letterSpacing: 1),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Scope: $projectScope',
                style: pw.TextStyle(font: bodyFont, fontSize: 9, color: PdfColor.fromInt(0xFFB3D4FC)),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'ERP AUDIT',
              style: pw.TextStyle(font: headerFont, fontSize: 8, color: _darkBlue, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION TITLE ─────────────────────────────────────────────────
  static pw.Widget _buildSectionTitle(String title, pw.Font headerFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primaryBlue, width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 16,
            color: _primaryBlue,
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(font: headerFont, fontSize: 11, color: _darkBlue, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  // ─── FINANCIAL SUMMARY ─────────────────────────────────────────────
  static pw.Widget _buildFinancialSummaryTable({
    required double totalBudget,
    required double totalSpent,
    required double utilization,
    required double totalExpenses,
    required int expenseCount,
    required int projectCount,
    required pw.Font headerFont,
    required pw.Font bodyFont,
  }) {
    final formatter = NumberFormat('#,##,###.00');
    final remaining = totalBudget - totalSpent;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _primaryBlue, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _kpiBlock('Total Budget', '₹${formatter.format(totalBudget)}', _darkBlue, headerFont, bodyFont),
              _kpiBlock('Total Spent', '₹${formatter.format(totalSpent)}', _accentOrange, headerFont, bodyFont),
              _kpiBlock('Remaining', '₹${formatter.format(remaining)}', remaining >= 0 ? _green : _red, headerFont, bodyFont),
              _kpiBlock('Utilization', '${utilization.toStringAsFixed(1)}%', utilization > 90 ? _red : _darkBlue, headerFont, bodyFont),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _primaryBlue, thickness: 0.3),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Active Projects: $projectCount', style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _grey600)),
              pw.Text('Logged Expense Entries: $expenseCount', style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _grey600)),
              pw.Text('Total Site Outflows: ₹${formatter.format(totalExpenses)}', style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _grey600)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpiBlock(String label, String value, PdfColor color, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: pw.TextStyle(font: bodyFont, fontSize: 7, color: _grey600)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(font: headerFont, fontSize: 12, color: color)),
      ],
    );
  }

  // ─── PROJECT DETAILS TABLE ─────────────────────────────────────────
  static pw.Widget _buildProjectDetailsTable(List<Project> projects, pw.Font headerFont, pw.Font bodyFont) {
    final formatter = NumberFormat('#,##,###.00');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 8, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: ['Project Name', 'Client', 'Status', 'Budget (₹)', 'Spent (₹)', 'Start Date'],
      data: projects.take(20).map((p) => [
        p.name,
        p.clientName ?? p.customerName ?? '-',
        p.status.toUpperCase(),
        formatter.format(p.budget),
        formatter.format(p.spent),
        p.startDate ?? '-',
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── EXPENSE TABLE ─────────────────────────────────────────────────
  static pw.Widget _buildExpenseTable(List<Expense> expenses, pw.Font headerFont, pw.Font bodyFont) {
    final formatter = NumberFormat('#,##,###.00');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 8, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: ['Date', 'Category', 'Amount (₹)', 'Payment', 'Project Site', 'Notes'],
      data: expenses.take(30).map((e) => [
        e.expenseDate,
        e.category.toUpperCase(),
        formatter.format(e.amount),
        e.paymentMode.toUpperCase(),
        e.projectName ?? 'General',
        (e.notes ?? '-').length > 35 ? '${(e.notes ?? '-').substring(0, 35)}...' : (e.notes ?? '-'),
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── INVENTORY SUMMARY ROW ─────────────────────────────────────────
  static pw.Widget _buildInventorySummaryRow(double valuation, int lowStock, int totalItems, pw.Font bodyFont, pw.Font headerFont) {
    final formatter = NumberFormat('#,##,###.00');
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total Stock Valuation: ₹${formatter.format(valuation)}', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _darkBlue)),
          pw.Text('Total Items: $totalItems', style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _grey600)),
          pw.Text(
            'Low Stock Alerts: $lowStock',
            style: pw.TextStyle(font: headerFont, fontSize: 8, color: lowStock > 0 ? _red : _green),
          ),
        ],
      ),
    );
  }

  // ─── INVENTORY TABLE ───────────────────────────────────────────────
  static pw.Widget _buildInventoryTable(List<InventoryItem> items, pw.Font headerFont, pw.Font bodyFont) {
    final formatter = NumberFormat('#,##,###.00');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 8, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: ['Material', 'Category', 'Stock', 'Unit', 'Price (₹)', 'Valuation (₹)', 'Status'],
      data: items.take(30).map((i) => [
        i.materialName,
        i.category,
        i.availableStock.toStringAsFixed(1),
        i.unit,
        formatter.format(i.purchasePrice),
        formatter.format(i.totalValuation),
        i.isLowStock ? 'LOW STOCK' : 'Healthy',
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── ATTENDANCE TABLE ──────────────────────────────────────────────
  static pw.Widget _buildAttendanceTable(List<Attendance> records, pw.Font headerFont, pw.Font bodyFont) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 8, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: ['Date', 'Worker Name', 'Status', 'Project Site'],
      data: records.take(30).map((a) => [
        a.date,
        a.employeeName ?? 'Worker',
        a.status.toUpperCase(),
        a.projectName ?? 'General',
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── REPORT CLOSURE ────────────────────────────────────────────────
  static pw.Widget _buildReportClosure(pw.Font headerFont, pw.Font bodyFont, pw.Font italicFont, String timestamp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _primaryBlue, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'END OF REPORT',
            style: pw.TextStyle(font: headerFont, fontSize: 11, color: _darkBlue, letterSpacing: 2),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: _grey200, thickness: 0.5),
          pw.SizedBox(height: 6),
          pw.Text(
            'This report was auto-generated by the IBUILD ERP Report Engine on $timestamp.',
            style: pw.TextStyle(font: italicFont, fontSize: 7.5, color: _grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'IBUILD — Able Construction | Confidential & Internal Use Only',
            style: pw.TextStyle(font: headerFont, fontSize: 7, color: _darkBlue, letterSpacing: 0.5),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}
