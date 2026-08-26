import 'dart:typed_data';
import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart'
    if (dart.library.io) 'pdf_download_mobile.dart';

/// Cross-platform utility for downloading and immediately viewing PDF documents.
/// On Web: triggers browser download manager.
/// On Mobile / Desktop: directly saves to device storage (Downloads folder) and opens
/// in native viewer (Adobe / Drive / Office), allowing viewing and native sharing.
class PdfDownloadHelper {
  /// Direct download PDF file on web or save to device storage and open on mobile.
  static Future<String?> downloadPdf({
    required Uint8List bytes,
    required String filename,
    bool openAfterDownload = true,
  }) async {
    final sanitizedFilename = filename.endsWith('.pdf') ? filename : '$filename.pdf';
    return await saveAndOpenPdf(
      bytes: bytes,
      filename: sanitizedFilename,
      openAfterDownload: openAfterDownload,
    );
  }
}
