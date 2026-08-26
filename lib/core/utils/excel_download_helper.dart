import 'dart:typed_data';
import 'excel_download_stub.dart'
    if (dart.library.html) 'excel_download_web.dart'
    if (dart.library.io) 'excel_download_mobile.dart';

/// Cross-platform utility for saving/downloading and opening Excel (.xlsx) files.
/// On Web: triggers browser download manager.
/// On Mobile / Desktop: directly saves to device storage (Downloads folder) and opens
/// in native viewer (Excel / Sheets / Office), allowing viewing and native sharing.
class ExcelDownloadHelper {
  /// Save or download Excel file bytes on Web or Mobile/Desktop.
  static Future<String?> downloadExcel({
    required List<int> bytes,
    required String filename,
    bool openAfterDownload = true,
  }) async {
    final sanitizedFilename = filename.endsWith('.xlsx')
        ? filename
        : '$filename.xlsx';
    final uint8bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    return await saveAndOpenExcel(
      bytes: uint8bytes,
      filename: sanitizedFilename,
      openAfterDownload: openAfterDownload,
    );
  }
}
