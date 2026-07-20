import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/supabase_billing_repository.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../data/models/bill_model.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  return SupabaseBillingRepository(client, activityRepo);
});

class BillingListState {
  final List<Bill> bills;
  final bool isLoading;
  final String? errorMessage;
  final String? projectFilter;
  final String? statusFilter;
  final int offset;
  final bool hasMore;

  BillingListState({
    required this.bills,
    required this.isLoading,
    this.errorMessage,
    this.projectFilter,
    this.statusFilter,
    this.offset = 0,
    this.hasMore = true,
  });

  factory BillingListState.initial() =>
      BillingListState(bills: [], isLoading: false);

  BillingListState copyWith({
    List<Bill>? bills,
    bool? isLoading,
    String? errorMessage,
    String? projectFilter,
    bool clearProjectFilter = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    int? offset,
    bool? hasMore,
  }) {
    return BillingListState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      projectFilter: clearProjectFilter
          ? null
          : (projectFilter ?? this.projectFilter),
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class BillingController extends StateNotifier<BillingListState> {
  final BillingRepository _repository;
  static const _pageSize = 20;

  BillingController(this._repository) : super(BillingListState.initial()) {
    loadBills();
  }

  Future<void> loadBills({bool reset = true}) async {
    if (state.isLoading) return;
    final newOffset = reset ? 0 : state.offset;
    state = state.copyWith(isLoading: true, offset: newOffset);
    if (reset) state = state.copyWith(bills: []);

    try {
      final results = await _repository.getBills(
        projectId: state.projectFilter,
        statusFilter: state.statusFilter,
        limit: _pageSize,
        offset: newOffset,
      );
      final combined = reset ? results : [...state.bills, ...results];
      state = state.copyWith(
        bills: combined,
        isLoading: false,
        offset: newOffset + results.length,
        hasMore: results.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void loadMore() => loadBills(reset: false);

  void setProjectFilter(String? p) {
    state = state.copyWith(projectFilter: p, clearProjectFilter: p == null);
    loadBills();
  }

  void setStatusFilter(String? s) {
    state = state.copyWith(statusFilter: s, clearStatusFilter: s == null);
    loadBills();
  }

  Future<bool> addBill(Bill bill) async {
    try {
      await _repository.createBill(bill);
      await loadBills();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> editBill(Bill bill) async {
    try {
      await _repository.updateBill(bill);
      await loadBills();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeBill(String id) async {
    try {
      await _repository.deleteBill(id);
      await loadBills();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final billingControllerProvider =
    StateNotifierProvider<BillingController, BillingListState>((ref) {
      final repo = ref.watch(billingRepositoryProvider);
      return BillingController(repo);
    });
