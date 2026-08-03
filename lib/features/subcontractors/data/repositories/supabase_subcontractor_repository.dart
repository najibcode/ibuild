import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subcontractor_model.dart';

class SupabaseSubcontractorRepository {
  final SupabaseClient _client;

  SupabaseSubcontractorRepository(this._client);

  Future<List<Subcontractor>> fetchSubcontractors() async {
    final response = await _client.from('subcontractors').select().order('name', ascending: true);
    return (response as List).map((json) => Subcontractor.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<Subcontractor> createSubcontractor(Subcontractor sub) async {
    final response = await _client.from('subcontractors').insert(sub.toDbJson()).select().single();
    final created = Subcontractor.fromJson(Map<String, dynamic>.from(response));
    return created.copyWith(
      companyNameProp: sub.companyNameProp,
      contactPersonProp: sub.contactPersonProp,
      siteNameProp: sub.siteNameProp,
    );
  }

  Future<void> updateSubcontractor(Subcontractor sub) async {
    await _client.from('subcontractors').update(sub.toDbJson()).eq('id', sub.id);
  }

  Future<void> deleteSubcontractor(String id) async {
    await _client.from('subcontractors').delete().eq('id', id);
  }
}
