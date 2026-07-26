import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment_model.dart';

class SupabaseEquipmentRepository {
  final SupabaseClient _client;

  SupabaseEquipmentRepository(this._client);

  Future<List<EquipmentItem>> fetchEquipment() async {
    try {
      final response = await _client
          .from('equipment')
          .select()
          .order('name', ascending: true);
      return (response as List).map((json) => EquipmentItem.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<EquipmentItem?> createEquipment(EquipmentItem item) async {
    try {
      final response = await _client
          .from('equipment')
          .insert(item.toJson())
          .select()
          .single();
      return EquipmentItem.fromJson(response);
    } catch (_) {
      return item;
    }
  }

  Future<void> updateEquipment(EquipmentItem item) async {
    try {
      await _client
          .from('equipment')
          .update(item.toJson())
          .eq('id', item.id);
    } catch (_) {}
  }

  Future<void> deleteEquipment(String id) async {
    try {
      await _client.from('equipment').delete().eq('id', id);
    } catch (_) {}
  }
}
