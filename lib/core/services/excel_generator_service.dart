import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../features/attendance/data/models/attendance_model.dart';
import '../../features/employees/data/models/employee_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/inventory/data/models/inventory_history_model.dart';
import '../../features/inventory/data/models/inventory_item_model.dart';
import '../../features/payments/data/models/payment_ledger_model.dart';
import '../../features/projects/data/models/project_model.dart';
import '../../features/subcontractors/data/models/subcontractor_model.dart';

/// Data bundle for building a consolidated, authoritative IBUILD ERP Excel Report
class ConsolidatedReportData {
  final Project? project; // Specific project context or null for portfolio-wide
  final String projectName;
  final String siteName;
  final String clientName;
  final String periodTitle; // e.g. "Monthly Report • August 2026"
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;

  // Key Financial Metrics (Authoritative from Supabase/Riverpod state)
  final double totalBudget;
  final double totalSpent;
  final double remainingBalance;
  final double budgetUtilization;
  final double physicalProgress;
  final String projectStatus;

  // Attention Items (Real actionable issues only)
  final List<String> attentionItems;

  // Domain Datasets (Filtered to authorized scope and date range)
  final List<Attendance> attendanceRecords;
  final List<Employee> employees;
  final List<InventoryHistory> inventoryHistory;
  final List<InventoryItem> inventoryItems;
  final List<Subcontractor> subcontractors;
  final List<Expense> expenses;
  final List<PaymentLedgerEntry> payments;

  ConsolidatedReportData({
    this.project,
    required this.projectName,
    required this.siteName,
    required this.clientName,
    required this.periodTitle,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.totalBudget,
    required this.totalSpent,
    required this.remainingBalance,
    required this.budgetUtilization,
    required this.physicalProgress,
    required this.projectStatus,
    this.attentionItems = const [],
    this.attendanceRecords = const [],
    this.employees = const [],
    this.inventoryHistory = const [],
    this.inventoryItems = const [],
    this.subcontractors = const [],
    this.expenses = const [],
    this.payments = const [],
  });
}

/// Service for generating minimal, professional, construction-ERP-oriented Excel (.xlsx) workbooks.
class ExcelGeneratorService {
  // ── Theme Palettes & Styles ──
  static final CellStyle reportTitleStyle = CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'), // Deep IBUILD Blue
    horizontalAlign: HorizontalAlign.Center,
  );

  static final CellStyle reportSubTitleStyle = CellStyle(
    bold: true,
    fontSize: 12,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#2563EB'), // Primary IBUILD Blue
    horizontalAlign: HorizontalAlign.Center,
  );

  static final CellStyle sectionHeaderStyle = CellStyle(
    bold: true,
    fontSize: 11,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#1F2937'), // Slate Gray
  );

  static final CellStyle sectionAlertHeaderStyle = CellStyle(
    bold: true,
    fontSize: 11,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#DC2626'), // Action Red
  );

  static final CellStyle tableHeaderStyle = CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('#374151'), // Cool Gray Header
    horizontalAlign: HorizontalAlign.Left,
  );

  static final CellStyle metaLabelStyle = CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#111827'),
    backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
  );

  static final CellStyle metaValueStyle = CellStyle(
    bold: false,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#1F2937'),
  );

  static final CellStyle dataRowRegularStyle = CellStyle(
    bold: false,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#111827'),
  );

  static final CellStyle dataRowAltStyle = CellStyle(
    bold: false,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#111827'),
    backgroundColorHex: ExcelColor.fromHexString('#F9FAFB'), // Light alternate row
  );

  static final CellStyle summaryRowStyle = CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
    backgroundColorHex: ExcelColor.fromHexString('#E5E7EB'), // Highlighted summary
  );

  static final CellStyle positiveNoticeStyle = CellStyle(
    bold: false,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#166534'),
    backgroundColorHex: ExcelColor.fromHexString('#F0FDF4'),
  );

  static final CellStyle alertNoticeStyle = CellStyle(
    bold: false,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#991B1B'),
    backgroundColorHex: ExcelColor.fromHexString('#FEF2F2'),
  );

  /// Helper to convert raw dynamic values into Excel numeric or text cell types.
  static CellValue toCellValue(dynamic val) {
    if (val == null) return TextCellValue('');
    if (val is int) return IntCellValue(val);
    if (val is double) return DoubleCellValue(double.parse(val.toStringAsFixed(2)));
    if (val is num) return DoubleCellValue(double.parse(val.toDouble().toStringAsFixed(2)));
    if (val is bool) return TextCellValue(val ? 'Yes' : 'No');
    if (val is DateTime) return TextCellValue(DateFormat('dd-MM-yyyy').format(val));
    return TextCellValue(val.toString());
  }

  /// Calculates and applies sensible column widths based on cell content length.
  static void _autoFitColumns(Sheet sheet, int maxCols, {int minWidth = 12, int maxWidth = 45}) {
    for (int col = 0; col < maxCols; col++) {
      int maxLen = minWidth;
      for (int row = 0; row < sheet.maxRows; row++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        final val = cell.value;
        if (val != null) {
          final strLen = val.toString().length;
          if (strLen > maxLen) {
            maxLen = strLen;
          }
        }
      }
      final double finalWidth = maxLen.clamp(minWidth, maxWidth).toDouble() + 3.0;
      sheet.setColumnWidth(col, finalWidth);
    }
  }

  // ===========================================================================
  // 1. CONSOLIDATED MULTI-SHEET PROJECT REPORT
  // ===========================================================================

  /// Generates a complete, multi-sheet, consolidated ERP project report workbook.
  static Uint8List generateConsolidatedReportExcel(ConsolidatedReportData data) {
    final excel = Excel.createExcel();

    // ── SHEET 1: Executive Summary ──
    _buildExecutiveSummarySheet(excel, data);

    // ── SHEET 2: Attendance (if data exists or with clean placeholder) ──
    _buildAttendanceSheet(excel, data);

    // ── SHEET 3: Materials & Inventory Movements ──
    _buildMaterialsSheet(excel, data);

    // ── SHEET 4: Subcontractors & Trade Partners ──
    _buildSubcontractorsSheet(excel, data);

    // ── SHEET 5: Direct Site Expenses ──
    _buildExpensesSheet(excel, data);

    // ── SHEET 6: Payment Ledger ──
    _buildPaymentsSheet(excel, data);

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  // ---------------------------------------------------------------------------
  // SHEET 1: Executive Summary
  // ---------------------------------------------------------------------------
  static void _buildExecutiveSummarySheet(Excel excel, ConsolidatedReportData data) {
    const sheetName = 'Executive Summary';
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    final dateFmt = DateFormat('dd-MM-yyyy');
    final timeFmt = DateFormat('dd-MM-yyyy hh:mm a');

    // Title Row
    sheet.appendRow([TextCellValue('IBUILD ERP — CONSTRUCTION MANAGEMENT')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

    // Subtitle Row
    sheet.appendRow([TextCellValue('PROJECT / SITE CONSOLIDATED REPORT')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = reportSubTitleStyle;

    // Spacer
    sheet.appendRow([]);

    // Report Metadata Table
    final metaRows = [
      ['Project:', data.projectName, 'Report Period:', '${dateFmt.format(data.startDate)} to ${dateFmt.format(data.endDate)}'],
      ['Site / Location:', data.siteName, 'Report Scope:', data.periodTitle],
      ['Client:', data.clientName, 'Generated On:', timeFmt.format(data.generatedAt)],
    ];

    for (final mRow in metaRows) {
      sheet.appendRow([
        TextCellValue(mRow[0]),
        TextCellValue(mRow[1]),
        TextCellValue(mRow[2]),
        TextCellValue(mRow[3]),
      ]);
      final rowIdx = sheet.maxRows - 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = metaLabelStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).cellStyle = metaValueStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).cellStyle = metaLabelStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).cellStyle = metaValueStyle;
    }

    // Spacer
    sheet.appendRow([]);

    // ── SECTION: Key Financial Figures ──
    sheet.appendRow([TextCellValue('KEY FINANCIAL FIGURES')]);
    final finHeaderRow = sheet.maxRows - 1;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: finHeaderRow),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: finHeaderRow),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: finHeaderRow)).cellStyle = sectionHeaderStyle;

    // Financial Table Headers
    sheet.appendRow([
      TextCellValue('Metric Description'),
      TextCellValue('Authoritative Value (INR / %)'),
      TextCellValue('Unit'),
      TextCellValue('Accounting Notes'),
    ]);
    final finColsRow = sheet.maxRows - 1;
    for (int col = 0; col < 4; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: finColsRow)).cellStyle = tableHeaderStyle;
    }

    // Financial Data Rows
    final finData = [
      ['Total Allocated Budget', data.totalBudget, 'INR', 'Approved contractual cost baseline'],
      ['Total Cumulative Spend', data.totalSpent, 'INR', 'Vendor bills, site costs & disbursements'],
      ['Remaining Project Balance', data.remainingBalance, 'INR', 'Allocated Budget - Cumulative Spend'],
      ['Budget Utilization', data.budgetUtilization, '%', 'Calculated: (Spent / Budget) * 100'],
      ['Physical Site Progress', data.physicalProgress, '%', 'Engineered site milestone completion'],
      ['Current Project Status', data.projectStatus.toUpperCase(), '-', 'Operational status from Supabase'],
    ];

    for (int i = 0; i < finData.length; i++) {
      final item = finData[i];
      sheet.appendRow([
        TextCellValue(item[0].toString()),
        toCellValue(item[1]),
        TextCellValue(item[2].toString()),
        TextCellValue(item[3].toString()),
      ]);
      final rowIdx = sheet.maxRows - 1;
      final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
      for (int col = 0; col < 4; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
      }
    }

    // Spacer
    sheet.appendRow([]);

    // ── SECTION: Operational Summary ──
    sheet.appendRow([TextCellValue('OPERATIONAL SUMMARY')]);
    final opHeaderRow = sheet.maxRows - 1;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: opHeaderRow),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: opHeaderRow),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: opHeaderRow)).cellStyle = sectionHeaderStyle;

    // Operational Table Headers
    sheet.appendRow([
      TextCellValue('Operational Domain'),
      TextCellValue('Logged Quantity / Count'),
      TextCellValue('Financial Incurred (INR)'),
      TextCellValue('Operational Status'),
    ]);
    final opColsRow = sheet.maxRows - 1;
    for (int col = 0; col < 4; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: opColsRow)).cellStyle = tableHeaderStyle;
    }

    final double totalExpensesAmt = data.expenses.fold(0.0, (s, e) => s + e.amount);
    final double totalPaymentsAmt = data.payments.fold(0.0, (s, p) => s + p.amount);

    final opData = [
      ['Worker Attendance & Shifts', data.attendanceRecords.length, '-', '${data.attendanceRecords.length} shifts recorded'],
      ['Material Dispatches & Movements', data.inventoryHistory.length, '-', '${data.inventoryHistory.length} transaction entries'],
      ['Subcontractors & Trade Partners', data.subcontractors.length, '-', '${data.subcontractors.length} active partners'],
      ['Direct Operational Expenses', data.expenses.length, totalExpensesAmt, 'Vouchers logged in period'],
      ['Payment Ledger Transactions', data.payments.length, totalPaymentsAmt, 'Inflows & Outflows recorded'],
    ];

    for (int i = 0; i < opData.length; i++) {
      final item = opData[i];
      sheet.appendRow([
        TextCellValue(item[0].toString()),
        toCellValue(item[1]),
        toCellValue(item[2]),
        TextCellValue(item[3].toString()),
      ]);
      final rowIdx = sheet.maxRows - 1;
      final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
      for (int col = 0; col < 4; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
      }
    }

    // Spacer
    sheet.appendRow([]);

    // ── SECTION: Attention Required & Action Items ──
    final hasAlerts = data.attentionItems.isNotEmpty;
    sheet.appendRow([TextCellValue('ATTENTION REQUIRED & ACTION ITEMS')]);
    final alertHeaderRow = sheet.maxRows - 1;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: alertHeaderRow),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: alertHeaderRow),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: alertHeaderRow)).cellStyle =
        hasAlerts ? sectionAlertHeaderStyle : sectionHeaderStyle;

    if (hasAlerts) {
      sheet.appendRow([
        TextCellValue('#'),
        TextCellValue('Identified Action Item / Threshold'),
        TextCellValue('Category'),
        TextCellValue('Status'),
      ]);
      final alertColsRow = sheet.maxRows - 1;
      for (int col = 0; col < 4; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: alertColsRow)).cellStyle = tableHeaderStyle;
      }

      for (int i = 0; i < data.attentionItems.length; i++) {
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(data.attentionItems[i]),
          TextCellValue('Action Required'),
          TextCellValue('OPEN'),
        ]);
        final rowIdx = sheet.maxRows - 1;
        for (int col = 0; col < 4; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = alertNoticeStyle;
        }
      }
    } else {
      sheet.appendRow([
        TextCellValue('Status:'),
        TextCellValue('All tracked operations, inventory thresholds, and budgets are currently operating normally.'),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final rowIdx = sheet.maxRows - 1;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx),
      );
      for (int col = 0; col < 4; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = positiveNoticeStyle;
      }
    }

    _autoFitColumns(sheet, 4, minWidth: 16, maxWidth: 50);
  }

  // ---------------------------------------------------------------------------
  // SHEET 2: Attendance
  // ---------------------------------------------------------------------------
  static void _buildAttendanceSheet(Excel excel, ConsolidatedReportData data) {
    const sheetName = 'Attendance';
    final sheet = excel[sheetName];

    sheet.appendRow([TextCellValue('IBUILD ERP — ATTENDANCE & MUSTER ROLL')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

    sheet.appendRow([TextCellValue('Period: ${DateFormat('dd-MM-yyyy').format(data.startDate)} to ${DateFormat('dd-MM-yyyy').format(data.endDate)} | Project: ${data.projectName}')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 1),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = reportSubTitleStyle;

    sheet.appendRow([]);

    final headers = [
      'Date',
      'Employee ID',
      'Employee Name',
      'Role / Designation',
      'Assigned Site',
      'Attendance Status',
      'Check In',
      'Check Out',
      'Work Hours',
      'Daily Wage (INR)',
      'Tea Allowance (INR)',
      'Total Payable (INR)',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    const headerRowIdx = 3;
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = tableHeaderStyle;
    }

    if (data.attendanceRecords.isEmpty) {
      sheet.appendRow([
        TextCellValue('No attendance records available for this period.'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final rowIdx = sheet.maxRows - 1;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIdx),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = positiveNoticeStyle;
    } else {
      // Map employees for quick wage/allowance lookups
      final empMap = {for (final e in data.employees) e.id: e};

      double sumHours = 0.0;
      double sumWages = 0.0;
      double sumAllowances = 0.0;
      double sumPayable = 0.0;

      for (int i = 0; i < data.attendanceRecords.length; i++) {
        final a = data.attendanceRecords[i];
        final emp = empMap[a.employeeId];
        final isPresent = a.status.toLowerCase() == 'present';
        final isHalfDay = a.status.toLowerCase() == 'half_day' || a.status.toLowerCase() == 'half day';

        final double hours = isPresent ? 8.0 : (isHalfDay ? 4.0 : 0.0);
        final double wage = emp != null ? (isPresent ? emp.salary : (isHalfDay ? emp.salary / 2.0 : 0.0)) : 0.0;
        final double tea = (emp != null && (isPresent || isHalfDay)) ? emp.teaSnackAllowance : 0.0;
        final double payable = wage + tea;

        sumHours += hours;
        sumWages += wage;
        sumAllowances += tea;
        sumPayable += payable;

        sheet.appendRow([
          TextCellValue(a.date),
          TextCellValue(emp?.shortId ?? (a.employeeId.length > 8 ? a.employeeId.substring(0, 8) : a.employeeId)),
          TextCellValue(a.employeeName ?? emp?.name ?? 'Worker'),
          TextCellValue(emp?.role ?? 'Site Staff'),
          TextCellValue(a.projectName ?? data.projectName),
          TextCellValue(a.status.toUpperCase()),
          TextCellValue(isPresent ? '08:00 AM' : '-'),
          TextCellValue(isPresent ? '05:00 PM' : '-'),
          DoubleCellValue(hours),
          DoubleCellValue(wage),
          DoubleCellValue(tea),
          DoubleCellValue(payable),
        ]);

        final rowIdx = sheet.maxRows - 1;
        final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
        for (int col = 0; col < headers.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
        }
      }

      // Summary Row
      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue(''),
        TextCellValue('${data.attendanceRecords.length} Shifts'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(sumHours),
        DoubleCellValue(sumWages),
        DoubleCellValue(sumAllowances),
        DoubleCellValue(sumPayable),
      ]);
      final sumRowIdx = sheet.maxRows - 1;
      for (int col = 0; col < headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sumRowIdx)).cellStyle = summaryRowStyle;
      }
    }

    _autoFitColumns(sheet, headers.length, minWidth: 12, maxWidth: 35);
  }

  // ---------------------------------------------------------------------------
  // SHEET 3: Materials & Inventory Movements
  // ---------------------------------------------------------------------------
  static void _buildMaterialsSheet(Excel excel, ConsolidatedReportData data) {
    const sheetName = 'Materials';
    final sheet = excel[sheetName];

    sheet.appendRow([TextCellValue('IBUILD ERP — MATERIALS & INVENTORY MOVEMENTS')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

    sheet.appendRow([TextCellValue('Project: ${data.projectName} | Site: ${data.siteName}')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 1),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = reportSubTitleStyle;

    sheet.appendRow([]);

    final headers = [
      'Date / Timestamp',
      'Material Name',
      'Category',
      'Transaction Type',
      'Quantity Change',
      'Unit of Measure',
      'Unit Rate (INR)',
      'Estimated Value (INR)',
      'Project / Site',
      'Reference / Notes',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    const headerRowIdx = 3;
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = tableHeaderStyle;
    }

    if (data.inventoryHistory.isEmpty) {
      sheet.appendRow([
        TextCellValue('No material transactions available for this period.'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final rowIdx = sheet.maxRows - 1;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = positiveNoticeStyle;
    } else {
      final itemMap = {for (final item in data.inventoryItems) item.id: item};
      double sumQty = 0.0;
      double sumValue = 0.0;

      for (int i = 0; i < data.inventoryHistory.length; i++) {
        final h = data.inventoryHistory[i];
        final item = itemMap[h.inventoryId];
        final unitPrice = item?.purchasePrice ?? 0.0;
        final totalCost = unitPrice * h.quantityChange.abs();

        sumQty += h.quantityChange;
        sumValue += totalCost;

        String txType = h.changeType.toUpperCase();
        if (h.changeType == 'added') txType = 'RECEIVED';
        if (h.changeType == 'used') txType = 'ISSUED';
        if (h.changeType == 'adjusted') txType = 'ADJUSTED';

        sheet.appendRow([
          TextCellValue(h.createdAt ?? DateFormat('dd-MM-yyyy').format(data.startDate)),
          TextCellValue(item?.materialName ?? 'Material Item'),
          TextCellValue(item?.category ?? 'General'),
          TextCellValue(txType),
          DoubleCellValue(h.quantityChange),
          TextCellValue(item?.unit ?? 'Units'),
          DoubleCellValue(unitPrice),
          DoubleCellValue(totalCost),
          TextCellValue(data.projectName),
          TextCellValue(h.notes ?? '-'),
        ]);

        final rowIdx = sheet.maxRows - 1;
        final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
        for (int col = 0; col < headers.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
        }
      }

      // Summary Row
      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('${data.inventoryHistory.length} Transactions'),
        DoubleCellValue(sumQty),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(sumValue),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final sumRowIdx = sheet.maxRows - 1;
      for (int col = 0; col < headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sumRowIdx)).cellStyle = summaryRowStyle;
      }
    }

    _autoFitColumns(sheet, headers.length, minWidth: 12, maxWidth: 40);
  }

  // ---------------------------------------------------------------------------
  // SHEET 4: Subcontractors & Trade Partners
  // ---------------------------------------------------------------------------
  static void _buildSubcontractorsSheet(Excel excel, ConsolidatedReportData data) {
    const sheetName = 'Subcontractors';
    final sheet = excel[sheetName];

    sheet.appendRow([TextCellValue('IBUILD ERP — SUBCONTRACTORS & TRADE PARTNERS')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

    sheet.appendRow([TextCellValue('Project: ${data.projectName} | Site: ${data.siteName}')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 1),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = reportSubTitleStyle;

    sheet.appendRow([]);

    final headers = [
      'Registration Date',
      'Trade Partner / Company',
      'Trade Specialization',
      'Contact Person',
      'Phone Number',
      'Assigned Site',
      'Contract Value (INR)',
      'Paid Amount (INR)',
      'Outstanding / Retention (INR)',
      'Status',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    const headerRowIdx = 3;
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = tableHeaderStyle;
    }

    if (data.subcontractors.isEmpty) {
      sheet.appendRow([
        TextCellValue('No subcontractor records available for this period.'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final rowIdx = sheet.maxRows - 1;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = positiveNoticeStyle;
    } else {
      double sumContract = 0.0;
      double sumPaid = 0.0;
      double sumRetention = 0.0;

      for (int i = 0; i < data.subcontractors.length; i++) {
        final s = data.subcontractors[i];
        sumContract += s.contractValue;
        sumPaid += s.paidAmount;
        sumRetention += s.outstandingAmount;

        sheet.appendRow([
          TextCellValue(DateFormat('dd-MM-yyyy').format(s.createdAt)),
          TextCellValue(s.companyName),
          TextCellValue(s.tradeSpecialization),
          TextCellValue(s.contactPerson),
          TextCellValue(s.phone ?? '-'),
          TextCellValue(s.siteName),
          DoubleCellValue(s.contractValue),
          DoubleCellValue(s.paidAmount),
          DoubleCellValue(s.outstandingAmount),
          TextCellValue(s.status.toUpperCase()),
        ]);

        final rowIdx = sheet.maxRows - 1;
        final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
        for (int col = 0; col < headers.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
        }
      }

      // Summary Row
      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue(''),
        TextCellValue('${data.subcontractors.length} Contractors'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(sumContract),
        DoubleCellValue(sumPaid),
        DoubleCellValue(sumRetention),
        TextCellValue(''),
      ]);
      final sumRowIdx = sheet.maxRows - 1;
      for (int col = 0; col < headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sumRowIdx)).cellStyle = summaryRowStyle;
      }
    }

    _autoFitColumns(sheet, headers.length, minWidth: 12, maxWidth: 35);
  }

  // ---------------------------------------------------------------------------
  // SHEET 5: Direct Site Expenses
  // ---------------------------------------------------------------------------
  static void _buildExpensesSheet(Excel excel, ConsolidatedReportData data) {
    const sheetName = 'Expenses';
    final sheet = excel[sheetName];

    sheet.appendRow([TextCellValue('IBUILD ERP — DIRECT SITE & OPERATIONAL EXPENSES')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

    sheet.appendRow([TextCellValue('Period: ${DateFormat('dd-MM-yyyy').format(data.startDate)} to ${DateFormat('dd-MM-yyyy').format(data.endDate)} | Project: ${data.projectName}')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = reportSubTitleStyle;

    sheet.appendRow([]);

    final headers = [
      'Expense Date',
      'Voucher ID',
      'Category',
      'Description / Purpose',
      'Project / Site',
      'Payment Mode',
      'Amount (INR)',
      'Recorded By',
      'Remarks',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    const headerRowIdx = 3;
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = tableHeaderStyle;
    }

    if (data.expenses.isEmpty) {
      sheet.appendRow([
        TextCellValue('No expense records available for this period.'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final rowIdx = sheet.maxRows - 1;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIdx),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = positiveNoticeStyle;
    } else {
      double sumExpenses = 0.0;

      for (int i = 0; i < data.expenses.length; i++) {
        final e = data.expenses[i];
        sumExpenses += e.amount;

        sheet.appendRow([
          TextCellValue(e.expenseDate),
          TextCellValue(e.shortId),
          TextCellValue(e.category),
          TextCellValue(e.notes ?? 'Operational Expense'),
          TextCellValue(e.projectName ?? data.projectName),
          TextCellValue(e.paymentMode.toUpperCase()),
          DoubleCellValue(e.amount),
          TextCellValue(e.recordedBy ?? 'Site Supervisor'),
          TextCellValue(e.notes ?? '-'),
        ]);

        final rowIdx = sheet.maxRows - 1;
        final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
        for (int col = 0; col < headers.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
        }
      }

      // Summary Row
      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue(''),
        TextCellValue('${data.expenses.length} Vouchers'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(sumExpenses),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final sumRowIdx = sheet.maxRows - 1;
      for (int col = 0; col < headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sumRowIdx)).cellStyle = summaryRowStyle;
      }
    }

    _autoFitColumns(sheet, headers.length, minWidth: 12, maxWidth: 40);
  }

  // ---------------------------------------------------------------------------
  // SHEET 6: Payment Ledger
  // ---------------------------------------------------------------------------
  static void _buildPaymentsSheet(Excel excel, ConsolidatedReportData data) {
    const sheetName = 'Payments';
    final sheet = excel[sheetName];

    sheet.appendRow([TextCellValue('IBUILD ERP — PAYMENT LEDGER & CASH FLOW LOG')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

    sheet.appendRow([TextCellValue('Period: ${DateFormat('dd-MM-yyyy').format(data.startDate)} to ${DateFormat('dd-MM-yyyy').format(data.endDate)} | Project: ${data.projectName}')]);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 1),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = reportSubTitleStyle;

    sheet.appendRow([]);

    final headers = [
      'Transaction Date',
      'Transaction ID',
      'Flow Type',
      'Counterparty / Vendor / Client',
      'Party Category',
      'Payment Method',
      'Amount (INR)',
      'Running Balance (INR)',
      'Remarks',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    const headerRowIdx = 3;
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = tableHeaderStyle;
    }

    if (data.payments.isEmpty) {
      sheet.appendRow([
        TextCellValue('No payment ledger entries available for this period.'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final rowIdx = sheet.maxRows - 1;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIdx),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle = positiveNoticeStyle;
    } else {
      double sumInflow = 0.0;
      double sumOutflow = 0.0;

      for (int i = 0; i < data.payments.length; i++) {
        final p = data.payments[i];
        final isReceived = p.paymentType.toLowerCase() == 'received';
        if (isReceived) {
          sumInflow += p.amount;
        } else {
          sumOutflow += p.amount;
        }

        sheet.appendRow([
          TextCellValue(DateFormat('dd-MM-yyyy').format(p.paymentDate)),
          TextCellValue(p.id.length > 8 ? p.id.substring(0, 8).toUpperCase() : p.id.toUpperCase()),
          TextCellValue(isReceived ? 'MONEY IN (INFLOW)' : 'MONEY OUT (OUTFLOW)'),
          TextCellValue(p.counterpartyName),
          TextCellValue(p.counterpartyType),
          TextCellValue(p.paymentMethod),
          DoubleCellValue(p.amount),
          DoubleCellValue(p.runningBalance),
          TextCellValue(p.remarks ?? '-'),
        ]);

        final rowIdx = sheet.maxRows - 1;
        final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
        for (int col = 0; col < headers.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
        }
      }

      // Summary Row
      final netBalance = sumInflow - sumOutflow;
      sheet.appendRow([
        TextCellValue('SUMMARY'),
        TextCellValue(''),
        TextCellValue('Inflow: ₹${sumInflow.toStringAsFixed(2)}'),
        TextCellValue('Outflow: ₹${sumOutflow.toStringAsFixed(2)}'),
        TextCellValue(''),
        TextCellValue('Net Balance:'),
        DoubleCellValue(netBalance),
        TextCellValue(''),
        TextCellValue(''),
      ]);
      final sumRowIdx = sheet.maxRows - 1;
      for (int col = 0; col < headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sumRowIdx)).cellStyle = summaryRowStyle;
      }
    }

    _autoFitColumns(sheet, headers.length, minWidth: 12, maxWidth: 35);
  }

  // ===========================================================================
  // 2. BACKWARD COMPATIBLE SINGLE & MULTI-SHEET EXPORTERS
  // ===========================================================================

  /// Generates raw .xlsx bytes for any single table dataset with professional styling.
  static Uint8List generateTableExcel({
    required String sheetName,
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<dynamic>? summaryRow,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    // Row 1: Title Header
    sheet.appendRow([TextCellValue(title)]);
    if (headers.isNotEmpty) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0),
      );
    }
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

    // Row 2: Empty spacer
    sheet.appendRow([]);

    // Row 3: Column Headers
    final List<CellValue> headerCells = headers.map((h) => TextCellValue(h)).toList();
    sheet.appendRow(headerCells);
    const int headerRowIndex = 2;
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex)).cellStyle = tableHeaderStyle;
    }

    // Rows 4+: Data Rows
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final List<CellValue> cellValues = row.map((val) => toCellValue(val)).toList();
      sheet.appendRow(cellValues);

      final rowIdx = sheet.maxRows - 1;
      final rowStyle = (i % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
      for (int col = 0; col < headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
      }
    }

    // Optional Summary Row
    if (summaryRow != null && summaryRow.isNotEmpty) {
      final List<CellValue> summaryCells = summaryRow.map((val) => toCellValue(val)).toList();
      sheet.appendRow(summaryCells);

      final summaryRowIdx = sheet.maxRows - 1;
      for (int col = 0; col < summaryRow.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: summaryRowIdx)).cellStyle = summaryRowStyle;
      }
    }

    _autoFitColumns(sheet, headers.length, minWidth: 12, maxWidth: 45);

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Generates a rich multi-sheet Excel (.xlsx) workbook (e.g. for complete GST Tax & Audit Packages).
  static Uint8List generateMultiSheetExcel({
    required List<ExcelSheetConfig> sheets,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    for (int i = 0; i < sheets.length; i++) {
      final config = sheets[i];
      final sheetName = config.sheetName;

      if (i == 0 && defaultSheet != null) {
        excel.rename(defaultSheet, sheetName);
      }

      final sheet = excel[sheetName];

      // Row 1: Title Header
      sheet.appendRow([TextCellValue(config.title)]);
      if (config.headers.isNotEmpty) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: config.headers.length - 1, rowIndex: 0),
        );
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = reportTitleStyle;

      // Row 2: Spacer
      sheet.appendRow([]);

      // Row 3: Column Headers
      final List<CellValue> headerCells = config.headers.map((h) => TextCellValue(h)).toList();
      sheet.appendRow(headerCells);
      const int headerRowIndex = 2;
      for (int col = 0; col < config.headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex)).cellStyle = tableHeaderStyle;
      }

      // Data Rows
      for (int r = 0; r < config.rows.length; r++) {
        final row = config.rows[r];
        final List<CellValue> cellValues = row.map((val) => toCellValue(val)).toList();
        sheet.appendRow(cellValues);

        final rowIdx = sheet.maxRows - 1;
        final rowStyle = (r % 2 == 0) ? dataRowRegularStyle : dataRowAltStyle;
        for (int col = 0; col < config.headers.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx)).cellStyle = rowStyle;
        }
      }

      // Summary Row
      if (config.summaryRow != null && config.summaryRow!.isNotEmpty) {
        final List<CellValue> summaryCells = config.summaryRow!.map((val) => toCellValue(val)).toList();
        sheet.appendRow(summaryCells);

        final summaryRowIdx = sheet.maxRows - 1;
        for (int col = 0; col < config.summaryRow!.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: summaryRowIdx)).cellStyle = summaryRowStyle;
        }
      }

      _autoFitColumns(sheet, config.headers.length, minWidth: 12, maxWidth: 45);
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}

class ExcelSheetConfig {
  final String sheetName;
  final String title;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final List<dynamic>? summaryRow;

  const ExcelSheetConfig({
    required this.sheetName,
    required this.title,
    required this.headers,
    required this.rows,
    this.summaryRow,
  });
}
