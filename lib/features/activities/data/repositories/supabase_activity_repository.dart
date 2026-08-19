import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';
import '../../../../core/supabase/supabase_client.provider.dart';

final activityRepositoryProvider = Provider<SupabaseActivityRepository>((ref) {
  return SupabaseActivityRepository(ref.watch(supabaseClientProvider));
});

final recentActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  return await repo.getRecentActivities();
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  final notifications = await repo.getNotificationsForUser();
  return notifications.length;
});

class SupabaseActivityRepository {
  final SupabaseClient _client;

  SupabaseActivityRepository(this._client);

  Future<void> logSiteActivityAndNotify({
    required String actionType,
    required String entityType,
    required String entityId,
    required String title,
    String? projectId,
    Map<String, dynamic> details = const {},
  }) async {
    try {
      final user = _client.auth.currentUser;

      final mergedDetails = Map<String, dynamic>.from(details);
      mergedDetails['title'] = title;
      if (projectId != null) mergedDetails['project_id'] = projectId;
      mergedDetails['target_roles'] = ['owner', 'admin', 'supervisor'];

      try {
        await _client.from('activities').insert({
          'user_id': user?.id ?? 'system',
          'action_type': actionType,
          'entity_type': entityType,
          'entity_id': entityId,
          'details': mergedDetails,
        });
        return;
      } catch (_) {}

      // Fallback to audit_logs table
      try {
        await _client.from('audit_logs').insert({
          'actor_id': user?.id,
          'actor_name': user?.email?.split('@').first ?? 'System',
          'action': actionType,
          'target_type': entityType,
          'target_id': entityId,
          'details': mergedDetails,
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('Failed to log site activity: $e');
    }
  }

  Future<void> logActivity({
    required String actionType,
    required String entityType,
    required String entityId,
    Map<String, dynamic> details = const {},
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      try {
        await _client.from('activities').insert({
          'user_id': user.id,
          'action_type': actionType,
          'entity_type': entityType,
          'entity_id': entityId,
          'details': details,
        });
        return;
      } catch (_) {}

      // Fallback to audit_logs table
      try {
        await _client.from('audit_logs').insert({
          'actor_id': user.id,
          'actor_name': user.email?.split('@').first ?? 'User',
          'action': actionType,
          'target_type': entityType,
          'target_id': entityId,
          'details': details,
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('Failed to log activity: $e');
    }
  }

  Future<List<Activity>> getRecentActivities({int limit = 20}) async {
    // 1. Try querying activities table
    try {
      final response = await _client
          .from('activities')
          .select('*, profiles(company_name)')
          .order('created_at', ascending: false)
          .limit(limit);

      if (response.isNotEmpty) {
        return (response as List).map((json) {
          final profile = json['profiles'] as Map<String, dynamic>?;
          final userName = profile != null ? profile['company_name'] : 'System User';
          return Activity.fromJson(json, userName: userName as String?);
        }).toList();
      }
    } catch (_) {}

    // 2. Try querying audit_logs table
    try {
      final response = await _client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      if (response.isNotEmpty) {
        return (response as List).map((json) {
          return Activity.fromJson(json, userName: json['actor_name'] as String?);
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  Future<List<Activity>> getNotificationsForUser({int limit = 10}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('activities')
          .select('*, profiles(company_name)')
          .order('created_at', ascending: false)
          .limit(limit);

      if (response.isNotEmpty) {
        return (response as List).map((json) {
          final profile = json['profiles'] as Map<String, dynamic>?;
          final userName = profile != null ? profile['company_name'] : 'System User';
          return Activity.fromJson(json, userName: userName as String?);
        }).toList();
      }
    } catch (_) {}

    try {
      final response = await _client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      if (response.isNotEmpty) {
        return (response as List).map((json) {
          return Activity.fromJson(json, userName: json['actor_name'] as String?);
        }).toList();
      }
    } catch (_) {}

    return [];
  }
}
