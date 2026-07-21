import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcontractor_model.dart';

class SupabaseSubcontractorRepository {
  final SupabaseClient _client;

  SupabaseSubcontractorRepository(this._client);

  Future<List<Subcontractor>> fetchSubcontractors() async {
    try {
      final response = await _client.from('subcontractors').select().order('name', ascending: true);
      return (response as List).map((json) => Subcontractor.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Subcontractor?> createSubcontractor(Subcontractor sub) async {
    try {
      final response = await _client.from('subcontractors').insert(sub.toJson()).select().single();
      return Subcontractor.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
