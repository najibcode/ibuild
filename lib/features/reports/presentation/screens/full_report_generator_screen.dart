import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/mobile_nav_helper.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../attendance/presentation/controllers/attendance_controller.dart';
import '../../../subcontractors/presentation/controllers/subcontractor_controller.dart';
import '../../../daily_progress/presentation/controllers/daily_progress_controller.dart';
import '../../../daily_progress/data/models/daily_progress_model.dart';
import '../../../inventory/data/models/inventory_history_model.dart';
import '../../../subcontractors/data/models/subcontractor_model.dart';
import '../../../employees/presentation/controllers/employee_controller.dart';
import '../../../payments/data/models/payment_ledger_model.dart';
import '../../../payments/data/repositories/supabase_payment_ledger_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/pdf_report_generator.dart';

enum ReportCadence { daily, weekly, monthly, custom }

class FullReportGeneratorScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final String? initialProjectId;
  final VoidCallback? onBackPressed;

  const FullReportGeneratorScreen({
    super.key,
    this.showAppBar = true,
    this.initialProjectId,
    this.onBackPressed,
  });

  @override
  ConsumerState<FullReportGeneratorScreen> createState() =>
      _FullReportGeneratorScreenState();
}

class _FullReportGeneratorScreenState
    extends ConsumerState<FullReportGeneratorScreen> {
  ReportCadence _cadence = ReportCadence.daily;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _customStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customEndDate = DateTime.now();

  String? _selectedProjectId = 'all'; // 'all' means all projects
  String _activeSectionFilter = 'all'; // 'all', 'projects', 'inventory', 'subcontractors', 'expenses', 'attendance'

  List<DailyProgress> _loadedDailyProgress = [];
  List<InventoryHistory> _loadedInventoryHistory = [];
  bool _isLoadingPeriodData = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProjectId != null && widget.initialProjectId!.isNotEmpty) {
      _selectedProjectId = widget.initialProjectId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPeriodData();
    });
  }

  String get _startDateStr {
    switch (_cadence) {
      case ReportCadence.daily:
        return DateFormat('yyyy-MM-dd').format(_selectedDate);
      case ReportCadence.weekly:
        return DateFormat('yyyy-MM-dd').format(_selectedWeekStart);
      case ReportCadence.monthly:
        return DateFormat('yyyy-MM-dd').format(
          DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        );
      case ReportCadence.custom:
        return DateFormat('yyyy-MM-dd').format(_customStartDate);
    }
  }

  String get _endDateStr {
    switch (_cadence) {
      case ReportCadence.daily:
        return DateFormat('yyyy-MM-dd').format(_selectedDate);
      case ReportCadence.weekly:
        return DateFormat('yyyy-MM-dd').format(
          _selectedWeekStart.add(const Duration(days: 6)),
        );
      case ReportCadence.monthly:
        return DateFormat('yyyy-MM-dd').format(
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
        );
      case ReportCadence.custom:
        return DateFormat('yyyy-MM-dd').format(_customEndDate);
    }
  }

  String get _periodTitle {
    switch (_cadence) {
      case ReportCadence.daily:
        final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        final dateStr = DateFormat('dd MMMM yyyy').format(_selectedDate);
        return isToday ? 'Daily Report • Today ($dateStr)' : 'Daily Report • $dateStr';
      case ReportCadence.weekly:
        final start = DateFormat('dd MMM').format(_selectedWeekStart);
        final end = DateFormat('dd MMM yyyy').format(
          _selectedWeekStart.add(const Duration(days: 6)),
        );
        return 'Weekly Report • $start – $end';
      case ReportCadence.monthly:
        return 'Monthly Report • ${DateFormat('MMMM yyyy').format(_selectedMonth)}';
      case ReportCadence.custom:
        final start = DateFormat('dd MMM yyyy').format(_customStartDate);
        final end = DateFormat('dd MMM yyyy').format(_customEndDate);
        return 'Custom Audit Report • $start – $end';
    }
  }

  Future<void> _fetchPeriodData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPeriodData = true;
    });

    try {
      final dailyProgressRepo = ref.read(dailyProgressRepositoryProvider);
      final inventoryRepo = ref.read(inventoryRepositoryProvider);

      final progressList = await dailyProgressRepo.getProgressForDateRange(
        projectId: _selectedProjectId == 'all' ? null : _selectedProjectId,
        startDate: _startDateStr,
        endDate: _endDateStr,
      );

      final historyList = await inventoryRepo.getAllHistory(
        startDate: _startDateStr,
        endDate: _endDateStr,
      );

      if (mounted) {
        setState(() {
          _loadedDailyProgress = progressList;
          _loadedInventoryHistory = historyList;
          _isLoadingPeriodData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPeriodData = false;
        });
      }
    }
  }

  void _shiftDate(int days) {
    setState(() {
      switch (_cadence) {
        case ReportCadence.daily:
          _selectedDate = _selectedDate.add(Duration(days: days));
          break;
        case ReportCadence.weekly:
          _selectedWeekStart = _selectedWeekStart.add(Duration(days: days * 7));
          break;
        case ReportCadence.monthly:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + days,
            1,
          );
          break;
        case ReportCadence.custom:
          break;
      }
    });
    _fetchPeriodData();
  }

  String _generateFormattedReportText() {
    final projectState = ref.read(projectControllerProvider);
    final expenseState = ref.read(expenseControllerProvider);
    final attendanceState = ref.read(attendanceControllerProvider);
    final subcontractorState = ref.read(subcontractorControllerProvider);
    final inventoryState = ref.read(inventoryControllerProvider);
    final employees = ref.read(employeeListControllerProvider).valueOrNull ?? [];

    final projects = _selectedProjectId == null || _selectedProjectId == 'all'
        ? projectState.projects
        : projectState.projects
            .where((p) => p.id == _selectedProjectId)
            .toList();

    final projectName = projects.isEmpty
        ? 'All Enterprise Sites'
        : (projects.length == 1
            ? '${projects.first.name} (${projects.first.address ?? "Site Location"})'
            : '${projects.length} Selected Projects');

    // Filter expenses for this date range
    final filteredExpenses = expenseState.expenses.where((e) {
      final matchesProject = _selectedProjectId == null ||
          _selectedProjectId == 'all' ||
          e.projectId == _selectedProjectId;
      final inRange = e.expenseDate.compareTo(_startDateStr) >= 0 &&
          e.expenseDate.compareTo(_endDateStr) <= 0;
      return matchesProject && inRange;
    }).toList();

    final double totalExpensesAmount = filteredExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    // Filter attendance for this date range
    final filteredAttendance = attendanceState.attendanceList.where((a) {
      final matchesProject = _selectedProjectId == null ||
          _selectedProjectId == 'all' ||
          a.projectId == _selectedProjectId;
      final inRange = a.date.compareTo(_startDateStr) >= 0 &&
          a.date.compareTo(_endDateStr) <= 0;
      return matchesProject && inRange;
    }).toList();

    final double totalBudget = projects.fold(0.0, (sum, p) => sum + p.budget);
    final double totalSpent = projects.fold(0.0, (sum, p) => sum + p.spent);
    final double remainingBal = totalBudget > totalSpent ? (totalBudget - totalSpent) : 0.0;
    final double budgetUtil = totalBudget > 0 ? ((totalSpent / totalBudget) * 100).clamp(0.0, 100.0) : 0.0;

    final buffer = StringBuffer();
    buffer.writeln("================================================================================");
    buffer.writeln("                    IBUILD CONSTRUCTION MANAGEMENT ERP                         ");
    buffer.writeln("                   OFFICIAL AUDIT & OPERATIONAL REPORT                          ");
    buffer.writeln("================================================================================");
    buffer.writeln("Report Scope   : $projectName");
    buffer.writeln("Report Cadence : $_periodTitle");
    buffer.writeln("Date Interval  : $_startDateStr to $_endDateStr");
    buffer.writeln("Generated On   : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}");
    buffer.writeln("================================================================================\n");

    buffer.writeln("1. EXECUTIVE FINANCIAL & OPERATIONAL TELEMETRY");
    buffer.writeln("--------------------------------------------------------------------------------");
    buffer.writeln("• Period Outflows / Spend    : ₹${totalExpensesAmount.toStringAsFixed(2)} (${filteredExpenses.length} vouchers logged)");
    buffer.writeln("• Total Project Baseline     : ₹${totalBudget.toStringAsFixed(2)}");
    buffer.writeln("• Total Cumulative Spend     : ₹${totalSpent.toStringAsFixed(2)}");
    buffer.writeln("• Remaining Balance          : ₹${remainingBal.toStringAsFixed(2)}");
    buffer.writeln("• Financial Utilization Rate : ${budgetUtil.toStringAsFixed(1)}%");
    buffer.writeln("• Material Movements Logged  : ${_loadedInventoryHistory.length} transaction entries");
    buffer.writeln("• Active Trade Partners      : ${subcontractorState.items.length} subcontractor firms");
    buffer.writeln("• Labor Shifts Recorded      : ${filteredAttendance.length} worker shifts\n");

    // Category-wise Breakdown
    if (filteredExpenses.isNotEmpty) {
      buffer.writeln("2. PERIOD EXPENSE CATEGORY BREAKDOWN");
      buffer.writeln("--------------------------------------------------------------------------------");
      final Map<String, double> catTotals = {};
      for (final e in filteredExpenses) {
        final c = e.category.isEmpty ? 'General' : e.category;
        catTotals[c] = (catTotals[c] ?? 0.0) + e.amount;
      }
      for (final entry in catTotals.entries) {
        final pct = totalExpensesAmount > 0 ? (entry.value / totalExpensesAmount * 100) : 0.0;
        buffer.writeln("• ${entry.key.padRight(20)}: ₹${entry.value.toStringAsFixed(2).padLeft(12)} (${pct.toStringAsFixed(1)}%)");
      }
      buffer.writeln();
    }

    // 3. Project Portfolio Status
    buffer.writeln("3. PROJECT SITES & DAILY OPERATIONAL NOTES");
    buffer.writeln("--------------------------------------------------------------------------------");
    if (projects.isEmpty) {
      buffer.writeln("• No active projects found in this scope.\n");
    } else {
      for (final p in projects) {
        final progressVal = ((p.physicalProgress ?? (p.budget > 0 ? (p.spent / p.budget * 100) : 0.0))).clamp(0.0, 100.0);
        buffer.writeln("• Site: ${p.name} [Status: ${p.status.toUpperCase()}]");
        buffer.writeln("  - Client: ${p.clientName ?? p.customerName ?? 'Direct Client'} | Location: ${p.address ?? '-'}");
        buffer.writeln("  - Progress: ${progressVal.toStringAsFixed(0)}% | Budget: ₹${p.budget.toStringAsFixed(0)} | Spent: ₹${p.spent.toStringAsFixed(0)} | Balance: ₹${(p.budget - p.spent).toStringAsFixed(0)}");
      }
      if (_loadedDailyProgress.isNotEmpty) {
        buffer.writeln("\n  Site Execution Logs:");
        for (final dp in _loadedDailyProgress) {
          final notes = dp.allNotes.isNotEmpty ? dp.allNotes.join(' | ') : 'Operational progress recorded';
          buffer.writeln("  - [${dp.date}] Milestone: ${dp.progressPercentage}% | Details: $notes");
        }
      }
      buffer.writeln();
    }

    // 4. Subcontractors Ledger
    buffer.writeln("4. TRADE PARTNERS & SUBCONTRACTORS LEDGER");
    buffer.writeln("--------------------------------------------------------------------------------");
    if (subcontractorState.items.isEmpty) {
      buffer.writeln("• No subcontractor records registered.\n");
    } else {
      for (final s in subcontractorState.items) {
        buffer.writeln("• ${s.companyName} (${s.tradeSpecialization}) - Site: ${s.siteName}");
        buffer.writeln("  - Contact: ${s.contactPerson} (${s.phone ?? '-'}) | Status: ${s.status.toUpperCase()}");
        buffer.writeln("  - Contract: ₹${s.contractValue.toStringAsFixed(0)} | Paid: ₹${s.paidAmount.toStringAsFixed(0)} | Retention Due: ₹${s.outstandingAmount.toStringAsFixed(0)}");
      }
      buffer.writeln();
    }

    // 5. Inventory Stock Movements & Health
    buffer.writeln("5. INVENTORY STOCK MOVEMENTS & HEALTH AUDIT");
    buffer.writeln("--------------------------------------------------------------------------------");
    if (_loadedInventoryHistory.isEmpty) {
      buffer.writeln("• No material movements logged for this period.");
    } else {
      for (final h in _loadedInventoryHistory) {
        final type = h.changeType == 'added' ? 'RECEIVED (GRN)' : (h.changeType == 'used' ? 'ISSUED (Site)' : h.changeType.toUpperCase());
        buffer.writeln("• [${h.createdAt?.substring(0, 10) ?? _startDateStr}] $type: ${h.quantityChange.abs().toStringAsFixed(1)} units | Details: ${h.notes ?? '-'}");
      }
    }
    final lowStockItems = inventoryState.items.where((i) => i.isLowStock).toList();
    if (lowStockItems.isNotEmpty) {
      buffer.writeln("\n  Low Stock Reorder Alerts:");
      for (final item in lowStockItems) {
        buffer.writeln("  ! ${item.materialName}: ${item.availableStock} ${item.unit} available (below minimum ${item.minimumStock} ${item.unit})");
      }
    }
    buffer.writeln();

    // 6. Labor Attendance & Muster Roll
    buffer.writeln("6. WORKER ATTENDANCE & MUSTER ROLL");
    buffer.writeln("--------------------------------------------------------------------------------");
    if (filteredAttendance.isEmpty) {
      buffer.writeln("• No attendance records logged for this period.\n");
    } else {
      final empMap = {for (final e in employees) e.id: e};
      for (final a in filteredAttendance) {
        final emp = empMap[a.employeeId];
        buffer.writeln("• ${a.date} | ${a.employeeName ?? emp?.name ?? 'Worker'} (${emp?.role ?? 'Staff'}) | Shift: ${a.status.toUpperCase()} | Site: ${a.projectName ?? 'General Site'}");
      }
      buffer.writeln();
    }

    // 7. Individual Expense Outflows
    buffer.writeln("7. LOGGED SITE EXPENSE VOUCHERS");
    buffer.writeln("--------------------------------------------------------------------------------");
    if (filteredExpenses.isEmpty) {
      buffer.writeln("• No expense records for this period.\n");
    } else {
      for (final e in filteredExpenses) {
        buffer.writeln("• ${e.expenseDate} | [${e.category.toUpperCase()}] ₹${e.amount.toStringAsFixed(2)} via ${e.paymentMode.toUpperCase()} | Recorded By: ${e.recordedBy ?? '-'} | Site: ${e.projectName ?? 'General'} | Ref: ${e.notes ?? '-'}");
      }
      buffer.writeln();
    }

    buffer.writeln("================================================================================");
    buffer.writeln("                      END OF OFFICIAL AUDIT REPORT                              ");
    buffer.writeln("================================================================================");

    return buffer.toString();
  }

  String _generateWhatsAppReportText() {
    final projects = ref.read(projectControllerProvider).projects;
    final projectName = _selectedProjectId == 'all'
        ? 'All Portfolio Sites'
        : (projects.where((p) => p.id == _selectedProjectId).isNotEmpty
            ? projects.firstWhere((p) => p.id == _selectedProjectId).name
            : 'Project Site');
    final expenseState = ref.read(expenseControllerProvider);
    final attendanceState = ref.read(attendanceControllerProvider);
    final subcontractorState = ref.read(subcontractorControllerProvider);
    final inventoryState = ref.read(inventoryControllerProvider);

    final filteredExpenses = expenseState.expenses.where((e) {
      final matchesProject = _selectedProjectId == null ||
          _selectedProjectId == 'all' ||
          e.projectId == _selectedProjectId;
      final inRange = e.expenseDate.compareTo(_startDateStr) >= 0 &&
          e.expenseDate.compareTo(_endDateStr) <= 0;
      return matchesProject && inRange;
    }).toList();

    final totalExpensesAmount = filteredExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final filteredAttendance = attendanceState.attendanceList.where((a) {
      final matchesProject = _selectedProjectId == null ||
          _selectedProjectId == 'all' ||
          a.projectId == _selectedProjectId;
      final inRange = a.date.compareTo(_startDateStr) >= 0 &&
          a.date.compareTo(_endDateStr) <= 0;
      return matchesProject && inRange;
    }).toList();

    final buffer = StringBuffer();
    buffer.writeln("🏗️ *IBUILD SITE EXECUTIVE REPORT*");
    buffer.writeln("📍 *Scope:* $projectName");
    buffer.writeln("📅 *Period:* $_periodTitle");
    buffer.writeln("🗓️ *Dates:* $_startDateStr to $_endDateStr");
    buffer.writeln("----------------------------------------");
    buffer.writeln("📊 *EXECUTIVE SUMMARY*");
    buffer.writeln("• *Period Outflow:* ₹${totalExpensesAmount.toStringAsFixed(0)} (${filteredExpenses.length} vouchers)");
    buffer.writeln("• *Material Shifts:* ${_loadedInventoryHistory.length} txns");
    buffer.writeln("• *Labor Attendance:* ${filteredAttendance.length} shifts recorded");
    buffer.writeln("• *Trade Partners:* ${subcontractorState.items.length} active");
    buffer.writeln("----------------------------------------");

    if (_loadedDailyProgress.isNotEmpty) {
      buffer.writeln("🚧 *SITE WORK PROGRESS*");
      for (final dp in _loadedDailyProgress.take(4)) {
        final notes = dp.allNotes.isNotEmpty ? dp.allNotes.join(', ') : 'Daily site work executed';
        buffer.writeln("• *${dp.date}* (${dp.progressPercentage}%): $notes");
      }
      buffer.writeln("----------------------------------------");
    }

    if (filteredExpenses.isNotEmpty) {
      buffer.writeln("💰 *TOP EXPENSE BREAKDOWN*");
      final Map<String, double> catTotals = {};
      for (final e in filteredExpenses) {
        final c = e.category.isEmpty ? 'General' : e.category;
        catTotals[c] = (catTotals[c] ?? 0.0) + e.amount;
      }
      for (final entry in catTotals.entries.take(4)) {
        buffer.writeln("• *${entry.key}:* ₹${entry.value.toStringAsFixed(0)}");
      }
      buffer.writeln("----------------------------------------");
    }

    if (_loadedInventoryHistory.isNotEmpty) {
      buffer.writeln("📦 *INVENTORY STOCK DELIVERIES*");
      for (final h in _loadedInventoryHistory.take(4)) {
        final type = h.changeType == 'added' ? '📥 [Received]' : '📤 [Issued]';
        buffer.writeln("• $type: ${h.quantityChange.abs().toStringAsFixed(1)} units (${h.notes ?? 'Movement'})");
      }
      buffer.writeln("----------------------------------------");
    }

    final lowStock = inventoryState.items.where((i) => i.isLowStock).toList();
    if (lowStock.isNotEmpty) {
      buffer.writeln("⚠️ *LOW STOCK WARNINGS*");
      for (final item in lowStock.take(3)) {
        buffer.writeln("• ${item.materialName}: ${item.availableStock} ${item.unit} (Min: ${item.minimumStock})");
      }
      buffer.writeln("----------------------------------------");
    }

    buffer.writeln("⚡ _Generated via IBUILD Construction ERP_");
    return buffer.toString();
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final text = _generateWhatsAppReportText();
    await WhatsAppHelper.shareMessage(
      context: context,
      message: text,
      successNotice: 'Executive site report prepared',
    );
  }

  void _showReportPreviewModal(BuildContext context) {
    final reportText = _generateFormattedReportText();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.article_outlined,
              color: AppColors.secondary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Audit Report Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width < 600 ? double.maxFinite : 580,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: SelectableText(
                reportText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.text(context),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _shareViaWhatsApp(context);
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('WhatsApp Dispatch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied full Audit Report to clipboard! Ready to paste/share.'),
                  backgroundColor: AppColors.secondary,
                ),
              );
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Text'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text(context),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportPdf(context);
            },
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Export as PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final projectState = ref.read(projectControllerProvider);
    final expenseState = ref.read(expenseControllerProvider);
    final inventoryState = ref.read(inventoryControllerProvider);
    final attendanceState = ref.read(attendanceControllerProvider);
    final subcontractorState = ref.read(subcontractorControllerProvider);
    final employees = ref.read(employeeListControllerProvider).valueOrNull ?? [];

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating comprehensive PDF report...'),
          duration: Duration(seconds: 1),
        ),
      );

      final isSingleProject = _selectedProjectId != null && _selectedProjectId != 'all';
      final filteredProjects = isSingleProject
          ? projectState.projects.where((p) => p.id == _selectedProjectId).toList()
          : projectState.projects;

      final filteredExpenses = expenseState.expenses.where((e) {
        final matchesProject = !isSingleProject || e.projectId == _selectedProjectId;
        final inRange = e.expenseDate.compareTo(_startDateStr) >= 0 &&
            e.expenseDate.compareTo(_endDateStr) <= 0;
        return matchesProject && inRange;
      }).toList();

      final filteredAttendance = attendanceState.attendanceList.where((a) {
        final matchesProject = !isSingleProject || a.projectId == _selectedProjectId;
        final inRange = a.date.compareTo(_startDateStr) >= 0 &&
            a.date.compareTo(_endDateStr) <= 0;
        return matchesProject && inRange;
      }).toList();

      // Fetch payment ledger records
      List<PaymentLedgerEntry> ledgerEntries = [];
      try {
        final ledgerRepo = SupabasePaymentLedgerRepository(Supabase.instance.client);
        final allEntries = isSingleProject && _selectedProjectId != null
            ? await ledgerRepo.fetchLedgerForProject(_selectedProjectId!)
            : await ledgerRepo.fetchAllLedgerEntries();
        ledgerEntries = allEntries.where((p) {
          final pDateStr = DateFormat('yyyy-MM-dd').format(p.paymentDate);
          return pDateStr.compareTo(_startDateStr) >= 0 && pDateStr.compareTo(_endDateStr) <= 0;
        }).toList();
      } catch (_) {}

      // Compile attention required items
      final List<String> attentionItems = [];
      for (final p in filteredProjects) {
        if (p.spent > p.budget && p.budget > 0) {
          attentionItems.add('Budget alert: "${p.name}" spent ₹${p.spent.toStringAsFixed(0)} against budget ₹${p.budget.toStringAsFixed(0)}');
        }
      }
      for (final item in inventoryState.items) {
        if (item.isLowStock) {
          attentionItems.add('Low inventory warning: ${item.materialName} has ${item.availableStock} ${item.unit} in stock (below minimum ${item.minimumStock})');
        }
      }
      for (final s in subcontractorState.items) {
        if (s.outstandingAmount > 0) {
          attentionItems.add('Payment retention balance pending for trade partner ${s.companyName}: ₹${s.outstandingAmount.toStringAsFixed(0)}');
        }
      }

      final pdfBytes = await PdfReportGenerator.generateReport(
        reportType: _periodTitle,
        dateRangeLabel: '$_startDateStr to $_endDateStr',
        projects: projectState.projects,
        expenses: filteredExpenses,
        inventoryItems: inventoryState.items,
        inventoryMovements: _loadedInventoryHistory,
        subcontractors: subcontractorState.items,
        dailyProgressList: _loadedDailyProgress,
        attendanceRecords: filteredAttendance,
        employees: employees,
        payments: ledgerEntries,
        attentionItems: attentionItems,
        selectedProjectId: _selectedProjectId == 'all' ? null : _selectedProjectId,
      );

      final safeName = _periodTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'IBUILD_$safeName.pdf';

      await PdfDownloadHelper.downloadPdf(bytes: pdfBytes, filename: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded PDF: $fileName'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    final projectState = ref.read(projectControllerProvider);
    final expenseState = ref.read(expenseControllerProvider);
    final attendanceState = ref.read(attendanceControllerProvider);
    final subcontractorState = ref.read(subcontractorControllerProvider);
    final inventoryState = ref.read(inventoryControllerProvider);
    final employees = ref.read(employeeListControllerProvider).valueOrNull ?? [];

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generating consolidated ERP Excel report...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // 1. Identify Target Project or Portfolio Context
      final isSingleProject = _selectedProjectId != null && _selectedProjectId != 'all';
      final projects = isSingleProject
          ? projectState.projects.where((p) => p.id == _selectedProjectId).toList()
          : projectState.projects;
      final targetProject = projects.isNotEmpty ? projects.first : null;

      final String projectName = isSingleProject
          ? (targetProject?.name ?? 'Project Site')
          : 'Enterprise Portfolio (All Sites)';
      final String siteName = isSingleProject
          ? (targetProject?.address ?? targetProject?.name ?? 'Site Location')
          : 'All Construction Sites';
      final String clientName = isSingleProject
          ? (targetProject?.clientName ?? targetProject?.customerName ?? 'Direct Client')
          : 'Multiple Enterprise Clients';

      final double totalBudget = isSingleProject
          ? (targetProject?.budget ?? 0.0)
          : projectState.projects.fold(0.0, (s, p) => s + p.budget);
      final double totalSpent = isSingleProject
          ? (targetProject?.spent ?? 0.0)
          : projectState.projects.fold(0.0, (s, p) => s + p.spent);
      final double remainingBalance = totalBudget > totalSpent ? (totalBudget - totalSpent) : 0.0;
      final double budgetUtilization = totalBudget > 0 ? ((totalSpent / totalBudget) * 100).clamp(0.0, 100.0) : 0.0;
      final double physicalProgress = isSingleProject
          ? (targetProject?.physicalProgress ?? (totalBudget > 0 ? ((totalSpent / totalBudget) * 100).clamp(0.0, 100.0) : 0.0))
          : (projectState.projects.isEmpty
              ? 0.0
              : projectState.projects.fold(0.0, (s, p) => s + (p.physicalProgress ?? 0.0)) / projectState.projects.length);
      final String projectStatus = isSingleProject ? (targetProject?.status ?? 'active') : 'Active Portfolio';

      // 2. Filter domain records for period and project scope
      final filteredExpenses = expenseState.expenses.where((e) {
        final inRange = e.expenseDate.compareTo(_startDateStr) >= 0 && e.expenseDate.compareTo(_endDateStr) <= 0;
        final matchesProject = !isSingleProject || e.projectId == _selectedProjectId;
        return inRange && matchesProject;
      }).toList();

      final filteredAttendance = attendanceState.attendanceList.where((a) {
        final inRange = a.date.compareTo(_startDateStr) >= 0 && a.date.compareTo(_endDateStr) <= 0;
        final matchesProject = !isSingleProject || a.projectId == _selectedProjectId;
        return inRange && matchesProject;
      }).toList();

      final filteredSubcontractors = subcontractorState.items.where((s) {
        if (!isSingleProject) return true;
        return s.siteName.toLowerCase().contains(projectName.toLowerCase()) ||
            projectName.toLowerCase().contains(s.siteName.toLowerCase());
      }).toList();

      final filteredInventory = inventoryState.items;

      // Fetch payment ledger records
      List<PaymentLedgerEntry> ledgerEntries = [];
      try {
        final ledgerRepo = SupabasePaymentLedgerRepository(Supabase.instance.client);
        final allEntries = isSingleProject && _selectedProjectId != null
            ? await ledgerRepo.fetchLedgerForProject(_selectedProjectId!)
            : await ledgerRepo.fetchAllLedgerEntries();
        ledgerEntries = allEntries.where((p) {
          final pDateStr = DateFormat('yyyy-MM-dd').format(p.paymentDate);
          return pDateStr.compareTo(_startDateStr) >= 0 && pDateStr.compareTo(_endDateStr) <= 0;
        }).toList();
      } catch (_) {
        // Fallback if ledger fetch fails
      }

      // 3. Compile Real Attention Required Items (No mock data)
      final List<String> attentionItems = [];
      for (final p in projects) {
        if (p.spent > p.budget && p.budget > 0) {
          attentionItems.add('Budget alert: "${p.name}" spent ₹${p.spent.toStringAsFixed(0)} against budget ₹${p.budget.toStringAsFixed(0)}');
        }
      }
      for (final item in filteredInventory) {
        if (item.isLowStock) {
          attentionItems.add('Low inventory warning: ${item.materialName} has ${item.availableStock} ${item.unit} in stock (below minimum ${item.minimumStock})');
        }
      }
      for (final s in filteredSubcontractors) {
        if (s.outstandingAmount > 0) {
          attentionItems.add('Payment retention balance pending for trade partner ${s.companyName}: ₹${s.outstandingAmount.toStringAsFixed(0)}');
        }
      }

      // 4. Generate Multi-Sheet Consolidated Workbook
      final reportData = ConsolidatedReportData(
        project: targetProject,
        projects: projects,
        dailyProgress: _loadedDailyProgress,
        projectName: projectName,
        siteName: siteName,
        clientName: clientName,
        periodTitle: _periodTitle,
        startDate: DateFormat('yyyy-MM-dd').parse(_startDateStr),
        endDate: DateFormat('yyyy-MM-dd').parse(_endDateStr),
        generatedAt: DateTime.now(),
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        remainingBalance: remainingBalance,
        budgetUtilization: budgetUtilization,
        physicalProgress: physicalProgress,
        projectStatus: projectStatus,
        attentionItems: attentionItems,
        attendanceRecords: filteredAttendance,
        employees: employees,
        inventoryHistory: _loadedInventoryHistory,
        inventoryItems: filteredInventory,
        subcontractors: filteredSubcontractors,
        expenses: filteredExpenses,
        payments: ledgerEntries,
      );

      final excelBytes = ExcelGeneratorService.generateConsolidatedReportExcel(reportData);

      // 5. Generate Safe Dynamic Filename
      final safeName = (isSingleProject ? targetProject?.name ?? 'Project' : 'Portfolio')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'IBUILD_${safeName}_Report_$dateStamp.xlsx';

      await ExcelDownloadHelper.downloadExcel(bytes: excelBytes, filename: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated successfully: $fileName ✓'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to generate report: $e. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectControllerProvider);
    final expenseState = ref.watch(expenseControllerProvider);
    final inventoryState = ref.watch(inventoryControllerProvider);
    final attendanceState = ref.watch(attendanceControllerProvider);
    final subcontractorState = ref.watch(subcontractorControllerProvider);

    // Filter projects based on selectedProjectId
    final filteredProjects = _selectedProjectId == null || _selectedProjectId == 'all'
        ? projectState.projects
        : projectState.projects.where((p) => p.id == _selectedProjectId).toList();

    // Filter expenses for this date range
    final filteredExpenses = expenseState.expenses.where((e) {
      final matchesProject = _selectedProjectId == null ||
          _selectedProjectId == 'all' ||
          e.projectId == _selectedProjectId;
      final inRange = e.expenseDate.compareTo(_startDateStr) >= 0 &&
          e.expenseDate.compareTo(_endDateStr) <= 0;
      return matchesProject && inRange;
    }).toList();

    final double totalExpensesForPeriod = filteredExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    // Filter attendance for this date range
    final filteredAttendance = attendanceState.attendanceList.where((a) {
      final matchesProject = _selectedProjectId == null ||
          _selectedProjectId == 'all' ||
          a.projectId == _selectedProjectId;
      final inRange = a.date.compareTo(_startDateStr) >= 0 &&
          a.date.compareTo(_endDateStr) <= 0;
      return matchesProject && inRange;
    }).toList();

    final receivedCount = _loadedInventoryHistory.where((h) => h.changeType == 'added').length;
    final issuedCount = _loadedInventoryHistory.where((h) => h.changeType == 'used').length;

    final hasBack = widget.onBackPressed != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: widget.showAppBar
          ? AppBar(
              leading: hasBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Go back',
                      onPressed: () {
                        if (widget.onBackPressed != null) {
                          widget.onBackPressed!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Open navigation menu',
                      onPressed: MobileNavHelper.openDrawer,
                    ),
              titleSpacing: 0,
              title: const Text(
                'Reports & Operational Audits',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.cardBg(context),
              elevation: 0.5,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Report Data',
                  onPressed: _fetchPeriodData,
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top Header & Action Controls ─────────────────────────────
            _buildHeaderCard(context),
            const SizedBox(height: 16),

            // ─── Cadence Mode Selector (Daily, Weekly, Monthly, Custom) ───
            _buildCadenceSelector(context),
            const SizedBox(height: 14),

            // ─── Date Picker & Scope Filter Ribbon ─────────────────────────
            _buildDateFilterRibbon(context, projectState.projects),
            const SizedBox(height: 16),

            // ─── Live Executive KPI Ribbon for Selected Period ────────────
            _buildKpiRibbon(
              context,
              totalExpenses: totalExpensesForPeriod,
              expenseCount: filteredExpenses.length,
              inventoryMovements: _loadedInventoryHistory.length,
              receivedCount: receivedCount,
              issuedCount: issuedCount,
              activeProjectsCount: filteredProjects.length,
              subcontractorsCount: subcontractorState.items.length,
              workersPresentCount: filteredAttendance.length,
            ),
            const SizedBox(height: 18),

            // ─── Section View Filter Chips ────────────────────────────────
            _buildSectionFilterChips(context),
            const SizedBox(height: 16),

            // ─── Loading Indicator ─────────────────────────────────────────
            if (_isLoadingPeriodData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Aggregating live project updates, inventory logs & subcontractor data...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ─── 1. Changes Made in Projects ─────────────────────────────
              if (_activeSectionFilter == 'all' || _activeSectionFilter == 'projects') ...[
                _buildProjectsSection(context, filteredProjects),
                const SizedBox(height: 20),
              ],

              // ─── 2. Changes Made in Inventory (Received / Issued) ─────────
              if (_activeSectionFilter == 'all' || _activeSectionFilter == 'inventory') ...[
                _buildInventorySection(context, inventoryState.items),
                const SizedBox(height: 20),
              ],

              // ─── 3. Status of the Subcontractors ──────────────────────────
              if (_activeSectionFilter == 'all' || _activeSectionFilter == 'subcontractors') ...[
                _buildSubcontractorsSection(context, subcontractorState.items),
                const SizedBox(height: 20),
              ],

              // ─── 4. Site Expenses & Financial Outflows ────────────────────
              if (_activeSectionFilter == 'all' || _activeSectionFilter == 'expenses') ...[
                _buildExpensesSection(context, filteredExpenses),
                const SizedBox(height: 20),
              ],

              // ─── 5. Worker Attendance & Shifts ────────────────────────────
              if (_activeSectionFilter == 'all' || _activeSectionFilter == 'attendance') ...[
                _buildAttendanceSection(context, filteredAttendance),
                const SizedBox(height: 20),
              ],
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI COMPONENTS & SECTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.analytics_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Comprehensive Audit & Operational Reports',
                                style: TextStyle(
                                  fontSize: isNarrow ? 15 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track project changes, inventory deliveries & issuances, subcontractor statuses, and daily expenses.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportPdf(context),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportExcel(context),
                    icon: const Icon(Icons.table_chart_outlined, size: 16),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF107C41),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _shareViaWhatsApp(context),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('WhatsApp Dispatch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showReportPreviewModal(context),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                    label: const Text('Preview & Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCadenceSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return isNarrow
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _cadenceButton(
                            ReportCadence.daily,
                            Icons.today_outlined,
                            'Daily Report',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _cadenceButton(
                            ReportCadence.weekly,
                            Icons.calendar_view_week_outlined,
                            'Weekly Report',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _cadenceButton(
                            ReportCadence.monthly,
                            Icons.calendar_month_outlined,
                            'Monthly Report',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _cadenceButton(
                            ReportCadence.custom,
                            Icons.date_range_outlined,
                            'Custom Audit',
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _cadenceButton(
                        ReportCadence.daily,
                        Icons.today_outlined,
                        'Daily Report',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _cadenceButton(
                        ReportCadence.weekly,
                        Icons.calendar_view_week_outlined,
                        'Weekly Report',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _cadenceButton(
                        ReportCadence.monthly,
                        Icons.calendar_month_outlined,
                        'Monthly Report',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _cadenceButton(
                        ReportCadence.custom,
                        Icons.date_range_outlined,
                        'Custom Audit',
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _cadenceButton(ReportCadence cadence, IconData icon, String title) {
    final isSelected = _cadence == cadence;
    return InkWell(
      onTap: () {
        setState(() {
          _cadence = cadence;
        });
        _fetchPeriodData();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.text(context),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.text(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterRibbon(BuildContext context, List<dynamic> projects) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          final dateControls = Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _shiftDate(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Date / Period',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.bg(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: isMobile ? 1 : 0,
                child: InkWell(
                  onTap: () => _pickDateOrRange(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _periodTitle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _shiftDate(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Date / Period',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.bg(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );

          final projectDropdown = SizedBox(
            width: isMobile ? double.infinity : 240,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedProjectId,
              isExpanded: true,
              dropdownColor: AppColors.cardBg(context),
              decoration: InputDecoration(
                labelText: 'Site Scope',
                labelStyle: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.business_outlined, size: 18),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Enterprise Sites (Portfolio)', style: TextStyle(fontSize: 12)),
                ),
                ...projects.map((p) => DropdownMenuItem(
                      value: p.id as String,
                      child: Text(p.name as String, style: const TextStyle(fontSize: 12)),
                    )),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedProjectId = val;
                });
                _fetchPeriodData();
              },
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateControls,
                const SizedBox(height: 10),
                projectDropdown,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              dateControls,
              const SizedBox(width: 14),
              projectDropdown,
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDateOrRange(BuildContext context) async {
    if (_cadence == ReportCadence.daily) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
        _fetchPeriodData();
      }
    } else if (_cadence == ReportCadence.custom || _cadence == ReportCadence.weekly) {
      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: DateTimeRange(
          start: _cadence == ReportCadence.weekly ? _selectedWeekStart : _customStartDate,
          end: _cadence == ReportCadence.weekly
              ? _selectedWeekStart.add(const Duration(days: 6))
              : _customEndDate,
        ),
      );
      if (pickedRange != null) {
        setState(() {
          if (_cadence == ReportCadence.weekly) {
            _selectedWeekStart = pickedRange.start;
          } else {
            _customStartDate = pickedRange.start;
            _customEndDate = pickedRange.end;
          }
        });
        _fetchPeriodData();
      }
    } else if (_cadence == ReportCadence.monthly) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedMonth,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        setState(() => _selectedMonth = DateTime(picked.year, picked.month, 1));
        _fetchPeriodData();
      }
    }
  }

  Widget _buildKpiRibbon(
    BuildContext context, {
    required double totalExpenses,
    required int expenseCount,
    required int inventoryMovements,
    required int receivedCount,
    required int issuedCount,
    required int activeProjectsCount,
    required int subcontractorsCount,
    required int workersPresentCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth < 600
            ? 2
            : (constraints.maxWidth < 950 ? 3 : 5);

        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth < 600 ? 1.6 : 1.4,
          children: [
            _kpiCard(
              context,
              title: 'Period Outflows',
              value: '₹${totalExpenses.toStringAsFixed(0)}',
              subtitle: '$expenseCount expense records',
              icon: Icons.payments_outlined,
              color: Colors.deepOrange,
            ),
            _kpiCard(
              context,
              title: 'Stock Movements',
              value: '$inventoryMovements txn',
              subtitle: '+$receivedCount In / -$issuedCount Out',
              icon: Icons.inventory_2_outlined,
              color: AppColors.secondary,
            ),
            _kpiCard(
              context,
              title: 'Active Projects',
              value: '$activeProjectsCount Sites',
              subtitle: 'Active portfolio sites',
              icon: Icons.apartment_outlined,
              color: AppColors.primary,
            ),
            _kpiCard(
              context,
              title: 'Subcontractors',
              value: '$subcontractorsCount Partners',
              subtitle: 'Registered trade firms',
              icon: Icons.handshake_outlined,
              color: Colors.purple,
            ),
            _kpiCard(
              context,
              title: 'Worker Attendance',
              value: '$workersPresentCount Shifts',
              subtitle: 'Worker shifts recorded',
              icon: Icons.badge_outlined,
              color: Colors.teal,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.mutedText(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionFilterChips(BuildContext context) {
    final sections = [
      {'key': 'all', 'label': 'All Sections', 'icon': Icons.view_agenda_outlined},
      {'key': 'projects', 'label': 'Project Changes', 'icon': Icons.apartment_outlined},
      {'key': 'inventory', 'label': 'Inventory Movements', 'icon': Icons.inventory_2_outlined},
      {'key': 'subcontractors', 'label': 'Subcontractors', 'icon': Icons.handshake_outlined},
      {'key': 'expenses', 'label': 'Site Expenses', 'icon': Icons.payments_outlined},
      {'key': 'attendance', 'label': 'Worker Attendance', 'icon': Icons.badge_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sections.map((sec) {
          final isSelected = _activeSectionFilter == sec['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                sec['icon'] as IconData,
                size: 15,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              label: Text(
                sec['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.text(context),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.cardBg(context),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _activeSectionFilter = sec['key'] as String;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 1: CHANGES MADE IN PROJECTS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildProjectsSection(BuildContext context, List<dynamic> projects) {
    return _sectionContainer(
      context,
      title: '1. Changes Made in Projects & Site Daily Logs',
      badge: '${projects.length} Active Sites',
      icon: Icons.apartment_outlined,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (projects.isEmpty)
            _emptyState(context, 'No active projects found in selected scope.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (context, index) => const Divider(height: 18),
              itemBuilder: (context, idx) {
                final p = projects[idx];
                final progressVal = ((p.physicalProgress ?? (p.budget > 0 ? (p.spent / p.budget * 100) : 0.0))).clamp(0.0, 100.0);
                final progressPct = progressVal.toInt();

                // Find matching daily progress updates for this project
                final siteLogs = _loadedDailyProgress
                    .where((dp) => dp.projectId == p.id)
                    .toList();

                return Column(
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
                                p.name as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                              Text(
                                'Client: ${p.clientName ?? p.customerName ?? "General"} • Status: ${p.status.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$progressPct% Complete',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (progressVal / 100.0).clamp(0.0, 1.0),
                        backgroundColor: AppColors.border(context),
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budget: ₹${(p.budget as num).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        Text(
                          'Spent: ₹${(p.spent as num).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),

                    // Daily Site Progress Notes / Image if available for this date
                    if (siteLogs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bg(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.edit_note_outlined,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Site Progress Notes for this Period:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ...siteLogs.map((dp) {
                              final noteText = dp.allNotes.isNotEmpty
                                  ? dp.allNotes.join('\n')
                                  : 'Physical Progress update: ${dp.progressPercentage}%';
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '• ${dp.date}: $noteText',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 2: CHANGES MADE IN INVENTORY (DELIVERIES & ISSUANCES)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildInventorySection(BuildContext context, List<dynamic> items) {
    return _sectionContainer(
      context,
      title: '2. Changes Made in Inventory (Deliveries & Issues)',
      badge: '${_loadedInventoryHistory.length} Stock Events',
      icon: Icons.inventory_2_outlined,
      color: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadedInventoryHistory.isEmpty)
            _emptyState(
              context,
              'No stock deliveries received or materials issued during this period.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loadedInventoryHistory.length,
              separatorBuilder: (context, index) => const Divider(height: 14),
              itemBuilder: (context, idx) {
                final h = _loadedInventoryHistory[idx];
                final isAdded = h.changeType == 'added';
                final isUsed = h.changeType == 'used';

                final badgeColor = isAdded
                    ? AppColors.secondary
                    : (isUsed ? Colors.deepOrange : Colors.blue);
                final badgeText = isAdded
                    ? 'RECEIVED (+)'
                    : (isUsed ? 'ISSUED (-)' : h.changeType.toUpperCase());

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.notes ?? 'Stock Movement',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Timestamp: ${h.createdAt?.substring(0, 16).replaceAll("T", " ") ?? _startDateStr}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      h.quantityChange > 0
                          ? '+${h.quantityChange.toStringAsFixed(1)}'
                          : h.quantityChange.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 3: STATUS OF THE SUBCONTRACTORS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSubcontractorsSection(BuildContext context, List<Subcontractor> subcontractors) {
    return _sectionContainer(
      context,
      title: '3. Status of Subcontractors & Trade Partners',
      badge: '${subcontractors.length} Trade Partners',
      icon: Icons.handshake_outlined,
      color: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subcontractors.isEmpty)
            _emptyState(context, 'No registered subcontractors found in the system.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subcontractors.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final sub = subcontractors[idx];
                final isCompleted = sub.status.toLowerCase() == 'completed';
                final statusColor = isCompleted ? AppColors.secondary : Colors.purple;

                return Column(
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
                                sub.companyName,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                              Text(
                                '${sub.tradeSpecialization} • Site: ${sub.siteName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            sub.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Contract: ₹${sub.contractValue.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                        ),
                        Text(
                          'Paid: ₹${sub.paidAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                        ),
                        Text(
                          'Balance: ₹${sub.outstandingAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 4: SITE EXPENSES & FINANCIAL OUTFLOWS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildExpensesSection(BuildContext context, List<dynamic> expenses) {
    return _sectionContainer(
      context,
      title: '4. Logged Site Expenses & Outflows',
      badge: '${expenses.length} Vouchers',
      icon: Icons.payments_outlined,
      color: Colors.deepOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expenses.isEmpty)
            _emptyState(context, 'No expenses recorded for this period.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (context, index) => const Divider(height: 14),
              itemBuilder: (context, idx) {
                final e = expenses[idx];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (e.category as String).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.notes ?? 'Operational Expense',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${e.expenseDate} • ${e.projectName ?? "General Site"} • Mode: ${(e.paymentMode as String).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(e.amount as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 5: WORKER ATTENDANCE & SHIFTS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildAttendanceSection(BuildContext context, List<dynamic> attendance) {
    return _sectionContainer(
      context,
      title: '5. Worker Attendance & Shifts',
      badge: '${attendance.length} Workers Logged',
      icon: Icons.badge_outlined,
      color: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attendance.isEmpty)
            _emptyState(context, 'No worker attendance entries recorded for this period.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendance.length,
              separatorBuilder: (context, index) => const Divider(height: 14),
              itemBuilder: (context, idx) {
                final a = attendance[idx];
                final isPresent = a.status.toLowerCase() == 'present';
                final statusColor = isPresent ? AppColors.secondary : Colors.red;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.employeeName ?? 'Worker',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          Text(
                            'Date: ${a.date} • Site: ${a.projectName ?? "General"}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _sectionContainer(
    BuildContext context, {
    required String title,
    required String badge,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 17, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedText(context),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
