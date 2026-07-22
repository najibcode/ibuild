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
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../attendance/presentation/controllers/attendance_controller.dart';
import '../../../attendance/data/models/attendance_model.dart';
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

  const ProjectOperationsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ProjectOperationsScreen> createState() => _ProjectOperationsScreenState();
}

class _ProjectOperationsScreenState extends ConsumerState<ProjectOperationsScreen> {
  int _activeSection = 0; // 0 = Grid, 1..10 = Submodules

  final Map<int, String> _sectionTitles = {
    0: 'Site Operations Dashboard',
    1: 'Today Attendance',
    2: 'Materials Inventory',
    3: 'Subcontractor / Trade Partners',
    4: 'Payment Ledger Status',
    5: 'Checklist Inspection',
    6: 'Site Drawings & Blueprints',
    7: 'Sales Bills & Client Invoices',
    8: 'Site Progress Images',
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

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
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
      body: Column(
        children: [
          if (_activeSection != 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.cardBg(context),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _returnToGrid,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Site Operations Grid'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _sectionTitles[_activeSection] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                  ),
                ],
              ),
            ),

          Expanded(child: _buildActiveContent()),
        ],
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
        return DailyProgressScreen(projectId: widget.projectId, projectName: widget.projectName);
      case 9:
        return _buildAboutSiteTab();
      case 10:
        return const FullReportGeneratorScreen();
      default:
        return _buildOverviewGridTab();
    }
  }

  // Perfectly Symmetrical 10-Card Responsive Grid (5 columns on Web/Desktop, 2 columns on Mobile)
  Widget _buildOverviewGridTab() {
    final projectAsync = ref.watch(projectDetailByIdProvider(widget.projectId));

    final cards = [
      _CardData('Today\nAttendance', Icons.calendar_today_outlined, AppColors.primary, 1),
      _CardData('Materials', Icons.inventory_2_outlined, Colors.orange, 2),
      _CardData('SubContractor', Icons.groups_outlined, Colors.amber.shade700, 3),
      _CardData('Payment\nStatus', Icons.account_balance_wallet_outlined, Colors.green, 4),
      _CardData('Check List', Icons.assignment_turned_in_outlined, Colors.blue, 5),
      _CardData('Drawing', Icons.architecture_outlined, Colors.indigo, 6),
      _CardData('Sales Bill', Icons.receipt_long_outlined, Colors.teal, 7),
      _CardData('Site Images', Icons.add_a_photo_outlined, Colors.pink, 8),
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

  // 1. Single-Day Attendance Logger Tab
  Widget _buildAttendanceTab() {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final activeEmployees = attendanceState.activeEmployees;
    final loggedAttendance = attendanceState.attendanceList;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppColors.cardBg(context),
            child: ListTile(
              leading: Icon(Icons.badge_outlined, color: AppColors.primaryColor(context)),
              title: Text('Today\'s Single-Day Worker Attendance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text(
                'Active Staff: ${activeEmployees.length} • Logged Today: ${loggedAttendance.length}',
                style: TextStyle(color: AppColors.mutedText(context)),
              ),
              trailing: ElevatedButton.icon(
                onPressed: () => ref.read(attendanceControllerProvider.notifier).loadAttendanceForToday(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: attendanceState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : activeEmployees.isEmpty
                    ? Center(
                        child: Text(
                          'No active employees found in database.',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: activeEmployees.length,
                        itemBuilder: (context, i) {
                          final emp = activeEmployees[i];
                          final record = loggedAttendance.firstWhere(
                            (a) => a.employeeId == emp.id,
                            orElse: () => Attendance(
                              id: '',
                              employeeId: emp.id,
                              date: DateTime.now().toIso8601String().substring(0, 10),
                              status: 'Absent',
                            ),
                          );

                          return Card(
                            color: AppColors.cardBg(context),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: record.status == 'Present'
                                    ? AppColors.secondary
                                    : (record.status == 'Leave' ? Colors.amber : AppColors.mutedText(context)),
                                child: Text(
                                  emp.name.isNotEmpty ? emp.name.substring(0, 1).toUpperCase() : 'E',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(emp.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                              subtitle: Text(
                                'Role: ${emp.role.toUpperCase()} • Daily Rate: ₹${emp.salary.toInt()}/day',
                                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Present', style: TextStyle(fontSize: 11)),
                                    selected: record.status == 'Present',
                                    selectedColor: AppColors.secondary,
                                    labelStyle: TextStyle(color: record.status == 'Present' ? Colors.white : AppColors.text(context)),
                                    onSelected: (_) {
                                      ref.read(attendanceControllerProvider.notifier).markAttendance(
                                        employeeId: emp.id,
                                        status: 'Present',
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  ChoiceChip(
                                    label: const Text('Absent', style: TextStyle(fontSize: 11)),
                                    selected: record.status == 'Absent',
                                    selectedColor: AppColors.error,
                                    labelStyle: TextStyle(color: record.status == 'Absent' ? Colors.white : AppColors.text(context)),
                                    onSelected: (_) {
                                      ref.read(attendanceControllerProvider.notifier).markAttendance(
                                        employeeId: emp.id,
                                        status: 'Absent',
                                      );
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
      ),
    );
  }

  // 2. Materials Tab
  Widget _buildMaterialsTab() {
    final invAsync = ref.watch(projectInventoryProvider);

    return invAsync.when(
      data: (items) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            color: AppColors.cardBg(context),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.category_outlined, color: AppColors.primary),
              title: Text(item.materialName, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text('Category: ${item.category} • Unit: ${item.unit}'),
              trailing: Text(
                'Qty: ${item.availableStock.toInt()}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
              ),
            ),
          );
        },
      ),
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
