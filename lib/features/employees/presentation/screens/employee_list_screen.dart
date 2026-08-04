import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import '../../data/models/employee_model.dart';
import '../controllers/employee_controller.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String _searchQuery = '';
  String? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeeListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: Text(
          'Workforce & Staff Directory',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
                );
                ref
                    .read(employeeListControllerProvider.notifier)
                    .loadEmployees();
              },
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text(
                '+ Add Employee',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor(context)),
            onPressed: () => ref
                .read(employeeListControllerProvider.notifier)
                .loadEmployees(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EmployeeFormScreen()));
          ref.read(employeeListControllerProvider.notifier).loadEmployees();
        },
        backgroundColor: AppColors.primaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
      body: employeesAsync.when(
        data: (employees) {
          // Compute Workforce & Daily Wage Metrics
          final activeCount = employees
              .where((e) => e.status.toLowerCase() == 'active')
              .length;
          final totalDailyWageEst = employees.fold(
            0.0,
            (sum, e) => sum + e.totalDailyCost,
          );

          // Extract unique roles for filter chips
          final roles = employees.map((e) => e.role).toSet().toList();

          // Apply client-side search and role filtering
          final filtered = employees.where((e) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.phone.contains(_searchQuery) ||
                e.role.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesRole =
                _roleFilter == null ||
                e.role.toLowerCase() == _roleFilter!.toLowerCase();
            return matchesSearch && matchesRole;
          }).toList();

          return Column(
            children: [
              // Workforce & Wage Summary Header Cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Total Workforce',
                        value: '${employees.length}',
                        subtitle: '$activeCount Active Staff',
                        icon: Icons.people_outline,
                        color: AppColors.primaryColor(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Active Ratio',
                        value:
                            '${employees.isEmpty ? 0 : ((activeCount / employees.length) * 100).toInt()}%',
                        subtitle: '$activeCount On Duty',
                        icon: Icons.check_circle_outline,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        title: 'Est Daily Wages',
                        value: '₹${totalDailyWageEst.toInt()}',
                        subtitle: 'Per Day Payroll',
                        icon: Icons.payments_outlined,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Search & Role Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SearchFilterBar(
                  hintText: 'Search staff by name, role, phone...',
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  filterOptions: roles,
                  activeFilter: _roleFilter,
                  onFilterChanged: (f) => setState(() => _roleFilter = f),
                ),
              ),
              const SizedBox(height: 8),

              // Employee Directory List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.mutedText(
                                context,
                              ).withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No staff records found.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add construction workers, supervisors, or site staff.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const EmployeeFormScreen(),
                                  ),
                                );
                                ref
                                    .read(
                                      employeeListControllerProvider.notifier,
                                    )
                                    .loadEmployees();
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add New Employee'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor(
                                  context,
                                ),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final employee = filtered[index];
                          return _buildEmployeeCard(context, employee);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading employees: $e')),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
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
            style: TextStyle(fontSize: 9, color: AppColors.mutedText(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Employee employee) {
    final isActive = employee.status.toLowerCase() == 'active';
    final primaryCol = AppColors.primaryColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmployeeDetailScreen(employee: employee),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundImage:
                    employee.photoUrl != null && employee.photoUrl!.isNotEmpty
                    ? NetworkImage(employee.photoUrl!)
                    : null,
                backgroundColor: primaryCol.withValues(alpha: 0.12),
                radius: 24,
                child: employee.photoUrl == null || employee.photoUrl!.isEmpty
                    ? Icon(Icons.person_outline, color: primaryCol, size: 24)
                    : null,
              ),
              const SizedBox(width: 14),

              // Staff Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            employee.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.text(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.secondary.withValues(alpha: 0.12)
                                : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            employee.status.toUpperCase(),
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.secondary
                                  : AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryCol.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            employee.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryCol,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${employee.salary.toInt()}/day + ₹${employee.teaSnackAllowance.toInt()} tea',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: AppColors.mutedText(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employee.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.mutedText(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
