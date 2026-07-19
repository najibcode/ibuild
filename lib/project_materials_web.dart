import 'package:flutter/material.dart';
import 'theme.dart';

class ProjectMaterialsWeb extends StatefulWidget {
  final VoidCallback onBack;

  const ProjectMaterialsWeb({super.key, required this.onBack});

  @override
  State<ProjectMaterialsWeb> createState() => _ProjectMaterialsWebState();
}

class _ProjectMaterialsWebState extends State<ProjectMaterialsWeb> {
  int _activeCategory =
      0; // 0: All, 1: Structural, 2: Electrical, 3: Plumbing, 4: Finishing

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header (Breadcrumbs + Actions)
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
                          // Search & Categories Filters Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Categories
                              Row(
                                children: [
                                  _buildCategoryChip('All', 0),
                                  _buildCategoryChip('Structural', 1),
                                  _buildCategoryChip('Electrical', 2),
                                  _buildCategoryChip('Plumbing', 3),
                                  _buildCategoryChip('Finishing', 4),
                                ],
                              ),
                              // Search input
                              Container(
                                width: 300,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.borderSubtle,
                                  ),
                                ),
                                child: const TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search materials...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: AppColors.outline,
                                      size: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Table View Card
                          Container(
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Table Header Row
                                Container(
                                  color: AppColors.background,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'MATERIAL NAME',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.outline,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'ALLOCATION',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.outline,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'PROGRESS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.outline,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'STATUS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.outline,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'ACTIONS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.outline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Table Rows
                                if (_activeCategory == 0 ||
                                    _activeCategory == 1) ...[
                                  _buildTableRow(
                                    title: 'Ready-mix Concrete',
                                    description: 'C35/45 Mix • Grade A',
                                    allocation: '500 units',
                                    consumed: '120 units',
                                    progress: 0.24,
                                    progressColor: AppColors.secondary,
                                    statusText: 'Delivered',
                                    statusColor: AppColors.secondary,
                                    statusBgColor: const Color(0x1F10B981),
                                  ),
                                  const Divider(
                                    color: AppColors.borderSubtle,
                                    height: 1,
                                  ),
                                  _buildTableRow(
                                    title: 'Steel Rebar #5',
                                    description: 'ASTM A615 • 15m Lengths',
                                    allocation: '2,500 units',
                                    consumed: '1,850 units',
                                    progress: 0.74,
                                    progressColor: AppColors.primary,
                                    statusText: 'On Order',
                                    statusColor: AppColors.warning,
                                    statusBgColor: const Color(0x1FFFDD5F),
                                  ),
                                ],
                                if (_activeCategory == 0 ||
                                    _activeCategory == 2) ...[
                                  if (_activeCategory == 0)
                                    const Divider(
                                      color: AppColors.borderSubtle,
                                      height: 1,
                                    ),
                                  _buildTableRow(
                                    title: 'Copper Wiring 12/2',
                                    description: 'Insulated • 250ft Spools',
                                    allocation: '45 units',
                                    consumed: '40 units',
                                    progress: 0.88,
                                    progressColor: AppColors.error,
                                    statusText: 'In Use',
                                    statusColor: AppColors.error,
                                    statusBgColor: const Color(0x1FBA1A1A),
                                  ),
                                ],
                              ],
                            ),
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerMargin,
              vertical: 32,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.architecture,
                    color: AppColors.primary,
                  ),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarNavItem(
                  Icons.dashboard,
                  'Dashboard',
                  false,
                  onTap: widget.onBack,
                ),
                _buildSidebarNavItem(
                  Icons.architecture,
                  'Projects',
                  false,
                  onTap: widget.onBack,
                ),
                _buildSidebarNavItem(Icons.group, 'Attendance', false),
                _buildSidebarNavItem(Icons.inventory_2, 'Materials', true),
                _buildSidebarNavItem(Icons.analytics, 'Analytics', false),
                _buildSidebarNavItem(Icons.settings, 'Settings', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryContainer.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? const Border(left: BorderSide(color: AppColors.primary, width: 4))
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textMuted,
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerMargin,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumbs
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              const Text(
                'Skyline Apartments',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.outline,
              ),
              const SizedBox(width: 4),
              const Text(
                'Materials',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Material'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int index) {
    final bool isActive = _activeCategory == index;
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.stackSm),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _activeCategory = index;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive
              ? AppColors.primary
              : AppColors.surfaceWhite,
          side: BorderSide(
            color: isActive ? AppColors.primary : AppColors.borderSubtle,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textMain,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String title,
    required String description,
    required String allocation,
    required String consumed,
    required double progress,
    required Color progressColor,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Material Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Allocation
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allocation,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  'Consumed: $consumed',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Progress
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Usage',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Update',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Request',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
