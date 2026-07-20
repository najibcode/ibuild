import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_stats_model.dart';
import '../../../inventory/data/models/inventory_item_model.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient _client;

  SupabaseDashboardRepository(this._client);

  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Run all queries concurrently for speed.
      final results = await Future.wait([
        _fetchProjects(),       // 0
        _fetchAttendance(),     // 1
        _fetchEmployees(),      // 2
        _fetchExpenses(),       // 3
        _fetchBills(),          // 4
        _fetchInventory(),      // 5
        _fetchWeeklyProgress(), // 6
        _fetchRecentActivity(), // 7
        _fetchLatestProject(),  // 8
      ]);

      final projectData = results[0] as _ProjectData;
      final attendanceData = results[1] as _AttendanceData;
      final employeeCount = results[2] as int;
      final expenseTotal = results[3] as double;
      final pendingBillsTotal = results[4] as double;
      final lowStockCount = results[5] as int;
      final weeklyCounts = results[6] as List<int>;
      final recentActivities = results[7] as List<RecentActivity>;
      final latestProject = results[8] as QuickAccessProject?;

      return DashboardStats(
        totalProjects: projectData.total,
        activeProjects: projectData.active,
        completedProjects: projectData.completed,
        delayedProjects: projectData.delayed,
        planningProjects: projectData.planning,
        totalBudget: projectData.totalBudget,
        totalSpent: projectData.totalSpent,
        employeesPresent: attendanceData.present,
        totalEmployees: employeeCount,
        monthlyExpense: expenseTotal,
        pendingBills: pendingBillsTotal,
        lowStockItems: lowStockCount,
        weeklyProgressCounts: weeklyCounts,
        recentActivities: recentActivities,
        latestProject: latestProject,
      );
    } catch (e) {
      // Return empty stats so the UI still renders gracefully.
      return DashboardStats.empty();
    }
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  Future<_ProjectData> _fetchProjects() async {
    final rows = await _client
        .from('projects')
        .select('status, budget, spent');

    int total = rows.length;
    int active = 0, completed = 0, delayed = 0, planning = 0;
    double totalBudget = 0.0, totalSpent = 0.0;

    for (final p in rows) {
      final status = p['status'] as String? ?? '';
      if (status == 'active') active++;
      if (status == 'completed') completed++;
      if (status == 'delayed') delayed++;
      if (status == 'planning') planning++;
      totalBudget += (p['budget'] as num? ?? 0).toDouble();
      totalSpent += (p['spent'] as num? ?? 0).toDouble();
    }

    return _ProjectData(
      total: total,
      active: active,
      completed: completed,
      delayed: delayed,
      planning: planning,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
    );
  }

  // ── Attendance (today) ────────────────────────────────────────────────────

  Future<_AttendanceData> _fetchAttendance() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _client
        .from('attendance')
        .select('morning_status')
        .eq('date', todayStr);

    int present = 0;
    for (final a in rows) {
      if (a['morning_status'] == 'present') present++;
    }

    return _AttendanceData(present: present);
  }

  // ── Employees count ───────────────────────────────────────────────────────

  Future<int> _fetchEmployees() async {
    final rows = await _client
        .from('employees')
        .select('id')
        .eq('status', 'active');
    return rows.length;
  }

  // ── Expenses (current month total) ────────────────────────────────────────

  Future<double> _fetchExpenses() async {
    final now = DateTime.now();
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final rows = await _client
        .from('expenses')
        .select('amount')
        .gte('expense_date', monthStart);

    double total = 0.0;
    for (final e in rows) {
      total += (e['amount'] as num? ?? 0).toDouble();
    }
    return total;
  }

  // ── Pending bills ─────────────────────────────────────────────────────────

  Future<double> _fetchBills() async {
    final rows = await _client
        .from('bills')
        .select('amount')
        .eq('status', 'pending');

    double total = 0.0;
    for (final b in rows) {
      total += (b['amount'] as num? ?? 0).toDouble();
    }
    return total;
  }

  // ── Inventory — low stock count ───────────────────────────────────────────

  Future<int> _fetchInventory() async {
    final rows = await _client.from('inventory').select();
    return (rows as List)
        .map((j) => InventoryItem.fromJson(j))
        .where((i) => i.isLowStock)
        .length;
  }

  // ── Weekly progress (last 7 days) ─────────────────────────────────────────

  Future<List<int>> _fetchWeeklyProgress() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final weekAgoStr = weekAgo.toIso8601String().substring(0, 10);

    final rows = await _client
        .from('daily_progress')
        .select('date')
        .gte('date', weekAgoStr)
        .order('date', ascending: true);

    // Build a map: date string → count
    final Map<String, int> countsByDate = {};
    for (final r in rows) {
      final d = r['date'] as String;
      countsByDate[d] = (countsByDate[d] ?? 0) + 1;
    }

    // Generate ordered list for last 7 days
    final List<int> result = [];
    for (int i = 0; i < 7; i++) {
      final day = weekAgo.add(Duration(days: i));
      final dayStr = day.toIso8601String().substring(0, 10);
      result.add(countsByDate[dayStr] ?? 0);
    }
    return result;
  }

  // ── Recent activity (from new activities table) ───────────────────────────

  Future<List<RecentActivity>> _fetchRecentActivity() async {
    final List<RecentActivity> activities = [];
    try {
      final rows = await _client
          .from('activities')
          .select('*, profiles(company_name)')
          .order('created_at', ascending: false)
          .limit(10);

      for (final r in rows) {
        final profile = r['profiles'] as Map<String, dynamic>?;
        final userName = profile != null ? profile['company_name'] : 'System';
        final actionType = r['action_type'] as String? ?? 'unknown';
        final entityType = r['entity_type'] as String? ?? 'Unknown';
        final details = r['details'] as Map<String, dynamic>? ?? {};
        
        // Build readable title and subtitle
        String title = 'Activity';
        String subtitle = 'By $userName';
        String type = 'info';

        if (actionType.contains('added') || actionType.contains('created')) {
          title = 'Added $entityType';
          type = 'add';
          if (details.containsKey('name')) {
            subtitle = 'By $userName — ${details['name']}';
          } else if (details.containsKey('item_name')) {
            subtitle = 'By $userName — ${details['item_name']}';
          } else if (details.containsKey('bill_number')) {
            subtitle = 'By $userName — #${details['bill_number']} (₹${details['amount'] ?? ''})';
          } else if (details.containsKey('category') && details.containsKey('amount')) {
            subtitle = 'By $userName — ${details['category']} (₹${details['amount']})';
          }
        } else if (actionType.contains('updated')) {
          title = 'Updated $entityType';
          type = 'edit';
          if (details.containsKey('name')) {
            subtitle = 'By $userName — ${details['name']}';
          } else if (details.containsKey('item_name')) {
            subtitle = 'By $userName — ${details['item_name']}';
          } else if (details.containsKey('bill_number')) {
            subtitle = 'By $userName — #${details['bill_number']} → ${details['status'] ?? ''}';
          } else if (details.containsKey('morning_status')) {
            final empName = details['employee_name'] ?? '';
            subtitle = 'By $userName — $empName: ${details['morning_status']}/${details['evening_status']}';
          } else if (details.containsKey('progress_percentage')) {
            subtitle = 'By $userName — ${details['progress_percentage']}% complete';
          }
        } else if (actionType.contains('deleted') || actionType.contains('archived')) {
          title = 'Removed $entityType';
          type = 'delete';
          if (details.containsKey('name')) {
            subtitle = 'By $userName — ${details['name']}';
          }
        } else if (actionType.startsWith('inventory_')) {
          title = 'Inventory ${actionType.split('_').last}';
          type = 'inventory';
          if (details.containsKey('quantity_change')) {
            subtitle = 'By $userName — Qty Change: ${details['quantity_change']}';
          }
        }

        activities.add(RecentActivity(
          type: type,
          title: title,
          subtitle: subtitle,
          timestamp: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    } catch (e) {
      print('Dashboard RecentActivity fetch error: $e');
    }

    return activities;
  }

  // ── Latest active project for quick access ────────────────────────────────

  Future<QuickAccessProject?> _fetchLatestProject() async {
    try {
      final rows = await _client
          .from('projects')
          .select('id, name, status, budget, spent')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return null;

      final p = rows.first;
      return QuickAccessProject(
        id: p['id'] as String,
        name: p['name'] as String,
        status: p['status'] as String,
        budget: (p['budget'] as num? ?? 0).toDouble(),
        spent: (p['spent'] as num? ?? 0).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

}

// ── Private data containers ─────────────────────────────────────────────────

class _ProjectData {
  final int total, active, completed, delayed, planning;
  final double totalBudget, totalSpent;

  _ProjectData({
    required this.total,
    required this.active,
    required this.completed,
    required this.delayed,
    required this.planning,
    required this.totalBudget,
    required this.totalSpent,
  });
}

class _AttendanceData {
  final int present;
  _AttendanceData({required this.present});
}
