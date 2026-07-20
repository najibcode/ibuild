import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'global_search_dialog.dart';

/// Shared top header bar for the web (desktop) layout.
/// Displays a search field, notifications, and contextual actions.
class WebHeader extends StatelessWidget {
  /// Optional title shown as breadcrumb text. Defaults to current section name.
  final String? title;

  /// Optional trailing action widget (e.g., "New Project" button).
  final Widget? trailing;

  final VoidCallback? onMenuPressed;

  const WebHeader({
    super.key,
    this.title,
    this.trailing,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: AppSpacing.gutter),
          ],
          // Search Input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: AppColors.outline, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Search projects, materials, or reports...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (query) {
                        showDialog(
                          context: context,
                          builder: (_) => GlobalSearchDialog(initialQuery: query),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Right Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.outline, size: 20),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: AppColors.outline, size: 20),
                onPressed: () {},
                tooltip: 'Help',
              ),
              if (trailing != null) ...[
                const VerticalDivider(
                  color: AppColors.borderSubtle,
                  width: 24,
                  indent: 18,
                  endIndent: 18,
                ),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
