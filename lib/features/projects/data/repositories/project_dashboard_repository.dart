import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_dashboard_model.dart';

/// Fetches all per-project dashboard data from Supabase in parallel safely and fault-tolerantly.
class ProjectDashboardRepository {
  final SupabaseClient _client;

  ProjectDashboardRepository(this._client);

  Future<ProjectDashboardStats> fetchDashboard(String projectId) async {
    Map<String, dynamic>? project;
    _AttendanceData attendance = _AttendanceData(present: 0, total: 0);
    _ExpenseData expenses = _ExpenseData(total: 0, breakdown: []);
    _ChecklistData checklist = _ChecklistData(total: 0, completed: 0);
    _PaymentData payments = _PaymentData(totalReceived: 0, pending: 0);
    List<int> weekly = List.filled(7, 0);
    List<ProjectDashboardActivity> activities = [];
    double? physProg;
    int materialsCount = 0;
    int snagsCount = 0;
    List<ProjectMilestoneStage> milestones = [];

    try {
      // 1. Fetch core project details
      project = await _fetchProject(projectId);

      // 2. Fetch parallel sub-metrics with independent error handling
      final futures = await Future.wait([
        _fetchAttendance(projectId).catchError((_) => _AttendanceData(present: 0, total: 0)),
        _fetchExpenses(projectId).catchError((_) => _ExpenseData(total: 0, breakdown: [])),
        _fetchChecklist(projectId).catchError((_) => _ChecklistData(total: 0, completed: 0)),
        _fetchPayments(projectId).catchError((_) => _PaymentData(totalReceived: 0, pending: 0)),
        _fetchWeeklyProgress(projectId).catchError((_) => List.filled(7, 0)),
        _fetchRecentActivity(projectId).catchError((_) => <ProjectDashboardActivity>[]),
        _fetchPhysicalProgress(projectId).catchError((_) => null),
        _fetchMaterialsCount(projectId).catchError((_) => 0),
        _fetchSnagsCount(projectId).catchError((_) => 0),
      ]).timeout(const Duration(seconds: 10), onTimeout: () {
        return [
          _AttendanceData(present: 0, total: 0),
          _ExpenseData(total: 0, breakdown: []),
          _ChecklistData(total: 0, completed: 0),
          _PaymentData(totalReceived: 0, pending: 0),
          List.filled(7, 0),
          <ProjectDashboardActivity>[],
          null,
          0,
          0,
        ];
      });

      attendance = futures[0] as _AttendanceData;
      expenses = futures[1] as _ExpenseData;
      checklist = futures[2] as _ChecklistData;
      payments = futures[3] as _PaymentData;
      weekly = futures[4] as List<int>;
      activities = futures[5] as List<ProjectDashboardActivity>;
      physProg = futures[6] as double?;
      materialsCount = futures[7] as int;
      snagsCount = futures[8] as int;

      final overallProgress = physProg ??
          ((project?['status'] as String?)?.toLowerCase() == 'completed'
              ? 100.0
              : ((project?['budget'] as num?)?.toDouble() ?? 0.0) > 0
                  ? (expenses.total /
                          ((project?['budget'] as num?)?.toDouble() ?? 1.0) *
                          100)
                      .clamp(0.0, 100.0)
                  : 0.0);

      milestones = await _fetchMilestones(projectId, project, overallProgress)
          .catchError((_) => <ProjectMilestoneStage>[]);
    } catch (_) {
      // Gracefully continue with any available data
    }

    final realSpent = expenses.total > 0
        ? expenses.total
        : ((project?['spent'] as num?)?.toDouble() ?? 0.0);

    return ProjectDashboardStats(
      projectId: projectId,
      projectName: project?['name'] as String? ?? 'Project Overview',
      status: (project?['status'] as String?)?.toLowerCase() ?? 'active',
      clientName: project?['client_name'] as String?,
      customerName: project?['customer_name'] as String?,
      startDate: project?['start_date'] as String?,
      expectedCompletion: project?['expected_completion'] as String?,
      address: project?['address'] as String?,
      imageUrl: project?['image_url'] as String?,
      budget: (project?['budget'] as num?)?.toDouble() ?? 0.0,
      spent: realSpent,
      estimatedCost: (project?['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      currentCost: (project?['current_cost'] as num?)?.toDouble() ?? 0.0,
      workersPresent: attendance.present,
      totalAssigned: attendance.total,
      totalExpenses: expenses.total,
      expenseBreakdown: expenses.breakdown,
      checklistTotal: checklist.total,
      checklistCompleted: checklist.completed,
      totalPayments: payments.totalReceived,
      pendingPayments: payments.pending,
      weeklyProgressCounts: weekly,
      recentActivities: activities,
      physicalProgress: physProg,
      materialsCount: materialsCount,
      openIssuesCount: snagsCount,
      milestones: milestones,
    );
  }

  // ── Project core data ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _fetchProject(String projectId) async {
    try {
      return await _client
          .from('projects')
          .select()
          .eq('id', projectId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  // ── Attendance (today) ──────────────────────────────────────────────────

  Future<_AttendanceData> _fetchAttendance(String projectId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await _client
          .from('attendance')
          .select('morning_status, status, project_id')
          .eq('date', todayStr)
          .eq('project_id', projectId)
          .timeout(const Duration(seconds: 5));

      int present = 0;
      for (final r in (rows as List)) {
        final st = (r['morning_status'] ?? r['status'] ?? '')
            .toString()
            .toLowerCase();
        if (st == 'present') {
          present++;
        }
      }
      return _AttendanceData(present: present, total: rows.length);
    } catch (_) {
      return _AttendanceData(present: 0, total: 0);
    }
  }

  // ── Expenses (all time, scoped to project) ────────────────────────────────

  Future<_ExpenseData> _fetchExpenses(String projectId) async {
    try {
      final rows = await _client
          .from('expenses')
          .select('amount, category')
          .eq('project_id', projectId)
          .timeout(const Duration(seconds: 5));

      double total = 0.0;
      final Map<String, double> byCategory = {};

      for (final e in (rows as List)) {
        final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
        final category = e['category'] as String? ?? 'Other';
        total += amount;
        byCategory[category] = (byCategory[category] ?? 0.0) + amount;
      }

      // Also ensure all subcontractor disbursements for this project are included in spent telemetry
      try {
        final subRows = await _client
            .from('subcontractors')
            .select('paid_amount')
            .eq('project_id', projectId)
            .timeout(const Duration(seconds: 5));

        double subTotalPaid = 0.0;
        for (final s in (subRows as List)) {
          final pAmt = (s['paid_amount'] as num?)?.toDouble() ?? 0.0;
          subTotalPaid += pAmt;
        }

        final recordedSubExpenses = byCategory['Subcontractor'] ?? 0.0;
        if (subTotalPaid > recordedSubExpenses) {
          final diff = subTotalPaid - recordedSubExpenses;
          total += diff;
          byCategory['Subcontractor'] = subTotalPaid;
        }
      } catch (_) {}

      final breakdown =
          byCategory.entries
              .map(
                (e) => ProjectExpenseCategory(category: e.key, amount: e.value),
              )
              .toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));

      return _ExpenseData(total: total, breakdown: breakdown);
    } catch (_) {
      return _ExpenseData(total: 0, breakdown: []);
    }
  }

  // ── Checklist progress (project_checklists) ────────────────────────────────

  Future<_ChecklistData> _fetchChecklist(String projectId) async {
    try {
      final rows = await _client
          .from('project_checklists')
          .select('is_completed')
          .eq('project_id', projectId)
          .timeout(const Duration(seconds: 5));

      int total = (rows as List).length;
      int completed = rows.where((r) => r['is_completed'] == true).length;

      return _ChecklistData(total: total, completed: completed);
    } catch (_) {
      return _ChecklistData(total: 0, completed: 0);
    }
  }

  // ── Payments (project_payments) ─────────────────────────────────────────────

  Future<_PaymentData> _fetchPayments(String projectId) async {
    try {
      final rows = await _client
          .from('project_payments')
          .select('amount, status')
          .eq('project_id', projectId)
          .timeout(const Duration(seconds: 5));

      double totalReceived = 0.0;
      double pending = 0.0;

      for (final p in (rows as List)) {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        final status = p['status'] as String? ?? '';
        if (status == 'paid' || status == 'received' || status == 'completed') {
          totalReceived += amount;
        } else {
          pending += amount;
        }
      }

      return _PaymentData(totalReceived: totalReceived, pending: pending);
    } catch (_) {
      return _PaymentData(totalReceived: 0, pending: 0);
    }
  }

  // ── 7-day daily progress ──────────────────────────────────────────────────

  Future<List<int>> _fetchWeeklyProgress(String projectId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));
      final weekAgoStr = weekAgo.toIso8601String().substring(0, 10);

      final rows = await _client
          .from('daily_progress')
          .select('date')
          .eq('project_id', projectId)
          .gte('date', weekAgoStr)
          .order('date', ascending: true)
          .timeout(const Duration(seconds: 5));

      final Map<String, int> countsByDate = {};
      for (final r in (rows as List)) {
        final d = r['date'] as String;
        countsByDate[d] = (countsByDate[d] ?? 0) + 1;
      }

      final List<int> result = [];
      for (int i = 0; i < 7; i++) {
        final day = weekAgo.add(Duration(days: i));
        final dayStr = day.toIso8601String().substring(0, 10);
        result.add(countsByDate[dayStr] ?? 0);
      }
      return result;
    } catch (_) {
      return List.filled(7, 0);
    }
  }

  // ── Recent activity (scoped to project entity) ────────────────────────────

  Future<List<ProjectDashboardActivity>> _fetchRecentActivity(
    String projectId,
  ) async {
    try {
      final rows = await _client
          .from('activities')
          .select()
          .eq('entity_id', projectId)
          .order('created_at', ascending: false)
          .limit(5)
          .timeout(const Duration(seconds: 5));

      return (rows as List).map((r) {
        final actionType = r['action_type'] as String? ?? 'unknown';
        final entityType = r['entity_type'] as String? ?? 'Item';
        final details = r['details'] as Map<String, dynamic>? ?? {};

        String title = '${_actionVerb(actionType)} $entityType';
        String subtitle =
            details['name'] as String? ?? details['item_name'] as String? ?? '';
        String type =
            actionType.contains('delete') || actionType.contains('archived')
            ? 'delete'
            : actionType.contains('add') || actionType.contains('created')
            ? 'add'
            : actionType.contains('update')
            ? 'edit'
            : 'info';

        return ProjectDashboardActivity(
          title: title,
          subtitle: subtitle,
          type: type,
          timestamp:
              DateTime.tryParse(r['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<double?> _fetchPhysicalProgress(String projectId) async {
    try {
      final rows = await _client
          .from('daily_progress')
          .select('progress_percentage')
          .eq('project_id', projectId)
          .order('created_at', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 5));

      if ((rows as List).isNotEmpty) {
        return (rows.first['progress_percentage'] as num?)?.toDouble();
      }
    } catch (_) {}
    return null;
  }

  Future<int> _fetchMaterialsCount(String projectId) async {
    try {
      final rows = await _client
          .from('inventory')
          .select('id')
          .eq('project_id', projectId)
          .timeout(const Duration(seconds: 3));
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchSnagsCount(String projectId) async {
    try {
      final rows = await _client
          .from('snag_items')
          .select('id')
          .eq('project_id', projectId)
          .neq('status', 'closed')
          .timeout(const Duration(seconds: 3));
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<ProjectMilestoneStage>> _fetchMilestones(
    String projectId,
    Map<String, dynamic>? project,
    double overallProgress,
  ) async {
    try {
      final rows = await _client
          .from('project_checklists')
          .select('phase_group, item_text, is_completed, due_date')
          .eq('project_id', projectId)
          .timeout(const Duration(seconds: 4));

      if ((rows as List).isNotEmpty) {
        final Map<String, List<Map<String, dynamic>>> groups = {};
        for (final r in rows) {
          final groupName = (r['phase_group'] as String?)?.trim();
          final name = (groupName != null && groupName.isNotEmpty)
              ? groupName
              : ((r['item_text'] as String?) ?? 'Site Inspection Phase');
          groups.putIfAbsent(name, () => []).add(r);
        }

        final List<ProjectMilestoneStage> list = [];
        for (final entry in groups.entries) {
          final items = entry.value;
          final total = items.length;
          final done = items.where((i) => i['is_completed'] == true).length;
          final pct = total > 0 ? (done / total) : 0.0;
          final status = pct >= 1.0
              ? 'Completed'
              : (pct > 0.0 ? 'In Progress' : 'Scheduled');

          String dates = 'Target: Active Schedule';
          final dueDates = items
              .map((i) => i['due_date'] as String?)
              .where((d) => d != null && d.isNotEmpty)
              .toList();
          if (dueDates.isNotEmpty) {
            dates = 'Due: ${dueDates.first}';
          }

          list.add(
            ProjectMilestoneStage(
              name: entry.key,
              status: status,
              pct: pct,
              dates: dates,
            ),
          );
        }
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {}

    // Dynamic milestone projection derived strictly from actual project properties
    final startDate = project?['start_date'] as String? ?? 'Site Inception';
    final targetDate = project?['expected_completion'] as String? ?? 'Handover';
    final p = overallProgress.clamp(0.0, 100.0);

    return [
      ProjectMilestoneStage(
        name: 'Site Prep, Survey & Excavation',
        status: p >= 25 ? 'Completed' : (p > 0 ? 'In Progress' : 'Scheduled'),
        pct: p >= 25 ? 1.0 : (p / 25).clamp(0.0, 1.0),
        dates: 'Start: $startDate',
      ),
      ProjectMilestoneStage(
        name: 'Substructure & Structural Works',
        status: p >= 50 ? 'Completed' : (p > 25 ? 'In Progress' : 'Scheduled'),
        pct: p >= 50 ? 1.0 : (p > 25 ? (p - 25) / 25 : 0.0).clamp(0.0, 1.0),
        dates: 'Phase Execution',
      ),
      ProjectMilestoneStage(
        name: 'Masonry, MEP & Core Infrastructure',
        status: p >= 75 ? 'Completed' : (p > 50 ? 'In Progress' : 'Scheduled'),
        pct: p >= 75 ? 1.0 : (p > 50 ? (p - 50) / 25 : 0.0).clamp(0.0, 1.0),
        dates: 'Services & Enclosure',
      ),
      ProjectMilestoneStage(
        name: 'Finishing, Testing & Client Handover',
        status: p >= 100 ? 'Completed' : (p > 75 ? 'In Progress' : 'Upcoming'),
        pct: p >= 100 ? 1.0 : (p > 75 ? (p - 75) / 25 : 0.0).clamp(0.0, 1.0),
        dates: 'Target: $targetDate',
      ),
    ];
  }

  String _actionVerb(String actionType) {
    if (actionType.contains('created') || actionType.contains('added')) {
      return 'Added';
    }
    if (actionType.contains('updated')) return 'Updated';
    if (actionType.contains('deleted')) return 'Removed';
    if (actionType.contains('archived')) return 'Archived';
    return 'Activity on';
  }
}

// ── Private data containers ─────────────────────────────────────────────────

class _AttendanceData {
  final int present;
  final int total;
  _AttendanceData({required this.present, required this.total});
}

class _ExpenseData {
  final double total;
  final List<ProjectExpenseCategory> breakdown;
  _ExpenseData({required this.total, required this.breakdown});
}

class _ChecklistData {
  final int total;
  final int completed;
  _ChecklistData({required this.total, required this.completed});
}

class _PaymentData {
  final double totalReceived;
  final double pending;
  _PaymentData({required this.totalReceived, required this.pending});
}
