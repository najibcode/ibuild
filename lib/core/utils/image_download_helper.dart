import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'logger.dart';
import 'image_download_web.dart'
    if (dart.library.io) 'image_download_mobile.dart';

/// Cross-platform utility for downloading/saving progress images.
class ImageDownloadHelper {
  /// Downloads an image from a URL or Base64 Data URI.
  /// On web: triggers a browser file download.
  /// On mobile: saves to the device gallery or share sheet.
  static Future<void> downloadImage({
    required String imageUrl,
    required String filename,
  }) async {
    try {
      Uint8List bytes;

      if (imageUrl.startsWith('data:image/')) {
        // Base64 Data URI → decode directly
        final base64Str = imageUrl.split(',').last;
        bytes = base64Decode(base64Str);
      } else {
        // Network URL → fetch bytes
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch image: HTTP ${response.statusCode}');
        }
        bytes = response.bodyBytes;
      }

      // Determine file extension
      String ext = 'jpg';
      if (imageUrl.contains('.png') || imageUrl.contains('image/png')) {
        ext = 'png';
      } else if (imageUrl.contains('.webp') || imageUrl.contains('image/webp')) {
        ext = 'webp';
      }

      final finalFilename = filename.contains('.') ? filename : '$filename.$ext';
      triggerImageDownload(bytes, finalFilename);
      appLogger.i('Image download triggered: $finalFilename (${bytes.length} bytes)');
    } catch (e) {
      appLogger.e('Image download failed: $e');
      rethrow;
    }
  }
}
