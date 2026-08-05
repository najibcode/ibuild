import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'excel_download_web.dart'
    if (dart.library.io) 'excel_download_mobile.dart';

/// Cross-platform utility for saving/downloading Excel (.xlsx) files.
class ExcelDownloadHelper {
  /// Save or download Excel file bytes on Web or Mobile/Desktop.
  static Future<void> downloadExcel({
    required List<int> bytes,
    required String filename,
  }) async {
    final sanitizedFilename = filename.endsWith('.xlsx')
        ? filename
        : '$filename.xlsx';
    final uint8bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    if (kIsWeb) {
      triggerWebExcelDownload(uint8bytes, sanitizedFilename);
    } else {
      await Printing.sharePdf(bytes: uint8bytes, filename: sanitizedFilename);
    }
  }
}
