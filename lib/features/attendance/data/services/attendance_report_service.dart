import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../employees/data/models/employee_model.dart';
import '../../../projects/data/models/project_model.dart';
import '../models/attendance_model.dart';

/// Structured PDF and Excel report generator for Worker Attendance & Site Deployment.
/// Formats reports grouped by DATE with dedicated date headers and worker details.
class AttendanceReportService {
  static final _navy = PdfColor.fromHex('#1E3A8A');
  static final _dark = PdfColor.fromHex('#1F2937');
  static final _slate = PdfColor.fromHex('#4B5563');
  static final _lightBg = PdfColor.fromHex('#F9FAFB');
  static final _border = PdfColor.fromHex('#E5E7EB');

  /// Helper to group attendance data by date for all active employees.
  static Map<String, List<Map<String, String>>> _buildGroupedData({
    required List<Attendance> records,
    required List<Employee> activeEmployees,
    required List<Project> projects,
    required Map<String, String> siteAssignments,
    required String startStr,
    required String endStr,
  }) {
    final Map<String, List<Map<String, String>>> grouped = {};

    // 1. Gather all unique dates present in records or range
    final Set<String> dateSet = {};
    for (final r in records) {
      if (r.date.isNotEmpty) dateSet.add(r.date);
    }

    // Always include dates in the range
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final dStr = d.toIso8601String().substring(0, 10);
        dateSet.add(dStr);
      }
    } catch (_) {}

    final sortedDates = dateSet.toList()..sort((a, b) => b.compareTo(a));

    // Map project lookup
    final Map<String, String> projectMap = {
      for (final p in projects) p.id: p.name
    };

    // Employee lookup map
    final Map<String, Employee> empMap = {
      for (final e in activeEmployees) e.id: e
    };

    // 2. Build worker rows per date
    for (final dStr in sortedDates) {
      final List<Map<String, String>> dayRows = [];

      // Find logged records for date
      final dateRecords = records.where((r) => r.date == dStr).toList();
      final Map<String, Attendance> dateLoggedMap = {
        for (final r in dateRecords) r.employeeId: r
      };

      // Collect all employees (both logged and active)
      final Set<String> empIdsForDay = {};
      empIdsForDay.addAll(dateLoggedMap.keys);
      empIdsForDay.addAll(empMap.keys);

      for (final empId in empIdsForDay) {
        final emp = empMap[empId];
        final logged = dateLoggedMap[empId];

        final workerName = emp?.name ?? logged?.employeeName ?? 'Worker ($empId)';
        final role = (emp?.role ?? 'Worker').toUpperCase();
        final status = (logged?.status ?? 'Absent').toUpperCase();

        // Resolve assigned site
        final siteId = logged?.projectId ?? siteAssignments['${empId}_$dStr'];
        String siteName = 'Unassigned / General Site';
        if (siteId != null && projectMap.containsKey(siteId)) {
          siteName = projectMap[siteId]!;
        } else if (logged?.projectName != null && logged!.projectName!.isNotEmpty) {
          siteName = logged.projectName!;
        }

        final wage = emp != null ? '₹${emp.salary.toInt()}' : 'N/A';

        dayRows.add({
          'empId': empId.length > 8 ? empId.substring(0, 8) : empId,
          'name': workerName,
          'role': role,
          'site': siteName,
          'status': status,
          'wage': wage,
        });
      }

      // Sort workers by status (Present first) then name
      dayRows.sort((a, b) {
        if (a['status'] == 'PRESENT' && b['status'] != 'PRESENT') return -1;
        if (a['status'] != 'PRESENT' && b['status'] == 'PRESENT') return 1;
        return a['name']!.compareTo(b['name']!);
      });

      grouped[dStr] = dayRows;
    }

    return grouped;
  }

  /// Generates a PDF document with date headers and nested worker tables.
  static Future<Uint8List> generatePdf({
    required String startStr,
    required String endStr,
    required List<Attendance> records,
    required List<Employee> activeEmployees,
    required List<Project> projects,
    required Map<String, String> siteAssignments,
  }) async {
    final pdf = pw.Document(title: 'Worker Attendance Audit Report');

    final grouped = _buildGroupedData(
      records: records,
      activeEmployees: activeEmployees,
      projects: projects,
      siteAssignments: siteAssignments,
      startStr: startStr,
      endStr: endStr,
    );

    // Calculate totals
    int totalShifts = 0;
    int totalPresent = 0;
    grouped.forEach((_, rows) {
      totalShifts += rows.length;
      totalPresent += rows.where((r) => r['status'] == 'PRESENT').length;
    });
    final totalAbsent = totalShifts - totalPresent;
    final pct = totalShifts > 0 ? ((totalPresent / totalShifts) * 100).toStringAsFixed(1) : '0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IBUILD CONSTRUCTIONS',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                      pw.Text(
                        'Civil Engineering & Site Deployment Audit',
                        style: pw.TextStyle(fontSize: 8, color: _slate),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: _navy,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'ATTENDANCE REPORT',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: _border),
              pw.SizedBox(height: 6),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: _border),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'IBUILD ERP - Verified Workforce Audit Log',
                    style: pw.TextStyle(fontSize: 8, color: _slate),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: _slate),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // Metadata Card
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _lightBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCol('PERIOD', '$startStr to $endStr'),
                  _buildMetricCol('TOTAL SHIFTS', '$totalShifts entries'),
                  _buildMetricCol('PRESENT', '$totalPresent'),
                  _buildMetricCol('ABSENT', '$totalAbsent'),
                  _buildMetricCol('ATTENDANCE %', '$pct%'),
                ],
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 14));

          // Grouped Sections per Date
          grouped.forEach((dateStr, rows) {
            final presentCount = rows.where((r) => r['status'] == 'PRESENT').length;
            final absentCount = rows.length - presentCount;

            DateTime? parsedDate;
            try {
              parsedDate = DateTime.parse(dateStr);
            } catch (_) {}
            final formattedDate = parsedDate != null
                ? DateFormat('EEEE, dd MMMM yyyy').format(parsedDate)
                : dateStr;

            // Date Section Header Box
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _navy,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'DATE: $formattedDate',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Present: $presentCount  |  Absent: $absentCount  |  Total: ${rows.length}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );

            // Table of workers for date
            widgets.add(
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: _border, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: _dark,
                  fontSize: 8,
                ),
                headerDecoration: pw.BoxDecoration(color: _lightBg),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headers: ['Worker Name', 'Role', 'Assigned Site / Project', 'Attendance Status'],
                data: rows.map((r) {
                  return [
                    r['name']!,
                    r['role']!,
                    r['site']!,
                    r['status']!,
                  ];
                }).toList(),
              ),
            );

            widgets.add(pw.SizedBox(height: 14));
          });

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricCol(String label, String val) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7, color: _slate)),
        pw.SizedBox(height: 2),
        pw.Text(
          val,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy),
        ),
      ],
    );
  }

  /// Generates a styled Excel sheet with special date header rows and worker lists.
  static Uint8List generateExcel({
    required String startStr,
    required String endStr,
    required List<Attendance> records,
    required List<Employee> activeEmployees,
    required List<Project> projects,
    required Map<String, String> siteAssignments,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Attendance_Report');
    final sheet = excel['Attendance_Report'];

    final grouped = _buildGroupedData(
      records: records,
      activeEmployees: activeEmployees,
      projects: projects,
      siteAssignments: siteAssignments,
      startStr: startStr,
      endStr: endStr,
    );

    final CellStyle dateHeaderStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
    );

    final CellStyle colHeaderStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#374151'),
    );

    final CellStyle presentStyle = CellStyle(
      fontSize: 10,
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#166534'),
    );

    final CellStyle absentStyle = CellStyle(
      fontSize: 10,
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#991B1B'),
    );

    // Minimalist Title Header
    sheet.appendRow([TextCellValue('Attendance Report ($startStr to $endStr)')]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = dateHeaderStyle;

    sheet.appendRow([]); // Spacer
    int currentRowIdx = 2;

    // Process each Date Section
    grouped.forEach((dateStr, rows) {
      final presentCount = rows.where((r) => r['status'] == 'PRESENT').length;
      final absentCount = rows.length - presentCount;

      DateTime? parsedDate;
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (_) {}
      final formattedDate = parsedDate != null
          ? DateFormat('dd MMM yyyy (EEEE)').format(parsedDate)
          : dateStr;

      // Neat Date Header Row
      sheet.appendRow([
        TextCellValue('Date: $formattedDate  |  Present: $presentCount, Absent: $absentCount')
      ]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRowIdx)).cellStyle = dateHeaderStyle;
      currentRowIdx++;

      // Column Headers Row for Date
      final headers = ['Worker Name', 'Role', 'Assigned Site', 'Status', 'Daily Rate'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
      for (int c = 0; c < headers.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRowIdx)).cellStyle = colHeaderStyle;
      }
      currentRowIdx++;

      // Worker Data Rows
      for (final r in rows) {
        final rowVals = [
          TextCellValue(r['name']!),
          TextCellValue(r['role']!),
          TextCellValue(r['site']!),
          TextCellValue(r['status']!),
          TextCellValue(r['wage']!),
        ];
        sheet.appendRow(rowVals);

        // Highlight status cell
        final statusCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRowIdx));
        if (r['status'] == 'PRESENT') {
          statusCell.cellStyle = presentStyle;
        } else {
          statusCell.cellStyle = absentStyle;
        }

        currentRowIdx++;
      }

      // Blank Spacer Row between dates
      sheet.appendRow([]);
      currentRowIdx++;
    });

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}
