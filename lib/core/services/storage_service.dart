import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../supabase/supabase_client.provider.dart';
import '../utils/logger.dart';

class StorageService {
  final SupabaseClient _client;
  static const _uuid = Uuid();

  StorageService(this._client);

  /// Uploads image bytes to Supabase Storage bucket.
  /// Returns the public URL of the uploaded file.
  /// Retries up to [maxRetries] times on failure.
  Future<String?> uploadImage({
    required String bucket,
    required Uint8List fileBytes,
    required String fileExtension,
    String? folder,
    int maxRetries = 3,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = '${_uuid.v4()}.$fileExtension';
    final path = folder != null ? '$folder/$fileName' : fileName;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        onProgress?.call(0.1 * attempt); // Signal start of attempt

        await _client.storage.from(bucket).uploadBinary(
              path,
              fileBytes,
              fileOptions: FileOptions(
                contentType: 'image/$fileExtension',
                upsert: true,
              ),
            );

        onProgress?.call(1.0);

        final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
        return publicUrl;
      } catch (e) {
        appLogger.w('Upload attempt $attempt failed for $path: $e');
        if (attempt == maxRetries) {
          appLogger.e('Upload failed after $maxRetries attempts for $path');
          return null;
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    return null;
  }

  /// Deletes a file from a Supabase Storage bucket by its full path.
  Future<bool> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await _client.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      appLogger.e('Failed to delete $filePath from $bucket: $e');
      return false;
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});
