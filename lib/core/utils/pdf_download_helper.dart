import 'dart:typed_data';
import 'package:printing/printing.dart';

/// Utility class for downloading PDF files directly without opening print settings.
class PdfDownloadHelper {
  /// Direct download PDF file on web or trigger native save prompt on mobile.
  static Future<void> downloadPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    final sanitizedFilename = filename.endsWith('.pdf') ? filename : '$filename.pdf';
    await Printing.sharePdf(
      bytes: bytes,
      filename: sanitizedFilename,
    );
  }
}
