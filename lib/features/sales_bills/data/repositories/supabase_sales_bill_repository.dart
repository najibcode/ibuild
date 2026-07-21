import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sales_bill_model.dart';

class SupabaseSalesBillRepository {
  final SupabaseClient _client;

  SupabaseSalesBillRepository(this._client);

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
}
