import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../features/rbac/presentation/providers/permission_provider.dart';

/// Defines sidebar navigation items for the web layout.
class WebSidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// The permission key required to see this item.
  /// If null, the item is always visible.
  final String? requiredPermission;

  const WebSidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.requiredPermission,
  });
}

/// Shared sidebar widget used by all web (desktop) screens.
/// Lives in the MainRouterScreen shell — individual screens do not
/// render their own sidebar.
///
/// Items are filtered based on the user's RBAC permissions.
class WebSidebar extends ConsumerWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const WebSidebar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  static const List<WebSidebarItem> allItems = [
    WebSidebarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      requiredPermission: 'dashboard.view',
    ),
    WebSidebarItem(
      icon: Icons.architecture_outlined,
      activeIcon: Icons.architecture,
      label: 'Projects',
      requiredPermission: 'project.view',
    ),
    WebSidebarItem(
      icon: Icons.pending_actions_outlined,
      activeIcon: Icons.pending_actions,
      label: 'Attendance',
      requiredPermission: 'attendance.view',
    ),
    WebSidebarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Employees',
      requiredPermission: 'employee.view',
    ),
    WebSidebarItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Inventory',
      requiredPermission: 'inventory.view',
    ),
    WebSidebarItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Billing',
      requiredPermission: 'billing.view',
    ),
    WebSidebarItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Expenses',
      requiredPermission: 'expense.view',
    ),
    WebSidebarItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      requiredPermission: 'settings.manage',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permsAsync = ref.watch(userPermissionsProvider);
    final permissions = permsAsync.valueOrNull ?? <String>{};
    final roleName = ref.watch(currentRoleProvider);

    // Filter items based on user's permissions
    final visibleItems = allItems.where((item) {
      if (item.requiredPermission == null) return true;
      return permissions.contains(item.requiredPermission);
    }).toList();

    // Resolve role display name
    String roleDisplay;
    switch (roleName) {
      case 'admin':
        roleDisplay = 'Admin';
        break;
      case 'owner':
        roleDisplay = 'Business Owner';
        break;
      case 'supervisor':
        roleDisplay = 'Supervisor';
        break;
      default:
        roleDisplay = 'User';
    }

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        children: [
          // ── Branding ──
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

          // ── Navigation Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                // Insert a divider before Settings if it's the last item
                if (index == visibleItems.length - 1 &&
                    visibleItems[index].label == 'Settings') {
                  return Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.borderSubtle, height: 1),
                      ),
                      _buildNavItem(visibleItems, index),
                    ],
                  );
                }
                return _buildNavItem(visibleItems, index);
              },
            ),
          ),

          // ── Profile Card ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: const NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCZnkMp8GaOnpeTS6OaCmsGI3BT-AMfqKQlZgzWl_1P_wcfcpgsueuBT4g62apzZaMM9KDkryd5NwO0zRN2_qLL3tVRv-tkiZRKLnT4yZ4jh501MqajmHWV3-Tb0c-i328KeaLVPjpouYAeHclbEWmGX3AUSDoVNlY9uR_PjZhazvKln1VD_OY2Heh8KEFXssZ8Xdam3ObeFuJxVLLzfu2zy1jVcOM0hcAKPmqxBIh6d75KpFm9T7V-oUnUvLYk5UEqRnVhrWXTfOc',
                    ),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IBUILD User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleDisplay,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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

  Widget _buildNavItem(List<WebSidebarItem> visibleItems, int index) {
    final item = visibleItems[index];
    final bool isActive = activeIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryContainer.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? const Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        onTap: () => onTabSelected(index),
        leading: Icon(
          isActive ? item.activeIcon : item.icon,
          color: isActive ? AppColors.primary : AppColors.textMuted,
          size: 20,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textMain,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
