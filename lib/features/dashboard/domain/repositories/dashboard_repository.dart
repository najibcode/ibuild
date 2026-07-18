import '../models/dashboard_stats_model.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getDashboardStats();
}
