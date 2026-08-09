import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

class ImageCompressionService {
  static const int maxWidth = 1200;
  static const int maxHeight = 1200;
  static const int quality = 75;

  /// Pick an image from gallery or camera, returns compressed bytes and extension.
  /// On web, camera is not supported — falls back to gallery automatically.
  static Future<({Uint8List bytes, String extension})?> pickAndCompress({
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();

      // On web, camera source is not supported — fall back to gallery
      final effectiveSource = (kIsWeb && source == ImageSource.camera)
          ? ImageSource.gallery
          : source;

      final picked = await picker.pickImage(
        source: effectiveSource,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        appLogger.w('ImageCompressionService: picked file has 0 bytes');
        return null;
      }

      final ext = picked.name.split('.').last.toLowerCase();
      final extension = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext) ? ext : 'jpg';

      appLogger.i('ImageCompressionService: picked ${bytes.length} bytes, ext=$extension');
      return (bytes: bytes, extension: extension);
    } catch (e) {
      appLogger.e('ImageCompressionService: pick failed: $e');
      return null;
    }
  }

  /// Pick from gallery specifically
  static Future<({Uint8List bytes, String extension})?> pickFromGallery() {
    return pickAndCompress(source: ImageSource.gallery);
  }

  /// Pick from camera specifically (falls back to gallery on web)
  static Future<({Uint8List bytes, String extension})?> pickFromCamera() {
    return pickAndCompress(source: ImageSource.camera);
  }

  /// Whether camera source is available on the current platform
  static bool get isCameraAvailable => !kIsWeb;
}
