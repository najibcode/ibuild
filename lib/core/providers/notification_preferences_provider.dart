import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.provider.dart';

class NotificationPreferences {
  final bool masterPushEnabled;
  final bool attendanceAlerts;
  final bool inventoryAlerts;
  final bool paymentAlerts;
  final bool snagQualityAlerts;
  final String notificationScope; // 'all', 'financial', 'site', 'muted'

  const NotificationPreferences({
    this.masterPushEnabled = true,
    this.attendanceAlerts = true,
    this.inventoryAlerts = true,
    this.paymentAlerts = true,
    this.snagQualityAlerts = true,
    this.notificationScope = 'all',
  });

  NotificationPreferences copyWith({
    bool? masterPushEnabled,
    bool? attendanceAlerts,
    bool? inventoryAlerts,
    bool? paymentAlerts,
    bool? snagQualityAlerts,
    String? notificationScope,
  }) {
    return NotificationPreferences(
      masterPushEnabled: masterPushEnabled ?? this.masterPushEnabled,
      attendanceAlerts: attendanceAlerts ?? this.attendanceAlerts,
      inventoryAlerts: inventoryAlerts ?? this.inventoryAlerts,
      paymentAlerts: paymentAlerts ?? this.paymentAlerts,
      snagQualityAlerts: snagQualityAlerts ?? this.snagQualityAlerts,
      notificationScope: notificationScope ?? this.notificationScope,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'master_push_enabled': masterPushEnabled,
      'attendance_alerts': attendanceAlerts,
      'inventory_alerts': inventoryAlerts,
      'payment_alerts': paymentAlerts,
      'snag_quality_alerts': snagQualityAlerts,
      'notification_scope': notificationScope,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPreferences();
    return NotificationPreferences(
      masterPushEnabled: json['master_push_enabled'] as bool? ?? true,
      attendanceAlerts: json['attendance_alerts'] as bool? ?? true,
      inventoryAlerts: json['inventory_alerts'] as bool? ?? true,
      paymentAlerts: json['payment_alerts'] as bool? ?? true,
      snagQualityAlerts: json['snag_quality_alerts'] as bool? ?? true,
      notificationScope: json['notification_scope'] as String? ?? 'all',
    );
  }

  bool isCategoryEnabled(String actionType, String entityType) {
    if (!masterPushEnabled || notificationScope == 'muted') return false;

    if (actionType.contains('attendance') || entityType.contains('attendance')) {
      if (notificationScope == 'financial') return false;
      return attendanceAlerts;
    }

    if (actionType.contains('inventory') || entityType.contains('inventory') || actionType.contains('material')) {
      return inventoryAlerts;
    }

    if (actionType.contains('payment') || actionType.contains('bill') || entityType.contains('payment') || entityType.contains('bill') || entityType.contains('expense')) {
      return paymentAlerts;
    }

    if (actionType.contains('snag') || actionType.contains('checklist') || entityType.contains('snag') || entityType.contains('checklist') || entityType.contains('drawing')) {
      if (notificationScope == 'financial') return false;
      return snagQualityAlerts;
    }

    return true;
  }
}

class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  final SupabaseClient _client;

  NotificationPreferencesNotifier(this._client) : super(const NotificationPreferences()) {
    _loadPreferences();
  }

  void _loadPreferences() {
    try {
      final user = _client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final rawPrefs = user.userMetadata?['notification_preferences'];
        if (rawPrefs is Map<String, dynamic>) {
          state = NotificationPreferences.fromJson(rawPrefs);
        }
      }
    } catch (_) {}
  }

  Future<bool> updatePreferences(NotificationPreferences newPrefs) async {
    state = newPrefs;
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final currentMeta = Map<String, dynamic>.from(user.userMetadata ?? {});
        currentMeta['notification_preferences'] = newPrefs.toJson();
        await _client.auth.updateUser(UserAttributes(data: currentMeta));
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> toggleMasterPush(bool val) async {
    await updatePreferences(state.copyWith(masterPushEnabled: val));
  }

  Future<void> toggleAttendance(bool val) async {
    await updatePreferences(state.copyWith(attendanceAlerts: val));
  }

  Future<void> toggleInventory(bool val) async {
    await updatePreferences(state.copyWith(inventoryAlerts: val));
  }

  Future<void> togglePayment(bool val) async {
    await updatePreferences(state.copyWith(paymentAlerts: val));
  }

  Future<void> toggleSnagQuality(bool val) async {
    await updatePreferences(state.copyWith(snagQualityAlerts: val));
  }

  Future<void> setScope(String scope) async {
    await updatePreferences(state.copyWith(notificationScope: scope));
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationPreferencesNotifier(client);
});
