import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../projects/data/models/project_model.dart';
import '../../expenses/data/models/expense_model.dart';
import '../../inventory/data/models/inventory_item_model.dart';
import '../../inventory/data/models/inventory_history_model.dart';
import '../../attendance/data/models/attendance_model.dart';
import '../../subcontractors/data/models/subcontractor_model.dart';
import '../../daily_progress/data/models/daily_progress_model.dart';

/// Professional PDF report generator for IBUILD ERP.
///
/// Uses bundled Roboto TTF fonts for full Unicode support (including ₹).
class PdfReportGenerator {
  static const String _companyName = 'IBUild';
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

  /// Loads bundled Roboto TTF fonts that support ₹ and other Unicode glyphs.
  static Future<Map<String, pw.Font>> _loadFonts() async {
    final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final italicData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
    return {
      'regular': pw.Font.ttf(regularData),
      'bold': pw.Font.ttf(boldData),
      'italic': pw.Font.ttf(italicData),
    };
  }

  /// Generates a complete PDF report as raw bytes.
  static Future<Uint8List> generateReport({
    required String reportType,
    String? dateRangeLabel,
    required List<Project> projects,
    required List<Expense> expenses,
    required List<InventoryItem> inventoryItems,
    List<InventoryHistory> inventoryMovements = const [],
    List<Subcontractor> subcontractors = const [],
    List<DailyProgress> dailyProgressList = const [],
    required List<Attendance> attendanceRecords,
    bool includeExpenses = true,
    bool includeInventory = true,
    bool includeInventoryMovements = true,
    bool includeSubcontractors = true,
    bool includeDailyProgress = true,
    bool includeAttendance = true,
    String? selectedProjectId,
  }) async {
    // Load TTF fonts with full Unicode support
    final fonts = await _loadFonts();
    final headerFont = fonts['bold']!;
    final bodyFont = fonts['regular']!;
    final italicFont = fonts['italic']!;

    final pdf = pw.Document(
      title: 'IBUILD ERP - $reportType',
      author: _companyName,
      creator: 'IBUILD ERP Report Engine',
      subject: reportType,
    );

    final now = DateTime.now();
    final dateFormatted = dateRangeLabel ?? DateFormat('dd MMMM yyyy').format(now);
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

    // Build PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildPageHeader(context, headerFont, bodyFont, dateFormatted, timeFormatted),
        footer: (context) => _buildPageFooter(context, bodyFont, italicFont, timestampFormatted),
        build: (context) => [
          _buildReportTitleBar(reportType, projectScopeName, dateFormatted, headerFont, bodyFont),
          pw.SizedBox(height: 14),

          // 1. Executive Summary
          _buildSectionTitle('Executive & Daily Performance Summary', headerFont),
          pw.SizedBox(height: 6),
          _buildFinancialSummaryTable(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            utilization: utilization,
            totalExpenses: totalExpensesAmount,
            expenseCount: filteredExpenses.length,
            projectCount: filteredProjects.length,
            inventoryMovementCount: inventoryMovements.length,
            subcontractorCount: subcontractors.length,
            headerFont: headerFont,
            bodyFont: bodyFont,
          ),
          pw.SizedBox(height: 14),

          // 2. Project Changes & Daily Progress
          if (filteredProjects.isNotEmpty) ...[
            _buildSectionTitle('1. Project Status, Budgets & Updates', headerFont),
            pw.SizedBox(height: 6),
            _buildProjectDetailsTable(filteredProjects, headerFont, bodyFont),
            pw.SizedBox(height: 14),
          ],

          if (includeDailyProgress && dailyProgressList.isNotEmpty) ...[
            _buildSectionTitle('Site Daily Progress & Operational Notes', headerFont),
            pw.SizedBox(height: 6),
            _buildDailyProgressTable(dailyProgressList, filteredProjects, headerFont, bodyFont),
            pw.SizedBox(height: 14),
          ],

          // 3. Inventory Changes & Movements
          if (includeInventoryMovements && inventoryMovements.isNotEmpty) ...[
            _buildSectionTitle('2. Inventory Changes & Stock Movements (Received / Issued)', headerFont),
            pw.SizedBox(height: 6),
            _buildInventoryMovementsTable(inventoryMovements, headerFont, bodyFont),
            pw.SizedBox(height: 14),
          ],

          // 4. Subcontractor Statuses
          if (includeSubcontractors && subcontractors.isNotEmpty) ...[
            _buildSectionTitle('3. Subcontractor & Trade Partner Status', headerFont),
            pw.SizedBox(height: 6),
            _buildSubcontractorsTable(subcontractors, headerFont, bodyFont),
            pw.SizedBox(height: 14),
          ],

          // 5. Site Expenses & Outflows
          if (includeExpenses && filteredExpenses.isNotEmpty) ...[
            _buildSectionTitle('4. Logged Site Expenses & Financial Outflows', headerFont),
            pw.SizedBox(height: 6),
            _buildExpenseTable(filteredExpenses, headerFont, bodyFont),
            pw.SizedBox(height: 14),
          ],

          // 6. Material Inventory Snapshot
          if (includeInventory && inventoryItems.isNotEmpty) ...[
            _buildSectionTitle('5. Material Inventory Valuation & Stock Health', headerFont),
            pw.SizedBox(height: 6),
            _buildInventorySummaryRow(totalInventoryValuation, lowStockCount, inventoryItems.length, bodyFont, headerFont),
            pw.SizedBox(height: 6),
            _buildInventoryTable(inventoryItems, headerFont, bodyFont),
            pw.SizedBox(height: 14),
          ],

          // 7. Attendance & Shift Log
          if (includeAttendance && attendanceRecords.isNotEmpty) ...[
            _buildSectionTitle('6. Worker Attendance & Daily Wages Log', headerFont),
            pw.SizedBox(height: 6),
            _buildAttendanceTable(attendanceRecords, headerFont, bodyFont),
            pw.SizedBox(height: 14),
          ],

          pw.SizedBox(height: 16),
          _buildReportClosure(headerFont, bodyFont, italicFont, timestampFormatted),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── PAGE HEADER ────────────────────────────────────────────────────
  static pw.Widget _buildPageHeader(
    pw.Context context, pw.Font headerFont, pw.Font bodyFont, String date, String time,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
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
              pw.Text(_companyName, style: pw.TextStyle(font: headerFont, fontSize: 22, color: _darkBlue, letterSpacing: 3)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(date, style: pw.TextStyle(font: headerFont, fontSize: 9.5, color: _darkBlue)),
              pw.SizedBox(height: 2),
              pw.Text(time, style: pw.TextStyle(font: bodyFont, fontSize: 8.5, color: _grey600)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PAGE FOOTER ────────────────────────────────────────────────────
  static pw.Widget _buildPageFooter(
    pw.Context context, pw.Font bodyFont, pw.Font italicFont, String timestamp,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _grey200, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CONFIDENTIAL - IBUILD ERP Comprehensive Operational Report', style: pw.TextStyle(font: italicFont, fontSize: 7, color: _grey600)),
          pw.Text('Generated: $timestamp  |  Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: bodyFont, fontSize: 7, color: _grey600)),
        ],
      ),
    );
  }

  // ─── REPORT TITLE BAR ──────────────────────────────────────────────
  static pw.Widget _buildReportTitleBar(String reportType, String projectScope, String dateFormatted, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(color: _darkBlue, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(reportType.toUpperCase(), style: pw.TextStyle(font: headerFont, fontSize: 13, color: _white, letterSpacing: 1)),
              pw.SizedBox(height: 3),
              pw.Text('Scope: $projectScope  |  Period: $dateFormatted', style: pw.TextStyle(font: bodyFont, fontSize: 8.5, color: PdfColor.fromInt(0xFFB3D4FC))),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(color: _white, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text('DAILY ERP AUDIT', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _darkBlue, letterSpacing: 1)),
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
          pw.Container(width: 3.5, height: 14, color: _primaryBlue),
          pw.SizedBox(width: 6),
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: headerFont, fontSize: 10, color: _darkBlue, letterSpacing: 0.6)),
        ],
      ),
    );
  }

  // ─── FINANCIAL & OPERATIONAL SUMMARY ─────────────────────────────────
  static pw.Widget _buildFinancialSummaryTable({
    required double totalBudget, required double totalSpent, required double utilization,
    required double totalExpenses, required int expenseCount, required int projectCount,
    required int inventoryMovementCount, required int subcontractorCount,
    required pw.Font headerFont, required pw.Font bodyFont,
  }) {
    final f = NumberFormat('#,##,###.00');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
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
              _kpiBlock('Period Outflows', '\u20B9${f.format(totalExpenses)}', _accentOrange, headerFont, bodyFont),
              _kpiBlock('Stock Movements', '$inventoryMovementCount records', _darkBlue, headerFont, bodyFont),
              _kpiBlock('Active Subcontractors', '$subcontractorCount partners', _green, headerFont, bodyFont),
              _kpiBlock('Active Projects', '$projectCount sites', _darkBlue, headerFont, bodyFont),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: _primaryBlue, thickness: 0.3),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Budget: \u20B9${f.format(totalBudget)}', style: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: _grey600)),
              pw.Text('Total Spent: \u20B9${f.format(totalSpent)}', style: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: _grey600)),
              pw.Text('Overall Utilization: ${utilization.toStringAsFixed(1)}%', style: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: _grey600)),
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
        pw.Text(label, style: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: _grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: headerFont, fontSize: 10.5, color: color)),
      ],
    );
  }

  // ─── PROJECT DETAILS TABLE ─────────────────────────────────────────
  static pw.Widget _buildProjectDetailsTable(List<Project> projects, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      headers: ['Project Name', 'Client', 'Status', 'Progress', 'Budget (\u20B9)', 'Spent (\u20B9)', 'Remaining (\u20B9)'],
      data: projects.take(20).map((p) {
        final progressVal = (p.physicalProgress ?? (p.budget > 0 ? (p.spent / p.budget * 100) : 0.0)).clamp(0.0, 100.0);
        return [
          p.name,
          p.clientName ?? p.customerName ?? '-',
          p.status.toUpperCase(),
          '${progressVal.toStringAsFixed(0)}%',
          f.format(p.budget),
          f.format(p.spent),
          f.format(p.budget - p.spent),
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── DAILY PROGRESS TABLE ──────────────────────────────────────────
  static pw.Widget _buildDailyProgressTable(List<DailyProgress> progressList, List<Project> projects, pw.Font headerFont, pw.Font bodyFont) {
    final projectMap = {for (var p in projects) p.id: p.name};
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      headers: ['Date', 'Project Site', 'Physical Progress', 'Site Notes & Executed Work'],
      data: progressList.take(25).map((dp) {
        final pName = projectMap[dp.projectId] ?? 'Project Site';
        final notes = dp.allNotes.isNotEmpty ? dp.allNotes.join(' | ') : 'Operational activity recorded';
        return [
          dp.date,
          pName,
          '${dp.progressPercentage}% Completed',
          notes.length > 50 ? '${notes.substring(0, 50)}...' : notes,
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── INVENTORY MOVEMENTS TABLE (RECEIVED & ISSUED) ──────────────────
  static pw.Widget _buildInventoryMovementsTable(List<InventoryHistory> movements, pw.Font headerFont, pw.Font bodyFont) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      headers: ['Timestamp', 'Type', 'Quantity Change', 'Transaction / Delivery Details'],
      data: movements.take(30).map((m) {
        final isAdd = m.changeType == 'added';
        final typeLabel = isAdd ? 'RECEIVED' : (m.changeType == 'used' ? 'ISSUED' : m.changeType.toUpperCase());
        final sign = m.quantityChange > 0 ? '+${m.quantityChange.toStringAsFixed(1)}' : m.quantityChange.toStringAsFixed(1);
        final dateStr = (m.createdAt != null && m.createdAt!.length >= 16)
            ? m.createdAt!.substring(0, 16).replaceAll('T', ' ')
            : 'Today';
        return [
          dateStr,
          typeLabel,
          sign,
          m.notes ?? '-',
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── SUBCONTRACTORS TABLE ──────────────────────────────────────────
  static pw.Widget _buildSubcontractorsTable(List<Subcontractor> subcontractors, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      headers: ['Subcontractor / Firm', 'Specialization', 'Status', 'Contract (\u20B9)', 'Paid (\u20B9)', 'Balance (\u20B9)', 'Phone'],
      data: subcontractors.take(25).map((s) => [
        s.companyName,
        s.tradeSpecialization,
        s.status.toUpperCase(),
        f.format(s.contractValue),
        f.format(s.paidAmount),
        f.format(s.outstandingAmount),
        s.phone ?? '-',
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── EXPENSE TABLE ─────────────────────────────────────────────────
  static pw.Widget _buildExpenseTable(List<Expense> expenses, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      headers: ['Date', 'Category', 'Amount (\u20B9)', 'Payment Mode', 'Project Site', 'Notes'],
      data: expenses.take(35).map((e) => [
        e.expenseDate,
        e.category.toUpperCase(),
        f.format(e.amount),
        e.paymentMode.toUpperCase(),
        e.projectName ?? 'General',
        (e.notes ?? '-').length > 35 ? '${(e.notes ?? '-').substring(0, 35)}...' : (e.notes ?? '-'),
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── INVENTORY SUMMARY ROW ─────────────────────────────────────────
  static pw.Widget _buildInventorySummaryRow(double valuation, int lowStock, int totalItems, pw.Font bodyFont, pw.Font headerFont) {
    final f = NumberFormat('#,##,###.00');
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(color: _lightBlue, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total Stock Valuation: \u20B9${f.format(valuation)}', style: pw.TextStyle(font: headerFont, fontSize: 8.5, color: _darkBlue)),
          pw.Text('Total Items: $totalItems', style: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: _grey600)),
          pw.Text('Low Stock Alerts: $lowStock', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: lowStock > 0 ? _red : _green)),
        ],
      ),
    );
  }

  // ─── INVENTORY TABLE ───────────────────────────────────────────────
  static pw.Widget _buildInventoryTable(List<InventoryItem> items, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      headers: ['Material', 'Category', 'Stock', 'Unit', 'Price (\u20B9)', 'Valuation (\u20B9)', 'Status'],
      data: items.take(25).map((i) => [
        i.materialName,
        i.category,
        i.availableStock.toStringAsFixed(1),
        i.unit,
        f.format(i.purchasePrice),
        f.format(i.totalValuation),
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
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 7, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      headers: ['Date', 'Worker Name', 'Shift Status', 'Assigned Site'],
      data: records.take(30).map((a) => [
        a.date,
        a.employeeName ?? 'Worker',
        a.status.toUpperCase(),
        a.projectName ?? 'General Site',
      ]).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── REPORT CLOSURE ────────────────────────────────────────────────
  static pw.Widget _buildReportClosure(pw.Font headerFont, pw.Font bodyFont, pw.Font italicFont, String timestamp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _primaryBlue, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('END OF AUDIT REPORT', style: pw.TextStyle(font: headerFont, fontSize: 10, color: _darkBlue, letterSpacing: 2)),
          pw.SizedBox(height: 4),
          pw.Divider(color: _grey200, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Text(
            'This report was auto-generated by the IBUILD ERP Engine on $timestamp.',
            style: pw.TextStyle(font: italicFont, fontSize: 7, color: _grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'IBUILD | Confidential & Official Corporate Record',
            style: pw.TextStyle(font: headerFont, fontSize: 6.5, color: _darkBlue, letterSpacing: 0.5),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}
