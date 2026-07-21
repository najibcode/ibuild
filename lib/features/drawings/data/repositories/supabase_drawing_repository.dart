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
      final response = await _client.from('site_drawings').insert(drawing.toJson()).select().single();
      return SiteDrawing.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
