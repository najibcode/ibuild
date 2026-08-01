import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/attendance_controller.dart';
import '../../data/models/attendance_model.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/screens/project_operations_screen.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}


class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceControllerProvider);
    final projectState = ref.watch(projectControllerProvider);
    final projects = projectState.projects;

    // Listen for errors and show SnackBar
    ref.listen<AttendanceState>(attendanceControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final todayStr = DateTime.now().toString().substring(0, 10);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: Text(
          'Attendance & Site Deployment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () {
              ref.read(attendanceControllerProvider.notifier).loadAttendanceForToday();
              ref.read(projectControllerProvider.notifier).loadProjects();
            },
          ),
        ],
      ),
      body: state.isLoading
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
                        'Add employees in the Workforce tab to take daily attendance.',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Date Header & Summary Metric Cards
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primaryColor(context)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Date: $todayStr (Today)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'DAILY LOG',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildSummaryCard(context, state.attendanceList, state.activeEmployees),
                        ],
                      ),
                    ),

                    // Search Worker Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: TextField(
                          onChanged: (q) => setState(() => _searchQuery = q),
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search worker by name or role...',
                            hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: AppColors.mutedText(context), size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Attendance Worker List
                    Expanded(
                      child: _buildWorkerList(context, state, projects),
                    ),
                  ],
                ),
    );
  }

  Widget _buildWorkerList(BuildContext context, AttendanceState state, List<Project> projects) {
    final filtered = state.activeEmployees.where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return e.name.toLowerCase().contains(q) || e.role.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No matching staff found for "$_searchQuery".',
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final employee = filtered[index];

        final logged = state.attendanceList.firstWhere(
          (a) => a.employeeId == employee.id,
          orElse: () => Attendance(
            id: '',
            employeeId: employee.id,
            date: '',
            status: 'Absent',
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
                          employee.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${employee.role.toUpperCase()} • Rate: ₹${employee.salary.toInt()}/day',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
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
                                initialSection: 1, // Today Attendance
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
              const SizedBox(height: 14),

              // Status Toggle & Site Selector
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
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

  Widget _buildSummaryCard(BuildContext context, List<Attendance> logged, List<dynamic> employees) {
    final int totalActive = employees.length;
    final int present = logged.where((a) => a.status.toLowerCase() == 'present').length;
    final int absent = totalActive - present;

    // Calculate today's wage payout for present workers
    double todayPayroll = 0;
    for (final l in logged) {
      if (l.status.toLowerCase() == 'present') {
        final matches = employees.where((e) => e.id == l.employeeId);
        if (matches.isNotEmpty) {
          todayPayroll += matches.first.salary;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCol(context, 'Total Staff', '$totalActive', AppColors.primaryColor(context)),
          _buildSummaryCol(context, 'Present Today', '$present', AppColors.secondary),
          _buildSummaryCol(context, 'Absent Today', '$absent', AppColors.error),
          _buildSummaryCol(context, 'Daily Wage Est', '₹${todayPayroll.toInt()}', Colors.amber.shade800),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(BuildContext context, String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : activeColor.withValues(alpha: 0.1),
          border: Border.all(color: isActive ? activeColor : activeColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(10),
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
