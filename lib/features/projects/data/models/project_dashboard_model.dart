// Per-project dashboard statistics model.
//
// Aggregates KPIs, expenses, attendance, checklists, payments,
// and recent activity for a single project.

class ProjectExpenseCategory {
  final String category;
  final double amount;

  ProjectExpenseCategory({required this.category, required this.amount});
}

class ProjectDashboardActivity {
  final String title;
  final String subtitle;
  final String type; // 'add', 'edit', 'delete', 'info'
  final DateTime timestamp;

  ProjectDashboardActivity({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });
}

class ProjectDashboardStats {
  // ── Core Project Info ──
  final String projectId;
  final String projectName;
  final String status;
  final String? clientName;
  final String? customerName;
  final String? startDate;
  final String? expectedCompletion;
  final String? address;
  final String? imageUrl;

  // ── Budget KPIs ──
  final double budget;
  final double spent;
  final double estimatedCost;
  final double currentCost;

  // ── Attendance (today) ──
  final int workersPresent;
  final int totalAssigned;

  // ── Expenses ──
  final double totalExpenses;
  final List<ProjectExpenseCategory> expenseBreakdown;

  // ── Checklist ──
  final int checklistTotal;
  final int checklistCompleted;

  // ── Payments ──
  final double totalPayments;
  final double pendingPayments;

  // ── 7-day daily progress ──
  final List<int> weeklyProgressCounts;

  // ── Recent activity ──
  final List<ProjectDashboardActivity> recentActivities;

  ProjectDashboardStats({
    required this.projectId,
    required this.projectName,
    required this.status,
    this.clientName,
    this.customerName,
    this.startDate,
    this.expectedCompletion,
    this.address,
    this.imageUrl,
    required this.budget,
    required this.spent,
    required this.estimatedCost,
    required this.currentCost,
    required this.workersPresent,
    required this.totalAssigned,
    required this.totalExpenses,
    required this.expenseBreakdown,
    required this.checklistTotal,
    required this.checklistCompleted,
    required this.totalPayments,
    required this.pendingPayments,
    required this.weeklyProgressCounts,
    required this.recentActivities,
  });

  // ── Computed getters ──

  double get remainingBalance => budget - spent;
  double get budgetUtilization => budget > 0 ? (spent / budget).clamp(0.0, 2.0) : 0.0;
  double get budgetUtilizationPct => budgetUtilization * 100;
  double get checklistCompletionPct =>
      checklistTotal > 0 ? (checklistCompleted / checklistTotal * 100) : 0.0;
  double get attendancePct =>
      totalAssigned > 0 ? (workersPresent / totalAssigned * 100) : 0.0;
  String get displayClient => clientName ?? customerName ?? 'Direct Client';

  factory ProjectDashboardStats.empty(String projectId) {
    return ProjectDashboardStats(
      projectId: projectId,
      projectName: 'Loading...',
      status: 'planning',
      budget: 0,
      spent: 0,
      estimatedCost: 0,
      currentCost: 0,
      workersPresent: 0,
      totalAssigned: 0,
      totalExpenses: 0,
      expenseBreakdown: [],
      checklistTotal: 0,
      checklistCompleted: 0,
      totalPayments: 0,
      pendingPayments: 0,
      weeklyProgressCounts: List.filled(7, 0),
      recentActivities: [],
    );
  }
}
