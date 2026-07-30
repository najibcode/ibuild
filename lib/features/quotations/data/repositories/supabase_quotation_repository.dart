import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/quotation_repository.dart';
import '../models/quotation_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseQuotationRepository implements QuotationRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseQuotationRepository(this._client, this._activityRepo);

  @override
  Future<List<Quotation>> getQuotations({
    String? statusFilter,
    String? projectId,
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic query = _client.from('quotations').select('*, projects(name)');

    if (projectId != null && projectId.isNotEmpty) {
      query = query.eq('project_id', projectId);
    }
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter.toLowerCase() != 'all') {
      query = query.eq('status', statusFilter.toLowerCase());
    }

    query = query.order('created_at', ascending: false);
    query = query.range(offset, offset + limit - 1);

    final response = await query;
    return (response as List).map((j) => Quotation.fromJson(j)).toList();
  }

  @override
  Future<Quotation> getQuotationById(String id) async {
    final response = await _client
        .from('quotations')
        .select('*, projects(name)')
        .eq('id', id)
        .single();
    return Quotation.fromJson(response);
  }

  @override
  Future<Quotation> createQuotation(Quotation quotation) async {
    if (quotation.clientName.trim().isEmpty) {
      throw ArgumentError('Client name is required');
    }
    if (quotation.subject.trim().isEmpty) {
      throw ArgumentError('Quotation subject is required');
    }

    final data = quotation.toJson();
    final response = await _client.from('quotations').insert(data).select('*, projects(name)').single();
    
    // Log activity
    try {
      await _activityRepo.logActivity(
        title: 'New Quotation Created',
        subtitle: '${quotation.clientName} - ₹${quotation.totalAmount.toStringAsFixed(2)} (${quotation.subject})',
        type: 'quotation',
      );
    } catch (_) {}

    return Quotation.fromJson(response);
  }

  @override
  Future<Quotation> updateQuotation(Quotation quotation) async {
    if (quotation.id.isEmpty) {
      throw ArgumentError('Quotation ID is required for update');
    }

    final data = quotation.toJson();
    final response = await _client
        .from('quotations')
        .update(data)
        .eq('id', quotation.id)
        .select('*, projects(name)')
        .single();

    // Log activity
    try {
      await _activityRepo.logActivity(
        title: 'Quotation Updated',
        subtitle: '${quotation.clientName} - ${quotation.status.toUpperCase()} (₹${quotation.totalAmount.toStringAsFixed(2)})',
        type: 'quotation',
      );
    } catch (_) {}

    return Quotation.fromJson(response);
  }

  @override
  Future<void> deleteQuotation(String id) async {
    await _client.from('quotations').delete().eq('id', id);

    // Log activity
    try {
      await _activityRepo.logActivity(
        title: 'Quotation Deleted',
        subtitle: 'Quotation Record #$id removed',
        type: 'quotation',
      );
    } catch (_) {}
  }
}
