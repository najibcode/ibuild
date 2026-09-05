import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseProjectRepository implements ProjectRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseProjectRepository(this._client, this._activityRepo);

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
    final cache = OfflineDataCache();
    List<Project> projects = [];

    try {
      final cached = cache.getCachedProjects();
      if (cached != null && cached.isNotEmpty) {
        for (final j in cached) {
          try {
            projects.add(Project.fromJson(j));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Cache read note: $e');
    }

    try {
      dynamic query = _client.from('projects').select();

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }

      final response = await query;
      if (response is List) {
        final List<Project> remote = [];
        for (final j in response) {
          try {
            remote.add(Project.fromJson(j));
          } catch (err) {
            debugPrint('Error mapping project: $err');
          }
        }
        // Remote Supabase response is the canonical truth — purge deleted projects from cache
        projects = remote;
        cache.cacheProjects(projects.map((p) => p.toMap()).toList());
      }
    } catch (e) {
      debugPrint('Projects query note: $e');
    }

    // ── Batch Fetch Real Expenses (Spent) ──
    final Map<String, double> spentByProject = {};
    try {
      final expRows = await _client
          .from('expenses')
          .select('project_id, amount');
      for (final r in (expRows as List)) {
        final pid = r['project_id']?.toString();
        final amt = (r['amount'] as num? ?? 0).toDouble();
        if (pid != null && pid.isNotEmpty) {
          spentByProject[pid] = (spentByProject[pid] ?? 0.0) + amt;
        }
      }
    } catch (_) {}

    // ── Batch Fetch Real Physical Progress & Updates ──
    final Map<String, ({double pct, DateTime date, String? userName})>
    progressByProject = {};
    try {
      final progRows = await _client
          .from('daily_progress')
          .select(
            'project_id, progress_percentage, date, user_name, created_at',
          )
          .order('created_at', ascending: false);

      for (final pr in (progRows as List)) {
        final pid = pr['project_id']?.toString();
        if (pid != null && pid.isNotEmpty && !progressByProject.containsKey(pid)) {
          final pct = (pr['progress_percentage'] as num? ?? 0).toDouble();
          final dtStr =
              pr['created_at']?.toString() ?? pr['date']?.toString();
          final dt = DateTime.tryParse(dtStr ?? '') ?? DateTime.now();
          final uName = pr['user_name']?.toString();
          progressByProject[pid] = (pct: pct, date: dt, userName: uName);
        }
      }
    } catch (_) {}

    // ── Batch Fetch Latest Activities for User Attribution ──
    final Map<String, ({DateTime date, String userName})> activityByProject =
        {};
    try {
      final actRows = await _client
          .from('activities')
          .select('project_id, created_at, user_name, details')
          .order('created_at', ascending: false);

      for (final ar in (actRows as List)) {
        final pid = ar['project_id']?.toString();
        final uName = ar['user_name']?.toString();
        final dt = DateTime.tryParse(ar['created_at']?.toString() ?? '');
        if (pid != null &&
            pid.isNotEmpty &&
            uName != null &&
            dt != null &&
            !activityByProject.containsKey(pid)) {
          activityByProject[pid] = (date: dt, userName: uName);
        }
      }
    } catch (_) {}

    // ── Enrich Projects with Real Metrics ──
    projects = projects.map((p) {
      final realSpent = spentByProject[p.id] ?? (p.spent > 0 ? p.spent : 0.0);
      final progData = progressByProject[p.id];
      final actData = activityByProject[p.id];

      // Determine latest update timestamp and user responsible
      DateTime? latestDate = progData?.date;
      String? latestUser = progData?.userName;

      if (actData != null) {
        if (latestDate == null || actData.date.isAfter(latestDate)) {
          latestDate = actData.date;
          latestUser = actData.userName;
        }
      }
      latestDate ??= p.createdAt != null
          ? DateTime.tryParse(p.createdAt!)
          : null;

      return p.copyWith(
        spent: realSpent,
        physicalProgress: progData?.pct,
        lastUpdatedDate: latestDate,
        lastUpdatedBy: latestUser,
      );
    }).toList();

    // Client-side search filter
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

    // ── Sort Logic ──
    projects.sort((a, b) {
      switch (sortBy) {
        case 'recently_updated':
        case 'created_at':
          final dtA = a.lastUpdatedDate ?? DateTime(2000);
          final dtB = b.lastUpdatedDate ?? DateTime(2000);
          return ascending ? dtA.compareTo(dtB) : dtB.compareTo(dtA);
        case 'name':
          return ascending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        case 'budget':
          return ascending
              ? a.budget.compareTo(b.budget)
              : b.budget.compareTo(a.budget);
        case 'progress':
          return ascending
              ? a.computedProgress.compareTo(b.computedProgress)
              : b.computedProgress.compareTo(a.computedProgress);
        case 'due_date':
          final dueA = a.targetDueDate ?? DateTime(2099);
          final dueB = b.targetDueDate ?? DateTime(2099);
          return ascending ? dueA.compareTo(dueB) : dueB.compareTo(dueA);
        case 'status':
          return ascending
              ? a.status.compareTo(b.status)
              : b.status.compareTo(a.status);
        default:
          final dtA = a.lastUpdatedDate ?? DateTime(2000);
          final dtB = b.lastUpdatedDate ?? DateTime(2000);
          return dtB.compareTo(dtA);
      }
    });

    // Pagination
    if (offset >= projects.length) return [];
    final endIndex = (offset + limit).clamp(0, projects.length);
    return projects.sublist(offset, endIndex);
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final cache = OfflineDataCache();
    final cached = cache.getCachedProjects();
    if (cached != null) {
      final found = cached.firstWhere((p) => p['id'] == id, orElse: () => {});
      if (found.isNotEmpty) return Project.fromJson(found);
    }

    try {
      final response = await _client
          .from('projects')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null) return Project.fromJson(response);
    } catch (_) {}
    return null;
  }

  @override
  Future<void> createProject(Project project) async {
    // Validate
    if (project.name.trim().isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }
    if (project.budget < 0) {
      throw ArgumentError('Project budget cannot be negative.');
    }

    final assignedId = project.id.isNotEmpty ? project.id : const Uuid().v4();
    final projToSave = project.copyWith(id: assignedId);

    // Save to OfflineDataCache
    final cache = OfflineDataCache();
    final existing = cache.getCachedProjects() ?? [];
    existing.removeWhere((p) => p['id'] == assignedId || p['id'] == project.id);
    existing.insert(0, projToSave.toMap());
    cache.cacheProjects(existing);

    String entityId = assignedId;

    try {
      final insertMap = Map<String, dynamic>.from(projToSave.toMap());
      final response = await _client.from('projects').insert(insertMap).select().maybeSingle();
      if (response != null) {
        final createdProject = Project.fromJson(response);
        entityId = createdProject.id;

        // Update cache with server UUID
        final updatedList = cache.getCachedProjects() ?? [];
        updatedList.removeWhere((p) => p['id'] == assignedId || p['id'] == createdProject.id);
        updatedList.insert(0, createdProject.toMap());
        cache.cacheProjects(updatedList);
      }
    } catch (e) {
      debugPrint('Supabase insert project error: $e. Retrying with basic fields.');
      try {
        final basicMap = {
          'id': assignedId,
          'name': projToSave.name,
          'client_name': projToSave.clientName,
          'budget': projToSave.budget,
          'status': projToSave.status,
        };
        await _client.from('projects').insert(basicMap);
      } catch (_) {}
    }

    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'created_project',
        entityType: 'Project',
        entityId: entityId,
        details: {'name': projToSave.name},
      );
    } catch (_) {}
  }

  @override
  Future<void> updateProject(Project project) async {
    final cache = OfflineDataCache();
    final existing = cache.getCachedProjects() ?? [];
    final idx = existing.indexWhere((p) => p['id'] == project.id);
    if (idx != -1) {
      existing[idx] = project.toMap();
    } else {
      existing.insert(0, project.toMap());
    }
    cache.cacheProjects(existing);

    try {
      await _client
          .from('projects')
          .update(project.toJson())
          .eq('id', project.id);
    } catch (e) {
      debugPrint('Supabase update project error: $e. Retrying with basic fields.');
      try {
        final fallbackMap = {
          'name': project.name,
          'client_name': project.clientName,
          'budget': project.budget,
          'status': project.status,
        };
        await _client.from('projects').update(fallbackMap).eq('id', project.id);
      } catch (_) {}
    }

    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'updated_project',
        entityType: 'Project',
        entityId: project.id,
        details: {'name': project.name},
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteProject(String id) async {
    try {
      // 1. Try atomic cascade delete RPC, or clean up dependent foreign key tables in order
      try {
        await _client.rpc('delete_project_cascade', params: {'p_project_id': id});
      } catch (_) {
        // Fallback: manually delete dependent child records first to satisfy foreign keys
        try { await _client.from('expenses').delete().eq('project_id', id); } catch (_) {}
        try { await _client.from('daily_progress').delete().eq('project_id', id); } catch (_) {}
        try { await _client.from('snags').delete().eq('project_id', id); } catch (_) {}
        try { await _client.from('bills').delete().eq('project_id', id); } catch (_) {}
        try { await _client.from('project_checklists').delete().eq('project_id', id); } catch (_) {}
        try { await _client.from('project_drawings').delete().eq('project_id', id); } catch (_) {}
        try { await _client.from('subcontractors').update({'project_id': null}).eq('project_id', id); } catch (_) {}
        try { await _client.from('equipment').update({'project_id': null}).eq('project_id', id); } catch (_) {}
        try { await _client.from('attendance').update({'project_id': null}).eq('project_id', id); } catch (_) {}

        // Finally delete the project record from Supabase
        await _client.from('projects').delete().eq('id', id);
      }

      // 2. Update local cache ONLY AFTER Supabase deletion succeeds
      final cache = OfflineDataCache();
      final existing = cache.getCachedProjects() ?? [];
      existing.removeWhere((p) => p['id'] == id);
      cache.cacheProjects(existing);

      // 3. Log activity
      try {
        await _activityRepo.logActivity(
          actionType: 'deleted_project',
          entityType: 'Project',
          entityId: id,
          details: {'id': id},
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Supabase delete project error: $e');
      rethrow;
    }
  }

  @override
  Future<void> archiveProject(String id) async {
    final cache = OfflineDataCache();
    final existing = cache.getCachedProjects() ?? [];
    final idx = existing.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      existing[idx]['is_archived'] = true;
      cache.cacheProjects(existing);
    }

    try {
      await _client
          .from('projects')
          .update({'is_archived': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Supabase archive project error: $e');
    }

    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'archived_project',
        entityType: 'Project',
        entityId: id,
        details: {'id': id},
      );
    } catch (_) {}
  }

  @override
  Future<int> getProjectCount({
    String? statusFilter,
    bool includeArchived = false,
  }) async {
    final cache = OfflineDataCache();
    final cached = cache.getCachedProjects() ?? [];
    if (cached.isNotEmpty) {
      return cached.length;
    }

    try {
      dynamic query = _client.from('projects').select();
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }
      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }
      final response = await query;
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }
}
