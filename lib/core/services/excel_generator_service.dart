import 'dart:typed_data';
import 'package:excel/excel.dart';

/// Generic service for building styled Excel (.xlsx) workbooks from tabular data.
class ExcelGeneratorService {
  /// Generates raw .xlsx bytes for any table dataset.
  static Uint8List generateTableExcel({
    required String sheetName,
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<dynamic>? summaryRow,
  }) {
    final excel = Excel.createExcel();
    // Default sheet is 'Sheet1', rename or use target sheetName
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];

    final CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
      horizontalAlignment: HorizontalAlignment.Center,
    );

    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1F2937'),
      horizontalAlignment: HorizontalAlignment.Left,
    );

    final CellStyle summaryStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
      backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
    );

    // Row 1: Title Header Banner
    sheet.appendRow([CellValue.text('IBUILD ERP - $title')]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

    // Row 2: Metadata
    sheet.appendRow([CellValue.text('Generated On: ${DateTime.now().toString().split('.').first}')]);

    // Row 3: Empty spacer
    sheet.appendRow([]);

    // Row 4: Column Headers
    final headerCells = headers.map((h) => CellValue.text(h)).toList();
    sheet.appendRow(headerCells);
    final int headerRowIndex = 3;
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex)).cellStyle = headerStyle;
    }

    // Rows 5+: Data Rows
    for (final row in rows) {
      final cellValues = row.map((val) {
        if (val == null) return CellValue.text('');
        if (val is num) return CellValue.number(val);
        if (val is bool) return CellValue.text(val ? 'Yes' : 'No');
        return CellValue.text(val.toString());
      }).toList();
      sheet.appendRow(cellValues);
    }

    // Optional Summary Row
    if (summaryRow != null && summaryRow.isNotEmpty) {
      sheet.appendRow([]); // Spacer
      final summaryCells = summaryRow.map((val) {
        if (val == null) return CellValue.text('');
        if (val is num) return CellValue.number(val);
        return CellValue.text(val.toString());
      }).toList();
      sheet.appendRow(summaryCells);

      final summaryRowIdx = sheet.maxRows - 1;
      for (int col = 0; col < summaryRow.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: summaryRowIdx)).cellStyle = summaryStyle;
      }
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}
