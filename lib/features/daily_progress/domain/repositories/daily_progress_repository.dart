import '../../data/models/daily_progress_model.dart';

abstract class DailyProgressRepository {
  Future<List<DailyProgress>> getProgressForProject(String projectId, {int limit = 30, int offset = 0});
  Future<DailyProgress?> getProgressForDate(String projectId, String date);
  Future<void> upsertProgress(DailyProgress progress);
}
