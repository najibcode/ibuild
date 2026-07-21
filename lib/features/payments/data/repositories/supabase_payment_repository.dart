import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';

class SupabasePaymentRepository {
  final SupabaseClient _client;

  SupabasePaymentRepository(this._client);

  Future<List<ProjectPayment>> fetchPaymentsForProject(String projectId) async {
    try {
      final response = await _client
          .from('project_payments')
          .select()
          .eq('project_id', projectId)
          .order('payment_date', ascending: false);
      return (response as List).map((json) => ProjectPayment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ProjectPayment?> recordPayment(ProjectPayment payment) async {
    try {
      final response = await _client
          .from('project_payments')
          .insert(payment.toJson())
          .select()
          .single();
      return ProjectPayment.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
