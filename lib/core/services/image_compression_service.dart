import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

class ImageCompressionService {
  /// Maximum dimension (width or height) for site progress photos.
  /// 1200px gives sharp, clear photos while dramatically reducing file size.
  static const int maxDimension = 1200;

  /// Starting JPEG quality — 85 is visually indistinguishable from original.
  static const int startQuality = 85;

  /// Hard ceiling: every image must be under this size.
  static const int maxFileSizeBytes = 1024 * 1024; // 1 MB

  /// Pick an image from gallery or camera, then compress to under 1 MB
  /// while maintaining clear, sharp visual quality.
  static Future<({Uint8List bytes, String extension})?> pickAndCompress({
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();

      // On web, camera source is not supported
      final effectiveSource = (kIsWeb && source == ImageSource.camera)
          ? ImageSource.gallery
          : source;

      // Pick at FULL quality — let flutter_image_compress handle everything
      final picked = await picker.pickImage(
        source: effectiveSource,
        // Do NOT set imageQuality here — we want the raw pixels
        // so flutter_image_compress can do a single efficient encode
      );

      if (picked == null) return null;

      final rawBytes = await picked.readAsBytes();
      if (rawBytes.isEmpty) {
        appLogger.w('ImageCompressionService: picked file has 0 bytes');
        return null;
      }

      final rawSizeKB = (rawBytes.length / 1024).toStringAsFixed(1);
      appLogger.i('ImageCompressionService: raw image = $rawSizeKB KB');

      // Compress with flutter_image_compress (resize + JPEG encode in one pass)
      final compressed = await _compressToTarget(rawBytes);

      final compressedSizeKB = (compressed.length / 1024).toStringAsFixed(1);
      final savings = rawBytes.length - compressed.length;
      final savingsPercent = rawBytes.isNotEmpty
          ? ((savings / rawBytes.length) * 100).toStringAsFixed(1)
          : '0';

      appLogger.i(
        'ImageCompressionService: $rawSizeKB KB → $compressedSizeKB KB '
        '(saved $savingsPercent%)',
      );

      return (bytes: compressed, extension: 'jpg');
    } catch (e) {
      appLogger.e('ImageCompressionService: pick failed: $e');
      return null;
    }
  }

  /// Compresses raw image bytes to under [maxFileSizeBytes] (1 MB).
  ///
  /// Strategy:
  ///  1. Resize to [maxDimension] and encode as JPEG at quality 85
  ///  2. If still over 1 MB, progressively reduce quality (75 → 65 → 55 → 45)
  ///  3. If still over 1 MB, also reduce dimensions (1000 → 800)
  ///
  /// Quality 85 JPEG is visually indistinguishable from the original for photos.
  /// Quality 65 is the lowest we go — still looks sharp and clear.
  static Future<Uint8List> _compressToTarget(Uint8List rawBytes) async {
    // Quality steps: try high quality first, step down only if needed
    const qualitySteps = [85, 75, 65, 55, 45];
    // Dimension steps: reduce dimensions if quality reduction alone isn't enough
    const dimensionSteps = [1200, 1000, 800];

    for (final dim in dimensionSteps) {
      for (final q in qualitySteps) {
        try {
          final result = await FlutterImageCompress.compressWithList(
            rawBytes,
            minWidth: dim,
            minHeight: dim,
            quality: q,
            format: CompressFormat.jpeg,
            keepExif: false, // Strip metadata to save space
          );

          if (result.length <= maxFileSizeBytes) {
            appLogger.i(
              'ImageCompressionService: target hit at '
              'dim=${dim}px, quality=$q → ${(result.length / 1024).toStringAsFixed(1)} KB',
            );
            return result;
          }
        } catch (e) {
          appLogger.w('ImageCompressionService: compress failed at q=$q dim=$dim: $e');
        }
      }
    }

    // Final fallback — aggressive compression
    try {
      final fallback = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: 640,
        minHeight: 640,
        quality: 40,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      appLogger.i(
        'ImageCompressionService: fallback compression → '
        '${(fallback.length / 1024).toStringAsFixed(1)} KB',
      );
      return fallback;
    } catch (e) {
      appLogger.w('ImageCompressionService: all compression failed, returning raw bytes');
      return rawBytes;
    }
  }

  /// Standalone compression method for external callers (e.g., ImageNotifier).
  /// Compresses arbitrary image bytes to under 1 MB JPEG.
  static Future<Uint8List> compressBytes(
    Uint8List rawBytes, {
    String targetExt = 'jpg',
  }) async {
    return _compressToTarget(rawBytes);
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
