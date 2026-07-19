import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';

class SupabaseProjectRepository implements ProjectRepository {
  final SupabaseClient _client;

  SupabaseProjectRepository(this._client);

  @override
  Future<List<Project>> getProjects({
    String? search,
    String? statusFilter,
    String? sortBy,
    bool ascending = true,
    int limit = 20,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    dynamic query = _client.from('projects').select();

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }

    // Apply sort
    final orderColumn = sortBy ?? 'created_at';
    query = query.order(orderColumn, ascending: ascending);

    // Apply pagination
    query = query.range(offset, offset + limit - 1);

    final response = await query;
    List<Project> projects = (response as List)
        .map((j) => Project.fromJson(j))
        .toList();

    // Client-side search filter (Supabase free tier doesn't have full-text search)
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      projects = projects
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                (p.clientName?.toLowerCase().contains(q) ?? false) ||
                (p.projectCode?.toLowerCase().contains(q) ?? false) ||
                (p.address?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    return projects;
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Project.fromJson(response);
  }

  @override
  Future<void> createProject(Project project) async {
    await _client.from('projects').insert(project.toJson());
  }

  @override
  Future<void> updateProject(Project project) async {
    final updated = await _client
        .from('projects')
        .update(project.toJson())
        .eq('id', project.id)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError(
        'Project was not found or you do not have permission to update it.',
      );
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    final deleted = await _client
        .from('projects')
        .delete()
        .eq('id', id)
        .select('id')
        .maybeSingle();
    if (deleted == null) {
      throw StateError(
        'Project was not found or you do not have permission to delete it.',
      );
    }
  }

  @override
  Future<void> archiveProject(String id) async {
    final archived = await _client
        .from('projects')
        .update({'is_archived': true})
        .eq('id', id)
        .select('id')
        .maybeSingle();
    if (archived == null) {
      throw StateError(
        'Project was not found or you do not have permission to archive it.',
      );
    }
  }

  @override
  Future<int> getProjectCount({
    String? statusFilter,
    bool includeArchived = false,
  }) async {
    dynamic query = _client.from('projects').select();
    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }
    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }
    final response = await query;
    return (response as List).length;
  }
}
