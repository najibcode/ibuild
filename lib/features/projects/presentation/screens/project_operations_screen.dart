import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../sales_bills/data/sales_bill_pdf_generator.dart';
import '../../../payments/data/payment_ledger_pdf_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';

import '../../../checklists/data/models/checklist_model.dart';
import '../../../checklists/data/repositories/supabase_checklist_repository.dart';
import '../../../sales_bills/data/models/sales_bill_model.dart';
import '../../../sales_bills/data/repositories/supabase_sales_bill_repository.dart';
import '../../../payments/data/models/payment_model.dart';
import '../../../payments/data/repositories/supabase_payment_repository.dart';
import '../../../drawings/data/models/site_drawing_model.dart';
import '../../../drawings/data/repositories/supabase_drawing_repository.dart';
import '../../../subcontractors/data/models/subcontractor_model.dart';
import '../../../subcontractors/data/repositories/supabase_subcontractor_repository.dart';
import '../../../inventory/data/models/inventory_item_model.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../attendance/presentation/controllers/attendance_controller.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../employees/presentation/controllers/employee_controller.dart';
import '../../../daily_progress/presentation/screens/daily_progress_screen.dart';
import '../../../reports/presentation/screens/full_report_generator_screen.dart';
import '../../../sales_bills/presentation/screens/sales_bill_builder_screen.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../expenses/presentation/screens/expense_form_screen.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';
import 'project_dashboard_screen.dart';

// Providers
final projectExpensesProvider =
    FutureProvider.family<List<Expense>, String>((ref, projectId) async {
      final repo = ref.watch(expenseRepositoryProvider);
      return await repo.getExpenses(
        projectId: projectId,
        limit: 500,
        sortBy: 'expense_date',
        ascending: false,
      );
    });

final projectChecklistProvider =
    FutureProvider.family<List<ChecklistItem>, String>((ref, projectId) async {
      final client = ref.watch(supabaseClientProvider);
      return await SupabaseChecklistRepository(
        client,
      ).fetchChecklistForProject(projectId);
    });

final projectSalesBillsProvider =
    FutureProvider.family<List<SalesBill>, String>((ref, projectId) async {
      final client = ref.watch(supabaseClientProvider);
      return await SupabaseSalesBillRepository(
        client,
      ).fetchSalesBillsForProject(projectId);
    });

final projectPaymentsProvider =
    FutureProvider.family<List<ProjectPayment>, String>((ref, projectId) async {
      final client = ref.watch(supabaseClientProvider);
      return await SupabasePaymentRepository(
        client,
      ).fetchPaymentsForProject(projectId);
    });

final projectDrawingsProvider =
    FutureProvider.family<List<SiteDrawing>, String>((ref, projectId) async {
      final client = ref.watch(supabaseClientProvider);
      return await SupabaseDrawingRepository(
        client,
      ).fetchDrawingsForProject(projectId);
    });

final projectSubcontractorsProvider = FutureProvider<List<Subcontractor>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseSubcontractorRepository(client).fetchSubcontractors();
});

final projectInventoryProvider = FutureProvider<List<InventoryItem>>((
  ref,
) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return await repo.getItems();
});

final projectDetailByIdProvider = FutureProvider.family<Project?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(projectRepositoryProvider);
  return await repo.getProjectById(id);
});

class ProjectOperationsScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final int initialSection;

  const ProjectOperationsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.initialSection = 0,
  });

  @override
  ConsumerState<ProjectOperationsScreen> createState() =>
      _ProjectOperationsScreenState();
}

class _ProjectOperationsScreenState
    extends ConsumerState<ProjectOperationsScreen> {
  late int _activeSection; // 1..10 = Submodules
  int _financeSegment = 0; // 0 = Project Expenses & Outflows, 1 = Payment Receipts & Inflows
  String _expenseCategoryFilter = 'All';
  String _expenseSearch = '';
  final TextEditingController _expenseSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
  }

  @override
  void dispose() {
    _expenseSearchController.dispose();
    super.dispose();
  }

  final Map<int, String> _sectionTitles = {
    0: 'Project Dashboard',
    1: 'Today Attendance',
    2: 'Materials Inventory',
    3: 'Subcontractor / Trade Partners',
    4: 'Project Expenses & Financials',
    5: 'Checklist Inspection',
    6: 'Site Drawings & Blueprints',
    7: 'Sales Bills & Client Invoices',
    8: 'Daily Progress & Site Updates',
    9: 'About Site Specifications',
    10: 'Full Site Reports & Export',
  };

  void _openSection(int section) {
    setState(() {
      _activeSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mutedText = AppColors.mutedText(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.projectName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              Text(
                _sectionTitles[_activeSection] ?? 'Project Operations',
                style: TextStyle(fontSize: 12, color: mutedText),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: () => _openSection(10),
                icon: const Icon(Icons.description_outlined, color: AppColors.secondary),
                tooltip: 'Full Site Reports & Export',
              ),
            ),
          ],
        ),
        body: _buildActiveContent(),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeSection) {
      case 0:
        return ProjectDashboardScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
        );
      case 1:
        return _buildAttendanceTab();
      case 2:
        return _buildMaterialsTab();
      case 3:
        return _buildSubcontractorsTab();
      case 4:
        return _buildPaymentsTab();
      case 5:
        return _buildChecklistTab();
      case 6:
        return _buildDrawingsTab();
      case 7:
        return _buildSalesBillsTab();
      case 8:
        return DailyProgressScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
          showAppBar: false,
        );
      case 9:
        return _buildAboutSiteTab();
      case 10:
        return const FullReportGeneratorScreen(showAppBar: false);
      default:
        return ProjectDashboardScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
        );
    }
  }



  void _showDeployWorkerSheet(BuildContext context) {
    final globalState = ref.read(attendanceControllerProvider);
    final activeEmployees = globalState.activeEmployees;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentAttendance = ref
                .watch(attendanceControllerProvider)
                .attendanceList;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deploy Workers to Site',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (activeEmployees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No active employees available to deploy.'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeEmployees.length,
                        itemBuilder: (context, idx) {
                          final emp = activeEmployees[idx];
                          final match = currentAttendance.where(
                            (a) => a.employeeId == emp.id,
                          );
                          final currentRecord = match.isNotEmpty
                              ? match.first
                              : null;
                          final isAssignedHere =
                              currentRecord?.projectId == widget.projectId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAssignedHere
                                  ? AppColors.secondary
                                  : AppColors.primaryColor(context),
                              child: Text(
                                emp.name.isNotEmpty
                                    ? emp.name.substring(0, 1).toUpperCase()
                                    : 'W',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              emp.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
                              ),
                            ),
                            subtitle: Text(
                              '${emp.role} • \u20B9${emp.salary.toInt()}/day + \u20B9${emp.teaSnackAllowance.toInt()} tea',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAssignedHere
                                    ? AppColors.secondary
                                    : AppColors.primaryColor(context),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () async {
                                await ref
                                    .read(attendanceControllerProvider.notifier)
                                    .markAttendance(
                                      employeeId: emp.id,
                                      status: 'Present',
                                      projectId: widget.projectId,
                                    );
                                setModalState(() {});
                              },
                              child: Text(
                                isAssignedHere ? 'Deployed ✓' : 'Deploy Here',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 1. Project-Scoped Attendance Tab
  Widget _buildAttendanceTab() {
    final projectAttendanceAsync = ref.watch(
      projectAttendanceProvider(widget.projectId),
    );

    return projectAttendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading attendance: $e')),
      data: (data) {
        final todayRecords = data.todayRecords;
        // Recent history excluding today to avoid duplicates
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final historyRecords = data.recentHistory
            .where((r) => r.date != todayStr)
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                color: AppColors.cardBg(context),
                child: ListTile(
                  leading: Icon(
                    Icons.badge_outlined,
                    color: AppColors.primaryColor(context),
                  ),
                  title: Text(
                    'Site Attendance - Today',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  subtitle: Text(
                    'Workers on site: ${todayRecords.where((r) => r.status == 'Present').length} present • ${todayRecords.where((r) => r.status != 'Present').length} absent',
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showDeployWorkerSheet(context),
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text(
                          'Deploy',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.invalidate(
                          projectAttendanceProvider(widget.projectId),
                        ),
                        icon: Icon(
                          Icons.refresh,
                          color: AppColors.primaryColor(context),
                          size: 20,
                        ),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Today's Workers List
              if (todayRecords.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_off_outlined,
                          size: 48,
                          color: AppColors.mutedText(
                            context,
                          ).withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No workers assigned to this site today.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deploy workers here or assign them from the main Attendance tab.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showDeployWorkerSheet(context),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Deploy Workers to This Site'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor(context),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...todayRecords.map(
                  (record) => _buildProjectWorkerCard(record),
                ),

              // Recent History Section
              if (historyRecords.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SITE WORKER ATTENDANCE LOGS & PAST RECORDS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryColor(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHistoryTable(historyRecords),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectWorkerCard(Attendance record) {
    final employeesAsync = ref.watch(employeeListControllerProvider);
    final employees = employeesAsync.valueOrNull ?? [];
    final empMatch = employees.where((e) => e.id == record.employeeId);
    final emp = empMatch.isNotEmpty ? empMatch.first : null;

    final name = emp?.name ?? record.employeeName ?? 'Worker';
    final role = emp?.role.toUpperCase() ?? 'STAFF';
    final rate = emp != null
        ? 'Rate: \u20B9${emp.salary.toInt()}/day + \u20B9${emp.teaSnackAllowance.toInt()} tea'
        : '';
    final isPresent = record.status.toLowerCase() == 'present';

    return Card(
      color: AppColors.cardBg(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isPresent
                  ? AppColors.secondary
                  : AppColors.error,
              radius: 20,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'W',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rate.isNotEmpty ? '$role • $rate' : role,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                FilterChip(
                  label: Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPresent ? Colors.white : AppColors.text(context),
                    ),
                  ),
                  selected: isPresent,
                  onSelected: (_) {
                    ref
                        .read(attendanceControllerProvider.notifier)
                        .markAttendance(
                          employeeId: record.employeeId,
                          status: 'Present',
                          projectId: widget.projectId,
                        );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      ref.invalidate(
                        projectAttendanceProvider(widget.projectId),
                      );
                    });
                  },
                  backgroundColor: AppColors.cardBg(context),
                  selectedColor: AppColors.secondary,
                  side: BorderSide(
                    color: isPresent
                        ? AppColors.secondary
                        : AppColors.border(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                ),
                FilterChip(
                  label: Text(
                    'Absent',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: !isPresent
                          ? Colors.white
                          : AppColors.text(context),
                    ),
                  ),
                  selected: !isPresent,
                  onSelected: (_) {
                    ref
                        .read(attendanceControllerProvider.notifier)
                        .markAttendance(
                          employeeId: record.employeeId,
                          status: 'Absent',
                          projectId: widget.projectId,
                        );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      ref.invalidate(
                        projectAttendanceProvider(widget.projectId),
                      );
                    });
                  },
                  backgroundColor: AppColors.cardBg(context),
                  selectedColor: AppColors.error,
                  side: BorderSide(
                    color: !isPresent
                        ? AppColors.error
                        : AppColors.border(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable(List<Attendance> records) {
    final employeesAsync = ref.watch(employeeListControllerProvider);
    final employees = employeesAsync.valueOrNull ?? [];

    final Map<String, List<Attendance>> byDate = {};
    for (final r in records) {
      if (r.date.isNotEmpty) {
        byDate.putIfAbsent(r.date, () => []).add(r);
      }
    }
    final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Worker Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ...sortedDates.expand((date) {
            final dayRecords = byDate[date]!;
            return dayRecords.map((r) {
              final empMatch = employees.where((e) => e.id == r.employeeId);
              final emp = empMatch.isNotEmpty ? empMatch.first : null;
              final workerName = emp?.name ?? r.employeeName ?? 'Worker';
              final role = emp?.role ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        r.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text(context),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workerName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          if (role.isNotEmpty)
                            Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: r.status == 'Present'
                              ? AppColors.secondary.withValues(alpha: 0.12)
                              : AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          r.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: r.status == 'Present'
                                ? AppColors.secondary
                                : AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  // 2. Materials Tab
  Widget _buildMaterialsTab() {
    final invAsync = ref.watch(projectInventoryProvider);

    return invAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _emptyState(
            'No materials in stock',
            'Register or assign site inventory for this project',
          );
        }

        final double totalValuation = items.fold(
          0.0,
          (sum, i) => sum + (i.availableStock * i.purchasePrice),
        );
        final int lowStockCount = items.where((i) => i.isLowStock).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Site Inventory Financial Summary
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Site Material Valuation',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalValuation.toInt()}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${items.length} Material Types Tracked',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                  if (lowStockCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$lowStockCount Low Stock',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Material Cards
            ...items.map((item) {
              final double valuation = item.totalValuation;
              final int runwayDays = item.stockRunwayDays;
              final Color runwayColor = runwayDays < 3
                  ? AppColors.error
                  : (runwayDays <= 7 ? Colors.orange : AppColors.secondary);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isLowStock
                        ? AppColors.error.withValues(alpha: 0.4)
                        : AppColors.border(context),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: runwayColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                runwayDays > 90
                                    ? 'Runway: 90+ Days'
                                    : 'Runway: $runwayDays Days',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: runwayColor,
                                ),
                              ),
                            ),
                            if (item.isLowStock) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LOW STOCK',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.materialName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Burn Rate: ~${item.estimatedDailyBurnRate.toStringAsFixed(1)} ${item.unit}/day • Rate: ₹${item.purchasePrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${valuation.toInt()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.primaryColor(context),
                              ),
                            ),
                            Text(
                              'Available: ${item.availableStock.toStringAsFixed(1)} ${item.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (item.isLowStock) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Auto Reorder Suggestion: Order +${item.recommendedReorderQty.toInt()} ${item.unit} (Est ₹${item.estimatedReorderCost.toInt()})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading inventory: $e')),
    );
  }

  // 3. Subcontractors Tab
  Widget _buildSubcontractorsTab() {
    final subsAsync = ref.watch(projectSubcontractorsProvider);

    return subsAsync.when(
      data: (subs) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subs.length,
        itemBuilder: (context, i) {
          final sub = subs[i];
          return Card(
            color: AppColors.cardBg(context),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(
                Icons.engineering_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                sub.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              subtitle: Text(
                'Trade: ${sub.specialization ?? 'General'} • Phone: ${sub.phone ?? 'N/A'}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${sub.contractValue.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  Text(
                    sub.status,
                    style: TextStyle(
                      color: sub.status == 'Active'
                          ? AppColors.secondary
                          : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading subcontractors: $e')),
    );
  }

  // 4. Project Expenses & Financials Tab
  IconData _getExpenseCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'labour':
        return Icons.engineering_outlined;
      case 'materials':
      case 'material':
        return Icons.inventory_2_outlined;
      case 'transport':
        return Icons.local_shipping_outlined;
      case 'equipment':
        return Icons.build_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'fuel':
        return Icons.local_gas_station_outlined;
      case 'office & admin':
        return Icons.business_outlined;
      case 'safety & ppe':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _getExpenseCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'materials':
      case 'material':
        return const Color(0xFFF59E0B);
      case 'equipment':
        return const Color(0xFF6366F1);
      case 'labour':
        return const Color(0xFF059669);
      case 'transport':
        return const Color(0xFF3B82F6);
      case 'fuel':
        return const Color(0xFFEF4444);
      case 'food':
        return const Color(0xFFEC4899);
      case 'office & admin':
        return const Color(0xFF8B5CF6);
      case 'safety & ppe':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Future<void> _confirmDeleteProjectExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: const Text('Delete Expense Record'),
        content: Text(
          'Are you sure you want to delete this ₹${expense.amount.toStringAsFixed(2)} (${expense.category}) expense?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(expenseControllerProvider.notifier)
          .removeExpense(expense.id);
      if (mounted) {
        if (success) {
          ref.invalidate(projectExpensesProvider(widget.projectId));
          ref.invalidate(projectDetailByIdProvider(widget.projectId));
          ref.read(projectControllerProvider.notifier).loadProjects();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete expense'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildPaymentsTab() {
    return Column(
      children: [
        // Top Segmented Switch: Expenses vs Inflow Receipts
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _financeSegment = 0),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _financeSegment == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 16,
                            color: _financeSegment == 0
                                ? Colors.white
                                : AppColors.text(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Project Expenses (All Outflows)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _financeSegment == 0
                                  ? Colors.white
                                  : AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _financeSegment = 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _financeSegment == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: _financeSegment == 1
                                ? Colors.white
                                : AppColors.text(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Inflows & Ledger',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _financeSegment == 1
                                  ? Colors.white
                                  : AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Body Content based on active financial segment
        Expanded(
          child: _financeSegment == 0
              ? _buildProjectExpensesView()
              : _buildPaymentReceiptsView(),
        ),
      ],
    );
  }

  Widget _buildProjectExpensesView() {
    final expensesAsync = ref.watch(projectExpensesProvider(widget.projectId));

    return expensesAsync.when(
      data: (allExpenses) {
        final totalAmount = allExpenses.fold(0.0, (s, e) => s + e.amount);
        final labourAmount = allExpenses
            .where((e) => e.category.toLowerCase() == 'labour')
            .fold(0.0, (s, e) => s + e.amount);
        final materialAmount = allExpenses
            .where((e) =>
                e.category.toLowerCase().contains('mat') ||
                e.category.toLowerCase().contains('inven'))
            .fold(0.0, (s, e) => s + e.amount);
        final otherAmount =
            (totalAmount - labourAmount - materialAmount).clamp(0.0, double.infinity);

        // Filter by category and search
        final filteredExpenses = allExpenses.where((e) {
          final matchesCat = _expenseCategoryFilter == 'All' ||
              e.category.toLowerCase() == _expenseCategoryFilter.toLowerCase() ||
              (_expenseCategoryFilter == 'Materials' &&
                  e.category.toLowerCase().contains('mat'));
          final matchesSearch = _expenseSearch.isEmpty ||
              (e.notes ?? '').toLowerCase().contains(_expenseSearch.toLowerCase()) ||
              e.category.toLowerCase().contains(_expenseSearch.toLowerCase()) ||
              (e.projectName ?? '').toLowerCase().contains(_expenseSearch.toLowerCase());
          return matchesCat && matchesSearch;
        }).toList();

        return CustomScrollView(
          slivers: [
            // KPI Summary Cards Strip
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    final cardList = [
                      _buildExpenseSummaryTile(
                        title: 'Total Spent',
                        amount: totalAmount,
                        icon: Icons.trending_up_outlined,
                        color: const Color(0xFF059669),
                        subtitle: '${allExpenses.length} total expense entries',
                      ),
                      _buildExpenseSummaryTile(
                        title: 'Labour & Wages',
                        amount: labourAmount,
                        icon: Icons.engineering_outlined,
                        color: const Color(0xFF059669),
                        subtitle: 'Site worker attendance wages',
                      ),
                      _buildExpenseSummaryTile(
                        title: 'Materials & Stock',
                        amount: materialAmount,
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFF59E0B),
                        subtitle: 'Inventory deliveries & issues',
                      ),
                      _buildExpenseSummaryTile(
                        title: 'Other Operations',
                        amount: otherAmount,
                        icon: Icons.build_outlined,
                        color: const Color(0xFF6366F1),
                        subtitle: 'Equipment, fuel, transport, etc.',
                      ),
                    ];

                    if (isWide) {
                      return Row(
                        children: cardList
                            .map((c) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: c,
                                  ),
                                ))
                            .toList(),
                      );
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: cardList,
                    );
                  },
                ),
              ),
            ),

            // Action Bar: Search, Category Filter, Export, Add Expense
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expenseSearchController,
                            style: TextStyle(color: AppColors.text(context), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search expenses (salary, materials, notes)...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              suffixIcon: _expenseSearch.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _expenseSearchController.clear();
                                        setState(() => _expenseSearch = '');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (v) => setState(() => _expenseSearch = v.trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DataExportActions(
                          compact: true,
                          onExportPdfWithDates: (start, end) async {
                            final startStr =
                                '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
                            final endStr =
                                '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
                            final filtered = allExpenses.where((e) {
                              final d = DateTime.tryParse(e.expenseDate);
                              if (d == null) return false;
                              return !d.isBefore(start) && !d.isAfter(end);
                            }).toList();
                            final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                              title: '${widget.projectName} — Expenses & Outflows',
                              subtitle:
                                  'Complete financial outflow ledger ($startStr to $endStr)',
                              headers: [
                                'ID',
                                'Date',
                                'Category',
                                'Amount (INR)',
                                'Mode',
                                'Description / Notes'
                              ],
                              data: filtered
                                  .map((e) => [
                                        e.shortId,
                                        e.expenseDate,
                                        e.category,
                                        'INR ${e.amount.toStringAsFixed(2)}',
                                        e.paymentMode.toUpperCase(),
                                        e.notes ?? '',
                                      ])
                                  .toList(),
                            );
                            await PdfDownloadHelper.downloadPdf(
                              bytes: pdfBytes,
                              filename:
                                  '${widget.projectName}_Expenses_${startStr}_to_$endStr.pdf',
                            );
                          },
                          onExportExcelWithDates: (start, end) async {
                            final startStr =
                                '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
                            final endStr =
                                '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
                            final filtered = allExpenses.where((e) {
                              final d = DateTime.tryParse(e.expenseDate);
                              if (d == null) return false;
                              return !d.isBefore(start) && !d.isAfter(end);
                            }).toList();
                            final excelBytes = ExcelGeneratorService.generateTableExcel(
                              sheetName: 'Expenses',
                              title: '${widget.projectName} — Project Outflows',
                              headers: [
                                'Expense ID',
                                'Date',
                                'Category',
                                'Amount (INR)',
                                'Payment Mode',
                                'Description / Notes'
                              ],
                              rows: filtered
                                  .map((e) => [
                                        e.shortId,
                                        e.expenseDate,
                                        e.category,
                                        e.amount,
                                        e.paymentMode.toUpperCase(),
                                        e.notes ?? '',
                                      ])
                                  .toList(),
                            );
                            await ExcelDownloadHelper.downloadExcel(
                              bytes: excelBytes,
                              filename:
                                  '${widget.projectName}_Expenses_${startStr}_to_$endStr.xlsx',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExpenseFormScreen(
                                  initialProjectId: widget.projectId,
                                ),
                              ),
                            );
                            ref.invalidate(projectExpensesProvider(widget.projectId));
                            ref.invalidate(projectDetailByIdProvider(widget.projectId));
                            ref.read(projectControllerProvider.notifier).loadProjects();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Expense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All',
                          'Labour',
                          'Materials',
                          'Equipment',
                          'Transport',
                          'Fuel',
                          'Food',
                          'Office & Admin',
                          'Safety & PPE',
                          'Miscellaneous',
                        ].map((cat) {
                          final isSel = _expenseCategoryFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? Colors.white : AppColors.text(context),
                                ),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.cardBg(context),
                              checkmarkColor: Colors.white,
                              onSelected: (_) {
                                setState(() => _expenseCategoryFilter = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Expenses List
            if (filteredExpenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(
                  'No expenses found',
                  allExpenses.isEmpty
                      ? 'No expenses recorded for this project yet. Assign workers, issue materials, or click "+ Add Expense".'
                      : 'No expenses match the selected filter or search term.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = filteredExpenses[index];
                      final catColor = _getExpenseCategoryColor(exp.category);
                      final catIcon = _getExpenseCategoryIcon(exp.category);

                      return Card(
                        color: AppColors.cardBg(context),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border(context)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: catColor.withValues(alpha: 0.3)),
                                ),
                                child: Icon(catIcon, color: catColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (exp.notes != null && exp.notes!.trim().isNotEmpty)
                                          ? exp.notes!
                                          : '${exp.category} Expense',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.mutedText(context).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            exp.shortId,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.mutedText(context),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            exp.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.border(context),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            exp.paymentMode.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mutedText(context),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 11,
                                              color: AppColors.mutedText(context),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              exp.expenseDate,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.mutedText(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '-${CurrencyFormatter.formatFullINR(exp.amount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit Expense',
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ExpenseFormScreen(
                                                expense: exp,
                                                initialProjectId: widget.projectId,
                                              ),
                                            ),
                                          );
                                          ref.invalidate(
                                              projectExpensesProvider(widget.projectId));
                                          ref.invalidate(
                                              projectDetailByIdProvider(widget.projectId));
                                          ref
                                              .read(projectControllerProvider.notifier)
                                              .loadProjects();
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 16, color: AppColors.error),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete Expense',
                                        onPressed: () => _confirmDeleteProjectExpense(exp),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: filteredExpenses.length,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading project expenses: $e')),
    );
  }

  Widget _buildExpenseSummaryTile({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppColors.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReceiptsView() {
    final payAsync = ref.watch(projectPaymentsProvider(widget.projectId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Ledger & Receipts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.text(context),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddPaymentDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: payAsync.when(
            data: (payments) {
              if (payments.isEmpty) {
                return _emptyState(
                  'No payment records',
                  'Record client receipts and payments received or paid for this project',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: payments.length,
                itemBuilder: (context, i) {
                  final p = payments[i];
                  final isRec = p.paymentType == 'Received';
                  return Card(
                    color: AppColors.cardBg(context),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        isRec ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isRec ? AppColors.secondary : AppColors.error,
                      ),
                      title: Text(
                        p.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      subtitle: Text(
                        'Method: ${p.paymentMethod} • Ref: ${p.referenceNo ?? 'N/A'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isRec ? '+' : '-'}₹${p.amount.toInt()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isRec
                                  ? AppColors.secondary
                                  : AppColors.error,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.print_outlined, size: 18),
                            tooltip: 'Print Payment Receipt PDF',
                            onPressed: () async {
                              final pdfBytes =
                                  await PaymentLedgerPdfGenerator.generatePaymentReceipt(
                                    p,
                                  );
                              await Printing.layoutPdf(
                                onLayout: (_) async =>
                                    Uint8List.fromList(pdfBytes),
                                name: 'Payment_Receipt_${p.id}.pdf',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading payments: $e')),
          ),
        ),
      ],
    );
  }


  // 5. Checklist Tab
  Widget _buildChecklistTab() {
    final checkAsync = ref.watch(projectChecklistProvider(widget.projectId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Site Inspection Checklist',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text(context),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddChecklistDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor(context),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: checkAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _emptyState(
                  'No checklist items',
                  'Add quality inspection tasks for this site',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Card(
                    color: AppColors.cardBg(context),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: CheckboxListTile(
                      value: item.isCompleted,
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        'Phase: ${item.phaseGroup} • Status: ${item.approvalStatus}',
                      ),
                      onChanged: (val) async {
                        if (val != null) {
                          final client = ref.read(supabaseClientProvider);
                          await SupabaseChecklistRepository(
                            client,
                          ).toggleChecklistItem(item.id, val);
                          ref.invalidate(
                            projectChecklistProvider(widget.projectId),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading checklist: $e')),
          ),
        ),
      ],
    );
  }

  // 6. Drawings Tab
  Widget _buildDrawingsTab() {
    final dwgAsync = ref.watch(projectDrawingsProvider(widget.projectId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blueprints & Site Drawings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text(context),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddDrawingDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Drawing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor(context),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dwgAsync.when(
            data: (drawings) {
              if (drawings.isEmpty) {
                return _emptyState(
                  'No site drawings',
                  'Blueprints and structural layouts will appear here',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: drawings.length,
                itemBuilder: (context, i) {
                  final d = drawings[i];
                  return Card(
                    color: AppColors.cardBg(context),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.draw_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        d.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      subtitle: Text(
                        'Category: ${d.category} • Version: ${d.version}',
                      ),
                      trailing: const Icon(
                        Icons.download,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading drawings: $e')),
          ),
        ),
      ],
    );
  }

  // 7. Sales Bills Tab
  Widget _buildSalesBillsTab() {
    final billsAsync = ref.watch(projectSalesBillsProvider(widget.projectId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Invoices & Client Billing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text(context),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SalesBillBuilderScreen(),
                    ),
                  );
                  ref.invalidate(projectSalesBillsProvider(widget.projectId));
                },
                icon: const Icon(Icons.point_of_sale, size: 16),
                label: const Text('Draw Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor(context),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: billsAsync.when(
            data: (bills) {
              if (bills.isEmpty) {
                return _emptyState(
                  'No sales bills',
                  'Invoices generated for client billing',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: bills.length,
                itemBuilder: (context, i) {
                  final b = bills[i];
                  return Card(
                    color: AppColors.cardBg(context),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.receipt_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'Bill #${b.billNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      subtitle: Text('Client: ${b.clientName}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${b.totalAmount.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                              Text(
                                b.status,
                                style: TextStyle(
                                  color: b.status == 'Paid'
                                      ? AppColors.secondary
                                      : AppColors.error,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.print_outlined, size: 18),
                            tooltip: 'Print Sales Invoice PDF',
                            onPressed: () async {
                              final pdfBytes =
                                  await SalesBillPdfGenerator.generatePdf(b);
                              await Printing.layoutPdf(
                                onLayout: (_) async =>
                                    Uint8List.fromList(pdfBytes),
                                name: 'Sales_Invoice_${b.billNumber}.pdf',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                Center(child: Text('Error loading sales bills: $e')),
          ),
        ),
      ],
    );
  }

  void _showAddDrawingDialog() {
    final titleCtrl = TextEditingController();
    final versionCtrl = TextEditingController(text: 'v1.0');
    final fileUrlCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Architectural';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Site Drawing & Blueprint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Drawing Title *',
                  hintText: 'e.g. Structural Foundation Layout',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    [
                          'Architectural',
                          'Structural',
                          'Electrical',
                          'Plumbing',
                          'HVAC',
                          'Other',
                        ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) => category = v ?? category,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: versionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Version (e.g. v1.0, v2.1)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fileUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Blueprint File URL / Document Ref',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes / Revision Details',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final drawing = SiteDrawing(
                id: '',
                projectId: widget.projectId,
                title: titleCtrl.text.trim(),
                category: category,
                version: versionCtrl.text.trim().isEmpty
                    ? 'v1.0'
                    : versionCtrl.text.trim(),
                fileUrl: fileUrlCtrl.text.trim().isEmpty
                    ? 'https://storage.supabase.co/drawings/site_blueprint.pdf'
                    : fileUrlCtrl.text.trim(),
                notes: notesCtrl.text.trim().isEmpty
                    ? null
                    : notesCtrl.text.trim(),
                createdAt: DateTime.now(),
              );
              final client = ref.read(supabaseClientProvider);
              final saved = await SupabaseDrawingRepository(
                client,
              ).addDrawing(drawing);
              if (saved != null) {
                await SupabaseActivityRepository(
                  client,
                ).logSiteActivityAndNotify(
                  actionType: 'drawing_added',
                  entityType: 'site_drawings',
                  entityId: saved.id,
                  title:
                      'New Site Blueprint: ${saved.title} (${saved.category})',
                  projectId: widget.projectId,
                );
              }
              ref.invalidate(projectDrawingsProvider(widget.projectId));
              ref.invalidate(recentActivitiesProvider);
              ref.invalidate(unreadNotificationsCountProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Drawing'),
          ),
        ],
      ),
    );
  }

  void _showAddChecklistDialog() {
    final titleCtrl = TextEditingController();
    String category = 'Quality Control';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Inspection Checklist Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Inspection Task Title *',
                hintText: 'e.g. Slump Test & Rebar Quality Check',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                'Quality Control',
                'Safety Inspection',
                'General Inspection',
                'Site Preparation',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v ?? category,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final item = ChecklistItem(
                id: '',
                projectId: widget.projectId,
                title: titleCtrl.text.trim(),
                category: category,
                isCompleted: false,
                createdAt: DateTime.now(),
              );
              final client = ref.read(supabaseClientProvider);
              final saved = await SupabaseChecklistRepository(
                client,
              ).addChecklistItem(item);
              if (saved != null) {
                await SupabaseActivityRepository(
                  client,
                ).logSiteActivityAndNotify(
                  actionType: 'checklist_item_added',
                  entityType: 'project_checklists',
                  entityId: saved.id,
                  title: 'Inspection Task Added: ${saved.title}',
                  projectId: widget.projectId,
                );
              }
              ref.invalidate(projectChecklistProvider(widget.projectId));
              ref.invalidate(recentActivitiesProvider);
              ref.invalidate(unreadNotificationsCountProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Inspection Task'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final refNoCtrl = TextEditingController();
    String paymentType = 'Received';
    String paymentMethod = 'Bank Transfer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Site Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Payment Title *',
                  hintText: 'e.g. Milestone 1 Client Advance',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: paymentType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: ['Received', 'Paid']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => paymentType = v ?? paymentType,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) *',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: ['Bank Transfer', 'UPI', 'Cash', 'Cheque', 'Credit Card']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => paymentMethod = v ?? paymentMethod,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reference / Transaction No.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty ||
                  amountCtrl.text.trim().isEmpty) {
                return;
              }
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              final payment = ProjectPayment(
                id: '',
                projectId: widget.projectId,
                title: titleCtrl.text.trim(),
                paymentType: paymentType,
                amount: amount,
                paymentMethod: paymentMethod,
                referenceNo: refNoCtrl.text.trim().isEmpty
                    ? null
                    : refNoCtrl.text.trim(),
                paymentDate: DateTime.now(),
                createdAt: DateTime.now(),
              );
              final client = ref.read(supabaseClientProvider);
              final saved = await SupabasePaymentRepository(
                client,
              ).recordPayment(payment);
              if (saved != null) {
                await SupabaseActivityRepository(
                  client,
                ).logSiteActivityAndNotify(
                  actionType: 'payment_recorded',
                  entityType: 'project_payments',
                  entityId: saved.id,
                  title:
                      'Payment $paymentType: ₹${amount.toInt()} - ${saved.title}',
                  projectId: widget.projectId,
                  details: {'amount': amount, 'type': paymentType},
                );
              }
              ref.invalidate(projectPaymentsProvider(widget.projectId));
              ref.invalidate(projectDetailByIdProvider(widget.projectId));
              ref.invalidate(recentActivitiesProvider);
              ref.invalidate(unreadNotificationsCountProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Payment'),
          ),
        ],
      ),
    );
  }

  // 8. About Site Tab
  Widget _buildAboutSiteTab() {
    final projectAsync = ref.watch(projectDetailByIdProvider(widget.projectId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: projectAsync.when(
        data: (p) {
          if (p == null) {
            return _emptyState('Site Not Found', 'Could not load site details');
          }
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Site Specifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                const Divider(height: 24),
                _infoTile('Site Name', p.name),
                _infoTile(
                  'Site Address & Location',
                  (p.address != null && p.address!.isNotEmpty)
                      ? p.address!
                      : 'N/A',
                ),
                _infoTile('Project Status', p.status.toUpperCase()),
                const Divider(height: 24),
                Text(
                  'Customer / Owner Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 8),
                _infoTile('Customer Name', p.customerName ?? 'Direct Client'),
                _infoTile('Customer Mobile', p.customerMobile ?? 'N/A'),
                _infoTile('Customer Email', p.customerEmail ?? 'N/A'),
                _infoTile('Customer Address', p.customerAddress ?? 'N/A'),
                _infoTile('Customer Date of Birth', p.customerDob ?? 'N/A'),
                const Divider(height: 24),
                Text(
                  'Site Engineering Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 8),
                _infoTile(
                  'Built-Up Area',
                  p.builtUpArea > 0 ? '${p.builtUpArea.toInt()} sqft' : 'N/A',
                ),
                _infoTile(
                  'Flat Area',
                  p.flatArea > 0 ? '${p.flatArea.toInt()} sqft' : 'N/A',
                ),
                _infoTile(
                  'Project Duration',
                  p.duration != null ? '${p.duration} Months' : 'N/A',
                ),
                _infoTile(
                  'Assigned Supervisor',
                  p.supervisorId ?? 'Unassigned',
                ),
                _infoTile('Total Budget Amount', '₹${p.budget.toInt()}'),
                _infoTile('Total Amount Spent', '₹${p.spent.toInt()}'),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading site info: $e')),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.outline),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}


