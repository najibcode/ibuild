import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../controllers/employee_controller.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: const Text(
          'Employees',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(employeeListControllerProvider.notifier).loadEmployees(),
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(
              child: Text(
                'No employees found. Add some!',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                        ? NetworkImage(employee.photoUrl!)
                        : null,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: employee.photoUrl == null || employee.photoUrl!.isEmpty
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  title: Text(
                    employee.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  subtitle: Text('${employee.role} • ${employee.phone}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EmployeeDetailScreen(employee: employee),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading employees: $e')),
      ),
      floatingActionButton: PermissionGuard(
        permission: 'employee.create',
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EmployeeFormScreen(),
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
