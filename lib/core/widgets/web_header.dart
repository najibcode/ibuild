import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'global_search_dialog.dart';
import 'notifications_dropdown.dart';
import 'package:ibuild/features/profile/presentation/screens/user_profile_screen.dart';

/// Shared top header bar for the web (desktop) layout.
/// Displays a search field, notifications, and contextual actions.
class WebHeader extends ConsumerWidget {
  /// Optional title shown as breadcrumb text. Defaults to current section name.
  final String? title;

  /// Optional trailing action widget (e.g., "New Project" button).
  final Widget? trailing;

  final VoidCallback? onMenuPressed;

  const WebHeader({super.key, this.title, this.trailing, this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerMargin,
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(icon: const Icon(Icons.menu), onPressed: onMenuPressed),
            const SizedBox(width: AppSpacing.gutter),
          ],
          // Search Input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: AppColors.outline, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text(context),
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 15),
                        hintText: 'Search projects, materials, or reports...',
                        hintStyle: TextStyle(
                          color: AppColors.mutedText(context),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (query) {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              GlobalSearchDialog(initialQuery: query),
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
              const NotificationsDropdown(),
              IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.outline,
                  size: 22,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UserProfileScreen(),
                    ),
                  );
                },
                tooltip: 'My Profile',
              ),
              IconButton(
                icon: const Icon(
                  Icons.help_outline,
                  color: AppColors.outline,
                  size: 20,
                ),
                onPressed: () {},
                tooltip: 'Help',
              ),
              if (trailing != null) ...[
                VerticalDivider(
                  color: AppColors.border(context),
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
