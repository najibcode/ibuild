import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.provider.dart';
import '../core/utils/logger.dart';
import '../models/image_model.dart';

class ImageRepository {
  final SupabaseClient _client;

  ImageRepository(this._client);

  /// Persists new image metadata record in PostgreSQL.
  Future<AppImage?> saveImageMetadata(AppImage image) async {
    try {
      final data = await _client
          .from('app_images')
          .insert(image.toJson())
          .select()
          .single();

      return AppImage.fromJson(data);
    } catch (e) {
      appLogger.e('Failed to save image metadata to DB: $e');
      return image;
    }
  }

  /// Fetches image records by folder or project/employee ID.
  Future<List<AppImage>> getImagesByFolder(String folder) async {
    try {
      final response = await _client
          .from('app_images')
          .select()
          .eq('folder', folder)
          .order('uploaded_at', ascending: false);

      return (response as List).map((json) => AppImage.fromJson(json)).toList();
    } catch (e) {
      appLogger.w('Could not fetch app_images for folder $folder: $e');
      return [];
    }
  }

  /// Deletes image metadata record from PostgreSQL.
  Future<bool> deleteImageMetadata(String imageId) async {
    try {
      await _client.from('app_images').delete().eq('id', imageId);
      return true;
    } catch (e) {
      appLogger.e('Failed to delete image metadata $imageId: $e');
      return false;
    }
  }
}

final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ImageRepository(client);
});
