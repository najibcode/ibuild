import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/date_range_filter_helper.dart';
import '../controllers/attendance_controller.dart';
import '../../data/models/attendance_model.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/screens/project_operations_screen.dart';
import '../../../rbac/presentation/providers/permission_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _searchQuery = '';
  String? _selectedFilterProjectId;

  /// Whether the current user is a supervisor (restricted to today-only)
  bool get _isSupervisor => ref.read(isSupervisorProvider);

  /// Whether the current user is an owner (full access)
  bool get _isOwner => ref.read(isOwnerProvider);

  /// Whether the current user is an admin (full access with technical privileges)
  bool get _isAdmin => ref.read(isAdminProvider);

  /// Whether the user can navigate to other dates
  bool get _canChangeDates => _isOwner || _isAdmin;

  void _pickDate(BuildContext context, String currentDateStr) async {
    if (!_canChangeDates) return;
    DateTime initial = DateTime.tryParse(currentDateStr) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ref.read(attendanceControllerProvider.notifier).changeSelectedDate(picked);
    }
  }

  void _shiftDate(int days, String currentDateStr) {
    if (!_canChangeDates) return;
    DateTime current = DateTime.tryParse(currentDateStr) ?? DateTime.now();
    DateTime shifted = current.add(Duration(days: days));
    ref.read(attendanceControllerProvider.notifier).changeSelectedDate(shifted);
  }

  String _getRelativeDateLabel(String selectedDateStr) {
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10);
    final yesterdayStr = DateTime(now.year, now.month, now.day - 1).toIso8601String().substring(0, 10);
    final tomorrowStr = DateTime(now.year, now.month, now.day + 1).toIso8601String().substring(0, 10);

    if (selectedDateStr == todayStr) return 'TODAY';
    if (selectedDateStr == yesterdayStr) return 'YESTERDAY';
    if (selectedDateStr == tomorrowStr) return 'TOMORROW';
    return 'PAST DATE';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceControllerProvider);
    final projectState = ref.watch(projectControllerProvider);
    final projects = projectState.projects;

    // Error and Success feedback listeners
    ref.listen<AttendanceState>(attendanceControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    final selectedDateParsed = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    final isToday = state.selectedDate == DateTime.now().toIso8601String().substring(0, 10);
    final formattedDateStr = DateFormat('EEE, dd MMMM yyyy').format(selectedDateParsed);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Attendance & Site Deployment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final records = DateRangeFilterHelper.filter(
                state.attendanceList,
                start: start,
                end: end,
                getDate: (a) => a.date,
              );
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Worker Attendance & Deployment Log',
                subtitle: 'Attendance log for Date: ${state.selectedDate}',
                headers: ['Date', 'Worker Name', 'Site / Project', 'Attendance Status'],
                data: records.map((a) => [
                  a.date,
                  a.employeeName ?? 'Worker',
                  a.projectName ?? 'General',
                  a.status.toUpperCase(),
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Attendance_${state.selectedDate}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final records = DateRangeFilterHelper.filter(
                state.attendanceList,
                start: start,
                end: end,
                getDate: (a) => a.date,
              );
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Attendance',
                title: 'Attendance & Daily Deployment Summary',
                headers: ['Date', 'Worker Name', 'Site / Project', 'Attendance Status'],
                rows: records.map((a) => [
                  a.date,
                  a.employeeName ?? 'Worker',
                  a.projectName ?? 'General',
                  a.status.toUpperCase(),
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Attendance_${state.selectedDate}.xlsx',
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            tooltip: 'Refresh Data',
            onPressed: () {
              ref.read(attendanceControllerProvider.notifier).loadAttendanceForDate(state.selectedDate);
              ref.read(projectControllerProvider.notifier).loadProjects();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.activeEmployees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.activeEmployees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_reg_outlined, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'No active workers found.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add staff in the Workforce tab to track site attendance.',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Interactive Date Navigator & Bulk Actions Bar ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.cardBg(context),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Date Picker & Shift Arrows
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (_canChangeDates)
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left, size: 20),
                                          onPressed: () => _shiftDate(-1, state.selectedDate),
                                          tooltip: 'Previous Day',
                                        ),
                                      InkWell(
                                        onTap: _canChangeDates ? () => _pickDate(context, state.selectedDate) : null,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor(context).withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.primaryColor(context).withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_month, size: 16, color: AppColors.primaryColor(context)),
                                              const SizedBox(width: 6),
                                              Text(
                                                formattedDateStr,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: AppColors.primaryColor(context),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isToday
                                                      ? AppColors.secondary.withValues(alpha: 0.15)
                                                      : Colors.amber.withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isToday
                                                        ? AppColors.secondary.withValues(alpha: 0.3)
                                                        : Colors.amber.withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: Text(
                                                  _getRelativeDateLabel(state.selectedDate),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isToday ? AppColors.secondary : Colors.amber.shade900,
                                                  ),
                                                ),
                                              ),
                                              if (_isSupervisor) ...[
                                                const SizedBox(width: 6),
                                                Icon(Icons.lock_outline, size: 12, color: AppColors.mutedText(context)),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_canChangeDates)
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right, size: 20),
                                          onPressed: () => _shiftDate(1, state.selectedDate),
                                          tooltip: 'Next Day',
                                        ),
                                      if (!isToday && _canChangeDates)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                                              ref.read(attendanceControllerProvider.notifier).loadAttendanceForDate(todayStr);
                                            },
                                            icon: const Icon(Icons.today, size: 14),
                                            label: const Text('Go to Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              side: BorderSide(color: AppColors.primaryColor(context)),
                                              foregroundColor: AppColors.primaryColor(context),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Quick Bulk Actions Menu (only for owners/admins, or supervisors on today)
                              if (_canChangeDates || isToday)
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: AppColors.primaryColor(context)),
                                  tooltip: 'Bulk Actions',
                                  color: AppColors.cardBg(context),
                                  onSelected: (val) {
                                    if (val == 'all_present') {
                                      ref.read(attendanceControllerProvider.notifier).markAllPresent();
                                    } else if (val == 'all_absent') {
                                      ref.read(attendanceControllerProvider.notifier).markAllAbsent();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'all_present',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark All Staff Present'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'all_absent',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                                          SizedBox(width: 8),
                                          Text('Mark All Staff Absent'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryCard(context, state.attendanceList, state.activeEmployees, _getRelativeDateLabel(state.selectedDate)),
                        ],
                      ),
                    ),

                    // ── Search & Filter Controls ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.cardBg(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: TextField(
                                onChanged: (q) => setState(() => _searchQuery = q),
                                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search staff by name or role...',
                                  hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                                  prefixIcon: Icon(Icons.search, color: AppColors.mutedText(context), size: 18),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Project Filter Dropdown
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedFilterProjectId,
                                  dropdownColor: AppColors.cardBg(context),
                                  hint: Text('Filter Site', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                                  isExpanded: true,
                                  style: TextStyle(fontSize: 12, color: AppColors.text(context)),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Sites', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                                    ),
                                    ...projects.map((p) => DropdownMenuItem<String?>(
                                          value: p.id,
                                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (val) => setState(() => _selectedFilterProjectId = val),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Staff List ──
                    Expanded(
                      child: _buildWorkerList(context, state, projects, isToday),
                    ),
                  ],
                ),
    );
  }

  Widget _buildWorkerList(BuildContext context, AttendanceState state, List<Project> projects, bool isToday) {
    final filtered = state.activeEmployees.where((e) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!e.name.toLowerCase().contains(q) && !e.role.toLowerCase().contains(q)) {
          return false;
        }
      }

      if (_selectedFilterProjectId != null) {
        final record = state.attendanceList.firstWhere(
          (a) => a.employeeId == e.id,
          orElse: () => Attendance(id: '', employeeId: e.id, date: '', status: 'Absent'),
        );
        if (record.projectId != _selectedFilterProjectId) {
          return false;
        }
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No matching staff found for current filter.',
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final employee = filtered[index];

        final logged = state.attendanceList.firstWhere(
          (a) => a.employeeId == employee.id,
          orElse: () => Attendance(
            id: '',
            employeeId: employee.id,
            date: state.selectedDate,
            status: 'Absent',
          ),
        );

        final isPresent = logged.status.toLowerCase() == 'present';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPresent
                ? AppColors.secondary.withValues(alpha: 0.05)
                : AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPresent
                  ? AppColors.secondary.withValues(alpha: 0.4)
                  : AppColors.border(context),
              width: isPresent ? 1.5 : 1.0,
            ),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                employee.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.text(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? AppColors.secondary.withValues(alpha: 0.15)
                                    : AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPresent ? 'PRESENT' : 'ABSENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isPresent ? AppColors.secondary : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${employee.role.toUpperCase()} • Rate: ₹${employee.salary.toInt()}/day + ₹${employee.teaSnackAllowance.toInt()} tea',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (logged.projectName != null && logged.projectName!.isNotEmpty)
                    InkWell(
                      onTap: () {
                        if (logged.projectId != null && logged.projectId!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectOperationsScreen(
                                projectId: logged.projectId!,
                                projectName: logged.projectName!,
                                initialSection: 1,
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor(context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primaryColor(context).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 12, color: AppColors.primaryColor(context)),
                            const SizedBox(width: 4),
                            Text(
                              'Site: ${logged.projectName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primaryColor(context)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Status Toggle & Site Assignment Dropdown
              // Supervisors can only edit attendance for today
              if (_isSupervisor && !isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Text(
                        'Supervisors can only edit today\'s attendance',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildStatusToggle(
                      context: context,
                      activeStatus: logged.status,
                      onSelected: (status) async {
                        await ref.read(attendanceControllerProvider.notifier).markAttendance(
                          employeeId: employee.id,
                          status: status,
                          projectId: logged.projectId,
                        );
                      },
                    ),
                    _buildSiteAssignmentDropdown(
                      context: context,
                      projects: projects,
                      currentProjectId: logged.projectId,
                      onProjectSelected: (projId) async {
                        if (projId == null) return;
                        final success = await ref.read(attendanceControllerProvider.notifier).markAttendance(
                          employeeId: employee.id,
                          status: logged.status == 'Absent' ? 'Present' : logged.status,
                          projectId: projId,
                        );
                        if (success && context.mounted) {
                          final match = projects.where((p) => p.id == projId);
                          final siteName = match.isNotEmpty ? match.first.name : 'Site';
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${employee.name} assigned to $siteName ✓'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              width: 280,
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    List<Attendance> logged,
    List<dynamic> employees,
    String dateLabel,
  ) {
    final int totalActive = employees.length;
    final int present = logged.where((a) => a.status.toLowerCase() == 'present').length;
    final int absent = totalActive - present;

    double todayPayroll = 0;
    for (final l in logged) {
      if (l.status.toLowerCase() == 'present') {
        final matches = employees.where((e) => e.id == l.employeeId);
        if (matches.isNotEmpty) {
          todayPayroll += matches.first.totalDailyCost;
        }
      }
    }

    final presentTitle = dateLabel == 'TODAY'
        ? 'Present Today'
        : (dateLabel == 'YESTERDAY' ? 'Present Yesterday' : 'Present');

    final absentTitle = dateLabel == 'TODAY'
        ? 'Absent Today'
        : (dateLabel == 'YESTERDAY' ? 'Absent Yesterday' : 'Absent');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCol(context, 'Total Staff', '$totalActive', AppColors.primaryColor(context)),
          _buildSummaryCol(context, presentTitle, '$present', AppColors.secondary),
          _buildSummaryCol(context, absentTitle, '$absent', AppColors.error),
          _buildSummaryCol(context, 'Daily Cost (Pay + Tea)', '₹${todayPayroll.toInt()}', Colors.amber.shade800),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(BuildContext context, String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.mutedText(context), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatusToggle({
    required BuildContext context,
    required String activeStatus,
    required Function(String status) onSelected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton('Present', 'Present', activeStatus, AppColors.secondary, onSelected),
        const SizedBox(width: 8),
        _buildToggleButton('Absent', 'Absent', activeStatus, AppColors.error, onSelected),
      ],
    );
  }

  Widget _buildToggleButton(
    String label,
    String status,
    String activeStatus,
    Color activeColor,
    Function(String status) onSelected,
  ) {
    final bool isActive = activeStatus.toLowerCase() == status.toLowerCase();
    return GestureDetector(
      onTap: () => onSelected(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor : activeColor.withValues(alpha: 0.1),
          border: Border.all(color: isActive ? activeColor : activeColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'Present' ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 14,
              color: isActive ? Colors.white : activeColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteAssignmentDropdown({
    required BuildContext context,
    required List<Project> projects,
    required String? currentProjectId,
    required Function(String? projectId) onProjectSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryColor(context)),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: (currentProjectId != null && projects.any((p) => p.id == currentProjectId))
                ? currentProjectId
                : null,
            dropdownColor: AppColors.cardBg(context),
            hint: Text(
              'Assign Site',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontWeight: FontWeight.w600),
            ),
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            items: projects
                .map((p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(
                        p.name,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                      ),
                    ))
                .toList(),
            onChanged: onProjectSelected,
          ),
        ],
      ),
    );
  }
}
