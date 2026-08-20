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
import '../../employees/data/models/employee_model.dart';
import '../../subcontractors/data/models/subcontractor_model.dart';
import '../../daily_progress/data/models/daily_progress_model.dart';
import '../../payments/data/models/payment_ledger_model.dart';

/// Professional, highly detailed enterprise PDF report generator for IBUILD ERP.
///
/// Produces comprehensive daily, weekly, and monthly operational reports
/// with full financial breakdowns, muster rolls, stock movements, and trade disbursements.
class PdfReportGenerator {
  static const String _companyName = 'IBUild';
  static const PdfColor _primaryBlue = PdfColor.fromInt(0xFF1E40AF); // Vibrant Indigo
  static const PdfColor _darkBlue = PdfColor.fromInt(0xFF0F172A); // Slate Dark Navy
  static const PdfColor _lightBlue = PdfColor.fromInt(0xFFEFF6FF); // Soft Indigo Tint
  static const PdfColor _accentOrange = PdfColor.fromInt(0xFFD97706); // Amber Orange
  static const PdfColor _grey600 = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _grey200 = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _green = PdfColor.fromInt(0xFF059669); // Emerald
  static const PdfColor _red = PdfColor.fromInt(0xFFDC2626); // Error Red
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _rowBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _alertBg = PdfColor.fromInt(0xFFFEF2F2);

  /// Loads bundled Roboto TTF fonts that support Unicode glyphs (including ₹).
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

  /// Generates a comprehensive, highly detailed multi-page PDF report.
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
    List<Employee> employees = const [],
    List<PaymentLedgerEntry> payments = const [],
    List<String> attentionItems = const [],
    bool includeExpenses = true,
    bool includeInventory = true,
    bool includeInventoryMovements = true,
    bool includeSubcontractors = true,
    bool includeDailyProgress = true,
    bool includeAttendance = true,
    bool includePayments = true,
    String? selectedProjectId,
  }) async {
    final fonts = await _loadFonts();
    final headerFont = fonts['bold']!;
    final bodyFont = fonts['regular']!;
    final italicFont = fonts['italic']!;

    final pdf = pw.Document(
      title: 'IBUILD ERP - $reportType',
      author: _companyName,
      creator: 'IBUILD Construction ERP Reporting Engine',
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
        ? 'Enterprise Portfolio (All Sites)'
        : (filteredProjects.length == 1
            ? '${filteredProjects.first.name} (${filteredProjects.first.address ?? "Site"})'
            : '${filteredProjects.length} Selected Project Sites');

    // Aggregate financial data
    final double totalBudget = filteredProjects.fold(0.0, (sum, p) => sum + p.budget);
    final double totalSpent = filteredProjects.fold(0.0, (sum, p) => sum + p.spent);
    final double totalRemaining = totalBudget > totalSpent ? (totalBudget - totalSpent) : 0.0;
    final double utilization = totalBudget > 0 ? ((totalSpent / totalBudget) * 100).clamp(0.0, 100.0) : 0.0;
    final double avgPhysicalProgress = filteredProjects.isEmpty
        ? 0.0
        : (filteredProjects.fold(0.0, (s, p) => s + (p.physicalProgress ?? (p.budget > 0 ? (p.spent / p.budget * 100) : 0.0))) / filteredProjects.length).clamp(0.0, 100.0);

    // Filter expenses by project
    final filteredExpenses = expenses.where((e) {
      if (selectedProjectId == null || selectedProjectId == 'all') return true;
      return e.projectId == selectedProjectId;
    }).toList();
    final double totalExpensesAmount = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final double totalInventoryValuation = inventoryItems.fold(0.0, (sum, i) => sum + i.totalValuation);
    final int lowStockCount = inventoryItems.where((i) => i.isLowStock).length;

    // Filter payments
    final filteredPayments = payments.where((p) {
      if (selectedProjectId == null || selectedProjectId == 'all') return true;
      return p.projectId == selectedProjectId;
    }).toList();
    final double totalRevenueCollected = filteredPayments.fold(0.0, (s, p) => s + p.amount);

    // Build PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPageHeader(context, headerFont, bodyFont, dateFormatted, timeFormatted),
        footer: (context) => _buildPageFooter(context, bodyFont, italicFont, timestampFormatted),
        build: (context) => [
          _buildReportTitleBar(reportType, projectScopeName, dateFormatted, headerFont, bodyFont),
          pw.SizedBox(height: 12),

          // 1. Executive Performance & Financial Summary Dashboard
          _buildSectionTitle('Executive & Daily Performance Telemetry', headerFont),
          pw.SizedBox(height: 6),
          _buildFinancialSummaryTable(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalRemaining: totalRemaining,
            utilization: utilization,
            physicalProgress: avgPhysicalProgress,
            totalExpenses: totalExpensesAmount,
            expenseCount: filteredExpenses.length,
            projectCount: filteredProjects.length,
            inventoryMovementCount: inventoryMovements.length,
            subcontractorCount: subcontractors.length,
            revenueCollected: totalRevenueCollected,
            workersCount: attendanceRecords.length,
            headerFont: headerFont,
            bodyFont: bodyFont,
          ),
          pw.SizedBox(height: 12),

          // Action Items / Attention Required (if any)
          if (attentionItems.isNotEmpty) ...[
            _buildAttentionRequiredBox(attentionItems, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 2. Project Portfolio Status & Milestone Tracking
          if (filteredProjects.isNotEmpty) ...[
            _buildSectionTitle('1. Project Site Status, Budgets & Financial Utilization', headerFont),
            pw.SizedBox(height: 6),
            _buildProjectDetailsTable(filteredProjects, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 3. Site Daily Progress & Execution Notes
          if (includeDailyProgress && dailyProgressList.isNotEmpty) ...[
            _buildSectionTitle('2. Site Daily Progress & Structural Execution Notes', headerFont),
            pw.SizedBox(height: 6),
            _buildDailyProgressTable(dailyProgressList, filteredProjects, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 4. Logged Site Expenses with Category Breakdown
          if (includeExpenses && filteredExpenses.isNotEmpty) ...[
            _buildSectionTitle('3. Period Expenses & Financial Outflows', headerFont),
            pw.SizedBox(height: 6),
            _buildExpenseCategoryBreakdownTable(filteredExpenses, headerFont, bodyFont),
            pw.SizedBox(height: 6),
            _buildExpenseTable(filteredExpenses, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 5. Trade Partners & Subcontractor Disbursements
          if (includeSubcontractors && subcontractors.isNotEmpty) ...[
            _buildSectionTitle('4. Trade Partners & Subcontractor Contract Ledger', headerFont),
            pw.SizedBox(height: 6),
            _buildSubcontractorsTable(subcontractors, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 6. Material Inventory & Stock Movements
          if (includeInventoryMovements && inventoryMovements.isNotEmpty) ...[
            _buildSectionTitle('5. Material Stock Movements (Received GRN & Site Issued)', headerFont),
            pw.SizedBox(height: 6),
            _buildInventoryMovementsTable(inventoryMovements, inventoryItems, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 7. Material Inventory Valuation & Stock Health
          if (includeInventory && inventoryItems.isNotEmpty) ...[
            _buildSectionTitle('6. Material Inventory Valuation & Stock Health Audit', headerFont),
            pw.SizedBox(height: 6),
            _buildInventorySummaryRow(totalInventoryValuation, lowStockCount, inventoryItems.length, bodyFont, headerFont),
            pw.SizedBox(height: 6),
            _buildInventoryTable(inventoryItems, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 8. Worker Attendance & Daily Wage Muster Roll
          if (includeAttendance && attendanceRecords.isNotEmpty) ...[
            _buildSectionTitle('7. Labor Attendance, Shifts & Wage Muster Roll', headerFont),
            pw.SizedBox(height: 6),
            _buildAttendanceTable(attendanceRecords, employees, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          // 9. Client Payments & Revenue Inflows
          if (includePayments && filteredPayments.isNotEmpty) ...[
            _buildSectionTitle('8. Client Payments & Revenue Inflows Ledger', headerFont),
            pw.SizedBox(height: 6),
            _buildPaymentsTable(filteredPayments, headerFont, bodyFont),
            pw.SizedBox(height: 12),
          ],

          pw.SizedBox(height: 14),
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
      padding: const pw.EdgeInsets.only(bottom: 8),
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
              pw.Text('IBUILD', style: pw.TextStyle(font: headerFont, fontSize: 18, color: _primaryBlue, letterSpacing: 2)),
              pw.Text('CONSTRUCTION MANAGEMENT & OPERATIONS ERP', style: pw.TextStyle(font: headerFont, fontSize: 7, color: _grey600, letterSpacing: 1)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(date, style: pw.TextStyle(font: headerFont, fontSize: 9, color: _darkBlue)),
              pw.SizedBox(height: 1),
              pw.Text(time, style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _grey600)),
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
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _grey200, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CONFIDENTIAL • Official IBUILD ERP Audit Record', style: pw.TextStyle(font: italicFont, fontSize: 7, color: _grey600)),
          pw.Text('Generated: $timestamp  |  Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: bodyFont, fontSize: 7, color: _grey600)),
        ],
      ),
    );
  }

  // ─── REPORT TITLE BAR ──────────────────────────────────────────────
  static pw.Widget _buildReportTitleBar(String reportType, String projectScope, String dateFormatted, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(color: _darkBlue, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(reportType.toUpperCase(), style: pw.TextStyle(font: headerFont, fontSize: 12, color: _white, letterSpacing: 0.8)),
              pw.SizedBox(height: 3),
              pw.Text('Scope: $projectScope  |  Period: $dateFormatted', style: pw.TextStyle(font: bodyFont, fontSize: 8, color: PdfColor.fromInt(0xFF94A3B8))),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(color: _primaryBlue, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text('VERIFIED AUDIT', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _white, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }

  // ─── SECTION TITLE ─────────────────────────────────────────────────
  static pw.Widget _buildSectionTitle(String title, pw.Font headerFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primaryBlue, width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Container(width: 3.5, height: 12, color: _primaryBlue),
          pw.SizedBox(width: 6),
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: headerFont, fontSize: 9, color: _darkBlue, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // ─── FINANCIAL & OPERATIONAL SUMMARY ─────────────────────────────────
  static pw.Widget _buildFinancialSummaryTable({
    required double totalBudget, required double totalSpent, required double totalRemaining,
    required double utilization, required double physicalProgress,
    required double totalExpenses, required int expenseCount, required int projectCount,
    required int inventoryMovementCount, required int subcontractorCount,
    required double revenueCollected, required int workersCount,
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
              _kpiBlock('Client Inflows', '\u20B9${f.format(revenueCollected)}', _green, headerFont, bodyFont),
              _kpiBlock('Stock Movements', '$inventoryMovementCount records', _primaryBlue, headerFont, bodyFont),
              _kpiBlock('Worker Shifts', '$workersCount logged', _darkBlue, headerFont, bodyFont),
              _kpiBlock('Trade Partners', '$subcontractorCount active', _darkBlue, headerFont, bodyFont),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: _grey200, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Budget: \u20B9${f.format(totalBudget)}', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _darkBlue)),
              pw.Text('Total Spent: \u20B9${f.format(totalSpent)}', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _darkBlue)),
              pw.Text('Balance: \u20B9${f.format(totalRemaining)}', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _green)),
              pw.Text('Financial Utilization: ${utilization.toStringAsFixed(1)}%', style: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: _grey600)),
              pw.Text('Physical Progress: ${physicalProgress.toStringAsFixed(1)}%', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _primaryBlue)),
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
        pw.Text(value, style: pw.TextStyle(font: headerFont, fontSize: 9.5, color: color)),
      ],
    );
  }

  // ─── ATTENTION REQUIRED BOX ─────────────────────────────────────────
  static pw.Widget _buildAttentionRequiredBox(List<String> items, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _alertBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _red, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: pw.BoxDecoration(color: _red, borderRadius: pw.BorderRadius.circular(2)),
                child: pw.Text('ACTION REQUIRED', style: pw.TextStyle(font: headerFont, fontSize: 6.5, color: _white)),
              ),
              pw.SizedBox(width: 6),
              pw.Text('${items.length} Operational Risk & Threshold Items Identified', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: _red)),
            ],
          ),
          pw.SizedBox(height: 4),
          ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(font: headerFont, fontSize: 7, color: _red)),
                    pw.Expanded(
                      child: pw.Text(item, style: pw.TextStyle(font: bodyFont, fontSize: 7, color: _darkBlue)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── PROJECT DETAILS TABLE ─────────────────────────────────────────
  static pw.Widget _buildProjectDetailsTable(List<Project> projects, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    final double sumBudget = projects.fold(0.0, (s, p) => s + p.budget);
    final double sumSpent = projects.fold(0.0, (s, p) => s + p.spent);
    final double sumRemaining = sumBudget > sumSpent ? (sumBudget - sumSpent) : 0.0;

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Project Name', 'Client', 'Location / Site', 'Status', 'Progress', 'Budget (\u20B9)', 'Spent (\u20B9)', 'Balance (\u20B9)'],
      data: [
        ...projects.map((p) {
          final progressVal = (p.physicalProgress ?? (p.budget > 0 ? (p.spent / p.budget * 100) : 0.0)).clamp(0.0, 100.0);
          return [
            p.name,
            p.clientName ?? p.customerName ?? '-',
            p.address ?? '-',
            p.status.toUpperCase(),
            '${progressVal.toStringAsFixed(0)}%',
            f.format(p.budget),
            f.format(p.spent),
            f.format(p.budget - p.spent),
          ];
        }),
        [
          'PORTFOLIO TOTAL',
          '',
          '',
          '${projects.length} Sites',
          '',
          f.format(sumBudget),
          f.format(sumSpent),
          f.format(sumRemaining),
        ],
      ],
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
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Date', 'Project Site', 'Physical Progress', 'Site Notes & Executed Work Details'],
      data: progressList.map((dp) {
        final pName = projectMap[dp.projectId] ?? 'Project Site';
        final notes = dp.allNotes.isNotEmpty ? dp.allNotes.join(' | ') : 'Operational progress recorded';
        return [
          dp.date,
          pName,
          '${dp.progressPercentage}% Completed',
          notes,
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── EXPENSE CATEGORY BREAKDOWN TABLE ───────────────────────────────
  static pw.Widget _buildExpenseCategoryBreakdownTable(List<Expense> expenses, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    final Map<String, List<Expense>> byCat = {};
    for (final e in expenses) {
      final c = e.category.isEmpty ? 'Other' : e.category;
      byCat.putIfAbsent(c, () => []).add(e);
    }

    final double totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _primaryBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 6.5, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      headers: ['Expense Category', 'Vouchers Logged', 'Subtotal (\u20B9)', '% of Period Spend'],
      data: byCat.entries.map((entry) {
        final subtotal = entry.value.fold(0.0, (s, e) => s + e.amount);
        final pct = totalExpenses > 0 ? (subtotal / totalExpenses * 100) : 0.0;
        return [
          entry.key.toUpperCase(),
          '${entry.value.length} vouchers',
          f.format(subtotal),
          '${pct.toStringAsFixed(1)}%',
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── EXPENSE TABLE ─────────────────────────────────────────────────
  static pw.Widget _buildExpenseTable(List<Expense> expenses, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    final double totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Date', 'Category', 'Payment Mode', 'Project Site', 'Amount (\u20B9)', 'Voucher ID / Notes'],
      data: [
        ...expenses.map((e) => [
              e.expenseDate,
              e.category.toUpperCase(),
              e.paymentMode.toUpperCase(),
              e.projectName ?? 'General Site',
              f.format(e.amount),
              '${e.shortId}${e.notes != null && e.notes!.isNotEmpty ? " • ${e.notes}" : ""}',
            ]),
        [
          'TOTAL OUTFLOWS',
          '',
          '',
          '${expenses.length} Vouchers',
          f.format(totalExpenses),
          '',
        ],
      ],
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── SUBCONTRACTORS TABLE ──────────────────────────────────────────
  static pw.Widget _buildSubcontractorsTable(List<Subcontractor> subcontractors, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    final double sumContract = subcontractors.fold(0.0, (s, sub) => s + sub.contractValue);
    final double sumPaid = subcontractors.fold(0.0, (s, sub) => s + sub.paidAmount);
    final double sumBalance = subcontractors.fold(0.0, (s, sub) => s + sub.outstandingAmount);

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Trade Partner / Firm', 'Specialization', 'Contact Person', 'Assigned Site', 'Contract (\u20B9)', 'Paid (\u20B9)', 'Retention Due (\u20B9)', 'Status'],
      data: [
        ...subcontractors.map((s) => [
              s.companyName,
              s.tradeSpecialization,
              '${s.contactPerson} (${s.phone ?? "-"})',
              s.siteName,
              f.format(s.contractValue),
              f.format(s.paidAmount),
              f.format(s.outstandingAmount),
              s.status.toUpperCase(),
            ]),
        [
          'TOTAL TRADE DISBURSEMENTS',
          '',
          '',
          '${subcontractors.length} Partners',
          f.format(sumContract),
          f.format(sumPaid),
          f.format(sumBalance),
          '',
        ],
      ],
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── INVENTORY MOVEMENTS TABLE (RECEIVED & ISSUED) ──────────────────
  static pw.Widget _buildInventoryMovementsTable(List<InventoryHistory> movements, List<InventoryItem> items, pw.Font headerFont, pw.Font bodyFont) {
    final itemMap = {for (final item in items) item.id: item};
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Timestamp', 'Material Name', 'Type', 'Qty Change', 'Unit', 'Transaction / Delivery Details'],
      data: movements.map((m) {
        final item = itemMap[m.inventoryId];
        final isAdd = m.changeType == 'added';
        final typeLabel = isAdd ? 'RECEIVED (GRN)' : (m.changeType == 'used' ? 'ISSUED (Site)' : m.changeType.toUpperCase());
        final sign = m.quantityChange > 0 ? '+${m.quantityChange.toStringAsFixed(1)}' : m.quantityChange.toStringAsFixed(1);
        final dateStr = (m.createdAt != null && m.createdAt!.length >= 16)
            ? m.createdAt!.substring(0, 16).replaceAll('T', ' ')
            : 'Today';
        return [
          dateStr,
          item?.materialName ?? 'Material Item',
          typeLabel,
          sign,
          item?.unit ?? 'Units',
          m.notes ?? '-',
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── INVENTORY SUMMARY ROW ─────────────────────────────────────────
  static pw.Widget _buildInventorySummaryRow(double valuation, int lowStock, int totalItems, pw.Font bodyFont, pw.Font headerFont) {
    final f = NumberFormat('#,##,###.00');
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(color: _lightBlue, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total Inventory Valuation: \u20B9${f.format(valuation)}', style: pw.TextStyle(font: headerFont, fontSize: 8, color: _darkBlue)),
          pw.Text('Active SKUs: $totalItems', style: pw.TextStyle(font: bodyFont, fontSize: 7.5, color: _grey600)),
          pw.Text('Low Stock Alerts: $lowStock', style: pw.TextStyle(font: headerFont, fontSize: 7.5, color: lowStock > 0 ? _red : _green)),
        ],
      ),
    );
  }

  // ─── INVENTORY TABLE ───────────────────────────────────────────────
  static pw.Widget _buildInventoryTable(List<InventoryItem> items, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    final double totalVal = items.fold(0.0, (s, i) => s + i.totalValuation);

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Material Name', 'Category', 'Available Stock', 'Min Threshold', 'Unit Rate (\u20B9)', 'Total Valuation (\u20B9)', 'Stock Health'],
      data: [
        ...items.map((i) => [
              i.materialName,
              i.category,
              '${i.availableStock.toStringAsFixed(1)} ${i.unit}',
              '${i.minimumStock.toStringAsFixed(1)} ${i.unit}',
              f.format(i.purchasePrice),
              f.format(i.totalValuation),
              i.isLowStock ? 'LOW STOCK' : 'Healthy',
            ]),
        [
          'TOTAL VALUATION',
          '',
          '',
          '',
          '${items.length} SKUs',
          f.format(totalVal),
          '',
        ],
      ],
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── ATTENDANCE TABLE ──────────────────────────────────────────────
  static pw.Widget _buildAttendanceTable(List<Attendance> records, List<Employee> employees, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    final empMap = {for (final e in employees) e.id: e};

    double sumWages = 0.0;
    double sumTea = 0.0;
    double sumNet = 0.0;

    for (final a in records) {
      final emp = empMap[a.employeeId];
      final isPresent = a.status.toLowerCase() == 'present';
      final isHalfDay = a.status.toLowerCase() == 'half_day' || a.status.toLowerCase() == 'half day';
      final wage = emp != null ? (isPresent ? emp.salary : (isHalfDay ? emp.salary / 2.0 : 0.0)) : 0.0;
      final tea = (emp != null && (isPresent || isHalfDay)) ? emp.teaSnackAllowance : 0.0;
      sumWages += wage;
      sumTea += tea;
      sumNet += (wage + tea);
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Date', 'Worker Name', 'Role / Trade', 'Shift Status', 'Daily Wage (\u20B9)', 'Tea Allowance (\u20B9)', 'Net Payable (\u20B9)', 'Site'],
      data: [
        ...records.map((a) {
          final emp = empMap[a.employeeId];
          final isPresent = a.status.toLowerCase() == 'present';
          final isHalfDay = a.status.toLowerCase() == 'half_day' || a.status.toLowerCase() == 'half day';
          final wage = emp != null ? (isPresent ? emp.salary : (isHalfDay ? emp.salary / 2.0 : 0.0)) : 0.0;
          final tea = (emp != null && (isPresent || isHalfDay)) ? emp.teaSnackAllowance : 0.0;
          final net = wage + tea;

          return [
            a.date,
            a.employeeName ?? emp?.name ?? 'Worker',
            emp?.role ?? 'Site Staff',
            a.status.toUpperCase(),
            f.format(wage),
            f.format(tea),
            f.format(net),
            a.projectName ?? 'General Site',
          ];
        }),
        [
          'TOTAL MUSTER ROLL',
          '',
          '',
          '${records.length} Shifts',
          f.format(sumWages),
          f.format(sumTea),
          f.format(sumNet),
          '',
        ],
      ],
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── PAYMENTS TABLE ────────────────────────────────────────────────
  static pw.Widget _buildPaymentsTable(List<PaymentLedgerEntry> payments, pw.Font headerFont, pw.Font bodyFont) {
    final f = NumberFormat('#,##,###.00');
    final double totalRevenue = payments.fold(0.0, (s, p) => s + p.amount);

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: _darkBlue),
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 7, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 6.5, color: PdfColors.black),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headers: ['Payment Date', 'Party / Counterparty', 'Type', 'Payment Method', 'Amount (\u20B9)', 'Remarks'],
      data: [
        ...payments.map((p) => [
              DateFormat('yyyy-MM-dd').format(p.paymentDate),
              p.counterpartyName,
              p.counterpartyType,
              p.paymentMethod.toUpperCase(),
              f.format(p.amount),
              p.remarks ?? '-',
            ]),
        [
          'TOTAL REVENUE INFLOWS',
          '',
          '',
          '${payments.length} Payments',
          f.format(totalRevenue),
          '',
        ],
      ],
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
    );
  }

  // ─── REPORT CLOSURE ────────────────────────────────────────────────
  static pw.Widget _buildReportClosure(pw.Font headerFont, pw.Font bodyFont, pw.Font italicFont, String timestamp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _primaryBlue, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('END OF AUDIT REPORT', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _primaryBlue, letterSpacing: 2)),
          pw.SizedBox(height: 3),
          pw.Divider(color: _grey200, thickness: 0.5),
          pw.SizedBox(height: 3),
          pw.Text(
            'This official audit report was compiled and verified by the IBUILD Construction ERP engine on $timestamp.',
            style: pw.TextStyle(font: italicFont, fontSize: 6.5, color: _grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'IBUILD • Enterprise Construction Management Platform',
            style: pw.TextStyle(font: headerFont, fontSize: 6, color: _darkBlue, letterSpacing: 0.5),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

