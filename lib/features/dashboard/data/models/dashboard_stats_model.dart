/// Represents a single recent activity entry for the dashboard feed.
class RecentActivity {
  /// Type of activity: 'expense', 'attendance', 'bill', 'progress'
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

/// Represents the latest active project for quick access on the dashboard.
class QuickAccessProject {
  final String id;
  final String name;
  final String status;
  final double budget;
  final double spent;

  QuickAccessProject({
    required this.id,
    required this.name,
    required this.status,
    required this.budget,
    required this.spent,
  });
}

class DashboardStats {
  // Project counts
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int delayedProjects;
  final int planningProjects;

  // Attendance
  final int employeesPresent;
  final int totalEmployees;

  // Financial
  final double totalBudget;
  final double totalSpent;
  final double monthlyExpense;
  final double pendingBills;

  // Inventory
  final int lowStockItems;

  // Velocity chart — count of daily_progress entries per day for last 7 days
  final List<int> weeklyProgressCounts;

  // Recent activity feed
  final List<RecentActivity> recentActivities;

  // Quick access — latest active project
  final QuickAccessProject? latestProject;

  DashboardStats({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.delayedProjects,
    required this.planningProjects,
    required this.employeesPresent,
    required this.totalEmployees,
    required this.totalBudget,
    required this.totalSpent,
    required this.monthlyExpense,
    required this.pendingBills,
    required this.lowStockItems,
    required this.weeklyProgressCounts,
    required this.recentActivities,
    this.latestProject,
  });

  /// Convenience: budget utilization percentage (0–100+).
  double get budgetUtilizationPct =>
      totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;

  /// Convenience: attendance percentage (0–100).
  double get attendancePct =>
      totalEmployees > 0 ? (employeesPresent / totalEmployees * 100) : 0.0;

  factory DashboardStats.empty() {
    return DashboardStats(
      totalProjects: 0,
      activeProjects: 0,
      completedProjects: 0,
      delayedProjects: 0,
      planningProjects: 0,
      employeesPresent: 0,
      totalEmployees: 0,
      totalBudget: 0.0,
      totalSpent: 0.0,
      monthlyExpense: 0.0,
      pendingBills: 0.0,
      lowStockItems: 0,
      weeklyProgressCounts: List.filled(7, 0),
      recentActivities: [],
      latestProject: null,
    );
  }
}
