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
    final cardColor = AppColors.cardBg(context);
    final borderColor = AppColors.border(context);
    final primaryCol = AppColors.primaryColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search row
        TextField(
          onChanged: onSearchChanged,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(color: AppColors.text(context)),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 14),
            prefixIcon: Icon(Icons.search, color: AppColors.mutedText(context), size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.defaultValue),
              borderSide: BorderSide(color: primaryCol, width: 2),
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
                          _buildChip(context, 'All', activeFilter == null, () => onFilterChanged?.call(null)),
                          ...filterOptions!.map((f) => _buildChip(context, _capitalize(f), activeFilter == f, () => onFilterChanged?.call(f))),
                        ],
                      ),
                    ),
                  ),
                // Sort dropdown
                if (sortOptions != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.sort, size: 20, color: AppColors.mutedText(context)),
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

  Widget _buildChip(BuildContext context, String label, bool isActive, VoidCallback onTap) {
    final primaryCol = AppColors.primaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.text(context),
          ),
        ),
        selected: isActive,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.cardBg(context),
        selectedColor: primaryCol,
        side: BorderSide(color: isActive ? primaryCol : AppColors.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
