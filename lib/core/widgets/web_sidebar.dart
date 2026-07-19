import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Defines sidebar navigation items for the web layout.
class WebSidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const WebSidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Shared sidebar widget used by all web (desktop) screens.
/// Lives in the MainRouterScreen shell — individual screens do not
/// render their own sidebar.
class WebSidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const WebSidebar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  static const List<WebSidebarItem> items = [
    WebSidebarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    WebSidebarItem(
      icon: Icons.architecture_outlined,
      activeIcon: Icons.architecture,
      label: 'Projects',
    ),
    WebSidebarItem(
      icon: Icons.pending_actions_outlined,
      activeIcon: Icons.pending_actions,
      label: 'Attendance',
    ),
    WebSidebarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Employees',
    ),
    WebSidebarItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Inventory',
    ),
    WebSidebarItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Billing',
    ),
    WebSidebarItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Expenses',
    ),
    WebSidebarItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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

          // ── Navigation Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                // Insert a divider before Settings (the last item)
                if (index == items.length - 1) {
                  return Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.borderSubtle, height: 1),
                      ),
                      _buildNavItem(index),
                    ],
                  );
                }
                return _buildNavItem(index);
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textMain,
                          ),
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

  Widget _buildNavItem(int index) {
    final item = items[index];
    final bool isActive = activeIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryContainer.withOpacity(0.08)
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
