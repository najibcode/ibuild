import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/billing_repository.dart';
import '../models/bill_model.dart';

class SupabaseBillingRepository implements BillingRepository {
  final SupabaseClient _client;

  SupabaseBillingRepository(this._client);

  @override
  Future<List<Bill>> getBills({
    String? projectId,
    String? statusFilter,
    String? sortBy,
    bool ascending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client.from('bills').select('*, projects(name)');

    if (projectId != null && projectId.isNotEmpty) {
      query = query.eq('project_id', projectId);
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }

    final orderCol = sortBy ?? 'created_at';
    query = query.order(orderCol, ascending: ascending);
    query = query.range(offset, offset + limit - 1);

    final response = await query;
    return (response as List).map((j) => Bill.fromJson(j)).toList();
  }

  @override
  Future<Bill?> getBillById(String id) async {
    final response = await _client
        .from('bills')
        .select('*, projects(name)')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Bill.fromJson(response);
  }

  @override
  Future<void> createBill(Bill bill) async {
    await _client.from('bills').insert(bill.toJson());
  }

  @override
  Future<void> updateBill(Bill bill) async {
    await _client.from('bills').update(bill.toJson()).eq('id', bill.id);
  }

  @override
  Future<void> deleteBill(String id) async {
    await _client.from('bills').delete().eq('id', id);
  }
}
