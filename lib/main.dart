import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
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

    return MaterialApp.router(
      title: 'IBUILD Construction Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
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

class MainRouterScreen extends StatefulWidget {
  const MainRouterScreen({super.key});

  @override
  State<MainRouterScreen> createState() => _MainRouterScreenState();
}

class _MainRouterScreenState extends State<MainRouterScreen> {
  // Navigation history stack for mobile view
  final List<MobileScreen> _mobileNavStack = [MobileScreen.dashboard];

  // Active Web Screen selection — indexes match WebSidebar.items:
  // 0: Dashboard, 1: Projects, 2: Attendance, 3: Employees,
  // 4: Inventory, 5: Billing, 6: Expenses, 7: Settings
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(),
      desktopLayout: _buildDesktopLayout(),
    );
  }

  // --- MOBILE NAVIGATION & LAYOUT ---
  Widget _buildMobileLayout() {
    Widget body;
    switch (_currentMobileScreen) {
      case MobileScreen.dashboard:
        body = MobileDashboard(
          onViewProjects: () => _pushMobile(MobileScreen.projectsList),
          onViewTrack: () => _pushMobile(MobileScreen.budget),
          onViewSupply: () => _pushMobile(MobileScreen.inventory),
        );
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

    // Map current screen to bottom bar index
    int bottomBarIndex = 0;
    if (_currentMobileScreen == MobileScreen.dashboard) {
      bottomBarIndex = 0;
    } else if (_currentMobileScreen == MobileScreen.projectsList ||
        _currentMobileScreen == MobileScreen.budget ||
        _currentMobileScreen == MobileScreen.inventory) {
      bottomBarIndex = 1;
    } else if (_currentMobileScreen == MobileScreen.attendance) {
      bottomBarIndex = 2;
    } else if (_currentMobileScreen == MobileScreen.employees) {
      bottomBarIndex = 3;
    } else if (_currentMobileScreen == MobileScreen.billing ||
        _currentMobileScreen == MobileScreen.expenses ||
        _currentMobileScreen == MobileScreen.settings) {
      bottomBarIndex = 4;
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
          if (index == 0) {
            _setMobileTab(MobileScreen.dashboard);
          } else if (index == 1) {
            _setMobileTab(MobileScreen.projectsList);
          } else if (index == 2) {
            _setMobileTab(MobileScreen.attendance);
          } else if (index == 3) {
            _setMobileTab(MobileScreen.employees);
          } else if (index == 4) {
            _showMoreMenu(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.foundation_outlined),
            activeIcon: Icon(Icons.foundation),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_outlined),
            activeIcon: Icon(Icons.pending_actions),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
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
  Widget _buildWebContent() {
    switch (_activeWebTab) {
      case 0:
        return const WebDashboard();
      case 1:
        return const ProjectListScreen();
      case 2:
        return const AttendanceScreen();
      case 3:
        return const EmployeeListScreen();
      case 4:
        return const InventoryListScreen();
      case 5:
        return const BillingListScreen();
      case 6:
        return const ExpenseListScreen();
      case 7:
        return const SettingsScreen();
      default:
        return const WebDashboard();
    }
  }
}
