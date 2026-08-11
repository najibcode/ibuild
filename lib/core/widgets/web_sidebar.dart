import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/rbac/presentation/providers/permission_provider.dart';
import 'package:ibuild/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ibuild/features/profile/presentation/screens/user_profile_screen.dart';
import 'app_logo.dart';

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

/// Shared collapsible sidebar widget for desktop/tablet ERP navigation.
/// Supports smooth 260px <-> 72px collapse animation, Dark Navy theme,
/// item tooltips in collapsed mode, and RBAC permissions without layout overflow.
class WebSidebar extends ConsumerStatefulWidget {
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
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Financials',
      requiredPermission: 'billing.view',
    ),
    WebSidebarItem(
      icon: Icons.construction_outlined,
      activeIcon: Icons.construction,
      label: 'Equipment, Machinery & Tools',
      requiredPermission: null,
    ),
    WebSidebarItem(
      icon: Icons.assignment_ind_outlined,
      activeIcon: Icons.assignment_ind,
      label: 'Subcontractors',
      requiredPermission: null,
    ),
    WebSidebarItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment,
      label: 'Reports & Export',
      requiredPermission: null,
    ),
    WebSidebarItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      requiredPermission: null,
    ),
  ];

  @override
  ConsumerState<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends ConsumerState<WebSidebar> {
  bool _isCollapsed = false;

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(userPermissionsProvider);
    final permissions = permissionsAsync.valueOrNull ?? {};
    final roleName = ref.watch(currentRoleProvider);

    final visibleItems = WebSidebar.allItems.where((item) {
      if (item.requiredPermission == null) return true;
      if (roleName == 'owner' || roleName == 'admin' || permissions.isEmpty) {
        return true;
      }
      return permissions.contains(item.requiredPermission);
    }).toList();

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

    final double width = _isCollapsed ? 72.0 : 260.0;

    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 270),
        curve: Curves.easeInOutCubic,
        width: width,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A), // Dark Navy Slate 900
          border: Border(
            right: BorderSide(color: Color(0xFF1E293B)), // Slate 800
          ),
        ),
        child: Column(
          children: [
            // ── Branding & Collapse Toggle Header ──
            Container(
              height: 70,
              padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 4 : 14),
              child: Row(
                mainAxisAlignment: _isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isCollapsed) ...[
                    const AppLogo(
                      size: 32,
                      subtitle: 'ERP ENTERPRISE',
                      inverted: true,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                      tooltip: 'Collapse Sidebar',
                      onPressed: _toggleCollapse,
                    ),
                  ] else ...[
                    Tooltip(
                      message: 'Expand Sidebar',
                      child: InkWell(
                        onTap: _toggleCollapse,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppLogo(
                                size: 24,
                                showText: false,
                                inverted: true,
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1E293B)),
            const SizedBox(height: 8),

            // ── Navigation Items List ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final isSettings = index == visibleItems.length - 1 &&
                      visibleItems[index].label == 'Settings';

                  if (isSettings) {
                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(color: Color(0xFF1E293B), height: 1),
                        ),
                        _buildNavItem(context, visibleItems, index),
                      ],
                    );
                  }
                  return _buildNavItem(context, visibleItems, index);
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1E293B)),

            // ── User Profile Footer Card ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authControllerProvider);
                  final profile = authState.profile;
                  final userName =
                      profile?['full_name'] as String? ?? 'IBUILD User';
                  final avatarUrl = profile?['avatar_url'] as String? ??
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCZnkMp8GaOnpeTS6OaCmsGI3BT-AMfqKQlZgzWl_1P_wcfcpgsueuBT4g62apzZaMM9KDkryd5NwO0zRN2_qLL3tVRv-tkiZRKLnT4yZ4jh501MqajmHWV3-Tb0c-i328KeaLVPjpouYAeHclbEWmGX3AUSDoVNlY9uR_PjZhazvKln1VD_OY2Heh8KEFXssZ8Xdam3ObeFuJxVLLzfu2zy1jVcOM0hcAKPmqxBIh6d75KpFm9T7V-oUnUvLYk5UEqRnVhrWXTfOc';

                  if (_isCollapsed) {
                    return Tooltip(
                      message: '$userName ($roleDisplay)',
                      preferBelow: false,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserProfileScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(avatarUrl),
                            radius: 18,
                          ),
                        ),
                      ),
                    );
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UserProfileScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(avatarUrl),
                            radius: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  roleDisplay,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    List<WebSidebarItem> visibleItems,
    int index,
  ) {
    final item = visibleItems[index];
    final bool isActive = widget.activeIndex == index;

    Widget navContent = InkWell(
      onTap: () => widget.onTabSelected(index),
      borderRadius: BorderRadius.circular(8),
      hoverColor: const Color(0xFF1E293B),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: _isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
              size: 20,
            ),
            if (!_isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (_isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Tooltip(
          message: item.label,
          preferBelow: false,
          child: navContent,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: navContent,
    );
  }
}
