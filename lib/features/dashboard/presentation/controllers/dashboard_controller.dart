import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/supabase_dashboard_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/models/dashboard_stats_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseDashboardRepository(client);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return await repo.getDashboardStats();
});
