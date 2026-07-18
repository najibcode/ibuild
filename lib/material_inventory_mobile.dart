import 'package:flutter/material.dart';
import 'theme.dart';

class MaterialInventoryMobile extends StatefulWidget {
  final VoidCallback onBack;

  const MaterialInventoryMobile({super.key, required this.onBack});

  @override
  State<MaterialInventoryMobile> createState() =>
      _MaterialInventoryMobileState();
}

class _MaterialInventoryMobileState extends State<MaterialInventoryMobile> {
  int _activeCategory =
      0; // 0: All, 1: Structural, 2: Finishing, 3: Electrical, 4: Plumbing

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
          'IBUILD: Inventory',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.containerMargin),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: AppColors.primary,
              ),
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
                      hintText: 'Search materials...',
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
                      _buildCategoryChip('Finishing', 2),
                      _buildCategoryChip('Electrical', 3),
                      _buildCategoryChip('Plumbing', 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Inventory List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
              ),
              children: [
                if (_activeCategory == 0 || _activeCategory == 1)
                  _buildInventoryCard(
                    category: 'Structural',
                    title: 'Cement Bag - Grade A',
                    currentStock: 450,
                    totalCapacity: 2000,
                    unitName: 'Units',
                    progress: 0.225,
                    isLowStock: true,
                    timeUpdated: 'Updated 14 mins ago',
                    buttonText: 'Order More',
                    buttonIcon: Icons.chevron_right,
                  ),
                if (_activeCategory == 0 || _activeCategory == 3) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  _buildInventoryCard(
                    category: 'Electrical',
                    title: 'Copper Wire - 2.5mm',
                    currentStock: 1200,
                    totalCapacity: 1500,
                    unitName: 'Rolls',
                    progress: 0.80,
                    isLowStock: false,
                    timeUpdated: 'Updated 2 hours ago',
                    buttonText: 'Log Usage',
                    buttonIcon: Icons.history_edu,
                  ),
                ],
                if (_activeCategory == 0 || _activeCategory == 2) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  _buildInventoryCard(
                    category: 'Finishing',
                    title: 'Ceramic Tiles - White Gloss',
                    currentStock: 850,
                    totalCapacity: 1000,
                    unitName: 'Boxes',
                    progress: 0.85,
                    isLowStock: false,
                    timeUpdated: 'Updated 5 hours ago',
                    buttonText: 'Log Usage',
                    buttonIcon: Icons.history_edu,
                  ),
                ],
                if (_activeCategory == 0 || _activeCategory == 4) ...[
                  const SizedBox(height: AppSpacing.gutter),
                  _buildInventoryCard(
                    category: 'Plumbing',
                    title: 'PVC Pipe - 4 inch',
                    currentStock: 45,
                    totalCapacity: 300,
                    unitName: 'Pieces',
                    progress: 0.15,
                    isLowStock: true,
                    timeUpdated: 'Updated Yesterday',
                    buttonText: 'Order More',
                    buttonIcon: Icons.chevron_right,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.add_box),
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

  Widget _buildInventoryCard({
    required String category,
    required String title,
    required int currentStock,
    required int totalCapacity,
    required String unitName,
    required double progress,
    required bool isLowStock,
    required String timeUpdated,
    required String buttonText,
    required IconData buttonIcon,
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
                    category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? const Color(0xFFFEE2E2)
                      : AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLowStock) ...[
                      const Icon(
                        Icons.warning,
                        color: AppColors.error,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isLowStock ? 'Low Stock' : 'Optimal',
                      style: TextStyle(
                        color: isLowStock
                            ? AppColors.error
                            : AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Stock',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                '$currentStock / $totalCapacity $unitName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLowStock ? AppColors.error : AppColors.secondary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeUpdated,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(buttonIcon, size: 16),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
