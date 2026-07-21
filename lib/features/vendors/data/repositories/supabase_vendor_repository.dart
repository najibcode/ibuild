import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor_model.dart';

class SupabaseVendorRepository {
  final SupabaseClient _client;

  SupabaseVendorRepository(this._client);

  Future<List<Vendor>> fetchVendors() async {
    try {
      final response = await _client.from('vendors').select().order('name', ascending: true);
      return (response as List).map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Vendor?> createVendor(Vendor vendor) async {
    try {
      final response = await _client.from('vendors').insert(vendor.toJson()).select().single();
      return Vendor.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
