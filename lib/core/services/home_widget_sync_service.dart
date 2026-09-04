import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ibuild/core/utils/currency_formatter.dart';
import 'package:ibuild/features/dashboard/data/models/dashboard_stats_model.dart';

/// Service that bridges live Flutter app data to the native Android Home Screen Widget (AppWidget).
class HomeWidgetSyncService {
  static const MethodChannel _channel = MethodChannel('com.example.ibuild/widget');
  static VoidCallback? _onRefreshRequestedCallback;

  /// Push updated executive & site metrics to the Android Home Screen Widget.
  static Future<void> syncDashboardStats(DashboardStats stats, {int streakDays = 14}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final now = DateTime.now();
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
      final minute = now.minute.toString().padLeft(2, '0');
      final timeStr = 'Last sync: $hour:$minute $period';

      final utilization = stats.totalBudget > 0
          ? ((stats.totalSpent / stats.totalBudget) * 100).round()
          : 0;

      final attendanceRate = stats.totalEmployees > 0
          ? ((stats.employeesPresent / stats.totalEmployees) * 100).round()
          : 0;

      final atRiskText = stats.atRiskCount == 0
          ? '0 At-Risk'
          : '${stats.atRiskCount} At-Risk';

      final atRiskSub = stats.atRiskCount == 0
          ? (stats.delayedProjects == 0 ? 'All Sites OK' : '${stats.delayedProjects} Delayed')
          : (stats.delayedProjects > 0 ? '${stats.delayedProjects} Delayed' : 'Attention Needed');

      await _channel.invokeMethod('updateWidgetData', {
        'portfolioValue': CurrencyFormatter.formatCompact(stats.totalBudget),
        'totalSpent': CurrencyFormatter.formatCompact(stats.totalSpent),
        'budgetUtilizationPct': utilization,
        'activeProjects': '${stats.activeProjects} Active',
        'totalProjects': '${stats.totalProjects} Total',
        'todayAttendance': '${stats.employeesPresent} / ${stats.totalEmployees}',
        'attendancePct': '$attendanceRate% On-Site',
        'streakDays': atRiskText,
        'streakSub': atRiskSub,
        'lastUpdated': timeStr,
      });
    } catch (e) {
      debugPrint('[HomeWidgetSyncService] Failed to sync with native widget: $e');
    }
  }

  /// Check if app was launched via home screen widget action.
  static Future<String?> getInitialWidgetRoute() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final route = await _channel.invokeMethod<String>('getInitialRoute');
      return route;
    } catch (e) {
      return null;
    }
  }

  /// Initialize listeners for widget interactions (route navigation & TradingView-style refresh clicks).
  static void initializeWidgetListeners({
    required Function(String route) onRoute,
    VoidCallback? onRefreshRequested,
  }) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _onRefreshRequestedCallback = onRefreshRequested;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onWidgetRoute':
          final route = call.arguments as String?;
          if (route != null && route.isNotEmpty) {
            onRoute(route);
          }
          break;
        case 'onRefreshRequested':
          _onRefreshRequestedCallback?.call();
          break;
      }
    });
  }
}
