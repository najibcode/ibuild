import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/attendance_controller.dart';
import '../../data/models/attendance_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: const Text(
          'Daily Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(attendanceControllerProvider.notifier).loadAttendanceForToday(),
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
                              morningStatus: 'absent',
                              eveningStatus: 'absent',
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
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
                                  Text(employee.role, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  const SizedBox(height: 16),
                                  
                                  // Morning Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Morning Shift:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      _buildStatusToggle(
                                        context: context,
                                        activeStatus: logged.morningStatus,
                                        onSelected: (status) {
                                          ref.read(attendanceControllerProvider.notifier).markAttendance(
                                            employeeId: employee.id,
                                            morningStatus: status,
                                            eveningStatus: logged.eveningStatus,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Evening Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Evening Shift:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      _buildStatusToggle(
                                        context: context,
                                        activeStatus: logged.eveningStatus,
                                        onSelected: (status) {
                                          ref.read(attendanceControllerProvider.notifier).markAttendance(
                                            employeeId: employee.id,
                                            morningStatus: logged.morningStatus,
                                            eveningStatus: status,
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
    final int marked = logged.length;
    final int present = logged.where((a) => a.morningStatus == 'present').length;
    final int absent = logged.where((a) => a.morningStatus == 'absent').length;
    final int leave = logged.where((a) => a.morningStatus == 'leave').length;

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
          _buildSummaryCol('Active', '$totalActive', AppColors.primary),
          _buildSummaryCol('Present', '$present', AppColors.secondary),
          _buildSummaryCol('Absent', '$absent', AppColors.error),
          _buildSummaryCol('Leave', '$leave', AppColors.warning),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton('P', 'present', activeStatus, AppColors.secondary, onSelected),
        const SizedBox(width: 6),
        _buildToggleButton('A', 'absent', activeStatus, AppColors.error, onSelected),
        const SizedBox(width: 6),
        _buildToggleButton('L', 'leave', activeStatus, AppColors.warning, onSelected),
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
    final bool isActive = activeStatus == status;
    return GestureDetector(
      onTap: () => onSelected(status),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          border: Border.all(color: isActive ? activeColor : AppColors.borderSubtle),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
