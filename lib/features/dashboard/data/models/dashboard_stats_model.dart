class DashboardStats {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int employeesPresent;
  final int lowStockItems;
  final double monthlyExpense;
  final double pendingBills;

  DashboardStats({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.employeesPresent,
    required this.lowStockItems,
    required this.monthlyExpense,
    required this.pendingBills,
  });

  factory DashboardStats.empty() {
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
