import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_model.dart';

class SupabasePropertyRepository {
  final SupabaseClient _client;

  SupabasePropertyRepository(this._client);

  Future<List<Property>> fetchProperties() async {
    try {
      final response = await _client.from('properties').select().order('created_at', ascending: false);
      return (response as List).map((json) => Property.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Property?> addProperty(Property property) async {
    try {
      final response = await _client.from('properties').insert(property.toJson()).select().single();
      return Property.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
