import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/employee_model.dart';
import '../controllers/employee_controller.dart';
import 'employee_form_screen.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/controllers/attendance_controller.dart';

final employeeAttendanceHistoryProvider = FutureProvider.family<List<Attendance>, String>((ref, employeeId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return await repo.getAttendanceHistory(employeeId);
});

class EmployeeDetailScreen extends ConsumerWidget {
  final Employee employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  void _onDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(employeeListControllerProvider.notifier)
          .removeEmployee(employee.id);
      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employee deleted successfully ✓'),
              backgroundColor: AppColors.secondary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete employee from database. Please verify permissions or try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesListAsync = ref.watch(employeeListControllerProvider);
    final currentEmployee = employeesListAsync.maybeWhen(
      data: (list) => list.firstWhere(
        (e) => e.id == employee.id,
        orElse: () => employee,
      ),
      orElse: () => employee,
    );

    final attendanceHistoryAsync = ref.watch(employeeAttendanceHistoryProvider(currentEmployee.id));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Employee Profile & Wages'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primaryColor(context)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmployeeFormScreen(employee: currentEmployee),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _onDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: currentEmployee.photoUrl != null && currentEmployee.photoUrl!.isNotEmpty
                        ? NetworkImage(currentEmployee.photoUrl!)
                        : null,
                    radius: 45,
                    backgroundColor: AppColors.primaryContainer,
                    child: currentEmployee.photoUrl == null || currentEmployee.photoUrl!.isEmpty
                        ? const Icon(Icons.person, size: 45, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentEmployee.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.mutedText(context).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          currentEmployee.shortId,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedText(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentEmployee.role.toUpperCase(),
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(currentEmployee.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: currentEmployee.status == 'active' ? AppColors.secondary : AppColors.outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Compensation & Tea Allowance Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.secondary,
                        child: Icon(Icons.payments_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Base Salary (Worker Pay)', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                            const SizedBox(height: 2),
                            Text(
                              '₹${currentEmployee.salary.toInt()} / day',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tea & Snacks Budget', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                            const SizedBox(height: 2),
                            Text(
                              '₹${currentEmployee.teaSnackAllowance.toInt()} / day',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Employer Daily Cost:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                      Text(
                        '₹${currentEmployee.totalDailyCost.toInt()} / day',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Mobile Phone: ${currentEmployee.phone}', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Attendance History Log
            Text('PAST ATTENDANCE LOGS & COST BREAKDOWN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),

            attendanceHistoryAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Center(
                      child: Text('No attendance history recorded yet.', style: TextStyle(color: AppColors.mutedText(context))),
                    ),
                  );
                }

                int presentDays = logs.where((l) => l.status == 'Present').length;
                double baseEarned = 0.0;
                double teaCost = 0.0;
                for (final l in logs) {
                  if (l.status == 'Present') {
                    baseEarned += (l.wageRate ?? currentEmployee.salary);
                    teaCost += (l.teaAllowance ?? currentEmployee.teaSnackAllowance);
                  }
                }
                double totalEmployerCost = baseEarned + teaCost;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Days Worked: $presentDays', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                              Text('Worker Pay: ₹${baseEarned.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tea & Snacks Spent:', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                              Text('₹${teaCost.toInt()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Employer Cost:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
                              Text('₹${totalEmployerCost.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryColor(context))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, i) {
                        final log = logs[i];
                        final isPresent = log.status == 'Present';
                        final earnedToday = isPresent ? (log.wageRate ?? currentEmployee.salary) : 0.0;
                        final teaToday = isPresent ? (log.teaAllowance ?? currentEmployee.teaSnackAllowance) : 0.0;

                        return Card(
                          color: AppColors.cardBg(context),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPresent ? AppColors.secondary : (log.status == 'Leave' ? Colors.amber : AppColors.error),
                              radius: 16,
                              child: Icon(
                                isPresent ? Icons.check : (log.status == 'Leave' ? Icons.time_to_leave : Icons.close),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text('Date: ${log.date}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                            subtitle: Text('Status: ${log.status}', style: TextStyle(color: AppColors.mutedText(context))),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isPresent ? '+₹${earnedToday.toInt()} pay' : '₹0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPresent ? AppColors.secondary : AppColors.mutedText(context),
                                  ),
                                ),
                                if (isPresent)
                                  Text(
                                    '+₹${teaToday.toInt()} tea',
                                    style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },

              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading attendance logs: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
