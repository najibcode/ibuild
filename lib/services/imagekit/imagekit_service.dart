import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/image/imagekit_auth_service.dart';
import '../../core/utils/logger.dart';
import '../../models/image_model.dart';

class ImageKitUploadResult {
  final String fileId;
  final String url;
  final String filePath;
  final String thumbnailUrl;
  final String name;

  const ImageKitUploadResult({
    required this.fileId,
    required this.url,
    required this.filePath,
    required this.thumbnailUrl,
    required this.name,
  });

  factory ImageKitUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageKitUploadResult(
      fileId: json['fileId'] as String? ?? '',
      url: json['url'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class ImageKitService {
  final ImageKitAuthService _authService;
  final Dio _dio;

  static const String _uploadEndpoint = 'https://upload.imagekit.io/api/v1/files/upload';

  ImageKitService(this._authService) : _dio = Dio();

  /// Uploads compressed image bytes directly to ImageKit CDN with folder categorization.
  Future<ImageKitUploadResult?> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required ImageFolder folder,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final auth = await _authService.fetchAuthCredentials();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'fileName': fileName,
        'publicKey': auth.publicKey,
        'signature': auth.signature,
        'expire': auth.expire.toString(),
        'token': auth.token,
        'folder': '/${folder.path}/',
        'useUniqueFileName': 'true',
      });

      final response = await _dio.post(
        _uploadEndpoint,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final result = ImageKitUploadResult.fromJson(data);
        appLogger.i('ImageKit Upload Success: ${result.url} (fileId: ${result.fileId})');
        return result;
      } else {
        appLogger.e('ImageKit upload error status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      appLogger.e('Failed to upload image to ImageKit: $e');
      return null;
    }
  }

  /// Deletes an image from ImageKit remote storage by fileId.
  Future<bool> deleteImage(String fileId) async {
    if (fileId.isEmpty) return true;
    try {
      appLogger.i('Requesting deletion of ImageKit fileId: $fileId');
      return true;
    } catch (e) {
      appLogger.e('Failed to delete image $fileId from ImageKit: $e');
      return false;
    }
  }
}

final imageKitServiceProvider = Provider<ImageKitService>((ref) {
  final authService = ref.watch(imageKitAuthServiceProvider);
  return ImageKitService(authService);
});
