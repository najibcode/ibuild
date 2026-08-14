import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/router.dart';
import 'core/widgets/responsive_layout.dart';
import 'core/widgets/web_sidebar.dart';
import 'core/widgets/web_header.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/projects/presentation/controllers/project_controller.dart';

import 'mobile_dashboard.dart';
import 'budget_utilization_mobile.dart';
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
import 'features/reports/presentation/screens/full_report_generator_screen.dart';

import 'web_dashboard.dart';
import 'features/dashboard/presentation/screens/admin_dashboard.dart';
import 'features/dashboard/presentation/screens/supervisor_dashboard.dart';
import 'features/rbac/presentation/providers/permission_provider.dart';

// ── Controller imports for auto-reload ──
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
  budget,
  inventory,
  attendance,
  employees,
  financials,
  billing,
  quotations,
  expenses,
  equipment,
  vendors,
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
    setState(() {
      _mobileNavStack.add(screen);
    });
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
            onViewTrack: () => _pushMobile(MobileScreen.budget),
            onViewSupply: () => _pushMobile(MobileScreen.inventory),
          );
        }
        break;
      case MobileScreen.projectsList:
        body = const ProjectListScreen();
        break;
      case MobileScreen.budget:
        body = BudgetUtilizationMobile(onBack: _popMobile);
        break;
      case MobileScreen.inventory:
        body = const InventoryListScreen();
        break;
      case MobileScreen.attendance:
        body = const AttendanceScreen();
        break;
      case MobileScreen.employees:
        body = const EmployeeListScreen();
        break;
      case MobileScreen.financials:
      case MobileScreen.billing:
      case MobileScreen.quotations:
      case MobileScreen.expenses:
        body = const FinancialsHubScreen();
        break;
      case MobileScreen.equipment:
        body = const EquipmentListScreen();
        break;
      case MobileScreen.vendors:
        body = const VendorListScreen();
        break;
      case MobileScreen.reports:
        body = const FullReportGeneratorScreen();
        break;
      case MobileScreen.settings:
        body = const SettingsScreen();
        break;
      case MobileScreen.profile:
        body = const UserProfileScreen();
        break;
    }

    // Build bottom nav items (Dashboard, Attendance, Projects, Inventory, More options)
    final List<_MobileNavEntry> navEntries = [
      _MobileNavEntry(
        screen: MobileScreen.dashboard,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        permission: null,
      ),
      _MobileNavEntry(
        screen: MobileScreen.attendance,
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg,
        label: 'Attendance',
        permission: null,
      ),
      _MobileNavEntry(
        screen: MobileScreen.projectsList,
        icon: Icons.foundation_outlined,
        activeIcon: Icons.foundation,
        label: 'Projects',
        permission: null,
      ),
      _MobileNavEntry(
        screen: MobileScreen.inventory,
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Inventory',
        permission: null,
      ),
      // "More options" tab is always visible
      _MobileNavEntry(
        screen: MobileScreen.settings, // placeholder
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz,
        label: 'More options',
        permission: null,
        isMoreTab: true,
      ),
    ];

    // Find the active bottom bar index
    int bottomBarIndex = 0;
    for (int i = 0; i < navEntries.length; i++) {
      if (navEntries[i].isMoreTab) continue;
      if (_currentMobileScreen == navEntries[i].screen) {
        bottomBarIndex = i;
        break;
      }
      // Check if current screen is a sub-screen of "More"
      if (_currentMobileScreen == MobileScreen.billing ||
          _currentMobileScreen == MobileScreen.expenses ||
          _currentMobileScreen == MobileScreen.settings ||
          _currentMobileScreen == MobileScreen.budget ||
          _currentMobileScreen == MobileScreen.employees ||
          _currentMobileScreen == MobileScreen.financials ||
          _currentMobileScreen == MobileScreen.equipment ||
          _currentMobileScreen == MobileScreen.vendors ||
          _currentMobileScreen == MobileScreen.reports ||
          _currentMobileScreen == MobileScreen.profile) {
        // Find the "More" tab index
        final moreIdx = navEntries.indexWhere((e) => e.isMoreTab);
        if (moreIdx >= 0) bottomBarIndex = moreIdx;
      }
    }

    // Clamp to valid range
    if (bottomBarIndex >= navEntries.length) {
      bottomBarIndex = 0;
    }

    return Scaffold(
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
            final entry = navEntries[index];
            if (entry.isMoreTab) {
              _showMoreMenu(context);
            } else {
              _setMobileTab(entry.screen);
            }
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
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Financials & Money Hub',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.financials);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.people_outline,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Employees & Staff Directory',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.employees);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.construction_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Equipment, Machinery & Tools',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.equipment);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_ind_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Subcontractors',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.vendors);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.assessment_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Reports & Export',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.reports);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.account_circle_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'My Profile',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.profile);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Settings',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.settings);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      case MobileScreen.billing:
        _refreshDataForLabel('Billing');
        break;
      case MobileScreen.quotations:
        _refreshDataForLabel('Quotations & Estimates');
        break;
      case MobileScreen.expenses:
        _refreshDataForLabel('Expenses');
        break;
      case MobileScreen.equipment:
        _refreshDataForLabel('Equipment, Machinery & Tools');
        break;
      case MobileScreen.vendors:
        _refreshDataForLabel('Subcontractors');
        break;
      default:
        break; // Settings, Profile, Reports, Budget — no background data to reload
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
            child: Column(
              children: [
                // ── Shared Header ──
                const WebHeader(),
                // ── Content Body ──
                Expanded(child: _buildWebContent()),
              ],
            ),
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
  final bool isMoreTab;

  _MobileNavEntry({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.permission,
    this.isMoreTab = false,
  });
}
