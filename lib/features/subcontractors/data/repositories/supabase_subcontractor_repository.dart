import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcontractor_model.dart';

class SupabaseSubcontractorRepository {
  final SupabaseClient _client;

  SupabaseSubcontractorRepository(this._client);

  Future<List<Subcontractor>> fetchSubcontractors() async {
    final response = await _client.from('subcontractors').select().order('name', ascending: true);
    return (response as List).map((json) => Subcontractor.fromJson(json)).toList();
  }

  Future<Subcontractor> createSubcontractor(Subcontractor sub) async {
    final response = await _client.from('subcontractors').insert(sub.toJson()).select().single();
    return Subcontractor.fromJson(response);
  }

  Future<void> updateSubcontractor(Subcontractor sub) async {
    await _client.from('subcontractors').update(sub.toJson()).eq('id', sub.id);
  }

  Future<void> deleteSubcontractor(String id) async {
    await _client.from('subcontractors').delete().eq('id', id);
  }
}
