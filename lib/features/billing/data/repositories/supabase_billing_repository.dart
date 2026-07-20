import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/billing_repository.dart';
import '../models/bill_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseBillingRepository implements BillingRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseBillingRepository(this._client, this._activityRepo);

  @override
  Future<List<Bill>> getBills({
    String? projectId,
    String? statusFilter,
    String? sortBy,
    bool ascending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client.from('bills').select('*, projects(name)');

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
    // Validate
    if (bill.billNumber.trim().isEmpty) {
      throw ArgumentError('Bill number cannot be empty.');
    }
    if (bill.amount <= 0) {
      throw ArgumentError('Bill amount must be greater than zero.');
    }

    await _client.from('bills').insert(bill.toJson());

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'created_bill',
      entityType: 'Bill',
      entityId: bill.id,
      details: {
        'bill_number': bill.billNumber,
        'amount': bill.amount,
        'status': bill.status,
      },
    );
  }

  @override
  Future<void> updateBill(Bill bill) async {
    await _client.from('bills').update(bill.toJson()).eq('id', bill.id);

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'updated_bill',
      entityType: 'Bill',
      entityId: bill.id,
      details: {
        'bill_number': bill.billNumber,
        'amount': bill.amount,
        'status': bill.status,
      },
    );
  }

  @override
  Future<void> deleteBill(String id) async {
    await _client.from('bills').delete().eq('id', id);

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'deleted_bill',
      entityType: 'Bill',
      entityId: id,
    );
  }
}
