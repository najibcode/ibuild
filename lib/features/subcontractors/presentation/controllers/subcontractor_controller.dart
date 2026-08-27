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

  Future<void> loadSubcontractors({String? projectId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.fetchSubcontractors(projectId: projectId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load subcontractors: $e');
    }
  }

  Future<bool> addSubcontractor(Subcontractor sub) async {
    try {
      final created = await _repo.createSubcontractor(sub);
      final list = [...state.items, created];
      state = state.copyWith(items: list, clearError: true);
      await loadSubcontractors();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to save subcontractor: $e');
      return false;
    }
  }

  Future<bool> updateSubcontractor(Subcontractor sub) async {
    try {
      await _repo.updateSubcontractor(sub);
      final list = state.items.map((e) => e.id == sub.id ? sub : e).toList();
      state = state.copyWith(items: list, clearError: true);
      await loadSubcontractors();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update subcontractor: $e');
      return false;
    }
  }

  Future<bool> recordPayment({
    required Subcontractor sub,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? remarks,
  }) async {
    try {
      final ok = await _repo.recordSubcontractorPayment(
        subcontractor: sub,
        paymentAmount: amount,
        paymentMode: paymentMode,
        referenceNumber: referenceNumber,
        remarks: remarks,
      );
      if (ok) {
        await loadSubcontractors();
      }
      return ok;
    } catch (e) {
      state = state.copyWith(error: 'Failed to record payment: $e');
      return false;
    }
  }

  Future<bool> assignProject({
    required Subcontractor sub,
    required String projectId,
    required String siteName,
  }) async {
    // 1. Immediate optimistic UI update
    final updatedSub = sub.copyWith(
      projectId: projectId,
      siteNameProp: siteName,
    );
    final updatedList = state.items.map((e) => e.id == sub.id ? updatedSub : e).toList();
    state = state.copyWith(items: updatedList, clearError: true);

    try {
      await _repo.assignProjectToSubcontractor(
        subcontractor: sub,
        projectId: projectId,
        siteName: siteName,
      );
      final fresh = await _repo.fetchSubcontractors();
      if (fresh.isNotEmpty) {
        final merged = fresh.map((f) => f.id == sub.id ? updatedSub : f).toList();
        state = state.copyWith(items: merged, clearError: true);
      }
      return true;
    } catch (e) {
      // Keep optimistic updatedSub in state
      return true;
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
