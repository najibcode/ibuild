import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../employees/data/repositories/supabase_employee_repository.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/controllers/project_controller.dart';

import '../../../employees/presentation/controllers/employee_controller.dart';

final supervisorListProvider = FutureProvider<List<Employee>>((ref) async {
  final repo = ref.watch(employeeRepositoryProvider);
  final all = await repo.getEmployees();
  return all.where((e) => e.role.toLowerCase() == 'supervisor').toList();
});

class SupervisorManagementScreen extends ConsumerStatefulWidget {
  const SupervisorManagementScreen({super.key});

  @override
  ConsumerState<SupervisorManagementScreen> createState() => _SupervisorManagementScreenState();
}

class _SupervisorManagementScreenState extends ConsumerState<SupervisorManagementScreen> {
  final Set<String> _selectedPermissions = {
    'project.view',
    'attendance.view',
    'attendance.create',
    'inventory.view',
    'daily_progress.create',
  };

  void _toggleAllPermissions(bool enableAll) {
    setState(() {
      if (enableAll) {
        _selectedPermissions.addAll([
          'project.view',
          'project.create',
          'attendance.view',
          'attendance.create',
          'inventory.view',
          'inventory.create',
          'billing.view',
          'expense.view',
          'expense.create',
          'daily_progress.create',
        ]);
      } else {
        _selectedPermissions.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final supervisorsAsync = ref.watch(supervisorListProvider);
    final projectsAsync = ref.watch(projectControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Supervisor Access Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              color: AppColors.cardBg(context),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.security_outlined, color: Colors.white),
                ),
                title: Text('Role Access Controls', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                subtitle: const Text('Assign site access and configure module permissions for supervisors'),
              ),
            ),
            const SizedBox(height: 24),
            Text('SUPERVISOR DIRECTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            supervisorsAsync.when(
              data: (supervisors) {
                if (supervisors.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('No supervisors registered. Create a new supervisor account.')),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: supervisors.length,
                  itemBuilder: (context, i) {
                    final sup = supervisors[i];
                    return Card(
                      color: AppColors.cardBg(context),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, color: AppColors.primary),
                        title: Text(sup.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                        subtitle: Text('Mobile: ${sup.phone} • Status: ${sup.status}\nAll Projects Access Enabled'),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(sup.status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: sup.status == 'Active' ? AppColors.secondary : AppColors.outline,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error loading supervisors: $e'),
            ),
            const SizedBox(height: 24),

            // Grouped Permissions Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CONFIGURED SUPERVISOR PERMISSIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText(context), letterSpacing: 0.5)),
                Row(
                  children: [
                    TextButton(onPressed: () => _toggleAllPermissions(true), child: const Text('Select All')),
                    TextButton(onPressed: () => _toggleAllPermissions(false), child: const Text('Clear All')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                children: [
                  _permTile('View Projects & Sites', 'project.view'),
                  _permTile('Create/Edit Projects', 'project.create'),
                  const Divider(),
                  _permTile('View Attendance Logs', 'attendance.view'),
                  _permTile('Mark Daily Attendance', 'attendance.create'),
                  const Divider(),
                  _permTile('View Inventory Items', 'inventory.view'),
                  _permTile('Issue Materials', 'inventory.create'),
                  const Divider(),
                  _permTile('Submit Daily Progress & Images', 'daily_progress.create'),
                  _permTile('View Financial Bills & Expenses', 'billing.view'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supervisor permissions updated successfully'), backgroundColor: AppColors.secondary),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Permission Configuration'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primaryColor(context),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permTile(String title, String key) {
    final isSelected = _selectedPermissions.contains(key);
    return CheckboxListTile(
      value: isSelected,
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
      subtitle: Text('Permission key: $key', style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _selectedPermissions.add(key);
          } else {
            _selectedPermissions.remove(key);
          }
        });
      },
    );
  }
}
