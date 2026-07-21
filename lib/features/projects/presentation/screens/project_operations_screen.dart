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
import '../../../tickets/data/models/site_ticket_model.dart';
import '../../../tickets/data/repositories/supabase_ticket_repository.dart';
import '../../../drawings/data/models/site_drawing_model.dart';
import '../../../drawings/data/repositories/supabase_drawing_repository.dart';
import '../../../subcontractors/data/models/subcontractor_model.dart';
import '../../../subcontractors/data/repositories/supabase_subcontractor_repository.dart';
import '../../../inventory/data/models/inventory_item_model.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../attendance/presentation/controllers/attendance_controller.dart';
import '../../../attendance/data/models/attendance_model.dart';

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

final projectTicketsProvider = FutureProvider.family<List<SiteTicket>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  return await SupabaseTicketRepository(client).fetchTicketsForProject(projectId);
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

class _ProjectOperationsScreenState extends ConsumerState<ProjectOperationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Attendance',
    'Materials',
    'Subcontractors',
    'Payments',
    'Checklist',
    'Tickets',
    'Drawings',
    'Sales Bills',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryCol = AppColors.primaryColor(context);
    final mutedText = AppColors.mutedText(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.projectName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            Text('Operations Hub', style: TextStyle(fontSize: 12, color: mutedText)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryCol,
          unselectedLabelColor: mutedText,
          indicatorColor: primaryCol,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceTab(),
          _buildMaterialsTab(),
          _buildSubcontractorsTab(),
          _buildPaymentsTab(),
          _buildChecklistTab(),
          _buildTicketsTab(),
          _buildDrawingsTab(),
          _buildSalesBillsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  // 1. Attendance Tab
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
              title: Text('Today\'s Project Attendance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
              subtitle: Text(
                'Active Staff: ${activeEmployees.length} • Marked Today: ${loggedAttendance.length}',
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
                              morningStatus: 'Absent',
                              eveningStatus: 'Absent',
                            ),
                          );

                          final isPresent = record.morningStatus == 'Present' || record.eveningStatus == 'Present';

                          return Card(
                            color: AppColors.cardBg(context),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPresent ? AppColors.secondary : AppColors.mutedText(context),
                                child: Text(
                                  emp.name.isNotEmpty ? emp.name.substring(0, 1).toUpperCase() : 'E',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(emp.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                              subtitle: Text(
                                'Role: ${emp.role.toUpperCase()} • Morning: ${record.morningStatus} | Evening: ${record.eveningStatus}',
                                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                              ),
                              trailing: Icon(
                                isPresent ? Icons.check_circle : Icons.cancel_outlined,
                                color: isPresent ? AppColors.secondary : AppColors.error,
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
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.category_outlined, color: AppColors.primary),
              title: Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Category: ${item.category} • Unit: ${item.unit}'),
              trailing: Text(
                'Qty: ${item.availableStock.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.engineering_outlined, color: AppColors.primary),
              title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Trade: ${sub.specialization ?? 'General'} • Phone: ${sub.phone ?? 'N/A'}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${sub.contractValue.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  isRec ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isRec ? AppColors.secondary : AppColors.error,
                ),
                title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: item.isCompleted,
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(item.category),
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

  // 6. Tickets Tab
  Widget _buildTicketsTab() {
    final tixAsync = ref.watch(projectTicketsProvider(widget.projectId));

    return tixAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return _emptyState('No site tickets', 'Site issues and problem reports will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, i) {
            final t = tickets[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ticket: #${t.ticketNumber} • Priority: ${t.priority}'),
                trailing: Chip(
                  label: Text(t.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: t.status == 'Open' ? AppColors.warning : AppColors.secondary,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading tickets: $e')),
    );
  }

  // 7. Drawings Tab
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
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.draw_outlined, color: AppColors.primary),
                title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // 8. Sales Bills Tab
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
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                title: Text('Bill #${b.billNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Client: ${b.clientName}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${b.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // 9. Reports Tab
  Widget _buildReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: AppColors.surfaceWhite,
            child: ListTile(
              leading: const Icon(Icons.assessment_outlined, color: AppColors.primary),
              title: const Text('Project Operational Summary Report', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Complete audit log of expenses, materials, and labor'),
              trailing: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading Full Project Report...')),
                ),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download PDF'),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
