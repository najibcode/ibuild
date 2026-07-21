import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/checklist_model.dart';

class SupabaseChecklistRepository {
  final SupabaseClient _client;

  SupabaseChecklistRepository(this._client);

  Future<List<ChecklistItem>> fetchChecklistForProject(String projectId) async {
    try {
      final response = await _client
          .from('project_checklists')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: true);
      return (response as List).map((json) => ChecklistItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ChecklistItem?> addChecklistItem(ChecklistItem item) async {
    try {
      final response = await _client
          .from('project_checklists')
          .insert(item.toJson())
          .select()
          .single();
      return ChecklistItem.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleChecklistItem(String id, bool isCompleted) async {
    try {
      await _client
          .from('project_checklists')
          .update({'is_completed': isCompleted, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
