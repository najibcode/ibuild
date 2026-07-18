import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final List<String>? filterOptions;
  final String? activeFilter;
  final ValueChanged<String?>? onFilterChanged;
  final List<String>? sortOptions;
  final String? activeSort;
  final ValueChanged<String?>? onSortChanged;

  const SearchFilterBar({
    super.key,
    this.hintText = 'Search...',
    required this.onSearchChanged,
    this.filterOptions,
    this.activeFilter,
    this.onFilterChanged,
    this.sortOptions,
    this.activeSort,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search row
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.outline, size: 20),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (filterOptions != null || sortOptions != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.stackSm),
            child: Row(
              children: [
                // Filter chips
                if (filterOptions != null)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChip('All', activeFilter == null, () => onFilterChanged?.call(null)),
                          ...filterOptions!.map((f) => _buildChip(f, activeFilter == f, () => onFilterChanged?.call(f))),
                        ],
                      ),
                    ),
                  ),
                // Sort dropdown
                if (sortOptions != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, size: 20, color: AppColors.outline),
                    onSelected: onSortChanged,
                    itemBuilder: (context) => sortOptions!
                        .map((s) => PopupMenuItem(value: s, child: Text(s)))
                        .toList(),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textMain,
          ),
        ),
        selected: isActive,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surfaceWhite,
        selectedColor: AppColors.primary,
        side: BorderSide(color: isActive ? AppColors.primary : AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}
