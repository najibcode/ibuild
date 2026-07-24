import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';

class MaterialInventoryMobile extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const MaterialInventoryMobile({super.key, required this.onBack});

  @override
  ConsumerState<MaterialInventoryMobile> createState() =>
      _MaterialInventoryMobileState();
}

class _MaterialInventoryMobileState
    extends ConsumerState<MaterialInventoryMobile> {
  int _activeCategoryIndex = 0;

  final List<String> _categories = [
    'All Materials',
    'Cement & Steel',
    'Aggregates',
    'Finishing',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor(context)),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Material Inventory & Supply',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filters Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: TextField(
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'Search materials...',
                        hintStyle: TextStyle(color: AppColors.mutedText(context)),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.mutedText(context),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        _categories.length,
                        (index) => _buildFilterChip(
                          context,
                          label: _categories[index],
                          isActive: _activeCategoryIndex == index,
                          onTap: () {
                            setState(() {
                              _activeCategoryIndex = index;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Material List Cards
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
              ),
              child: Column(
                children: [
                  _buildInventoryCard(
                    context: context,
                    category: 'STRUCTURE & CONCRETE',
                    title: 'Ultratech OPC 53 Grade Cement',
                    currentStock: 450,
                    totalCapacity: 1000,
                    unitName: 'Bags',
                    progress: 0.45,
                    isLowStock: true,
                    timeUpdated: 'Updated 2h ago',
                    buttonText: 'Order Supplies',
                    buttonIcon: Icons.shopping_cart_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInventoryCard(
                    context: context,
                    category: 'STEEL & REBAR',
                    title: 'TMT Steel Bars (12mm)',
                    currentStock: 8200,
                    totalCapacity: 10000,
                    unitName: 'Kg',
                    progress: 0.82,
                    isLowStock: false,
                    timeUpdated: 'Updated 4h ago',
                    buttonText: 'Stock Audit',
                    buttonIcon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInventoryCard(
                    context: context,
                    category: 'AGGREGATES & M-SAND',
                    title: 'Crushed M-Sand (Fine)',
                    currentStock: 120,
                    totalCapacity: 500,
                    unitName: 'Tons',
                    progress: 0.24,
                    isLowStock: true,
                    timeUpdated: 'Updated 1d ago',
                    buttonText: 'Order Supplies',
                    buttonIcon: Icons.shopping_cart_outlined,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final primaryCol = AppColors.primaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive
              ? primaryCol
              : AppColors.cardBg(context),
          side: BorderSide(
            color: isActive ? primaryCol : AppColors.border(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.text(context),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard({
    required BuildContext context,
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
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedText(context),
                  letterSpacing: 0.5,
                ),
              ),
              if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 12, color: AppColors.error),
                      SizedBox(width: 4),
                      Text(
                        'LOW STOCK',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available: $currentStock / $totalCapacity $unitName',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(context),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLowStock ? AppColors.error : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation(
                isLowStock ? AppColors.error : AppColors.secondary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeUpdated,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(buttonIcon, size: 14),
                label: Text(buttonText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLowStock
                      ? Colors.deepOrange
                      : AppColors.primaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
