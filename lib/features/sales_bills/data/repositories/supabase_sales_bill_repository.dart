import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../models/sales_bill_model.dart';

final salesBillRepositoryProvider = Provider<SupabaseSalesBillRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSalesBillRepository(client);
});

final allSalesBillsProvider = FutureProvider<List<SalesBill>>((ref) async {
  return await ref.watch(salesBillRepositoryProvider).fetchAllSalesBills();
});

class SupabaseSalesBillRepository {
  final SupabaseClient _client;

  SupabaseSalesBillRepository(this._client);

  Future<List<SalesBill>> fetchAllSalesBills() async {
    try {
      final response = await _client
          .from('sales_bills')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((json) => SalesBill.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SalesBill>> fetchSalesBillsForProject(String projectId) async {
    try {
      final response = await _client
          .from('sales_bills')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => SalesBill.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<SalesBill?> createSalesBill(SalesBill bill) async {
    try {
      final response = await _client
          .from('sales_bills')
          .insert(bill.toJson())
          .select()
          .single();
      return SalesBill.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateSalesBillStatus(String id, String status) async {
    try {
      await _client
          .from('sales_bills')
          .update({'status': status})
          .eq('id', id);
    } catch (_) {}
  }
}
