import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';

final activityRepositoryProvider = Provider<SupabaseActivityRepository>((ref) {
  return SupabaseActivityRepository(ref.watch(supabaseClientProvider));
});

class SupabaseActivityRepository {
  final SupabaseClient _client;

  SupabaseActivityRepository(this._client);

  Future<void> logActivity({
    required String actionType,
    required String entityType,
    required String entityId,
    Map<String, dynamic> details = const {},
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return; // Cannot log without auth

      await _client.from('activities').insert({
        'user_id': user.id,
        'action_type': actionType,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details,
      });
    } catch (e) {
      // Fail silently for activity logging so it doesn't break main workflows
      print('Failed to log activity: $e');
    }
  }

  Future<List<Activity>> getRecentActivities({int limit = 20}) async {
    final response = await _client
        .from('activities')
        .select('*, profiles(company_name)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      // Depending on if profiles uses company_name or we add name.
      // Let's fallback to 'A User' if not found.
      final userName = profile != null ? profile['company_name'] : 'Unknown User';
      return Activity.fromJson(json, userName: userName as String?);
    }).toList();
  }

  Future<List<Activity>> getNotificationsForUser({int limit = 10}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('activities')
        .select('*, profiles(company_name)')
        .neq('user_id', user.id) // Only activities from OTHER users
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      final userName = profile != null ? profile['company_name'] : 'Unknown User';
      return Activity.fromJson(json, userName: userName as String?);
    }).toList();
  }
}
