import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';

// Providers
final projectChecklistProvider = FutureProvider.family<List<ChecklistItem>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseChecklistRepository(client).fetchChecklistForProject(projectId);
});

final projectSalesBillsProvider = FutureProvider.family<List<SalesBill>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseSalesBillRepository(client).fetchSalesBillsForProject(projectId);
});

final projectPaymentsProvider = FutureProvider.family<List<ProjectPayment>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabasePaymentRepository(client).fetchPaymentsForProject(projectId);
});

final projectDrawingsProvider = FutureProvider.family<List<SiteDrawing>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseDrawingRepository(client).fetchDrawingsForProject(projectId);
});

final projectSubcontractorsProvider = FutureProvider<List<Subcontractor>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseSubcontractorRepository(client).fetchSubcontractors();
});

final projectInventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return await repo.getItems();
});

final projectDetailByIdProvider = FutureProvider.family<Project?, String>((ref, id) async {
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
  ConsumerState<ProjectOperationsScreen> createState() => _ProjectOperationsScreenState();
}

class _ProjectOperationsScreenState extends ConsumerState<ProjectOperationsScreen> {
  late int _activeSection; // 0 = Grid, 1..10 = Submodules

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
  }

  final Map<int, String> _sectionTitles = {
    0: 'Site Operations Dashboard',
    1: 'Today Attendance',
    2: 'Materials Inventory',
    3: 'Subcontractor / Trade Partners',
    4: 'Payment Ledger Status',
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

  void _returnToGrid() {
    setState(() {
      _activeSection = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mutedText = AppColors.mutedText(context);

    return PopScope(
      canPop: _activeSection == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeSection != 0) {
          _returnToGrid();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_activeSection != 0) {
                _returnToGrid();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.projectName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              Text(_sectionTitles[_activeSection] ?? 'Site Operations', style: TextStyle(fontSize: 12, color: mutedText)),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => _openSection(10),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Download Full Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
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
        return _buildOverviewGridTab();
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
        return DailyProgressScreen(projectId: widget.projectId, projectName: widget.projectName, showAppBar: false);
      case 9:
        return _buildAboutSiteTab();
      case 10:
        return const FullReportGeneratorScreen(showAppBar: false);
      default:
        return _buildOverviewGridTab();
    }
  }

  // Perfectly Symmetrical 10-Card Responsive Grid (5 columns on Web/Desktop, 2 columns on Mobile)
  Widget _buildOverviewGridTab() {
    final projectAsync = ref.watch(projectDetailByIdProvider(widget.projectId));

    final cards = [
      _CardData('Today\nAttendance', Icons.calendar_today_outlined, AppColors.primary, 1),
      _CardData('Daily Progress', Icons.analytics_outlined, Colors.pink, 8),
      _CardData('Materials', Icons.inventory_2_outlined, Colors.orange, 2),
      _CardData('SubContractor', Icons.groups_outlined, Colors.amber.shade700, 3),
      _CardData('Payment\nStatus', Icons.account_balance_wallet_outlined, Colors.green, 4),
      _CardData('Check List', Icons.assignment_turned_in_outlined, Colors.blue, 5),
      _CardData('Drawing', Icons.architecture_outlined, Colors.indigo, 6),
      _CardData('Sales Bill', Icons.receipt_long_outlined, Colors.teal, 7),
      _CardData('About Site', Icons.info_outline, Colors.purple, 9),
      _CardData('Site Report', Icons.summarize_outlined, Colors.deepOrange, 10),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900 ? 5 : (constraints.maxWidth > 600 ? 4 : 2);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb Header
              Row(
                children: [
                  Icon(Icons.home_outlined, size: 18, color: AppColors.mutedText(context)),
                  const SizedBox(width: 6),
                  Text('>', style: TextStyle(color: AppColors.mutedText(context), fontSize: 13)),
                  const SizedBox(width: 6),
                  Text('Site', style: TextStyle(color: AppColors.mutedText(context), fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text('>', style: TextStyle(color: AppColors.mutedText(context), fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(widget.projectName, style: TextStyle(color: AppColors.primaryColor(context), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Site Summary Bar at TOP
              projectAsync.when(
                data: (p) {
                  if (p == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metricCol('Budget', '₹${p.budget.toInt()}'),
                        _metricCol('Spent', '₹${p.spent.toInt()}'),
                        _metricCol('Customer', p.customerName ?? 'Direct Client'),
                        _metricCol('Status', p.status.toUpperCase()),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // 2. Perfectly Balanced & Symmetrical 10-Card Grid BELOW
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _buildSymmetricCard(card.title, card.icon, card.iconColor, () => _openSection(card.sectionIndex));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymmetricCard(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      ],
    );
  }

  // 1. Project-Scoped Attendance Tab
  Widget _buildAttendanceTab() {
    final projectAttendanceAsync = ref.watch(projectAttendanceProvider(widget.projectId));

    return projectAttendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading attendance: $e')),
      data: (data) {
        final todayRecords = data.todayRecords;
        // Recent history excluding today to avoid duplicates
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final historyRecords = data.recentHistory.where((r) => r.date != todayStr).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                color: AppColors.cardBg(context),
                child: ListTile(
                  leading: Icon(Icons.badge_outlined, color: AppColors.primaryColor(context)),
                  title: Text(
                    'Site Attendance - Today',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  subtitle: Text(
                    'Workers on site: ${todayRecords.where((r) => r.status == 'Present').length} present • ${todayRecords.where((r) => r.status != 'Present').length} absent',
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                  trailing: IconButton(
                    onPressed: () => ref.invalidate(projectAttendanceProvider(widget.projectId)),
                    icon: Icon(Icons.refresh, color: AppColors.primaryColor(context), size: 20),
                    tooltip: 'Refresh',
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
                        Icon(Icons.group_off_outlined, size: 48, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No workers assigned to this site today.',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.mutedText(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assign workers from the main Attendance tab to deploy them here.',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...todayRecords.map((record) => _buildProjectWorkerCard(record)),

              // Recent History Section
              if (historyRecords.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primaryColor(context), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(
                      'RECENT SITE HISTORY (LAST 7 DAYS)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryColor(context), letterSpacing: 0.5),
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
    final name = record.employeeName ?? 'Unknown Worker';
    final isPresent = record.status.toLowerCase() == 'present';

    return Card(
      color: AppColors.cardBg(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isPresent ? AppColors.secondary : AppColors.error,
              radius: 18,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'W',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context))),
                  const SizedBox(height: 2),
                  Text(
                    'Date: ${record.date}',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
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
                    ref.read(attendanceControllerProvider.notifier).markAttendance(
                      employeeId: record.employeeId,
                      status: 'Present',
                      projectId: widget.projectId,
                    );
                    // Refresh project-scoped data
                    Future.delayed(const Duration(milliseconds: 300), () {
                      ref.invalidate(projectAttendanceProvider(widget.projectId));
                    });
                  },
                  backgroundColor: AppColors.cardBg(context),
                  selectedColor: AppColors.secondary,
                  side: BorderSide(color: isPresent ? AppColors.secondary : AppColors.border(context)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                FilterChip(
                  label: Text(
                    'Absent',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: !isPresent ? Colors.white : AppColors.text(context),
                    ),
                  ),
                  selected: !isPresent,
                  onSelected: (_) {
                    ref.read(attendanceControllerProvider.notifier).markAttendance(
                      employeeId: record.employeeId,
                      status: 'Absent',
                      projectId: widget.projectId,
                    );
                    Future.delayed(const Duration(milliseconds: 300), () {
                      ref.invalidate(projectAttendanceProvider(widget.projectId));
                    });
                  },
                  backgroundColor: AppColors.cardBg(context),
                  selectedColor: AppColors.error,
                  side: BorderSide(color: !isPresent ? AppColors.error : AppColors.border(context)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable(List<Attendance> records) {
    // Group by date
    final Map<String, List<Attendance>> byDate = {};
    for (final r in records) {
      byDate.putIfAbsent(r.date, () => []).add(r);
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
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryColor(context)))),
                Expanded(flex: 3, child: Text('Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryColor(context)))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryColor(context)))),
              ],
            ),
          ),
          // Table Rows
          ...sortedDates.expand((date) {
            final dayRecords = byDate[date]!;
            return dayRecords.map((r) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border(context), width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(r.date, style: TextStyle(fontSize: 12, color: AppColors.text(context)))),
                  Expanded(flex: 3, child: Text(r.employeeName ?? 'Worker', style: TextStyle(fontSize: 12, color: AppColors.text(context)))),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          color: r.status == 'Present' ? AppColors.secondary : AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ));
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
          return _emptyState('No materials in stock', 'Register or assign site inventory for this project');
        }

        final double totalValuation = items.fold(0.0, (sum, i) => sum + (i.availableStock * i.purchasePrice));
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
                      Text('Site Material Valuation', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('₹${totalValuation.toInt()}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context))),
                      const SizedBox(height: 2),
                      Text('${items.length} Material Types Tracked', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                    ],
                  ),
                  if (lowStockCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text('$lowStockCount Low Stock', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 11)),
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
                  border: Border.all(color: item.isLowStock ? AppColors.error.withOpacity(0.4) : AppColors.border(context)),
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
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: runwayColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                runwayDays > 90 ? 'Runway: 90+ Days' : 'Runway: $runwayDays Days',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: runwayColor),
                              ),
                            ),
                            if (item.isLowStock) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('LOW STOCK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.error)),
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
                            Text(item.materialName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context))),
                            const SizedBox(height: 2),
                            Text('Burn Rate: ~${item.estimatedDailyBurnRate.toStringAsFixed(1)} ${item.unit}/day • Rate: ₹${item.purchasePrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${valuation.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryColor(context))),
                            Text('Available: ${item.availableStock.toStringAsFixed(1)} ${item.unit}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          ],
                        ),
                      ],
                    ),
                    if (item.isLowStock) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, size: 14, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text(
                              'Auto Reorder Suggestion: Order +${item.recommendedReorderQty.toInt()} ${item.unit} (Est ₹${item.estimatedReorderCost.toInt()})',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.text(context)),
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
              leading: const Icon(Icons.engineering_outlined, color: AppColors.primary),
              title: Text(sub.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('Trade: ${sub.specialization ?? 'General'} • Phone: ${sub.phone ?? 'N/A'}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${sub.contractValue.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  Text(sub.status, style: TextStyle(color: sub.status == 'Active' ? AppColors.secondary : AppColors.textMuted, fontSize: 11)),
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

  // 4. Payments Tab
  Widget _buildPaymentsTab() {
    final payAsync = ref.watch(projectPaymentsProvider(widget.projectId));

    return payAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return _emptyState('No payment records', 'Record payments received or paid for this project');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                title: Text(p.title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                subtitle: Text('Method: ${p.paymentMethod} • Ref: ${p.referenceNo ?? 'N/A'}'),
                trailing: Text(
                  '${isRec ? '+' : '-'}₹${p.amount.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRec ? AppColors.secondary : AppColors.error,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading payments: $e')),
    );
  }

  // 5. Checklist Tab
  Widget _buildChecklistTab() {
    final checkAsync = ref.watch(projectChecklistProvider(widget.projectId));

    return checkAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _emptyState('No checklist items', 'Add quality inspection tasks for this site');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text('Phase: ${item.phaseGroup} • Status: ${item.approvalStatus}'),
                onChanged: (val) async {
                  if (val != null) {
                    final client = ref.read(supabaseClientProvider);
                    await SupabaseChecklistRepository(client).toggleChecklistItem(item.id, val);
                    ref.invalidate(projectChecklistProvider(widget.projectId));
                  }
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading checklist: $e')),
    );
  }

  // 6. Drawings Tab
  Widget _buildDrawingsTab() {
    final dwgAsync = ref.watch(projectDrawingsProvider(widget.projectId));

    return dwgAsync.when(
      data: (drawings) {
        if (drawings.isEmpty) {
          return _emptyState('No site drawings', 'Blueprints and structural layouts will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drawings.length,
          itemBuilder: (context, i) {
            final d = drawings[i];
            return Card(
              color: AppColors.cardBg(context),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.draw_outlined, color: AppColors.primary),
                title: Text(d.title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                subtitle: Text('Category: ${d.category} • Version: ${d.version}'),
                trailing: const Icon(Icons.download, color: AppColors.primary),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading drawings: $e')),
    );
  }

  // 7. Sales Bills Tab
  Widget _buildSalesBillsTab() {
    final billsAsync = ref.watch(projectSalesBillsProvider(widget.projectId));

    return billsAsync.when(
      data: (bills) {
        if (bills.isEmpty) {
          return _emptyState('No sales bills', 'Invoices generated for client billing');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bills.length,
          itemBuilder: (context, i) {
            final b = bills[i];
            return Card(
              color: AppColors.cardBg(context),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                title: Text('Bill #${b.billNumber}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                subtitle: Text('Client: ${b.clientName}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${b.totalAmount.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    Text(b.status, style: TextStyle(color: b.status == 'Paid' ? AppColors.secondary : AppColors.error, fontSize: 11)),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading sales bills: $e')),
    );
  }

  // 8. About Site Tab
  Widget _buildAboutSiteTab() {
    final projectAsync = ref.watch(projectDetailByIdProvider(widget.projectId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: projectAsync.when(
        data: (p) {
          if (p == null) return _emptyState('Site Not Found', 'Could not load site details');
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
                Text('Detailed Site Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const Divider(height: 24),
                _infoTile('Site Name', p.name),
                _infoTile('Site Address & Location', (p.address != null && p.address!.isNotEmpty) ? p.address! : 'N/A'),
                _infoTile('Project Status', p.status.toUpperCase()),
                const Divider(height: 24),
                Text('Customer / Owner Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 8),
                _infoTile('Customer Name', p.customerName ?? 'Direct Client'),
                _infoTile('Customer Mobile', p.customerMobile ?? 'N/A'),
                _infoTile('Customer Email', p.customerEmail ?? 'N/A'),
                _infoTile('Customer Address', p.customerAddress ?? 'N/A'),
                _infoTile('Customer Date of Birth', p.customerDob ?? 'N/A'),
                const Divider(height: 24),
                Text('Site Engineering Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                const SizedBox(height: 8),
                _infoTile('Built-Up Area', p.builtUpArea > 0 ? '${p.builtUpArea.toInt()} sqft' : 'N/A'),
                _infoTile('Flat Area', p.flatArea > 0 ? '${p.flatArea.toInt()} sqft' : 'N/A'),
                _infoTile('Project Duration', p.duration != null ? '${p.duration} Months' : 'N/A'),
                _infoTile('Assigned Supervisor', p.supervisorId ?? 'Unassigned'),
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
            child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.mutedText(context), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text(context))),
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
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
        ],
      ),
    );
  }
}

class _CardData {
  final String title;
  final IconData icon;
  final Color iconColor;
  final int sectionIndex;

  _CardData(this.title, this.icon, this.iconColor, this.sectionIndex);
}
