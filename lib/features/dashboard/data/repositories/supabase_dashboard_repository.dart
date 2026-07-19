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

  // ── Recent activity (merged from multiple tables) ─────────────────────────

  Future<List<RecentActivity>> _fetchRecentActivity() async {
    final List<RecentActivity> activities = [];

    // Fetch last 3 expenses
    try {
      final expenses = await _client
          .from('expenses')
          .select('category, amount, expense_date, created_at, projects(name)')
          .order('created_at', ascending: false)
          .limit(3);

      for (final e in expenses) {
        final projectName = e['projects']?['name'] as String? ?? 'General';
        activities.add(RecentActivity(
          type: 'expense',
          title: 'Expense: ${e['category']}',
          subtitle: '₹${_formatNum(e['amount'])} — $projectName',
          timestamp: DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    } catch (_) {}

    // Fetch last 3 bills
    try {
      final bills = await _client
          .from('bills')
          .select('bill_number, amount, status, created_at, projects(name)')
          .order('created_at', ascending: false)
          .limit(3);

      for (final b in bills) {
        final projectName = b['projects']?['name'] as String? ?? 'Unknown';
        activities.add(RecentActivity(
          type: 'bill',
          title: 'Bill #${b['bill_number']}',
          subtitle: '₹${_formatNum(b['amount'])} — ${b['status']} — $projectName',
          timestamp: DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    } catch (_) {}

    // Fetch last 3 daily progress entries
    try {
      final progress = await _client
          .from('daily_progress')
          .select('date, progress_percentage, created_at, projects(name)')
          .order('created_at', ascending: false)
          .limit(3);

      for (final p in progress) {
        final projectName = p['projects']?['name'] as String? ?? 'Unknown';
        activities.add(RecentActivity(
          type: 'progress',
          title: 'Progress Update',
          subtitle: '$projectName — ${p['progress_percentage']}% on ${p['date']}',
          timestamp: DateTime.tryParse(p['created_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    } catch (_) {}

    // Sort all by timestamp descending, take top 5
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(5).toList();
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatNum(dynamic value) {
    final n = (value as num? ?? 0).toDouble();
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
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
