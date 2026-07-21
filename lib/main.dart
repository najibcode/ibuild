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

import 'mobile_dashboard.dart';
import 'budget_utilization_mobile.dart';
import 'features/attendance/presentation/screens/attendance_screen.dart';
import 'features/employees/presentation/screens/employee_list_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/billing/presentation/screens/billing_list_screen.dart';
import 'features/expenses/presentation/screens/expense_list_screen.dart';
import 'features/projects/presentation/screens/project_list_screen.dart';
import 'features/inventory/presentation/screens/inventory_list_screen.dart';

import 'web_dashboard.dart';
import 'features/dashboard/presentation/screens/admin_dashboard.dart';
import 'features/dashboard/presentation/screens/supervisor_dashboard.dart';
import 'features/rbac/presentation/providers/permission_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'IBUILD Construction Management',
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
  billing,
  expenses,
  settings,
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

  // Set absolute mobile screen (resets stack)
  void _setMobileTab(MobileScreen screen) {
    setState(() {
      _mobileNavStack.clear();
      _mobileNavStack.add(screen);
    });
  }

  // Get current active mobile screen
  MobileScreen get _currentMobileScreen => _mobileNavStack.last;

  /// Check if user has a specific permission
  bool _hasPerm(String perm) {
    return ref.watch(hasPermissionProvider(perm));
  }

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
      case MobileScreen.billing:
        body = const BillingListScreen();
        break;
      case MobileScreen.expenses:
        body = const ExpenseListScreen();
        break;
      case MobileScreen.settings:
        body = const SettingsScreen();
        break;
    }

    // Build bottom nav items based on permissions
    final List<_MobileNavEntry> navEntries = [
      _MobileNavEntry(
        screen: MobileScreen.dashboard,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        permission: 'dashboard.view',
      ),
      if (_hasPerm('project.view'))
        _MobileNavEntry(
          screen: MobileScreen.projectsList,
          icon: Icons.foundation_outlined,
          activeIcon: Icons.foundation,
          label: 'Projects',
          permission: 'project.view',
        ),
      if (_hasPerm('attendance.view'))
        _MobileNavEntry(
          screen: MobileScreen.attendance,
          icon: Icons.pending_actions_outlined,
          activeIcon: Icons.pending_actions,
          label: 'Attendance',
          permission: 'attendance.view',
        ),
      if (_hasPerm('employee.view'))
        _MobileNavEntry(
          screen: MobileScreen.employees,
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'Employees',
          permission: 'employee.view',
        ),
      // "More" tab is always visible
      _MobileNavEntry(
        screen: MobileScreen.settings, // placeholder
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz,
        label: 'More',
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
          _currentMobileScreen == MobileScreen.inventory) {
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
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomBarIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
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
                if (_hasPerm('billing.view'))
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Billing',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.billing);
                    },
                  ),
                if (_hasPerm('expense.view'))
                  ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Expenses',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.expenses);
                    },
                  ),
                if (_hasPerm('billing.view') || _hasPerm('expense.view'))
                  const Divider(),
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
        );
      },
    );
  }

  // --- DESKTOP NAVIGATION & LAYOUT ---
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Shared Sidebar ──
          WebSidebar(
            activeIndex: _activeWebTab,
            onTabSelected: (index) {
              setState(() {
                _activeWebTab = index;
              });
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
      case 'Billing':
        return const BillingListScreen();
      case 'Expenses':
        return const ExpenseListScreen();
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
