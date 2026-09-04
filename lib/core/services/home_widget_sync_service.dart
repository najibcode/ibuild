import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ibuild/features/dashboard/data/models/dashboard_stats_model.dart';

/// Service that bridges live Flutter app data to the native Android Home Screen Widget (AppWidget).
class HomeWidgetSyncService {
  static const MethodChannel _channel = MethodChannel('com.example.ibuild/widget');

  /// Push updated site metrics to the Android Home Screen Widget.
  static Future<void> syncDashboardStats(DashboardStats stats, {int streakDays = 14}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final now = DateTime.now();
      final timeStr = 'Updated ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await _channel.invokeMethod('updateWidgetData', {
        'activeProjects': '${stats.activeProjects} Active',
        'todayAttendance': '${stats.employeesPresent} / ${stats.totalEmployees}',
        'streakDays': '$streakDays Days',
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

  /// Listen for widget clicks while app is already running in background.
  static void initializeRouteListener(Function(String route) onRoute) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetRoute') {
        final route = call.arguments as String?;
        if (route != null && route.isNotEmpty) {
          onRoute(route);
        }
      }
    });
  }
}
