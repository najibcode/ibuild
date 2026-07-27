import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/models/equipment_model.dart';
import '../../data/repositories/supabase_equipment_repository.dart';

final equipmentRepositoryProvider = Provider<SupabaseEquipmentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseEquipmentRepository(client);
});

class EquipmentState {
  final List<EquipmentItem> items;
  final bool isLoading;
  final String? error;

  EquipmentState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  factory EquipmentState.initial() => EquipmentState(items: [], isLoading: false);

  EquipmentState copyWith({
    List<EquipmentItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return EquipmentState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EquipmentController extends StateNotifier<EquipmentState> {
  final SupabaseEquipmentRepository _repo;

  EquipmentController(this._repo) : super(EquipmentState.initial()) {
    loadEquipment();
  }

  Future<void> loadEquipment() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.fetchEquipment();
      state = state.copyWith(items: items, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addEquipment(EquipmentItem item) async {
    try {
      final created = await _repo.createEquipment(item);
      final list = [created, ...state.items];
      state = state.copyWith(items: list, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateEquipment(EquipmentItem item) async {
    try {
      await _repo.updateEquipment(item);
      final list = state.items.map((e) => e.id == item.id ? item : e).toList();
      state = state.copyWith(items: list, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteEquipment(String id) async {
    try {
      await _repo.deleteEquipment(id);
      final list = state.items.where((e) => e.id != id).toList();
      state = state.copyWith(items: list, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final equipmentControllerProvider =
    StateNotifierProvider<EquipmentController, EquipmentState>((ref) {
  final repo = ref.watch(equipmentRepositoryProvider);
  return EquipmentController(repo);
});
