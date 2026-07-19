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
      // 1. Projects statistics
      final projectsResponse = await _client.from('projects').select('status');
      int total = projectsResponse.length;
      int active = projectsResponse.where((p) => p['status'] == 'active').length;
      int completed = projectsResponse.where((p) => p['status'] == 'completed').length;

      // 2. Attendance count today
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final attendanceResponse = await _client
          .from('attendance')
          .select()
          .eq('date', todayStr)
          .eq('morning_status', 'present');
      int present = attendanceResponse.length;

      // 3. Expenses & bills statistics
      final expensesResponse = await _client.from('expenses').select();
      double monthlyExpense = 0.0;
      for (var exp in expensesResponse) {
        monthlyExpense += (exp['amount'] as num? ?? 0).toDouble();
      }

      final billsResponse = await _client.from('bills').select();
      double pendingBills = 0.0;
      for (var bill in billsResponse) {
        if (bill['status'] == 'pending') {
          pendingBills += (bill['amount'] as num? ?? 0).toDouble();
        }
      }

      // 4. Low stock inventory items
      final inventoryResponse = await _client.from('inventory').select();
      int lowStock = (inventoryResponse as List)
          .map((j) => InventoryItem.fromJson(j))
          .where((i) => i.isLowStock)
          .length;

      return DashboardStats(
        totalProjects: total,
        activeProjects: active,
        completedProjects: completed,
        employeesPresent: present,
        lowStockItems: lowStock,
        monthlyExpense: monthlyExpense,
        pendingBills: pendingBills,
      );
    } catch (e) {
      return DashboardStats(
        totalProjects: 0,
        activeProjects: 0,
        completedProjects: 0,
        employeesPresent: 0,
        lowStockItems: 0,
        monthlyExpense: 0.0,
        pendingBills: 0.0,
      );
    }
  }
}
