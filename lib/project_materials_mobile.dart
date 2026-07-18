import 'package:flutter/material.dart';
import 'theme.dart';

class ProjectMaterialsMobile extends StatefulWidget {
  final VoidCallback onBack;

  const ProjectMaterialsMobile({
    super.key,
    required this.onBack,
  });

  @override
  State<ProjectMaterialsMobile> createState() => _ProjectMaterialsMobileState();
}

class _ProjectMaterialsMobileState extends State<ProjectMaterialsMobile> {
  int _activeCategory = 0; // 0: All, 1: Structural, 2: Electrical, 3: Plumbing, 4: Finishing

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'IBUILD: Materials',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.containerMargin),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.primary),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search materials by name or ID...',
                      hintStyle: TextStyle(color: Color(0x8F757684)),
                      prefixIcon: Icon(Icons.search, color: AppColors.outline),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                // Horizontal Filters
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('All', 0),
                      _buildCategoryChip('Structural', 1),
                      _buildCategoryChip('Electrical', 2),
                      _buildCategoryChip('Plumbing', 3),
                      _buildCategoryChip('Finishing', 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Materials List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
              children: [
                if (_activeCategory == 0 || _activeCategory == 1)
                  _buildMaterialCard(
                    category: 'C35/45 Mix • Grade A',
                    title: 'Ready-mix Concrete',
                    statusText: 'Delivered',
                    statusColor: AppColors.secondary,
                    statusBgColor: const Color(0x1F10B981),
                    allocated: 500,
                    consumed: 120,
                    progress: 0.24,
                    progressColor: AppColors.secondary,
                  ),
                if (_activeCategory == 0 || _activeCategory == 1) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  _buildMaterialCard(
                    category: 'ASTM A615 • 15m Lengths',
                    title: 'Steel Rebar #5',
                    statusText: 'On Order',
                    statusColor: AppColors.warning,
                    statusBgColor: const Color(0x1FFFDD5F),
                    allocated: 2500,
                    consumed: 1850,
                    progress: 0.74,
                    progressColor: AppColors.primary,
                  ),
                ],
                if (_activeCategory == 0 || _activeCategory == 2) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  _buildMaterialCard(
                    category: 'Insulated • 250ft Spools',
                    title: 'Copper Wiring 12/2',
                    statusText: 'In Use',
                    statusColor: AppColors.error,
                    statusBgColor: const Color(0x1FBA1A1A),
                    allocated: 45,
                    consumed: 40,
                    progress: 0.88,
                    progressColor: AppColors.error,
                  ),
                ],
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: const Icon(Icons.add),
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
          backgroundColor: isActive ? AppColors.primary : AppColors.surfaceWhite,
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

  Widget _buildMaterialCard({
    required String category,
    required String title,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    required int allocated,
    required int consumed,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocated: $allocated units',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                'Consumed: $consumed units',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Update Usage',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Request More',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
