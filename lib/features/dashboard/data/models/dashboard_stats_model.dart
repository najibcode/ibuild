/// Represents a single recent activity entry for the dashboard feed.
class RecentActivity {
  /// Type of activity: 'expense', 'attendance', 'bill', 'progress'
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? entityId;

  RecentActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.entityId,
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

/// Detailed project item for overall portfolio performance & BI charts.
class PortfolioProjectItem {
  final String id;
  final String name;
  final String status; // active, completed, delayed, at_risk, planning, on_hold
  final double budget;
  final double spent;
  final double physicalProgress; // 0–100%
  final DateTime? lastProgressDate;

  PortfolioProjectItem({
    required this.id,
    required this.name,
    required this.status,
    required this.budget,
    required this.spent,
    required this.physicalProgress,
    this.lastProgressDate,
  });

  /// Budget utilization percentage (0–100%+).
  double get budgetUtilizationPct => budget > 0 ? (spent / budget * 100) : 0.0;

  /// Financial variance = Budget Used % - Physical Progress %.
  /// Positive variance indicates financial consumption is ahead of physical progress.
  double get variancePct => budgetUtilizationPct - physicalProgress;

  /// Whether this project requires attention or is at risk.
  bool get isAtRisk =>
      status == 'at_risk' || status == 'delayed' || variancePct > 15.0;

  /// Normalized status label for UI display.
  String get displayStatus {
    if (status == 'completed') return 'Completed';
    if (status == 'delayed') return 'Delayed';
    if (status == 'at_risk' || variancePct > 15.0) return 'At Risk';
    if (status == 'planning') return 'Planning';
    if (status == 'on_hold') return 'On Hold';
    return 'On Track';
  }
}

/// Represents a single monthly completion data point for portfolio trend line chart.
class MonthlyProgressTrendPoint {
  final String label; // e.g. "Apr", "May"
  final double averageProgress; // 0–100%

  MonthlyProgressTrendPoint({
    required this.label,
    required this.averageProgress,
  });
}

/// Actionable alert for Attention Required card.
class AttentionAlert {
  final String projectId;
  final String projectName;
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final String alertType; // 'budget_variance', 'delayed', 'no_update', 'inventory'

  AttentionAlert({
    required this.projectId,
    required this.projectName,
    required this.title,
    required this.message,
    required this.severity,
    required this.alertType,
  });
}

/// Low stock inventory item for Inventory Alerts section.
class DashboardInventoryAlert {
  final String id;
  final String itemName;
  final double currentQuantity;
  final double minQuantity;
  final String unit;

  DashboardInventoryAlert({
    required this.id,
    required this.itemName,
    required this.currentQuantity,
    required this.minQuantity,
    required this.unit,
  });
}

class DashboardStats {
  // Project counts
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int delayedProjects;
  final int planningProjects;
  final int atRiskCount;

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
  final List<DashboardInventoryAlert> inventoryAlerts;

  // Velocity chart — count of daily_progress entries per day for last 7 days
  final List<int> weeklyProgressCounts;

  // Recent activity feed
  final List<RecentActivity> recentActivities;

  // Quick access — latest active project
  final QuickAccessProject? latestProject;

  // Construction Portfolio Datasets
  final List<PortfolioProjectItem> portfolioProjects;
  final List<MonthlyProgressTrendPoint> progressTrends;
  final List<AttentionAlert> attentionAlerts;

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
    required this.atRiskCount,
    required this.inventoryAlerts,
    required this.portfolioProjects,
    required this.progressTrends,
    required this.attentionAlerts,
  });

  /// Convenience: budget utilization percentage (0–100+).
  double get budgetUtilizationPct =>
      totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;

  /// Convenience: attendance percentage (0–100).
  double get attendancePct =>
      totalEmployees > 0 ? (employeesPresent / totalEmployees * 100) : 0.0;

  /// Convenience: count of at risk or delayed projects requiring attention.
  int get atRiskProjects => atRiskCount > 0 ? atRiskCount : delayedProjects;

  /// Convenience: total portfolio project contract value / budget.
  double get totalProjectValue => totalBudget;

  factory DashboardStats.empty() {
    return DashboardStats(
      totalProjects: 0,
      activeProjects: 0,
      completedProjects: 0,
      delayedProjects: 0,
      planningProjects: 0,
      atRiskCount: 0,
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
      inventoryAlerts: [],
      portfolioProjects: [],
      progressTrends: [],
      attentionAlerts: [],
    );
  }
}
