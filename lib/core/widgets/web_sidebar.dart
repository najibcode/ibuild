import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/rbac/presentation/providers/permission_provider.dart';
import 'package:ibuild/core/utils/avatar_helper.dart';
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
/// Clean 260px <-> 72px navigation with compact square hover highlights in
/// collapsed mode, zero popup tooltips, and zero horizontal spillover.
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
      icon: Icons.checklist_rtl_outlined,
      activeIcon: Icons.checklist_rtl,
      label: 'Site Snags & Quality Punch List',
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

class _WebSidebarState extends ConsumerState<WebSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _curvedAnimation;
  late Animation<double> _widthAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _iconRotation;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0, // 1.0 = expanded
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _widthAnimation = Tween<double>(begin: 72.0, end: 260.0).animate(_curvedAnimation);

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _iconRotation = Tween<double>(begin: 0.5, end: 0.0).animate(_curvedAnimation);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _animController.reverse();
      } else {
        _animController.forward();
      }
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

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final double width = _widthAnimation.value;
          final bool isCompact = width < 180.0;

          return Container(
            width: width,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // Dark Navy Slate 900
              border: Border(
                right: BorderSide(color: Color(0xFF1E293B)), // Slate 800
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ClipRect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Branding & Collapse Toggle Header ──
                    Container(
                      height: 68,
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 14),
                      child: isCompact
                          ? Center(
                              child: InkWell(
                                onTap: _toggleCollapse,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: AppLogo(
                                    size: 28,
                                    showText: false,
                                    inverted: true,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                InkWell(
                                  onTap: null,
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: AppLogo(
                                      size: 28,
                                      showText: false,
                                      inverted: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: ClipRect(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: const TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'IBU',
                                                    style: TextStyle(
                                                      fontFamily: 'Roboto',
                                                      fontSize: 16.5,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF60A5FA),
                                                      letterSpacing: -0.5,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'ILD',
                                                    style: TextStyle(
                                                      fontFamily: 'Roboto',
                                                      fontSize: 16.5,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.white,
                                                      letterSpacing: -0.5,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'CONSTRUCTION ERP',
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF94A3B8),
                                                letterSpacing: 1.6,
                                                height: 1.0,
                                              ),
                                              maxLines: 1,
                                              softWrap: false,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                RotationTransition(
                                  turns: _iconRotation,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    splashRadius: 16,
                                    onPressed: _toggleCollapse,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const Divider(height: 1, color: Color(0xFF1E293B)),
                    const SizedBox(height: 8),

                    // ── Navigation Items List ──
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 10,
                        ),
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
                                _buildNavItem(
                                  visibleItems: visibleItems,
                                  index: index,
                                  isCompact: isCompact,
                                ),
                              ],
                            );
                          }
                          return _buildNavItem(
                            visibleItems: visibleItems,
                            index: index,
                            isCompact: isCompact,
                          );
                        },
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFF1E293B)),

                    // ── User Profile Footer Card ──
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final authState = ref.watch(authControllerProvider);
                          final profile = authState.profile;
                          final userName =
                              profile?['full_name'] as String? ?? 'IBUILD User';
                          final avatarUrl = RoleAvatarHelper.getAvatarUrl(
                            customAvatarUrl: profile?['avatar_url'] as String?,
                            role: profile?['role'] as String? ?? roleName,
                            email: authState.user?.email,
                          );

                          if (isCompact) {
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const UserProfileScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: CircleAvatar(
                                    backgroundColor: const Color(0xFF2563EB),
                                    backgroundImage: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    onBackgroundImageError: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                                        ? (_, _) {}
                                        : null,
                                    radius: 17,
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF2563EB),
                                    backgroundImage: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    onBackgroundImageError: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                                        ? (_, _) {}
                                        : null,
                                    radius: 16,
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: ClipRect(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                softWrap: false,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                roleDisplay,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                maxLines: 1,
                                                softWrap: false,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required List<WebSidebarItem> visibleItems,
    required int index,
    required bool isCompact,
  }) {
    final item = visibleItems[index];
    final bool isActive = widget.activeIndex == index;
    final roleName = ref.watch(currentRoleProvider);
    final isAdmin = roleName == 'admin';

    final String displayLabel = (item.label == 'Settings' && isAdmin)
        ? 'Admin Control Center'
        : item.label;

    final IconData iconData = (item.label == 'Settings' && isAdmin)
        ? (isActive ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined)
        : (isActive ? item.activeIcon : item.icon);

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Center(
          child: InkWell(
            onTap: () => widget.onTabSelected(index),
            borderRadius: BorderRadius.circular(8),
            hoverColor: const Color(0xFF1E293B),
            child: Container(
              height: 42,
              width: 48,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: InkWell(
        onTap: () => widget.onTabSelected(index),
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFF1E293B),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                iconData,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ClipRect(
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
