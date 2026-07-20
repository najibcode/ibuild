import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/daily_progress_repository.dart';
import '../models/daily_progress_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseDailyProgressRepository implements DailyProgressRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseDailyProgressRepository(this._client, this._activityRepo);

  @override
  Future<List<DailyProgress>> getProgressForProject(String projectId, {int limit = 30, int offset = 0}) async {
    final response = await _client
        .from('daily_progress')
        .select()
        .eq('project_id', projectId)
        .order('date', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((j) => DailyProgress.fromJson(j)).toList();
  }

  @override
  Future<DailyProgress?> getProgressForDate(String projectId, String date) async {
    final response = await _client
        .from('daily_progress')
        .select()
        .eq('project_id', projectId)
        .eq('date', date)
        .maybeSingle();
    if (response == null) return null;
    return DailyProgress.fromJson(response);
  }

  @override
  Future<void> upsertProgress(DailyProgress progress) async {
    await _client.from('daily_progress').upsert(progress.toJson());

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'updated_progress',
      entityType: 'Site Progress',
      entityId: progress.projectId,
      details: {
        'date': progress.date,
        'progress_percentage': progress.progressPercentage,
        'has_morning_image': progress.morningImageUrl != null,
        'has_evening_image': progress.eveningImageUrl != null,
      },
    );
  }
}
