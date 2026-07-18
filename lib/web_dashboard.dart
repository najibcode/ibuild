import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';

class WebDashboard extends ConsumerWidget {
  final VoidCallback onSelectProject;

  const WebDashboard({
    super.key,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: statsAsync.when(
        data: (stats) => Row(
          children: [
            // Sidebar
            _buildSidebar(context),
            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top Header
                  _buildHeader(context),
                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.containerMargin),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Portfolio Overview Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Portfolio Overview',
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Real-time status of active construction sites.',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _buildOutlineButton(Icons.calendar_today, 'Last 30 Days'),
                                    const SizedBox(width: 12),
                                    _buildOutlineButton(Icons.filter_list, 'Filters'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // KPI Cards Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildKPICard(
                                    context: context,
                                    icon: Icons.payments,
                                    value: '₹42.8Cr',
                                    label: 'Total Budget',
                                    trend: '+4.2%',
                                    trendColor: AppColors.secondary,
                                    subtitle: 'Allocated for Q3 FY24',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildKPICard(
                                    context: context,
                                    icon: Icons.group,
                                    value: '${stats.employeesPresent}',
                                    label: 'Workers Present',
                                    trend: '94% attendance',
                                    trendColor: AppColors.secondary,
                                    subtitle: 'Current shift strength',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildKPICard(
                                    context: context,
                                    icon: Icons.pending_actions,
                                    value: '2',
                                    label: 'Delayed Tasks',
                                    trend: 'Requires Action',
                                    trendColor: AppColors.error,
                                    subtitle: 'Across all active sites',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildKPICard(
                                    context: context,
                                    icon: Icons.architecture,
                                    value: '${stats.activeProjects}',
                                    label: 'Active Projects',
                                    trend: '+2 this week',
                                    trendColor: AppColors.secondary,
                                    subtitle: '3 in planning phase',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Double Column Section
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Velocity & Projects
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Project Velocity',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildVelocityChart(context),
                                      const SizedBox(height: 32),
                                      // Quick Project Link
                                      const Text(
                                        'Quick Access',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildQuickAccessCard(context),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                // Right Column: Recent Activity
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recent Activity',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildRecentActivityList(context),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading stats: $e')),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        children: [
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin, vertical: 32),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.architecture, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'IBUILD',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarNavItem(Icons.dashboard, 'Dashboard', true),
                _buildSidebarNavItem(Icons.architecture, 'Projects', false, onTap: onSelectProject),
                _buildSidebarNavItem(Icons.group, 'Attendance', false),
                _buildSidebarNavItem(Icons.inventory_2, 'Materials', false),
                _buildSidebarNavItem(Icons.analytics, 'Analytics', false),
                _buildSidebarNavItem(Icons.settings, 'Settings', false),
              ],
            ),
          ),
          // Profile Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCZnkMp8GaOnpeTS6OaCmsGI3BT-AMfqKQlZgzWl_1P_wcfcpgsueuBT4g62apzZaMM9KDkryd5NwO0zRN2_qLL3tVRv-tkiZRKLnT4yZ4jh501MqajmHWV3-Tb0c-i328KeaLVPjpouYAeHclbEWmGX3AUSDoVNlY9uR_PjZhazvKln1VD_OY2Heh8KEFXssZ8Xdam3ObeFuJxVLLzfu2zy1jVcOM0hcAKPmqxBIh6d75KpFm9T7V-oUnUvLYk5UEqRnVhrWXTfOc',
                    ),
                    radius: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Admin',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Global Supervisor',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryContainer.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? const Border(left: BorderSide(color: AppColors.primary, width: 4))
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isActive ? AppColors.primary : AppColors.textMuted),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textMain,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search Input
          Container(
            width: 400,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search projects, materials, or reports...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: AppColors.outline, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Right Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.outline),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: AppColors.outline),
                onPressed: () {},
              ),
              const VerticalDivider(color: AppColors.borderSubtle, width: 24, indent: 20, endIndent: 20),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 14, color: AppColors.textMain),
      label: Text(
        label,
        style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildKPICard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required String trend,
    required Color trendColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityChart(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: [
            _makeBarGroup(0, 4.0, false),
            _makeBarGroup(1, 6.0, false),
            _makeBarGroup(2, 5.5, false),
            _makeBarGroup(3, 8.5, false),
            _makeBarGroup(4, 7.0, false),
            _makeBarGroup(5, 9.5, false),
            _makeBarGroup(6, 10.0, true),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, bool isActive) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isActive ? AppColors.primary : AppColors.primaryContainer.withOpacity(0.2),
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apartment, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skyline Apartments',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Commercial • On Track',
                    style: TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onSelectProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Go to Detail'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            icon: Icons.check_circle,
            iconColor: AppColors.secondary,
            title: 'Materials Delivered',
            time: '2m ago',
            subtitle: 'Concrete slab order #492 arrived at Sector 7-G.',
          ),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _buildActivityItem(
            icon: Icons.warning,
            iconColor: AppColors.warning,
            title: 'Labor Shortage Alert',
            time: '1h ago',
            subtitle: 'Site B reporting 15% lower attendance than scheduled.',
          ),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _buildActivityItem(
            icon: Icons.description,
            iconColor: AppColors.primary,
            title: 'New Plan Uploaded',
            time: '3h ago',
            subtitle: 'Architect updated the electrical schematics for Phase 2.',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'JetBrains Mono'),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
