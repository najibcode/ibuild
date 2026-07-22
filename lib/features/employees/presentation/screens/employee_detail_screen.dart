import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
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
      if (success && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceHistoryAsync = ref.watch(employeeAttendanceHistoryProvider(employee.id));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Employee Profile & Wages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmployeeFormScreen(employee: employee),
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
                    backgroundImage: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                        ? NetworkImage(employee.photoUrl!)
                        : null,
                    radius: 45,
                    backgroundColor: AppColors.primaryContainer,
                    child: employee.photoUrl == null || employee.photoUrl!.isEmpty
                        ? const Icon(Icons.person, size: 45, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    employee.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.role.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(employee.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: employee.status == 'active' ? AppColors.secondary : AppColors.outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Wage Rate Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.payments_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Wage Salary Rate', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                      const SizedBox(height: 2),
                      Text(
                        '₹${employee.salary.toInt()} / day',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                      ),
                      Text('Mobile Phone: ${employee.phone}', style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Attendance History Log
            Text('PAST ATTENDANCE LOGS & DAILY EARNINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
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
                double totalEarned = presentDays * employee.salary;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Present Days: $presentDays', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                          Text('Accumulated Wages: ₹${totalEarned.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor(context))),
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
                        final earnedToday = isPresent ? employee.salary : 0.0;

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
                            subtitle: Text('Status: ${log.status}'),
                            trailing: Text(
                              isPresent ? '+₹${earnedToday.toInt()}' : '₹0',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPresent ? AppColors.secondary : AppColors.mutedText(context),
                              ),
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
