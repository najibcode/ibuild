import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
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
import '../../../inventory/presentation/screens/inventory_list_screen.dart';
import '../../../inventory/presentation/screens/inventory_form_screen.dart';
import '../../../subcontractors/presentation/controllers/subcontractor_controller.dart';
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
import '../controllers/project_dashboard_controller.dart';
import '../controllers/project_controller.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../data/models/project_model.dart';
import 'project_dashboard_screen.dart';
import 'project_form_screen.dart';

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

  // Drawings & Mapping State
  String _drawingCategoryFilter = 'All';
  String _drawingSearch = '';
  final TextEditingController _drawingSearchController = TextEditingController();
  bool _isDrawingGridView = true;

  // Materials & Inventory State
  String _materialSearch = '';
  final TextEditingController _materialSearchController = TextEditingController();
  bool _onlyLowStockMaterials = false;

  // Subcontractor State
  String _subcontractorSearch = '';
  final TextEditingController _subcontractorSearchController = TextEditingController();

  // Checklist State
  String _checklistFilter = 'All'; // 'All', 'Pending', 'Completed'

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
  }

  @override
  void dispose() {
    _expenseSearchController.dispose();
    _drawingSearchController.dispose();
    _materialSearchController.dispose();
    _subcontractorSearchController.dispose();
    super.dispose();
  }

  final Map<int, String> _sectionTitles = {
    0: 'Project Dashboard',
    1: 'Today Attendance',
    2: 'Materials Inventory',
    3: 'Subcontractor / Trade Partners',
    4: 'Project Expenses & Financials',
    5: 'Checklist Inspection',
    6: 'Drawings, Plans & Mapping',
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
        return FullReportGeneratorScreen(
          showAppBar: false,
          initialProjectId: widget.projectId,
        );
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
      data: (allItems) {
        final filteredItems = allItems.where((item) {
          final matchesSearch = _materialSearch.isEmpty ||
              item.materialName.toLowerCase().contains(_materialSearch.toLowerCase()) ||
              item.category.toLowerCase().contains(_materialSearch.toLowerCase());
          final matchesLowStock = !_onlyLowStockMaterials || item.isLowStock;
          return matchesSearch && matchesLowStock;
        }).toList();

        final double totalValuation = allItems.fold(
          0.0,
          (sum, i) => sum + (i.availableStock * i.purchasePrice),
        );
        final int lowStockCount = allItems.where((i) => i.isLowStock).length;

        return Column(
          children: [
            // Site Inventory Top Action & Summary Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                border: Border(bottom: BorderSide(color: AppColors.border(context))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Site Material Valuation',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${totalValuation.toInt()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor(context),
                            ),
                          ),
                          Text(
                            '${allItems.length} Materials Tracked • $lowStockCount Low Stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: lowStockCount > 0 ? AppColors.error : AppColors.mutedText(context),
                              fontWeight: lowStockCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const InventoryListScreen(),
                                ),
                              );
                              ref.invalidate(projectInventoryProvider);
                            },
                            icon: const Icon(Icons.inventory_2_outlined, size: 15),
                            label: const Text('Stock Manager', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const InventoryFormScreen(),
                                ),
                              );
                              ref.invalidate(projectInventoryProvider);
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Add Material', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search & Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _materialSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search site materials by name or category...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _materialSearch.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _materialSearchController.clear();
                                        _materialSearch = '';
                                      });
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) => setState(() => _materialSearch = val.trim()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Low Stock ($lowStockCount)', style: const TextStyle(fontSize: 11)),
                        selected: _onlyLowStockMaterials,
                        onSelected: (selected) => setState(() => _onlyLowStockMaterials = selected),
                        selectedColor: AppColors.error.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Material List / Cards
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.outline),
                          const SizedBox(height: 12),
                          Text(
                            _materialSearch.isNotEmpty ? 'No materials match "$_materialSearch"' : 'No materials in site stock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add items or transfer materials from central inventory',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const InventoryFormScreen(),
                                ),
                              );
                              ref.invalidate(projectInventoryProvider);
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Add First Material'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor(context),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, idx) {
                        final item = filteredItems[idx];
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: runwayColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          runwayDays > 90 ? 'Runway: 90+ Days' : 'Runway: $runwayDays Days',
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
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                  Expanded(
                                    child: Column(
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
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showAdjustStockDialog(item),
                                    icon: const Icon(Icons.tune, size: 14),
                                    label: const Text('Adjust / Receive Stock', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.isLowStock) ...[
                                const SizedBox(height: 8),
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
                                      Expanded(
                                        child: Text(
                                          'Auto Reorder Suggestion: Order +${item.recommendedReorderQty.toInt()} ${item.unit} (Est ₹${item.estimatedReorderCost.toInt()})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading inventory: $e')),
    );
  }

  void _showAdjustStockDialog(InventoryItem item) {
    final qtyCtrl = TextEditingController();
    bool isAddition = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${item.materialName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Available: ${item.availableStock} ${item.unit}',
                style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('+ Receive Stock'),
                      selected: isAddition,
                      onSelected: (s) => setDialogState(() => isAddition = true),
                      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('- Issue / Used'),
                      selected: !isAddition,
                      onSelected: (s) => setDialogState(() => isAddition = false),
                      selectedColor: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${isAddition ? 'Quantity Received' : 'Quantity Issued'} (${item.unit}) *',
                  hintText: 'e.g. 50',
                ),
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
                final qty = double.tryParse(qtyCtrl.text.trim());
                if (qty == null || qty <= 0) return;
                final delta = isAddition ? qty : -qty;
                await ref.read(inventoryControllerProvider.notifier).adjustStock(item, delta);
                ref.invalidate(projectInventoryProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock adjusted: ${delta > 0 ? '+$delta' : '$delta'} ${item.unit} for ${item.materialName}'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Update Stock'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Subcontractors Tab
  Widget _buildSubcontractorsTab() {
    final subsAsync = ref.watch(projectSubcontractorsProvider);

    return subsAsync.when(
      data: (allSubs) {
        // Filter specifically for this project (by projectId or siteName match)
        final projectSubs = allSubs.where((s) {
          return (s.projectId != null && s.projectId == widget.projectId) ||
              (s.siteName.toLowerCase() == widget.projectName.toLowerCase());
        }).toList();

        final subs = projectSubs.where((s) {
          if (_subcontractorSearch.isEmpty) return true;
          final q = _subcontractorSearch.toLowerCase();
          return s.name.toLowerCase().contains(q) ||
              (s.specialization?.toLowerCase().contains(q) ?? false) ||
              (s.contactPerson.toLowerCase().contains(q)) ||
              (s.phone?.toLowerCase().contains(q) ?? false);
        }).toList();

        final double totalContracts = projectSubs.fold(0.0, (sum, s) => sum + s.contractValue);
        final double totalPaid = projectSubs.fold(0.0, (sum, s) => sum + s.paidAmount);
        final double pendingBalance = totalContracts > totalPaid ? (totalContracts - totalPaid) : 0.0;

        return Column(
          children: [
            // Top Action & Summary Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                border: Border(bottom: BorderSide(color: AppColors.border(context))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Trade Partners & Subcontractors',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Assigned to ${widget.projectName} • ${projectSubs.length} Active Partners',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddSubcontractorDialog,
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('+ Add Partner', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Financial Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Committed', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('₹${totalContracts.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Paid / Disbursed', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('₹${totalPaid.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending Balance', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('₹${pendingBalance.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subcontractorSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search contractors by name, specialization, contact, phone...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _subcontractorSearch.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                setState(() {
                                  _subcontractorSearchController.clear();
                                  _subcontractorSearch = '';
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() => _subcontractorSearch = val.trim()),
                  ),
                ],
              ),
            ),

            // Subcontractor List
            Expanded(
              child: subs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.engineering_outlined, size: 48, color: AppColors.outline),
                          const SizedBox(height: 12),
                          Text(
                            _subcontractorSearch.isNotEmpty
                                ? 'No trade partners match "$_subcontractorSearch"'
                                : 'No trade partners assigned to this project',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assign masonry, electrical, plumbing & fabrication contractors to ${widget.projectName}',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddSubcontractorDialog,
                            icon: const Icon(Icons.person_add_alt_1, size: 16),
                            label: const Text('+ Assign First Trade Partner'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor(context),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: subs.length,
                      itemBuilder: (context, i) {
                        final sub = subs[i];
                        final balance = sub.contractValue > sub.paidAmount ? (sub.contractValue - sub.paidAmount) : 0.0;
                        final percent = sub.paymentProgress;

                        return Card(
                          color: AppColors.cardBg(context),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.border(context)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                      child: const Icon(Icons.engineering, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.text(context),
                                            ),
                                          ),
                                          Text(
                                            'Trade: ${sub.specialization ?? 'General'} • Contact: ${sub.contactPerson}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.mutedText(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: sub.status == 'Active'
                                            ? AppColors.secondary.withValues(alpha: 0.12)
                                            : AppColors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        sub.status,
                                        style: TextStyle(
                                          color: sub.status == 'Active'
                                              ? AppColors.secondary
                                              : AppColors.error,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (sub.scopeOfWork != null && sub.scopeOfWork!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.border(context).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Scope: ${sub.scopeOfWork}',
                                      style: TextStyle(fontSize: 11, color: AppColors.text(context), fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Contract Value', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                                        Text('₹${sub.contractValue.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Paid to Date', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                                        Text('₹${sub.paidAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Balance Due', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                                        Text('₹${balance.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percent,
                                          backgroundColor: AppColors.border(context),
                                          color: percent >= 1.0 ? const Color(0xFF10B981) : AppColors.primary,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(percent * 100).toInt()}%',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.mutedText(context)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Quick action: Record Payment
                                    ElevatedButton.icon(
                                      onPressed: () => _showRecordSubcontractorPaymentDialog(sub),
                                      icon: const Icon(Icons.payment_outlined, size: 14),
                                      label: const Text('Record Payment', style: TextStyle(fontSize: 11)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (sub.phone != null && sub.phone!.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                                            tooltip: 'WhatsApp Contractor',
                                            onPressed: () {
                                              WhatsAppHelper.shareMessage(
                                                context: context,
                                                message: 'Hello ${sub.name}, regarding works on project ${widget.projectName} (Contract: ₹${sub.contractValue.toInt()}, Paid: ₹${sub.paidAmount.toInt()}, Due: ₹${balance.toInt()})...',
                                                phoneNumber: sub.phone,
                                                successNotice: 'Opening WhatsApp chat with ${sub.name}',
                                              );
                                            },
                                          ),
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryColor(context)),
                                          tooltip: 'Edit Trade Partner Details',
                                          onPressed: () => _showEditSubcontractorDialog(sub),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                          tooltip: 'Remove Trade Partner',
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Delete Subcontractor?'),
                                                content: Text('Are you sure you want to remove "${sub.name}" from ${widget.projectName}?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await ref.read(subcontractorControllerProvider.notifier).deleteSubcontractor(sub.id);
                                              ref.invalidate(projectSubcontractorsProvider);
                                            }
                                          },
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
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading subcontractors: $e')),
    );
  }

  void _showRecordSubcontractorPaymentDialog(Subcontractor sub) {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String paymentMode = 'Bank Transfer';
    final balance = sub.contractValue > sub.paidAmount ? (sub.contractValue - sub.paidAmount) : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Record Payment to ${sub.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contract Value', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context))),
                          Text('₹${sub.contractValue.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid to Date', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context))),
                          Text('₹${sub.paidAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Balance Due', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context))),
                          Text('₹${balance.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount (₹) *',
                    hintText: 'e.g. 25000',
                    prefixIcon: Icon(Icons.currency_rupee, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode *'),
                  items: ['Bank Transfer', 'Cheque', 'Cash', 'UPI', 'NEFT / RTGS']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => paymentMode = v ?? paymentMode),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Ref # / Cheque # / RA Bill #',
                    hintText: 'e.g. RA-02 / UTR12345678',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Milestone Covered',
                    hintText: 'e.g. 2nd Floor slab casting completed',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                final ok = await ref.read(subcontractorControllerProvider.notifier).recordPayment(
                  sub: sub,
                  amount: amt,
                  paymentMode: paymentMode,
                  referenceNumber: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                  remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
                );

                // Invalidate providers to sync Project Spent & Subcontractors
                ref.invalidate(projectSubcontractorsProvider);
                ref.invalidate(projectExpensesProvider(widget.projectId));
                ref.invalidate(projectDashboardProvider(widget.projectId));
                ref.invalidate(projectDetailByIdProvider(widget.projectId));
                ref.invalidate(projectControllerProvider);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Disbursed ₹${amt.toInt()} to ${sub.name} & synced to Project Expenses ✓'
                          : 'Failed to record payment'),
                      backgroundColor: ok ? const Color(0xFF10B981) : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disburse & Sync Expense'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubcontractorDialog(Subcontractor sub) {
    final nameCtrl = TextEditingController(text: sub.name);
    final contactCtrl = TextEditingController(text: sub.contactPerson);
    final phoneCtrl = TextEditingController(text: sub.phone ?? '');
    final contractCtrl = TextEditingController(text: sub.contractValue > 0 ? sub.contractValue.toStringAsFixed(0) : '');
    final scopeCtrl = TextEditingController(text: sub.scopeOfWork ?? '');
    String specialization = sub.specialization ?? 'Civil & RCC';
    String status = sub.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Edit ${sub.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Company / Contractor Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: specialization,
                  decoration: const InputDecoration(labelText: 'Trade / Specialization *'),
                  items: [
                    'Civil & RCC',
                    'Masonry & Brickwork',
                    'Electrical & Wiring',
                    'Plumbing & Sanitary',
                    'Fabrication & Steel',
                    'Painting & Finishing',
                    'Carpentry & Woodwork',
                    'Flooring & Tiling',
                    'Waterproofing',
                    'HVAC',
                    'Other',
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDlgState(() => specialization = v ?? specialization),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Contract Status *'),
                  items: ['Active', 'Completed', 'Terminated']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => status = v ?? status),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Person Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone / WhatsApp Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contractCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Contract Value (₹) *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scopeCtrl,
                  decoration: const InputDecoration(labelText: 'Scope of Work / Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final updated = sub.copyWith(
                  name: nameCtrl.text.trim(),
                  companyNameProp: nameCtrl.text.trim(),
                  contactPersonProp: contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                  specialization: specialization,
                  status: status,
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  contractValue: double.tryParse(contractCtrl.text.trim()) ?? sub.contractValue,
                  scopeOfWork: scopeCtrl.text.trim().isEmpty ? null : scopeCtrl.text.trim(),
                );

                await ref.read(subcontractorControllerProvider.notifier).updateSubcontractor(updated);
                ref.invalidate(projectSubcontractorsProvider);
                ref.invalidate(projectDashboardProvider(widget.projectId));
                ref.invalidate(projectControllerProvider);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trade partner details updated successfully ✓'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubcontractorDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final contractCtrl = TextEditingController();
    final scopeCtrl = TextEditingController();
    String specialization = 'Civil & RCC';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Assign Trade Partner to ${widget.projectName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company / Contractor Name *',
                    hintText: 'e.g. Apex Electricals & Wiring',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: specialization,
                  decoration: const InputDecoration(labelText: 'Trade / Specialization *'),
                  items: [
                    'Civil & RCC',
                    'Masonry & Brickwork',
                    'Electrical & Wiring',
                    'Plumbing & Sanitary',
                    'Fabrication & Steel',
                    'Painting & Finishing',
                    'Carpentry & Woodwork',
                    'Flooring & Tiling',
                    'Waterproofing',
                    'HVAC',
                    'Other',
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDlgState(() => specialization = v ?? specialization),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person Name',
                    hintText: 'e.g. Rajesh Kumar',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone / WhatsApp Number',
                    hintText: 'e.g. 9876543210',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contractCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Contract Value (₹) *',
                    hintText: 'e.g. 250000',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scopeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Scope of Work',
                    hintText: 'e.g. Complete electrical conduit & wiring for Block A',
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
                if (nameCtrl.text.trim().isEmpty) return;
                final contractVal = double.tryParse(contractCtrl.text.trim()) ?? 0.0;
                final sub = Subcontractor(
                  id: '',
                  name: nameCtrl.text.trim(),
                  companyNameProp: nameCtrl.text.trim(),
                  contactPersonProp: contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                  specialization: specialization,
                  phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  projectId: widget.projectId,
                  siteNameProp: widget.projectName,
                  scopeOfWork: scopeCtrl.text.trim().isEmpty ? null : scopeCtrl.text.trim(),
                  contractValue: contractVal,
                  paidAmount: 0.0,
                  status: 'Active',
                  createdAt: DateTime.now(),
                );

                final ok = await ref.read(subcontractorControllerProvider.notifier).addSubcontractor(sub);
                ref.invalidate(projectSubcontractorsProvider);
                ref.invalidate(projectDashboardProvider(widget.projectId));
                ref.invalidate(projectControllerProvider);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Trade partner "${sub.name}" assigned to ${widget.projectName}!'
                          : 'Trade partner saved'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Assign Partner'),
            ),
          ],
        ),
      ),
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
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            tooltip: 'Download Payment Receipt PDF',
                            onPressed: () async {
                              final pdfBytes =
                                  await PaymentLedgerPdfGenerator.generatePaymentReceipt(
                                    p,
                                  );
                              await PdfDownloadHelper.downloadPdf(
                                bytes: Uint8List.fromList(pdfBytes),
                                filename: 'Payment_Receipt_${p.id}.pdf',
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

    return checkAsync.when(
      data: (allItems) {
        final completedCount = allItems.where((i) => i.isCompleted).length;
        final totalCount = allItems.length;
        final double progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

        final items = allItems.where((item) {
          if (_checklistFilter == 'Pending') return !item.isCompleted;
          if (_checklistFilter == 'Completed') return item.isCompleted;
          return true;
        }).toList();

        return Column(
          children: [
            // Top Progress & Action Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                border: Border(bottom: BorderSide(color: AppColors.border(context))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Site Quality & Inspection Tasks',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$completedCount of $totalCount Inspections Completed (${(progress * 100).toInt()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: completedCount == totalCount && totalCount > 0
                                  ? const Color(0xFF10B981)
                                  : AppColors.mutedText(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddChecklistDialog,
                        icon: const Icon(Icons.add_task, size: 16),
                        label: const Text('+ Add Task', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.border(context),
                      color: progress >= 1.0 ? const Color(0xFF10B981) : AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('All ($totalCount)', style: const TextStyle(fontSize: 11)),
                        selected: _checklistFilter == 'All',
                        onSelected: (s) => setState(() => _checklistFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Pending (${totalCount - completedCount})', style: const TextStyle(fontSize: 11)),
                        selected: _checklistFilter == 'Pending',
                        onSelected: (s) => setState(() => _checklistFilter = 'Pending'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Completed ($completedCount)', style: const TextStyle(fontSize: 11)),
                        selected: _checklistFilter == 'Completed',
                        selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                        onSelected: (s) => setState(() => _checklistFilter = 'Completed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Checklist Items List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt_outlined, size: 48, color: AppColors.outline),
                          const SizedBox(height: 12),
                          Text(
                            allItems.isEmpty ? 'No inspection tasks created yet' : 'No items match "$_checklistFilter"',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track slump tests, rebar inspections, curing & safety protocols',
                            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                          ),
                          if (allItems.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAddChecklistDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('+ Add First Inspection Task'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor(context),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return Card(
                          color: AppColors.cardBg(context),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: item.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.4) : AppColors.border(context),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isCompleted,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (val) async {
                                    if (val != null) {
                                      final client = ref.read(supabaseClientProvider);
                                      await SupabaseChecklistRepository(client).toggleChecklistItem(item.id, val);
                                      ref.invalidate(projectChecklistProvider(widget.projectId));
                                    }
                                  },
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.text(context),
                                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.category.toUpperCase(),
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.isCompleted ? 'Completed ✓' : 'Pending Inspection',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: item.isCompleted ? const Color(0xFF10B981) : AppColors.mutedText(context),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                  tooltip: 'Delete Task',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Checklist Task?'),
                                        content: Text('Remove "${item.title}" from inspection tasks?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final client = ref.read(supabaseClientProvider);
                                      await SupabaseChecklistRepository(client).deleteChecklistItem(item.id);
                                      ref.invalidate(projectChecklistProvider(widget.projectId));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading checklist: $e')),
    );
  }

  // 6. Drawings, Plans, Mapping & Site Photos Tab
  Widget _buildDrawingsTab() {
    final dwgAsync = ref.watch(projectDrawingsProvider(widget.projectId));

    return Column(
      children: [
        // Top Action Bar & Stat Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            border: Border(bottom: BorderSide(color: AppColors.border(context))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Site Drawings, Plans & Mapping',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload architectural layouts, structural blueprints, floor plans & site progress photos',
                          style: TextStyle(fontSize: 11.5, color: AppColors.mutedText(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isDrawingGridView = !_isDrawingGridView;
                          });
                        },
                        icon: Icon(
                          _isDrawingGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: AppColors.primaryColor(context),
                        ),
                        tooltip: _isDrawingGridView ? 'Switch to List View' : 'Switch to Grid View',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddDrawingDialog,
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                        label: const Text('Upload Plan / Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search & Filter Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _drawingSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search drawings, floor plans, blueprints, versions...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _drawingSearch.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _drawingSearchController.clear();
                                    setState(() {
                                      _drawingSearch = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.border(context)),
                          ),
                          filled: true,
                          fillColor: AppColors.bg(context),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _drawingSearch = v.trim().toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'Floor Plans & Mapping',
                    'Architectural',
                    'Structural',
                    'Electrical',
                    'Plumbing',
                    'Site Photos & Progress',
                    'HVAC',
                    'Other',
                  ].map((cat) {
                    final isSelected = _drawingCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryColor(context).withValues(alpha: 0.18),
                        backgroundColor: AppColors.bg(context),
                        checkmarkColor: AppColors.primaryColor(context),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primaryColor(context) : AppColors.text(context),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryColor(context) : AppColors.border(context),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _drawingCategoryFilter = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Body Content
        Expanded(
          child: dwgAsync.when(
            data: (allDrawings) {
              final filtered = allDrawings.where((d) {
                final matchCat = _drawingCategoryFilter == 'All' || d.category == _drawingCategoryFilter;
                final matchSearch = _drawingSearch.isEmpty ||
                    d.title.toLowerCase().contains(_drawingSearch) ||
                    d.category.toLowerCase().contains(_drawingSearch) ||
                    d.version.toLowerCase().contains(_drawingSearch) ||
                    (d.notes != null && d.notes!.toLowerCase().contains(_drawingSearch));
                return matchCat && matchSearch;
              }).toList();

              if (filtered.isEmpty) {
                return _emptyState(
                  allDrawings.isEmpty ? 'No site drawings or plans uploaded yet' : 'No drawings match filters',
                  allDrawings.isEmpty
                      ? 'Upload blueprints, architectural layouts, structural floor plans, or site progress photos directly.'
                      : 'Try resetting the search query or category filters.',
                );
              }

              if (_isDrawingGridView) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1100;
                    final isMedium = constraints.maxWidth > 700;
                    final crossAxisCount = isWide ? 4 : (isMedium ? 3 : (constraints.maxWidth > 480 ? 2 : 1));
                    final childAspectRatio = isWide ? 0.92 : (isMedium ? 0.90 : (constraints.maxWidth > 480 ? 0.88 : 1.3));

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _buildDrawingGridCard(filtered[i]),
                    );
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _buildDrawingListCard(filtered[i]),
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading project blueprints & drawings...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            error: (e, s) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                  const SizedBox(height: 8),
                  Text('Error loading drawings: $e', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.refresh(projectDrawingsProvider(widget.projectId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingGridCard(SiteDrawing d) {
    final catColor = _getDrawingCategoryColor(d.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFullscreenDrawingViewer(d),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail Header
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
                      child: _buildDrawingThumbnail(d.fileUrl),
                    ),
                    // Category Badge Overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          d.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Version Chip Overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          d.version,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body Details
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.text(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (d.notes != null && d.notes!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              d.notes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}',
                            style: TextStyle(fontSize: 10.5, color: AppColors.mutedText(context)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.fullscreen, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Inspect Fullscreen',
                                onPressed: () => _showFullscreenDrawingViewer(d),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.share_outlined, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Share via WhatsApp',
                                onPressed: () => _shareDrawingViaWhatsApp(d),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete Drawing',
                                onPressed: () => _deleteDrawingWithConfirmation(d),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingListCard(SiteDrawing d) {
    final catColor = _getDrawingCategoryColor(d.category);

    return Card(
      color: AppColors.cardBg(context),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 50,
            height: 50,
            child: _buildDrawingThumbnail(d.fileUrl),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                d.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: AppColors.text(context),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                d.category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: catColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                d.version,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${d.notes != null && d.notes!.isNotEmpty ? "${d.notes} • " : ""}Uploaded on ${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}',
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 20),
              tooltip: 'Fullscreen View',
              onPressed: () => _showFullscreenDrawingViewer(d),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 18),
              tooltip: 'Share via WhatsApp',
              onPressed: () => _shareDrawingViaWhatsApp(d),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              tooltip: 'Delete Drawing',
              onPressed: () => _deleteDrawingWithConfirmation(d),
            ),
          ],
        ),
        onTap: () => _showFullscreenDrawingViewer(d),
      ),
    );
  }

  Widget _buildDrawingThumbnail(String fileUrl) {
    if (fileUrl.startsWith('data:image')) {
      try {
        final commaIndex = fileUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = fileUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackDrawingIcon(),
          );
        }
      } catch (_) {}
    }
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return Image.network(
        fileUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.bg(context),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _fallbackDrawingIcon(),
      );
    }
    return _fallbackDrawingIcon();
  }

  Widget _fallbackDrawingIcon() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.architecture_outlined, size: 36, color: AppColors.primary),
      ),
    );
  }

  Color _getDrawingCategoryColor(String category) {
    switch (category) {
      case 'Floor Plans & Mapping':
        return const Color(0xFF8B5CF6);
      case 'Architectural':
        return const Color(0xFF0284C7);
      case 'Structural':
        return const Color(0xFFEA580C);
      case 'Electrical':
        return const Color(0xFFD97706);
      case 'Plumbing':
        return const Color(0xFF0D9488);
      case 'Site Photos & Progress':
        return const Color(0xFF059669);
      case 'HVAC':
        return const Color(0xFF4F46E5);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _shareDrawingViaWhatsApp(SiteDrawing d) {
    WhatsAppHelper.shareMessage(
      context: context,
      message: "*IBUILD SITE DRAWING & PLAN SHARE*\n"
          "----------------------------------------\n"
          "*Project:* ${widget.projectName}\n"
          "*Drawing Title:* ${d.title}\n"
          "*Category:* ${d.category}\n"
          "*Version:* ${d.version}\n"
          "*File Reference:* ${d.fileUrl.startsWith('http') ? d.fileUrl : 'Stored in IBUILD Site Portal'}\n"
          "${d.notes != null && d.notes!.isNotEmpty ? '*Notes:* ${d.notes}\n' : ''}"
          "----------------------------------------\n"
          "_Shared via IBUILD Construction ERP_",
      successNotice: 'Drawing details ready to share on WhatsApp',
    );
  }

  void _showFullscreenDrawingViewer(SiteDrawing d) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  '${d.category} • ${d.version} • Uploaded ${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                tooltip: 'Share via WhatsApp',
                onPressed: () => _shareDrawingViaWhatsApp(d),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: _buildDrawingThumbnail(d.fileUrl),
            ),
          ),
          bottomNavigationBar: d.notes != null && d.notes!.isNotEmpty
              ? Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Notes / Revisions: ${d.notes!}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  void _deleteDrawingWithConfirmation(SiteDrawing d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Drawing / Plan?'),
        content: Text('Are you sure you want to remove "${d.title}" (${d.version}) from this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final client = ref.read(supabaseClientProvider);
              final ok = await SupabaseDrawingRepository(client).deleteDrawing(d.id);
              if (ok) {
                ref.invalidate(projectDrawingsProvider(widget.projectId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Drawing "${d.title}" deleted.')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            tooltip: 'Download Sales Invoice PDF',
                            onPressed: () async {
                              final pdfBytes =
                                  await SalesBillPdfGenerator.generatePdf(b);
                              await PdfDownloadHelper.downloadPdf(
                                bytes: Uint8List.fromList(pdfBytes),
                                filename: 'Sales_Invoice_${b.billNumber}.pdf',
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
    String category = 'Floor Plans & Mapping';

    Uint8List? pickedBytes;
    String? pickedFileName;
    String? pickedExtension;
    bool isUploading = false;
    String uploadStatus = '';

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImage(ImageSource source) async {
            try {
              final result = await ImageCompressionService.pickAndCompress(source: source);
              if (result != null) {
                setDialogState(() {
                  pickedBytes = result.bytes;
                  pickedExtension = result.extension;
                  pickedFileName = 'site_${category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.${result.extension}';
                  if (titleCtrl.text.trim().isEmpty) {
                    titleCtrl.text = '$category Layout';
                  }
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error selecting photo: $e')),
              );
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primaryColor(context), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Upload Plan, Blueprint or Site Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width < 540 ? double.maxFinite : 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Direct Image Upload Picker Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: pickedBytes != null ? AppColors.secondary : AppColors.border(context),
                          width: pickedBytes != null ? 1.5 : 1,
                        ),
                      ),
                      child: pickedBytes != null
                          ? Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    pickedBytes!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Selected (${(pickedBytes!.length / 1024).toStringAsFixed(1)} KB)',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        setDialogState(() {
                                          pickedBytes = null;
                                          pickedFileName = null;
                                          pickedExtension = null;
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                      label: const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
                                const SizedBox(height: 6),
                                const Text(
                                  'Direct Image / Blueprint Upload',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Capture live site progress or pick high-res floor plans & blueprints from device',
                                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library_outlined, size: 15),
                                      label: const Text('Choose File / Gallery', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor(context),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => pickImage(ImageSource.camera),
                                      icon: const Icon(Icons.camera_alt_outlined, size: 15),
                                      label: const Text('Take Photo', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),

                    // Drawing Title
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Drawing / Plan Title *',
                        hintText: 'e.g. Ground Floor Layout & Structural Column Mapping',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category / Discipline *'),
                      items: [
                        'Floor Plans & Mapping',
                        'Architectural',
                        'Structural',
                        'Electrical',
                        'Plumbing',
                        'Site Photos & Progress',
                        'HVAC',
                        'Other',
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          category = v ?? category;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Version & Document Reference
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: versionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Version',
                              hintText: 'v1.0 / Rev A',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: fileUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'External URL (Optional)',
                              hintText: 'https://...',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes / Revisions
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Specifications / Revision Details',
                        hintText: 'Add revision details, grid references or site inspection notes...',
                      ),
                    ),

                    if (isUploading) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            uploadStatus.isNotEmpty ? uploadStatus : 'Uploading and processing drawing...',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryColor(context), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a drawing title.')),
                          );
                          return;
                        }

                        setDialogState(() {
                          isUploading = true;
                          uploadStatus = 'Uploading blueprint / site photo...';
                        });

                        String finalFileUrl = fileUrlCtrl.text.trim();

                        final client = ref.read(supabaseClientProvider);
                        final drawingRepo = SupabaseDrawingRepository(client);

                        if (pickedBytes != null) {
                          final uploadedUrl = await drawingRepo.uploadDrawingFile(
                            projectId: widget.projectId,
                            bytes: pickedBytes!,
                            fileName: pickedFileName ?? 'drawing.jpg',
                            extension: pickedExtension ?? 'jpg',
                          );
                          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                            finalFileUrl = uploadedUrl;
                          }
                        }

                        if (finalFileUrl.isEmpty) {
                          finalFileUrl = 'https://storage.supabase.co/drawings/site_blueprint.pdf';
                        }

                        final drawing = SiteDrawing(
                          id: '',
                          projectId: widget.projectId,
                          title: titleCtrl.text.trim(),
                          category: category,
                          version: versionCtrl.text.trim().isEmpty ? 'v1.0' : versionCtrl.text.trim(),
                          fileUrl: finalFileUrl,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          fileSizeBytes: pickedBytes?.length ?? 0,
                          createdAt: DateTime.now(),
                        );

                        final saved = await drawingRepo.addDrawing(drawing);

                        if (saved != null) {
                          await SupabaseActivityRepository(client).logSiteActivityAndNotify(
                            actionType: 'drawing_added',
                            entityType: 'site_drawings',
                            entityId: saved.id,
                            title: 'New Site Blueprint: ${saved.title} (${saved.category})',
                            projectId: widget.projectId,
                          );
                        }

                        ref.invalidate(projectDrawingsProvider(widget.projectId));
                        ref.invalidate(recentActivitiesProvider);
                        ref.invalidate(unreadNotificationsCountProvider);

                        if (ctx.mounted) Navigator.pop(ctx);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Drawing "${drawing.title}" uploaded successfully!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text('Save & Upload Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor(context),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
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

          final remainingBudget = p.budget - p.spent;
          final budgetPercent = p.budget > 0 ? (p.spent / p.budget).clamp(0.0, 1.0) : 0.0;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
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
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${p.id}',
                                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (p.customerMobile != null && p.customerMobile!.isNotEmpty)
                              IconButton.filledTonal(
                                icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                                tooltip: 'WhatsApp Client / Owner',
                                onPressed: () {
                                  WhatsAppHelper.shareMessage(
                                    context: context,
                                    message: 'Hello ${p.customerName ?? 'Sir/Madam'}, regarding the construction progress of ${p.name}...',
                                    phoneNumber: p.customerMobile,
                                    successNotice: 'Opening WhatsApp chat with client',
                                  );
                                },
                              ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProjectFormScreen(project: p),
                                  ),
                                );
                                ref.invalidate(projectDetailByIdProvider(widget.projectId));
                                ref.read(projectControllerProvider.notifier).loadProjects();
                              },
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              label: const Text('Edit Site Details', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor(context),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoTile('Site Name', p.name),
                    _infoTile(
                      'Site Address & Location',
                      (p.address != null && p.address!.isNotEmpty) ? p.address! : 'N/A',
                    ),
                    _infoTile('Project Status', p.status.toUpperCase()),
                    const Divider(height: 24),

                    // Financial Health Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Budget Utilization', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context))),
                              Text('${(budgetPercent * 100).toInt()}% Used', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: budgetPercent > 0.9 ? AppColors.error : const Color(0xFF10B981))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: budgetPercent,
                              backgroundColor: AppColors.border(context),
                              color: budgetPercent > 0.9 ? AppColors.error : AppColors.primary,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Allocated Budget', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                                  Text('₹${p.budget.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Spent', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                                  Text('₹${p.spent.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Remaining', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                                  Text('₹${remainingBudget.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: remainingBudget >= 0 ? const Color(0xFF10B981) : AppColors.error)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

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
                  ],
                ),
              ),
            ],
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


