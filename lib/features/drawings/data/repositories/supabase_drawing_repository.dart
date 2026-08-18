import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site_drawing_model.dart';

class SupabaseDrawingRepository {
  final SupabaseClient _client;

  SupabaseDrawingRepository(this._client);

  Future<List<SiteDrawing>> fetchDrawingsForProject(String projectId) async {
    try {
      final response = await _client
          .from('site_drawings')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => SiteDrawing.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<SiteDrawing?> addDrawing(SiteDrawing drawing) async {
    try {
      final payload = drawing.toJson();
      if (payload['id'] == null || (payload['id'] as String).isEmpty) {
        payload.remove('id');
      }
      final response = await _client
          .from('site_drawings')
          .insert(payload)
          .select()
          .single();
      return SiteDrawing.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteDrawing(String drawingId) async {
    try {
      await _client.from('site_drawings').delete().eq('id', drawingId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Uploads binary image/drawing bytes to Supabase storage with automatic fallback.
  Future<String?> uploadDrawingFile({
    required String projectId,
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$projectId/${timestamp}_$cleanFileName';

    final mimeType = extension.toLowerCase() == 'pdf'
        ? 'application/pdf'
        : 'image/${extension.toLowerCase() == 'jpg' ? 'jpeg' : extension.toLowerCase()}';

    // Try available storage buckets
    final buckets = ['site-drawings', 'drawings', 'site-progress', 'project-files'];
    for (final bucket in buckets) {
      try {
        await _client.storage.from(bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );
        final publicUrl = _client.storage.from(bucket).getPublicUrl(storagePath);
        if (publicUrl.isNotEmpty) {
          return publicUrl;
        }
      } catch (_) {
        // Try next bucket
      }
    }

    // Fallback: If storage bucket is unreachable, encode as Base64 Data URI for immediate offline viewing
    final base64String = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64String';
  }
}
