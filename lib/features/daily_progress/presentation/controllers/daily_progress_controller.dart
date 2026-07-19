import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/supabase_daily_progress_repository.dart';
import '../../domain/repositories/daily_progress_repository.dart';
import '../../data/models/daily_progress_model.dart';

final dailyProgressRepositoryProvider = Provider<DailyProgressRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseDailyProgressRepository(client);
});

final dailyProgressListProvider = FutureProvider.family<List<DailyProgress>, String>((ref, projectId) async {
  final repo = ref.watch(dailyProgressRepositoryProvider);
  return await repo.getProgressForProject(projectId);
});
