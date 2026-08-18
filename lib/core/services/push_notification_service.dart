import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/notification_preferences_provider.dart';
import '../supabase/supabase_client.provider.dart';
import 'web_notification_helper.dart';
import '../../features/activities/data/repositories/supabase_activity_repository.dart';

class PushNotificationService {
  final Ref _ref;
  final SupabaseClient _client;
  RealtimeChannel? _subscription;
  bool _isListening = false;

  PushNotificationService(this._ref, this._client);

  Future<String> getDevicePermissionStatus() async {
    if (kIsWeb) {
      return await WebNotificationHelper.getPermissionStatus();
    }
    return 'granted';
  }

  Future<bool> requestDevicePermission() async {
    if (kIsWeb) {
      return await WebNotificationHelper.requestPermission();
    }
    return true;
  }

  void initializeRealtimeListener(BuildContext? context) {
    if (_isListening) return;
    _isListening = true;

    try {
      _subscription = _client
          .channel('public:activities:realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'activities',
            callback: (payload) {
              _handleIncomingActivity(payload.newRecord, context);
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void _handleIncomingActivity(Map<String, dynamic> record, BuildContext? context) {
    final title = record['title'] as String? ?? 'Site Activity Update';
    final actionType = record['action_type'] as String? ?? 'update';
    final entityType = record['entity_type'] as String? ?? 'general';

    final prefs = _ref.read(notificationPreferencesProvider);

    // Check if user has enabled alerts for this category
    if (!prefs.isCategoryEnabled(actionType, entityType)) {
      return;
    }

    // 1. Invalidate notification providers so badges and dropdown update
    _ref.invalidate(recentActivitiesProvider);
    _ref.invalidate(unreadNotificationsCountProvider);

    // 2. Trigger native OS/Browser Push Notification
    WebNotificationHelper.showNotification(
      title: 'iBuild Alert: $title',
      body: 'Action: $actionType on $entityType',
    );

    // 3. Show In-App Banner/Toast if UI context is mounted
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Type: $actionType • $entityType',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
    }
  }

  Future<void> sendTestNotification({
    required BuildContext context,
    String testTitle = 'Test Cross-Device Alert',
    String testMessage = 'iBuild push notification system is active on this device ✓',
  }) async {
    // 1. Trigger native push
    WebNotificationHelper.showNotification(
      title: testTitle,
      body: testMessage,
    );

    // 2. Trigger in-app feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      testMessage,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }

    // 3. Log a test activity in Supabase
    try {
      await _ref.read(activityRepositoryProvider).logSiteActivityAndNotify(
            actionType: 'test_notification',
            entityType: 'device_test',
            entityId: 'test-${DateTime.now().millisecondsSinceEpoch}',
            title: testTitle,
          );
      _ref.invalidate(recentActivitiesProvider);
      _ref.invalidate(unreadNotificationsCountProvider);
    } catch (_) {}
  }

  void dispose() {
    _subscription?.unsubscribe();
    _isListening = false;
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final service = PushNotificationService(ref, client);
  ref.onDispose(() => service.dispose());
  return service;
});
