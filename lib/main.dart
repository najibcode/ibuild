import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/router.dart';
import 'core/navigation/mobile_nav_helper.dart';
import 'core/utils/avatar_helper.dart';
import 'core/services/push_notification_service.dart';
import 'core/widgets/app_logo.dart';
import 'core/widgets/responsive_layout.dart';
import 'core/widgets/web_sidebar.dart';
import 'core/widgets/offline_sync_indicator.dart';
import 'core/offline/offline_sync_service.dart';
import 'core/offline/offline_data_cache.dart';
import 'core/services/home_widget_sync_service.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/projects/presentation/controllers/project_controller.dart';

import 'mobile_dashboard.dart';
import 'features/attendance/presentation/screens/attendance_screen.dart';
import 'features/attendance/presentation/controllers/attendance_controller.dart';
import 'features/daily_progress/presentation/screens/daily_progress_screen.dart';
import 'features/projects/data/models/project_model.dart';
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

  // Initialize offline persistent cache (survives page refresh & restarts)
  try {
    await OfflineDataCache().init();
  } catch (e) {
    debugPrint('OfflineDataCache init note: $e');
  }

  try {
    OfflineSyncService.instance.setClient(Supabase.instance.client);
  } catch (e) {
    debugPrint('OfflineSyncService client initialization note: $e');
  }

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
  final String? initialTab;
  const MainRouterScreen({super.key, this.initialTab});

  @override
  ConsumerState<MainRouterScreen> createState() => _MainRouterScreenState();
}

class _MainRouterScreenState extends ConsumerState<MainRouterScreen> with WidgetsBindingObserver {
  // Navigation history stack for mobile view
  final List<MobileScreen> _mobileNavStack = [MobileScreen.dashboard];

  // Active Web Screen selection — now maps to filtered visible items
  int _activeWebTab = 0;

  RealtimeChannel? _realtimeChannel;
  dynamic _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribeToRealtimeSync();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          context.go('/reset-password');
        }
      }
    });

    // Initialize Home Screen Widget route listener and on-demand refresh listener
    HomeWidgetSyncService.initializeWidgetListeners(
      onRoute: (route) {
        if (!mounted) return;
        _handleTargetRoute(route);
      },
      onRefreshRequested: () {
        ref.invalidate(dashboardStatsProvider);
        ref.read(dashboardStatsProvider.future).then((stats) {
          HomeWidgetSyncService.syncDashboardStats(stats);
        }).catchError((_) {});
      },
    );

    // Check if app was launched directly from an Android Home Screen Widget action
    HomeWidgetSyncService.getInitialWidgetRoute().then((route) {
      if (!mounted || route == null) return;
      _handleTargetRoute(route);
    });

    if (widget.initialTab != null && widget.initialTab!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTargetRoute(widget.initialTab!);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pushNotificationServiceProvider).initializeRealtimeListener(context);
        // Initial sync of widget with fresh dashboard metrics
        ref.read(dashboardStatsProvider.future).then((stats) {
          HomeWidgetSyncService.syncDashboardStats(stats);
        }).catchError((_) {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant MainRouterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null &&
        widget.initialTab!.isNotEmpty &&
        widget.initialTab != oldWidget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTargetRoute(widget.initialTab!);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-sync widget metrics whenever user returns to the app
      ref.invalidate(dashboardStatsProvider);
      ref.read(dashboardStatsProvider.future).then((stats) {
        HomeWidgetSyncService.syncDashboardStats(stats);
      }).catchError((_) {});
    }
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
            table: 'daily_progress',
            callback: (payload) => _onTableChanged('daily_progress'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'employees',
            callback: (payload) => _onTableChanged('employees'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'inventory',
            callback: (payload) => _onTableChanged('inventory'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'equipment',
            callback: (payload) => _onTableChanged('equipment'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bills',
            callback: (payload) => _onTableChanged('bills'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'payment_ledger',
            callback: (payload) => _onTableChanged('payment_ledger'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'snags',
            callback: (payload) => _onTableChanged('snags'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            callback: (payload) => _onTableChanged('profiles'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'project_checklists',
            callback: (payload) => _onTableChanged('project_checklists'),
          )
          .subscribe();
    } catch (_) {}
  }

  /// Selective refresh: only reload the providers affected by the changed table.
  void _onTableChanged(String table) {
    if (!mounted) return;
    try {
      // Always refresh dashboard stats
      ref.invalidate(dashboardStatsProvider);

      switch (table) {
        case 'projects':
        case 'daily_progress':
        case 'project_checklists':
          ref.read(projectControllerProvider.notifier).loadProjects();
          break;
        case 'employees':
          ref.read(employeeListControllerProvider.notifier).loadEmployees();
          break;
        case 'attendance':
          final selDate = ref.read(attendanceControllerProvider).selectedDate;
          if (selDate.isNotEmpty) {
            ref.read(attendanceControllerProvider.notifier).loadAttendanceForDate(selDate, showLoading: false);
          }
          break;
        case 'expenses':
          ref.read(expenseControllerProvider.notifier).loadExpenses();
          ref.read(projectControllerProvider.notifier).loadProjects();
          break;
        case 'inventory':
        case 'equipment':
        case 'bills':
        case 'payment_ledger':
        case 'snags':
        case 'profiles':
          // Invalidating dashboardStatsProvider updates portfolio and financial metrics
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeChannel?.unsubscribe();
    _authSubscription?.cancel();
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

  /// Handles deep-linking and widget button clicks seamlessly without route crashes
  void _handleTargetRoute(String route) {
    if (!mounted) return;
    final cleanRoute = route.replaceAll('/', '').trim().toLowerCase();
    if (cleanRoute == 'attendance') {
      _setMobileTab(MobileScreen.attendance);
    } else if (cleanRoute == 'projects') {
      _setMobileTab(MobileScreen.projectsList);
    } else if (cleanRoute == 'dpr' || cleanRoute == 'daily_progress') {
      _openDprFlow();
    }
  }

  /// Opens the DPR workflow: switches to projects and launches project selector or screen
  Future<void> _openDprFlow() async {
    if (!mounted) return;
    _setMobileTab(MobileScreen.projectsList);

    var projects = ref.read(projectControllerProvider).projects;
    if (projects.isEmpty) {
      await ref.read(projectControllerProvider.notifier).loadProjects();
      projects = ref.read(projectControllerProvider).projects;
    }

    if (!mounted) return;

    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No projects found. Create a project first to log Daily Progress (DPR).'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (projects.length == 1) {
      _navigateToDprScreen(projects.first);
      return;
    }

    _showDprProjectSelectorModal(projects);
  }

  void _navigateToDprScreen(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyProgressScreen(
          projectId: project.id,
          projectName: project.name,
        ),
      ),
    );
  }

  void _showDprProjectSelectorModal(List<Project> projects) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBg(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(sheetContext),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_enhance_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Progress Report (DPR)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(sheetContext),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select project to record site work & photos',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(sheetContext),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.mutedText(sheetContext), size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Projects List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: projects.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final project = projects[index];
                    final isCompleted = project.status.toLowerCase() == 'completed';
                    final statusColor = isCompleted
                        ? Colors.grey
                        : (project.status.toLowerCase() == 'delayed'
                            ? Colors.redAccent
                            : AppColors.primary);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _navigateToDprScreen(project);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg(ctx),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border(ctx)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.foundation_rounded,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text(ctx),
                                      ),
                                    ),
                                    if (project.clientName != null && project.clientName!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        project.clientName!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mutedText(ctx),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  project.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.mutedText(ctx),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep Android Home Screen Widget constantly synced whenever stats change
    ref.listen(dashboardStatsProvider, (previous, next) {
      next.whenData((stats) {
        HomeWidgetSyncService.syncDashboardStats(stats);
      });
    });

    final session = Supabase.instance.client.auth.currentSession;
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;

    // 1. Session verification: if unauthenticated, redirect to login
    if (session == null && authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return _buildLoadingScreen(context);
    }

    // 2. Disabled account check: block deactivated users
    if (profile != null && profile['is_disabled'] == true) {
      return _buildDeactivatedAccountScreen(context);
    }

    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(),
      desktopLayout: _buildDesktopLayout(),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(
              size: 52,
              subtitle: 'ERP ENTERPRISE',
            ),
            SizedBox(height: 28),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeactivatedAccountScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(AppSpacing.containerMargin),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_outlined,
                  color: Colors.redAccent,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Account Deactivated',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your enterprise account has been deactivated by a system administrator. Please contact your administrator to restore portal access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.defaultValue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            border: Border(
              top: BorderSide(color: AppColors.border(context), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              backgroundColor: AppColors.cardBg(context),
              elevation: 0,
              currentIndex: bottomBarIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              showUnselectedLabels: true,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
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
            // Drawer Header with Brand Logo & User Profile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                border: Border(bottom: BorderSide(color: AppColors.border(context))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      AppLogo(size: 26, showText: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                            ? NetworkImage(avatarUrl)
                            : null,
                        onBackgroundImageError: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                            ? (exception, stackTrace) {}
                            : null,
                        child: (avatarUrl.isEmpty || !avatarUrl.startsWith('http'))
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                ],
              ),
            ),

            // Menu Items Organized By Categories
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  // CORE MODULES
                  _drawerSectionHeader(context, 'CORE MODULES'),
                  _drawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Executive Dashboard',
                    isSelected: _currentMobileScreen == MobileScreen.dashboard,
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.dashboard);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.foundation_outlined,
                    label: 'Projects Portfolio',
                    isSelected: _currentMobileScreen == MobileScreen.projectsList,
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.projectsList);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.how_to_reg_outlined,
                    label: 'Attendance & Site Roll Call',
                    isSelected: _currentMobileScreen == MobileScreen.attendance,
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.attendance);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Material Inventory',
                    isSelected: _currentMobileScreen == MobileScreen.inventory,
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.inventory);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Financials & Billing Hub',
                    isSelected: _currentMobileScreen == MobileScreen.financials,
                    onTap: () {
                      Navigator.pop(context);
                      _setMobileTab(MobileScreen.financials);
                    },
                  ),

                  // WORKFORCE & PARTNERS
                  _drawerSectionHeader(context, 'WORKFORCE & PARTNERS'),
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

            // Footer: Offline Sync & Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border(context))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: OfflineSyncIndicator(isCompact: false),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
                  ),
                ],
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
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.mutedText(context),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.text(context),
        ),
      ),
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
      if (item.label == 'User Management & Logins') {
        return role == 'admin';
      }
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
          // ── Main Content Area (Isolated for 60/120 FPS performance) ──
          Expanded(
            child: RepaintBoundary(
              child: _buildWebContent(),
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
      if (item.label == 'User Management & Logins') {
        return role == 'admin';
      }
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

  _MobileNavEntry({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
