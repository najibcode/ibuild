import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/employee_model.dart';
import '../controllers/employee_controller.dart';
import 'employee_form_screen.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employee Details'),
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
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                        ? NetworkImage(employee.photoUrl!)
                        : null,
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: employee.photoUrl == null || employee.photoUrl!.isEmpty
                        ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    employee.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.role.toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: employee.status == 'active'
                          ? const Color(0x1F10B981)
                          : const Color(0x1FBA1A1A),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      employee.status.toUpperCase(),
                      style: TextStyle(
                        color: employee.status == 'active' ? AppColors.secondary : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detail fields list
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.phone_outlined, 'Phone', employee.phone, true),
                  _buildDetailRow(Icons.payments_outlined, 'Salary', '₹${employee.salary.toStringAsFixed(2)}', true),
                  _buildDetailRow(Icons.work_outline, 'Assigned Projects', 'Skyline Apartments', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool showDivider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.outline, size: 20),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            color: AppColors.borderSubtle,
            height: 1,
            indent: 52,
          ),
      ],
    );
  }
}
