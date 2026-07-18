import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageCompressionService {
  static const int maxWidth = 1200;
  static const int maxHeight = 1200;
  static const int quality = 75;

  /// Pick an image from gallery or camera, returns compressed bytes and extension.
  static Future<({Uint8List bytes, String extension})?> pickAndCompress({
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final extension = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';

    return (bytes: bytes, extension: extension);
  }

  /// Pick from gallery specifically
  static Future<({Uint8List bytes, String extension})?> pickFromGallery() {
    return pickAndCompress(source: ImageSource.gallery);
  }

  /// Pick from camera specifically
  static Future<({Uint8List bytes, String extension})?> pickFromCamera() {
    return pickAndCompress(source: ImageSource.camera);
  }
}
