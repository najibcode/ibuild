import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/attendance_controller.dart';
import '../../data/models/attendance_model.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../projects/data/models/project_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceControllerProvider);
    final projectState = ref.watch(projectControllerProvider);
    final projects = projectState.projects;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: const Text(
          'Daily Attendance & Site Deployment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
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
              ? const Center(child: Text('No active employees found to mark attendance.', style: TextStyle(color: AppColors.textMuted)))
              : Column(
                  children: [
                    // Summary Card
                    _buildSummaryCard(state.attendanceList, state.activeEmployees.length),
                    
                    // List of Employees
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                        itemCount: state.activeEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = state.activeEmployees[index];
                          
                          // Find if there is an existing logged record
                          final logged = state.attendanceList.firstWhere(
                            (a) => a.employeeId == employee.id,
                            orElse: () => Attendance(
                              id: '',
                              employeeId: employee.id,
                              date: '',
                              status: 'Absent',
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
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
                                            employee.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          Text(
                                            '${employee.role.toUpperCase()} • Rate: ₹${employee.salary.toInt()}/day',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      if (logged.projectName != null && logged.projectName!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Site: ${logged.projectName}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Status & Daily Project Assignment Controls
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 10,
                                    children: [
                                      _buildStatusToggle(
                                        context: context,
                                        activeStatus: logged.status,
                                        onSelected: (status) {
                                          ref.read(attendanceControllerProvider.notifier).markAttendance(
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
                                        onProjectSelected: (projId) {
                                          ref.read(attendanceControllerProvider.notifier).markAttendance(
                                            employeeId: employee.id,
                                            status: logged.status == 'Absent' ? 'Present' : logged.status,
                                            projectId: projId,
                                          );
                                        },
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
                ),
    );
  }

  Widget _buildSummaryCard(List<Attendance> logged, int totalActive) {
    final int present = logged.where((a) => a.status.toLowerCase() == 'present').length;
    final int absent = totalActive - present;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.containerMargin),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCol('Active Staff', '$totalActive', AppColors.primary),
          _buildSummaryCol('Present', '$present', AppColors.secondary),
          _buildSummaryCol('Absent', '$absent', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildStatusToggle({
    required BuildContext context,
    required String activeStatus,
    required Function(String status) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildToggleButton('Present', 'Present', activeStatus, AppColors.secondary, onSelected),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : activeColor.withOpacity(0.08),
          border: Border.all(color: isActive ? activeColor : activeColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppRadius.defaultValue),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : activeColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
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
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.defaultValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: (currentProjectId != null && projects.any((p) => p.id == currentProjectId))
                ? currentProjectId
                : null,
            hint: const Text(
              'Assign Site',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            items: projects
                .map((p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain),
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
