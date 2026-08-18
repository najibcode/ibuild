import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/router.dart';
import 'core/navigation/mobile_nav_helper.dart';
import 'core/utils/avatar_helper.dart';
import 'core/services/push_notification_service.dart';
import 'core/widgets/responsive_layout.dart';
import 'core/widgets/web_sidebar.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/projects/presentation/controllers/project_controller.dart';

import 'mobile_dashboard.dart';
import 'features/attendance/presentation/screens/attendance_screen.dart';
import 'features/attendance/presentation/controllers/attendance_controller.dart';
import 'features/employees/presentation/screens/employee_list_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'package:ibuild/features/profile/presentation/screens/user_profile_screen.dart';

import 'features/billing/presentation/screens/financials_hub_screen.dart';
import 'features/projects/presentation/screens/project_list_screen.dart';
import 'features/inventory/presentation/screens/inventory_list_screen.dart';
import 'features/equipment/presentation/screens/equipment_list_screen.dart';
import 'features/vendors/presentation/screens/vendor_list_screen.dart';
import 'features/snags/presentation/screens/snag_list_screen.dart';
import 'features/reports/presentation/screens/full_report_generator_screen.dart';

import 'web_dashboard.dart';
import 'features/dashboard/presentation/screens/admin_dashboard.dart';
import 'features/dashboard/presentation/screens/supervisor_dashboard.dart';
import 'features/rbac/presentation/providers/permission_provider.dart';

import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/subcontractors/presentation/controllers/subcontractor_controller.dart';
import 'features/expenses/presentation/controllers/expense_controller.dart';
import 'features/employees/presentation/controllers/employee_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file with resilient fallback
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Note: .env load warning: $e');
  }

  const defaultSupabaseUrl = 'https://dxjvvashdbhlfvsjfdjq.supabase.co';
  const defaultSupabaseKey = 'sb_publishable_mTs0l8WYewMHwLNPwV0wow_FZ6Nvmnd';

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? defaultSupabaseUrl;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? defaultSupabaseKey;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'IBUild Construction Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

// Mobile Screen Enum for easy state navigation
enum MobileScreen {
  dashboard,
  projectsList,
  inventory,
  attendance,
  employees,
  financials,
  equipment,
  vendors,
  snags,
  reports,
  settings,
  profile,
}

class MainRouterScreen extends ConsumerStatefulWidget {
  const MainRouterScreen({super.key});

  @override
  ConsumerState<MainRouterScreen> createState() => _MainRouterScreenState();
}

class _MainRouterScreenState extends ConsumerState<MainRouterScreen> {
  // Navigation history stack for mobile view
  final List<MobileScreen> _mobileNavStack = [MobileScreen.dashboard];

  // Active Web Screen selection — now maps to filtered visible items
  int _activeWebTab = 0;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _subscribeToRealtimeSync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pushNotificationServiceProvider).initializeRealtimeListener(context);
      }
    });
  }

  void _subscribeToRealtimeSync() {
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client
          .channel('public:ibuild_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'projects',
            callback: (payload) => _onTableChanged('projects'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'expenses',
            callback: (payload) => _onTableChanged('expenses'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'attendance',
            callback: (payload) => _onTableChanged('attendance'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'system_settings',
            callback: (payload) => _onTableChanged('system_settings'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'daily_progress',
            callback: (payload) => _onTableChanged('daily_progress'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'checklist_items',
            callback: (payload) => _onTableChanged('checklist_items'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'payments',
            callback: (payload) => _onTableChanged('payments'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'material_stock',
            callback: (payload) => _onTableChanged('material_stock'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'vendor_bills',
            callback: (payload) => _onTableChanged('vendor_bills'),
          )
          .subscribe();
    } catch (_) {}
  }

  /// Selective refresh: only reload the providers affected by the changed table.
  void _onTableChanged(String table) {
    if (!mounted) return;
    try {
      // Always refresh dashboard stats (lightweight)
      ref.invalidate(dashboardStatsProvider);

      switch (table) {
        case 'projects':
          ref.read(projectControllerProvider.notifier).loadProjects();
          break;
        case 'attendance':
          final selDate = ref.read(attendanceControllerProvider).selectedDate;
          if (selDate.isNotEmpty) {
            ref.read(attendanceControllerProvider.notifier).loadAttendanceForDate(selDate, showLoading: false);
          }
          break;
        case 'expenses':
          ref.read(expenseControllerProvider.notifier).loadExpenses();
          break;
        case 'material_stock':
          // Inventory list will auto-refresh via its own provider watch
          break;
        case 'vendor_bills':
        case 'payments':
          // Billing/payments screens will refresh via their own provider watch
          break;
        case 'daily_progress':
        case 'checklist_items':
          // Refresh projects to update progress data
          ref.read(projectControllerProvider.notifier).loadProjects();
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // Push a new mobile screen
  void _pushMobile(MobileScreen screen) {
    if (_mobileNavStack.isNotEmpty && _mobileNavStack.last == screen) return;
    setState(() {
      _mobileNavStack.add(screen);
    });
    _refreshDataForMobileScreen(screen);
  }

  // Pop the top mobile screen
  void _popMobile() {
    if (_mobileNavStack.length > 1) {
      setState(() {
        _mobileNavStack.removeLast();
      });
    }
  }

  // Set absolute mobile screen (resets stack) + auto-reload
  void _setMobileTab(MobileScreen screen) {
    // Skip if already on this tab to avoid unnecessary rebuilds
    if (_mobileNavStack.length == 1 && _mobileNavStack.last == screen) return;
    setState(() {
      _mobileNavStack.clear();
      _mobileNavStack.add(screen);
    });
    _refreshDataForMobileScreen(screen);
  }

  // Get current active mobile screen
  MobileScreen get _currentMobileScreen => _mobileNavStack.last;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(),
      desktopLayout: _buildDesktopLayout(),
    );
  }

  // --- MOBILE NAVIGATION & LAYOUT ---
  Widget _buildMobileLayout() {
    final role = ref.watch(currentRoleProvider);
    final canPopMobile = _mobileNavStack.length > 1;
    final onBack = canPopMobile ? _popMobile : null;

    Widget body;
    switch (_currentMobileScreen) {
      case MobileScreen.dashboard:
        // Route to role-specific dashboard
        if (role == 'admin') {
          body = const AdminDashboard();
        } else if (role == 'supervisor') {
          body = const SupervisorDashboard();
        } else {
          // Owner or unknown gets the default business dashboard
          body = MobileDashboard(
            onViewProjects: () => _pushMobile(MobileScreen.projectsList),
            onViewTrack: () => _pushMobile(MobileScreen.financials),
            onViewSupply: () => _pushMobile(MobileScreen.inventory),
            onMenuPressed: MobileNavHelper.openDrawer,
          );
        }
        break;
      case MobileScreen.projectsList:
        body = ProjectListScreen(onBackPressed: onBack);
        break;
      case MobileScreen.inventory:
        body = InventoryListScreen(onBackPressed: onBack);
        break;
      case MobileScreen.attendance:
        body = AttendanceScreen(onBackPressed: onBack);
        break;
      case MobileScreen.employees:
        body = EmployeeListScreen(onBackPressed: onBack);
        break;
      case MobileScreen.financials:
        body = FinancialsHubScreen(onBackPressed: onBack);
        break;
      case MobileScreen.equipment:
        body = EquipmentListScreen(onBackPressed: onBack);
        break;
      case MobileScreen.vendors:
        body = VendorListScreen(onBackPressed: onBack);
        break;
      case MobileScreen.snags:
        body = SnagListScreen(onBackPressed: onBack);
        break;
      case MobileScreen.reports:
        body = FullReportGeneratorScreen(onBackPressed: onBack);
        break;
      case MobileScreen.settings:
        body = SettingsScreen(onBackPressed: onBack);
        break;
      case MobileScreen.profile:
        body = UserProfileScreen(onBackPressed: onBack);
        break;
    }

    // Build 5 primary bottom nav items: Dashboard, Attendance, Projects, Inventory, Financials
    final List<_MobileNavEntry> navEntries = [
      _MobileNavEntry(
        screen: MobileScreen.dashboard,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
      _MobileNavEntry(
        screen: MobileScreen.attendance,
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg,
        label: 'Attendance',
      ),
      _MobileNavEntry(
        screen: MobileScreen.projectsList,
        icon: Icons.foundation_outlined,
        activeIcon: Icons.foundation,
        label: 'Projects',
      ),
      _MobileNavEntry(
        screen: MobileScreen.inventory,
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Inventory',
      ),
      _MobileNavEntry(
        screen: MobileScreen.financials,
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        label: 'Financials',
      ),
    ];

    // Find the active bottom bar index
    int bottomBarIndex = 0;
    for (int i = 0; i < navEntries.length; i++) {
      if (_currentMobileScreen == navEntries[i].screen) {
        bottomBarIndex = i;
        break;
      }
    }

    // Clamp to valid range
    if (bottomBarIndex >= navEntries.length) {
      bottomBarIndex = 0;
    }

    return PopScope(
      canPop: _mobileNavStack.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _mobileNavStack.length > 1) {
          _popMobile();
        }
      },
      child: Scaffold(
        key: MobileNavHelper.scaffoldKey,
        drawer: _buildMobileDrawer(context, role),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: KeyedSubtree(
            key: ValueKey(_currentMobileScreen),
            child: body,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: bottomBarIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (index) {
            if (index < navEntries.length) {
              _setMobileTab(navEntries[index].screen);
            }
          },
          items: navEntries
              .map((e) => BottomNavigationBarItem(
                    icon: Icon(e.icon),
                    activeIcon: Icon(e.activeIcon),
                    label: e.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// Mobile Navigation Drawer accessible from the 3-line hamburger menu
  Widget _buildMobileDrawer(BuildContext context, String role) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final displayName = profile?['full_name'] as String? ??
        (authState.user?.email?.split('@').first ?? 'Business Owner');
    final email = authState.user?.email ?? 'admin@ibuild.app';
    final avatarUrl = RoleAvatarHelper.getAvatarUrl(
      customAvatarUrl: profile?['avatar_url'] as String?,
      role: profile?['role'] as String? ?? role,
      email: email,
    );
    final formattedRole = (profile?['role'] as String? ?? role).replaceAll('_', ' ').toUpperCase();

    return Drawer(
      backgroundColor: AppColors.cardBg(context),
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border(bottom: BorderSide(color: AppColors.border(context))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            formattedRole,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items Organized By Categories (No duplicate primary tabs)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  // BUSINESS
                  _drawerSectionHeader(context, 'BUSINESS'),
                  _drawerItem(
                    icon: Icons.people_outline,
                    label: 'Employees & Staff Directory',
                    isSelected: _currentMobileScreen == MobileScreen.employees,
                    onTap: () {
                      Navigator.pop(context);
                      _pushMobile(MobileScreen.employees);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Subcontractors & Trade Partners',
                    isSelected: _currentMobileScreen == MobileScreen.vendors,
                    onTap: () {
                      Navigator.pop(context);
                      _pushMobile(MobileScreen.vendors);
                    },
                  ),

                  // SITE OPERATIONS
                  _drawerSectionHeader(context, 'SITE OPERATIONS'),
                  _drawerItem(
                    icon: Icons.construction_outlined,
                    label: 'Equipment, Machinery & Tools',
                    isSelected: _currentMobileScreen == MobileScreen.equipment,
                    onTap: () {
                      Navigator.pop(context);
                      _pushMobile(MobileScreen.equipment);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.checklist_rtl_outlined,
                    label: 'Site Snags & Quality Punch List',
                    isSelected: _currentMobileScreen == MobileScreen.snags,
                    onTap: () {
                      Navigator.pop(context);
                      _pushMobile(MobileScreen.snags);
                    },
                  ),

                  // REPORTING
                  _drawerSectionHeader(context, 'REPORTING'),
                  _drawerItem(
                    icon: Icons.assessment_outlined,
                    label: 'Reports & Data Export',
                    isSelected: _currentMobileScreen == MobileScreen.reports,
                    onTap: () {
                      Navigator.pop(context);
                      _pushMobile(MobileScreen.reports);
                    },
                  ),

                  // ACCOUNT
                  _drawerSectionHeader(context, 'ACCOUNT'),
                  _drawerItem(
                    icon: Icons.account_circle_outlined,
                    label: 'My Profile & Notifications',
                    isSelected: _currentMobileScreen == MobileScreen.profile,
                    onTap: () {
                      Navigator.pop(context);
                      _pushMobile(MobileScreen.profile);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isSelected: _currentMobileScreen == MobileScreen.settings,
                    onTap: () {
                      Navigator.pop(context);
                      _pushMobile(MobileScreen.settings);
                    },
                  ),
                ],
              ),
            ),
            // Footer Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border(context))),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.mutedText(context),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.mutedText(context),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.text(context),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: onTap,
    );
  }

  // ── Auto-Reload Data on Tab Switch ──

  /// Refreshes data for the selected web sidebar tab
  void _refreshDataForWebTab(int index) {
    final permsAsync = ref.read(userPermissionsProvider);
    final permissions = permsAsync.valueOrNull ?? <String>{};
    final role = ref.read(currentRoleProvider);

    final visibleItems = WebSidebar.allItems.where((item) {
      if (item.requiredPermission == null) return true;
      if (role == 'owner' || role == 'admin' || permissions.isEmpty) return true;
      return permissions.contains(item.requiredPermission);
    }).toList();

    if (index >= visibleItems.length) return;

    final label = visibleItems[index].label;
    _refreshDataForLabel(label);
  }

  /// Refreshes data for the selected mobile screen
  void _refreshDataForMobileScreen(MobileScreen screen) {
    switch (screen) {
      case MobileScreen.dashboard:
        _refreshDataForLabel('Dashboard');
        break;
      case MobileScreen.projectsList:
        _refreshDataForLabel('Projects');
        break;
      case MobileScreen.attendance:
        _refreshDataForLabel('Attendance');
        break;
      case MobileScreen.employees:
        _refreshDataForLabel('Employees');
        break;
      case MobileScreen.inventory:
        _refreshDataForLabel('Inventory');
        break;
      case MobileScreen.snags:
      case MobileScreen.reports:
      case MobileScreen.profile:
        break; // These screens load their own data or are local-only
      case MobileScreen.financials:
        _refreshDataForLabel('Financials');
        break;
      case MobileScreen.equipment:
        _refreshDataForLabel('Equipment, Machinery & Tools');
        break;
      case MobileScreen.vendors:
        _refreshDataForLabel('Subcontractors');
        break;
      default:
        break; // Settings, Profile, Reports — no background data to reload
    }
  }

  /// Core reload dispatcher — triggers the right provider reload for each module
  void _refreshDataForLabel(String label) {
    switch (label) {
      case 'Dashboard':
        ref.invalidate(dashboardStatsProvider);
        break;
      case 'Projects':
        ref.read(projectControllerProvider.notifier).loadProjects();
        break;
      case 'Attendance':
        ref.read(attendanceControllerProvider.notifier).loadAttendanceForToday();
        break;
      case 'Employees':
        ref.read(employeeListControllerProvider.notifier).loadEmployees();
        break;
      case 'Subcontractors':
        ref.read(subcontractorControllerProvider.notifier).loadSubcontractors();
        break;
      case 'Expenses':
        ref.read(expenseControllerProvider.notifier).loadExpenses();
        break;
      default:
        break; // Other tabs reload via their own mechanisms
    }
  }

  // --- DESKTOP NAVIGATION & LAYOUT ---
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Row(
        children: [
          // ── Shared Sidebar ──
          WebSidebar(
            activeIndex: _activeWebTab,
            onTabSelected: (index) {
              setState(() {
                _activeWebTab = index;
              });
              _refreshDataForWebTab(index);
            },
          ),
          // ── Main Content Area ──
          Expanded(
            child: _buildWebContent(),
          ),
        ],
      ),
    );
  }

  /// Returns the content widget for the currently active web tab.
  /// Maps visible sidebar items (filtered by permissions) to actual screens.
  Widget _buildWebContent() {
    final permsAsync = ref.watch(userPermissionsProvider);
    final permissions = permsAsync.valueOrNull ?? <String>{};
    final role = ref.watch(currentRoleProvider);

    // Build the same filtered list that WebSidebar uses
    final visibleItems = WebSidebar.allItems.where((item) {
      if (item.requiredPermission == null) return true;
      if (role == 'owner' || role == 'admin' || permissions.isEmpty) return true;
      return permissions.contains(item.requiredPermission);
    }).toList();

    if (_activeWebTab >= visibleItems.length) {
      // Fallback to dashboard
      return _getDashboardForRole(role);
    }

    final selectedItem = visibleItems[_activeWebTab];
    switch (selectedItem.label) {
      case 'Dashboard':
        return _getDashboardForRole(role);
      case 'Projects':
        return const ProjectListScreen();
      case 'Attendance':
        return const AttendanceScreen();
      case 'Employees':
        return const EmployeeListScreen();
      case 'Inventory':
        return const InventoryListScreen();
      case 'Financials':
      case 'Billing':
      case 'Quotations & Estimates':
      case 'Expenses':
        return const FinancialsHubScreen();
      case 'Equipment, Machinery & Tools':
        return const EquipmentListScreen();
      case 'Subcontractors':
        return const VendorListScreen();
      case 'Site Snags & Quality Punch List':
      case 'Snags':
        return const SnagListScreen();
      case 'Reports & Export':
        return const FullReportGeneratorScreen();
      case 'Settings':
        return const SettingsScreen();
      default:
        return _getDashboardForRole(role);
    }
  }

  /// Returns the appropriate dashboard widget based on the user's role.
  Widget _getDashboardForRole(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'supervisor':
        return const SupervisorDashboard();
      default:
        // Owner or unknown — use the existing business dashboard
        return const WebDashboard();
    }
  }
}

/// Internal helper class for mobile bottom nav entries.
class _MobileNavEntry {
  final MobileScreen screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? permission;

  _MobileNavEntry({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.permission,
  });
}
