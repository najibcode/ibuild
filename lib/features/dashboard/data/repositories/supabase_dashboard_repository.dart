import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_stats_model.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient _client;

  SupabaseDashboardRepository(this._client);

  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Run all queries concurrently with individual safe fallbacks
      final results = await Future.wait([
        _fetchProjects().catchError((e) {
          debugPrint('Dashboard _fetchProjects error: $e');
          return _fallbackProjects();
        }), // 0
        _fetchAttendance().catchError((e) => _AttendanceData(present: 0)), // 1
        _fetchEmployees().catchError((e) => _fallbackEmployeeCount()), // 2
        _fetchExpenses().catchError((e) => 0.0), // 3
        _fetchBills().catchError((e) => 0.0), // 4
        _fetchInventoryData().catchError((e) => _InventoryData(lowStockCount: 0, alerts: [])), // 5
        _fetchWeeklyProgress().catchError((e) => [0, 0, 0, 0, 0, 0, 0]), // 6
        _fetchRecentActivity().catchError((e) => <RecentActivity>[]), // 7
        _fetchLatestProject().catchError((e) => null), // 8
        _fetchTotalSpentAllTime().catchError((e) => 0.0), // 9
        _fetchMonthlyTrends().catchError((e) => <MonthlyProgressTrendPoint>[]), // 10
      ]);

      final projectData = results[0] as _ProjectData;
      final attendanceData = results[1] as _AttendanceData;
      final employeeCount = results[2] as int;
      final expenseTotal = results[3] as double;
      final pendingBillsTotal = results[4] as double;
      final inventoryData = results[5] as _InventoryData;
      final weeklyCounts = results[6] as List<int>;
      final recentActivities = results[7] as List<RecentActivity>;
      final latestProject = results[8] as QuickAccessProject?;
      final totalSpentAllTime = results[9] as double;
      final monthlyTrends = results[10] as List<MonthlyProgressTrendPoint>;

      final effectiveTotalSpent = totalSpentAllTime > 0
          ? totalSpentAllTime
          : (expenseTotal > 0 ? expenseTotal : projectData.totalSpent);

      // Build Attention Alerts
      final List<AttentionAlert> attentionAlerts = [];
      final now = DateTime.now();

      for (final p in projectData.portfolioProjects) {
        if (p.variancePct > 15.0) {
          attentionAlerts.add(
            AttentionAlert(
              projectId: p.id,
              projectName: p.name,
              title: 'High Financial Variance',
              message:
                  'Budget consumption is ${p.variancePct.toStringAsFixed(0)}% ahead of physical progress.',
              severity: 'critical',
              alertType: 'budget_variance',
            ),
          );
        } else if (p.status == 'delayed') {
          attentionAlerts.add(
            AttentionAlert(
              projectId: p.id,
              projectName: p.name,
              title: 'Schedule Delayed',
              message: 'Project timeline is currently behind schedule.',
              severity: 'warning',
              alertType: 'delayed',
            ),
          );
        } else if (p.status == 'at_risk') {
          attentionAlerts.add(
            AttentionAlert(
              projectId: p.id,
              projectName: p.name,
              title: 'Project At Risk',
              message: 'Project is flagged requiring owner/admin attention.',
              severity: 'critical',
              alertType: 'at_risk',
            ),
          );
        }

        if (p.status == 'active' && p.lastProgressDate != null) {
          final diffDays = now.difference(p.lastProgressDate!).inDays;
          if (diffDays >= 3) {
            attentionAlerts.add(
              AttentionAlert(
                projectId: p.id,
                projectName: p.name,
                title: 'Stale Progress Log',
                message: 'No daily progress update recorded for $diffDays days.',
                severity: 'warning',
                alertType: 'no_update',
              ),
            );
          }
        }
      }

      return DashboardStats(
        totalProjects: projectData.total,
        activeProjects: projectData.active,
        completedProjects: projectData.completed,
        delayedProjects: projectData.delayed,
        planningProjects: projectData.planning,
        atRiskCount: projectData.atRiskCount,
        totalBudget: projectData.totalBudget,
        totalSpent: effectiveTotalSpent,
        employeesPresent: attendanceData.present,
        totalEmployees: employeeCount,
        monthlyExpense: expenseTotal > 0 ? expenseTotal : effectiveTotalSpent,
        pendingBills: pendingBillsTotal,
        lowStockItems: inventoryData.lowStockCount,
        weeklyProgressCounts: weeklyCounts,
        recentActivities: recentActivities,
        latestProject: latestProject ??
            (projectData.portfolioProjects.isNotEmpty
                ? QuickAccessProject(
                    id: projectData.portfolioProjects.first.id,
                    name: projectData.portfolioProjects.first.name,
                    status: projectData.portfolioProjects.first.status,
                    budget: projectData.portfolioProjects.first.budget,
                    spent: projectData.portfolioProjects.first.spent,
                  )
                : null),
        inventoryAlerts: inventoryData.alerts,
        portfolioProjects: projectData.portfolioProjects,
        progressTrends: monthlyTrends,
        attentionAlerts: attentionAlerts,
      );
    } catch (e) {
      debugPrint('Dashboard stats top-level error: $e');
      final fallbackProj = _fallbackProjects();
      return DashboardStats(
        totalProjects: fallbackProj.total,
        activeProjects: fallbackProj.active,
        completedProjects: fallbackProj.completed,
        delayedProjects: fallbackProj.delayed,
        planningProjects: fallbackProj.planning,
        atRiskCount: fallbackProj.atRiskCount,
        totalBudget: fallbackProj.totalBudget,
        totalSpent: fallbackProj.totalSpent,
        employeesPresent: 0,
        totalEmployees: _fallbackEmployeeCount(),
        monthlyExpense: fallbackProj.totalSpent,
        pendingBills: 0.0,
        lowStockItems: 0,
        weeklyProgressCounts: const [0, 0, 0, 0, 0, 0, 0],
        recentActivities: const [],
        latestProject: null,
        inventoryAlerts: const [],
        portfolioProjects: fallbackProj.portfolioProjects,
        progressTrends: const [],
        attentionAlerts: const [],
      );
    }
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  Future<_ProjectData> _fetchProjects() async {
    final cache = OfflineDataCache();
    final cached = cache.getCachedProjects() ?? [];
    List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(cached);

    try {
      final remoteRows = await _client
          .from('projects')
          .select('id, name, status, budget, spent, is_archived');
      // Canonical ground truth from Supabase — purge deleted projects from dashboard cache
      rows = List<Map<String, dynamic>>.from(remoteRows);
      cache.cacheProjects(rows);
    } catch (e) {
      debugPrint('Supabase projects query note: $e');
    }

    // Fetch latest daily progress entries to compute physical progress %
    final Map<String, ({double pct, DateTime date})> latestProgressByProject = {};
    try {
      final progressRows = await _client
          .from('daily_progress')
          .select('project_id, progress_percentage, date')
          .order('date', ascending: false);

      for (final pr in progressRows) {
        final pid = pr['project_id'] as String?;
        if (pid != null && !latestProgressByProject.containsKey(pid)) {
          final pct = (pr['progress_percentage'] as num? ?? 0).toDouble();
          final dt = DateTime.tryParse(pr['date'] as String? ?? '') ?? DateTime.now();
          latestProgressByProject[pid] = (pct: pct, date: dt);
        }
      }
    } catch (_) {}

    int total = 0;
    int active = 0, completed = 0, delayed = 0, planning = 0, atRiskCount = 0;
    double totalBudget = 0.0, totalSpent = 0.0;
    final List<PortfolioProjectItem> portfolioProjects = [];

    for (final p in rows) {
      final isArchived = p['is_archived'] as bool? ?? false;
      if (isArchived) continue;

      total++;
      final id = p['id']?.toString() ?? '';
      final name = p['name'] as String? ?? 'Site Project';
      final status = (p['status'] as String? ?? 'active').toLowerCase().trim();
      final budget = (p['budget'] as num? ?? 0).toDouble();
      final spent = (p['spent'] as num? ?? 0).toDouble();

      if (status == 'active') active++;
      if (status == 'completed') completed++;
      if (status == 'delayed') delayed++;
      if (status == 'planning') planning++;

      totalBudget += budget;
      totalSpent += spent;

      // Determine physical progress
      final latestPr = latestProgressByProject[id];
      double physicalProgress = latestPr?.pct ?? 0.0;
      if (status == 'completed') {
        physicalProgress = 100.0;
      } else if (latestPr == null && status == 'active') {
        physicalProgress = budget > 0 ? (spent / budget * 100).clamp(0.0, 100.0) : 0.0;
      }

      final item = PortfolioProjectItem(
        id: id,
        name: name,
        status: status,
        budget: budget,
        spent: spent,
        physicalProgress: physicalProgress,
        lastProgressDate: latestPr?.date,
      );

      portfolioProjects.add(item);

      if (item.isAtRisk) {
        atRiskCount++;
      }
    }

    portfolioProjects.sort((a, b) {
      if (a.isAtRisk != b.isAtRisk) {
        return a.isAtRisk ? -1 : 1;
      }
      return a.physicalProgress.compareTo(b.physicalProgress);
    });

    return _ProjectData(
      total: total,
      active: active,
      completed: completed,
      delayed: delayed,
      planning: planning,
      atRiskCount: atRiskCount,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      portfolioProjects: portfolioProjects,
    );
  }

  _ProjectData _fallbackProjects() {
    final cached = OfflineDataCache().getCachedProjects() ?? [];
    int total = 0, active = 0, completed = 0, delayed = 0, planning = 0, atRiskCount = 0;
    double totalBudget = 0.0, totalSpent = 0.0;
    final List<PortfolioProjectItem> portfolioProjects = [];

    for (final p in cached) {
      if (p['is_archived'] == true) continue;
      total++;
      final id = p['id']?.toString() ?? '';
      final name = p['name'] as String? ?? 'Site Project';
      final status = (p['status'] as String? ?? 'active').toLowerCase().trim();
      final budget = (p['budget'] as num? ?? 0).toDouble();
      final spent = (p['spent'] as num? ?? 0).toDouble();

      if (status == 'active') active++;
      if (status == 'completed') completed++;
      if (status == 'delayed') delayed++;
      if (status == 'planning') planning++;

      totalBudget += budget;
      totalSpent += spent;

      portfolioProjects.add(PortfolioProjectItem(
        id: id,
        name: name,
        status: status,
        budget: budget,
        spent: spent,
        physicalProgress: budget > 0 ? (spent / budget * 100).clamp(0.0, 100.0) : 0.0,
      ));
    }

    return _ProjectData(
      total: total,
      active: active,
      completed: completed,
      delayed: delayed,
      planning: planning,
      atRiskCount: atRiskCount,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      portfolioProjects: portfolioProjects,
    );
  }

  // ── Attendance (today) ────────────────────────────────────────────────────

  Future<_AttendanceData> _fetchAttendance() async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final rows = await _client
          .from('attendance')
          .select('morning_status')
          .eq('date', todayStr);

      int present = 0;
      for (final a in rows) {
        if (a['morning_status'] == 'present') present++;
      }

      return _AttendanceData(present: present);
    } catch (_) {
      final cached = OfflineDataCache().getCachedAttendanceForDate(todayStr);
      if (cached != null) {
        int present = cached.where((a) => a['morning_status'] == 'present').length;
        return _AttendanceData(present: present);
      }
      return _AttendanceData(present: 0);
    }
  }

  // ── Employees count ───────────────────────────────────────────────────────

  Future<int> _fetchEmployees() async {
    try {
      final rows = await _client.from('employees').select('id');
      return rows.length;
    } catch (_) {}
    return _fallbackEmployeeCount();
  }

  int _fallbackEmployeeCount() {
    final cached = OfflineDataCache().getCachedEmployees();
    return cached?.length ?? 0;
  }

  // ── Expenses ──────────────────────────────────────────────────────────────

  Future<double> _fetchExpenses() async {
    try {
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
    } catch (_) {
      return 0.0;
    }
  }

  Future<double> _fetchTotalSpentAllTime() async {
    try {
      final rows = await _client.from('expenses').select('amount');
      double total = 0.0;
      for (final e in rows) {
        total += (e['amount'] as num? ?? 0).toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  // ── Pending bills ─────────────────────────────────────────────────────────

  Future<double> _fetchBills() async {
    try {
      final rows = await _client
          .from('bills')
          .select('amount')
          .eq('status', 'pending');

      double total = 0.0;
      for (final b in rows) {
        total += (b['amount'] as num? ?? 0).toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  // ── Inventory Data ────────────────────────────────────────────────────────

  Future<_InventoryData> _fetchInventoryData() async {
    try {
      final rows = await _client.from('inventory').select();
      final List<DashboardInventoryAlert> alerts = [];

      for (final r in rows) {
        final current = (r['current_quantity'] as num? ?? 0).toDouble();
        final minQty = (r['minimum_threshold'] as num? ?? 0).toDouble();
        if (current <= minQty && minQty > 0) {
          alerts.add(
            DashboardInventoryAlert(
              id: r['id'] as String,
              itemName: r['item_name'] as String? ?? 'Item',
              currentQuantity: current,
              minQuantity: minQty,
              unit: r['unit'] as String? ?? 'units',
            ),
          );
        }
      }

      return _InventoryData(
        lowStockCount: alerts.length,
        alerts: alerts,
      );
    } catch (_) {
      final cached = OfflineDataCache().getCachedInventory() ?? [];
      final List<DashboardInventoryAlert> alerts = [];
      for (final r in cached) {
        final current = (r['current_quantity'] as num? ?? 0).toDouble();
        final minQty = (r['minimum_threshold'] as num? ?? 0).toDouble();
        if (current <= minQty && minQty > 0) {
          alerts.add(
            DashboardInventoryAlert(
              id: r['id']?.toString() ?? '',
              itemName: r['item_name'] as String? ?? 'Item',
              currentQuantity: current,
              minQuantity: minQty,
              unit: r['unit'] as String? ?? 'units',
            ),
          );
        }
      }
      return _InventoryData(lowStockCount: alerts.length, alerts: alerts);
    }
  }

  // ── Weekly progress (last 7 days) ─────────────────────────────────────────

  Future<List<int>> _fetchWeeklyProgress() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));
      final weekAgoStr = weekAgo.toIso8601String().substring(0, 10);

      final rows = await _client
          .from('daily_progress')
          .select('date')
          .gte('date', weekAgoStr)
          .order('date', ascending: true);

      final Map<String, int> countsByDate = {};
      for (final r in rows) {
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
      return [0, 0, 0, 0, 0, 0, 0];
    }
  }

  // ── Monthly Progress Trends (Last 6 Months) ───────────────────────────────

  Future<List<MonthlyProgressTrendPoint>> _fetchMonthlyTrends() async {
    final List<MonthlyProgressTrendPoint> points = [];
    final now = DateTime.now();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    try {
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final sixMonthsAgoStr = sixMonthsAgo.toIso8601String().substring(0, 10);

      final rows = await _client
          .from('daily_progress')
          .select('progress_percentage, date')
          .gte('date', sixMonthsAgoStr);

      final Map<String, List<double>> monthProgressValues = {};

      for (final r in rows) {
        final dt = DateTime.tryParse(r['date'] as String? ?? '');
        if (dt != null) {
          final monthKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          final pct = (r['progress_percentage'] as num? ?? 0).toDouble();
          monthProgressValues.putIfAbsent(monthKey, () => []).add(pct);
        }
      }

      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final monthKey = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        final label = monthNames[d.month - 1];
        final vals = monthProgressValues[monthKey];

        double avg = 0.0;
        if (vals != null && vals.isNotEmpty) {
          avg = vals.reduce((a, b) => a + b) / vals.length;
        }

        points.add(MonthlyProgressTrendPoint(
          label: label,
          averageProgress: avg,
        ));
      }
    } catch (_) {
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        points.add(MonthlyProgressTrendPoint(
          label: monthNames[d.month - 1],
          averageProgress: 0.0,
        ));
      }
    }

    return points;
  }

  // ── Recent activity ───────────────────────────────────────────────────────

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
          }
        } else if (actionType.contains('updated')) {
          title = 'Updated $entityType';
          type = 'edit';
          if (details.containsKey('name')) {
            subtitle = 'By $userName — ${details['name']}';
          }
        } else if (actionType.contains('deleted')) {
          title = 'Removed $entityType';
          type = 'delete';
        }

        activities.add(RecentActivity(
          type: type,
          title: title,
          subtitle: subtitle,
          timestamp: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          entityId: r['entity_id'] as String?,
        ));
      }
    } catch (_) {}

    return activities;
  }

  // ── Latest active project ──────────────────────────────────────────────────

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
      final cached = OfflineDataCache().getCachedProjects() ?? [];
      if (cached.isNotEmpty) {
        final p = cached.first;
        return QuickAccessProject(
          id: p['id']?.toString() ?? '',
          name: p['name'] as String? ?? 'Site Project',
          status: p['status'] as String? ?? 'active',
          budget: (p['budget'] as num? ?? 0).toDouble(),
          spent: (p['spent'] as num? ?? 0).toDouble(),
        );
      }
      return null;
    }
  }
}

// ── Private data containers ─────────────────────────────────────────────────

class _ProjectData {
  final int total, active, completed, delayed, planning, atRiskCount;
  final double totalBudget, totalSpent;
  final List<PortfolioProjectItem> portfolioProjects;

  _ProjectData({
    required this.total,
    required this.active,
    required this.completed,
    required this.delayed,
    required this.planning,
    required this.atRiskCount,
    required this.totalBudget,
    required this.totalSpent,
    required this.portfolioProjects,
  });
}

class _AttendanceData {
  final int present;
  _AttendanceData({required this.present});
}

class _InventoryData {
  final int lowStockCount;
  final List<DashboardInventoryAlert> alerts;
  _InventoryData({required this.lowStockCount, required this.alerts});
}
