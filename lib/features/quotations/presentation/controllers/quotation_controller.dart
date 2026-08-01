import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../data/repositories/supabase_quotation_repository.dart';
import '../../domain/repositories/quotation_repository.dart';
import '../../data/models/quotation_model.dart';

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  return SupabaseQuotationRepository(client, activityRepo);
});

class QuotationListState {
  final List<Quotation> quotations;
  final bool isLoading;
  final String? errorMessage;
  final String? statusFilter;
  final String? projectFilter;
  final int offset;
  final bool hasMore;

  QuotationListState({
    required this.quotations,
    required this.isLoading,
    this.errorMessage,
    this.statusFilter,
    this.projectFilter,
    this.offset = 0,
    this.hasMore = true,
  });

  factory QuotationListState.initial() => QuotationListState(
        quotations: [],
        isLoading: false,
      );

  QuotationListState copyWith({
    List<Quotation>? quotations,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? projectFilter,
    bool clearProjectFilter = false,
    int? offset,
    bool? hasMore,
  }) {
    return QuotationListState(
      quotations: quotations ?? this.quotations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      projectFilter: clearProjectFilter ? null : (projectFilter ?? this.projectFilter),
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class QuotationController extends StateNotifier<QuotationListState> {
  final QuotationRepository _repository;
  static const _pageSize = 20;

  QuotationController(this._repository) : super(QuotationListState.initial()) {
    loadQuotations();
  }

  Future<void> loadQuotations({bool reset = true}) async {
    if (state.isLoading) return;
    final newOffset = reset ? 0 : state.offset;
    state = state.copyWith(isLoading: true, offset: newOffset, clearErrorMessage: true);
    if (reset) state = state.copyWith(quotations: []);

    try {
      final results = await _repository.getQuotations(
        statusFilter: state.statusFilter,
        projectId: state.projectFilter,
        limit: _pageSize,
        offset: newOffset,
      );
      final combined = reset ? results : [...state.quotations, ...results];
      state = state.copyWith(
        quotations: combined,
        isLoading: false,
        offset: newOffset + results.length,
        hasMore: results.length >= _pageSize,
        clearErrorMessage: true,
      );
    } catch (e) {
      debugPrint('[QuotationCtrl] loadQuotations error: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void loadMore() => loadQuotations(reset: false);

  void setStatusFilter(String? s) {
    state = state.copyWith(statusFilter: s, clearStatusFilter: s == null || s == 'All');
    loadQuotations();
  }

  void setProjectFilter(String? p) {
    state = state.copyWith(projectFilter: p, clearProjectFilter: p == null);
    loadQuotations();
  }

  Future<bool> addQuotation(Quotation quotation) async {
    try {
      await _repository.createQuotation(quotation);
      await loadQuotations();
      return true;
    } catch (e) {
      debugPrint('[QuotationCtrl] addQuotation ERROR: $e');
      state = state.copyWith(errorMessage: 'Failed to create quotation: $e');
      return false;
    }
  }

  Future<bool> editQuotation(Quotation quotation) async {
    try {
      await _repository.updateQuotation(quotation);
      await loadQuotations();
      return true;
    } catch (e) {
      debugPrint('[QuotationCtrl] editQuotation ERROR: $e');
      state = state.copyWith(errorMessage: 'Failed to update quotation: $e');
      return false;
    }
  }

  Future<bool> removeQuotation(String id) async {
    try {
      await _repository.deleteQuotation(id);
      await loadQuotations();
      return true;
    } catch (e) {
      debugPrint('[QuotationCtrl] removeQuotation ERROR: $e');
      return false;
    }
  }
}

final quotationControllerProvider =
    StateNotifierProvider<QuotationController, QuotationListState>((ref) {
  final repo = ref.watch(quotationRepositoryProvider);
  return QuotationController(repo);
});
