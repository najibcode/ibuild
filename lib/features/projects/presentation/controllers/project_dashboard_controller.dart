import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/project_dashboard_model.dart';
import '../../data/repositories/project_dashboard_repository.dart';

final projectDashboardRepositoryProvider =
    Provider<ProjectDashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProjectDashboardRepository(client);
});

/// Fetches per-project dashboard stats keyed by [projectId].
final projectDashboardProvider =
    FutureProvider.family<ProjectDashboardStats, String>((ref, projectId) async {
  final repo = ref.watch(projectDashboardRepositoryProvider);
  return await repo.fetchDashboard(projectId);
});
