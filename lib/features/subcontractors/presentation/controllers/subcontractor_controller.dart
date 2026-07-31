import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/subcontractor_model.dart';
import '../../data/repositories/supabase_subcontractor_repository.dart';

final subcontractorRepositoryProvider = Provider<SupabaseSubcontractorRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSubcontractorRepository(client);
});

class SubcontractorState {
  final List<Subcontractor> items;
  final bool isLoading;
  final String? error;

  SubcontractorState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  factory SubcontractorState.initial() => SubcontractorState(items: [], isLoading: false);

  SubcontractorState copyWith({
    List<Subcontractor>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SubcontractorState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SubcontractorController extends StateNotifier<SubcontractorState> {
  final SupabaseSubcontractorRepository _repo;

  SubcontractorController(this._repo) : super(SubcontractorState.initial()) {
    loadSubcontractors();
  }

  Future<void> loadSubcontractors() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.fetchSubcontractors();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load subcontractors: $e');
    }
  }

  Future<bool> addSubcontractor(Subcontractor sub) async {
    try {
      final created = await _repo.createSubcontractor(sub);
      // Successfully persisted — add to local state
      final list = [...state.items, created];
      state = state.copyWith(items: list, clearError: true);
      // Re-fetch from DB to ensure consistency
      await loadSubcontractors();
      return true;
    } catch (e) {
      // Persistence failed — do NOT add to local state
      state = state.copyWith(error: 'Failed to save subcontractor: $e');
      return false;
    }
  }

  Future<bool> updateSubcontractor(Subcontractor sub) async {
    try {
      await _repo.updateSubcontractor(sub);
      final list = state.items.map((e) => e.id == sub.id ? sub : e).toList();
      state = state.copyWith(items: list, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update subcontractor: $e');
      return false;
    }
  }

  Future<bool> deleteSubcontractor(String id) async {
    try {
      await _repo.deleteSubcontractor(id);
      final list = state.items.where((e) => e.id != id).toList();
      state = state.copyWith(items: list, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete subcontractor: $e');
      return false;
    }
  }
}

final subcontractorControllerProvider =
    StateNotifierProvider<SubcontractorController, SubcontractorState>((ref) {
  final repo = ref.watch(subcontractorRepositoryProvider);
  return SubcontractorController(repo);
});
