import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_dashboard_model.dart';

/// Fetches all per-project dashboard data from Supabase in parallel safely.
class ProjectDashboardRepository {
  final SupabaseClient _client;

  ProjectDashboardRepository(this._client);

  Future<ProjectDashboardStats> fetchDashboard(String projectId) async {
    try {
      final results = await Future.wait([
        _fetchProject(projectId),          // 0
        _fetchAttendance(projectId),       // 1
        _fetchExpenses(projectId),         // 2
        _fetchChecklist(projectId),        // 3
        _fetchPayments(projectId),         // 4
        _fetchWeeklyProgress(projectId),   // 5
        _fetchRecentActivity(projectId),   // 6
      ]);

      final project = results[0] as Map<String, dynamic>?;
      final attendance = results[1] as _AttendanceData;
      final expenses = results[2] as _ExpenseData;
      final checklist = results[3] as _ChecklistData;
      final payments = results[4] as _PaymentData;
      final weekly = results[5] as List<int>;
      final activities = results[6] as List<ProjectDashboardActivity>;

      return ProjectDashboardStats(
        projectId: projectId,
        projectName: project?['name'] as String? ?? 'Project Dashboard',
        status: project?['status'] as String? ?? 'planning',
        clientName: project?['client_name'] as String?,
        customerName: project?['customer_name'] as String?,
        startDate: project?['start_date'] as String?,
        expectedCompletion: project?['expected_completion'] as String?,
        address: project?['address'] as String?,
        imageUrl: project?['image_url'] as String?,
        budget: (project?['budget'] as num?)?.toDouble() ?? 0.0,
        spent: (project?['spent'] as num?)?.toDouble() ?? 0.0,
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
      );
    } catch (e) {
      print('Error loading project dashboard stats: $e');
      return ProjectDashboardStats.empty(projectId);
    }
  }

  // ── Project core data ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _fetchProject(String projectId) async {
    try {
      return await _client
          .from('projects')
          .select()
          .eq('id', projectId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  // ── Attendance (today, scoped to project) ─────────────────────────────────

  Future<_AttendanceData> _fetchAttendance(String projectId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await _client
          .from('attendance')
          .select('morning_status')
          .eq('project_id', projectId)
          .eq('date', todayStr);

      int present = 0;
      for (final r in (rows as List)) {
        if (r['morning_status'] == 'present' ||
            r['morning_status'] == 'Present') {
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
          .eq('project_id', projectId);

      double total = 0.0;
      final Map<String, double> byCategory = {};

      for (final e in (rows as List)) {
        final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
        final category = e['category'] as String? ?? 'Other';
        total += amount;
        byCategory[category] = (byCategory[category] ?? 0.0) + amount;
      }

      final breakdown = byCategory.entries
          .map((e) => ProjectExpenseCategory(category: e.key, amount: e.value))
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
          .eq('project_id', projectId);

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
          .eq('project_id', projectId);

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
          .order('date', ascending: true);

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
          .limit(5);

      return (rows as List).map((r) {
        final actionType = r['action_type'] as String? ?? 'unknown';
        final entityType = r['entity_type'] as String? ?? 'Item';
        final details = r['details'] as Map<String, dynamic>? ?? {};

        String title = '${_actionVerb(actionType)} $entityType';
        String subtitle = details['name'] as String? ??
            details['item_name'] as String? ??
            '';
        String type = actionType.contains('delete') || actionType.contains('archived')
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
          timestamp: DateTime.tryParse(
                r['created_at'] as String? ?? '',
              ) ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String _actionVerb(String actionType) {
    if (actionType.contains('created') || actionType.contains('added')) return 'Added';
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
