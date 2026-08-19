import 'package:supabase_flutter/supabase_flutter.dart';
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
    List<Project> projects = (response as List)
        .map((j) => Project.fromJson(j))
        .toList();

    // ── Batch Fetch Real Expenses (Spent) ──
    final Map<String, double> spentByProject = {};
    try {
      final expRows = await _client
          .from('expenses')
          .select('project_id, amount');
      for (final r in expRows) {
        final pid = r['project_id'] as String?;
        final amt = (r['amount'] as num? ?? 0).toDouble();
        if (pid != null) {
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

      for (final pr in progRows) {
        final pid = pr['project_id'] as String?;
        if (pid != null && !progressByProject.containsKey(pid)) {
          final pct = (pr['progress_percentage'] as num? ?? 0).toDouble();
          final dtStr =
              (pr['created_at'] as String?) ?? (pr['date'] as String?);
          final dt = DateTime.tryParse(dtStr ?? '') ?? DateTime.now();
          final uName = pr['user_name'] as String?;
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

      for (final ar in actRows) {
        final pid = ar['project_id'] as String?;
        final uName = ar['user_name'] as String?;
        final dt = DateTime.tryParse(ar['created_at'] as String? ?? '');
        if (pid != null &&
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
    // Validate
    if (project.name.trim().isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }
    if (project.budget < 0) {
      throw ArgumentError('Project budget cannot be negative.');
    }

    await _client.from('projects').insert(project.toJson());

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'created_project',
      entityType: 'Project',
      entityId: project.id,
      details: {'name': project.name},
    );
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

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'updated_project',
      entityType: 'Project',
      entityId: project.id,
      details: {'name': project.name},
    );
  }

  @override
  Future<void> deleteProject(String id) async {
    final deleted = await _client
        .from('projects')
        .delete()
        .eq('id', id)
        .select('id, name')
        .maybeSingle();
    if (deleted == null) {
      throw StateError(
        'Project was not found or you do not have permission to delete it.',
      );
    }

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'deleted_project',
      entityType: 'Project',
      entityId: id,
      details: {'name': deleted['name'] ?? 'Unknown'},
    );
  }

  @override
  Future<void> archiveProject(String id) async {
    final archived = await _client
        .from('projects')
        .update({'is_archived': true})
        .eq('id', id)
        .select('id, name')
        .maybeSingle();
    if (archived == null) {
      throw StateError(
        'Project was not found or you do not have permission to archive it.',
      );
    }

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'archived_project',
      entityType: 'Project',
      entityId: id,
      details: {'name': archived['name']},
    );
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
