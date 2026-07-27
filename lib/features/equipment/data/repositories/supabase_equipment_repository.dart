import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment_model.dart';

class SupabaseEquipmentRepository {
  final SupabaseClient _client;

  SupabaseEquipmentRepository(this._client);

  Future<List<EquipmentItem>> fetchEquipment() async {
    final response = await _client
        .from('equipment')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => EquipmentItem.fromJson(json)).toList();
  }

  Future<EquipmentItem> createEquipment(EquipmentItem item) async {
    final response = await _client
        .from('equipment')
        .insert(item.toJson())
        .select()
        .single();
    return EquipmentItem.fromJson(response);
  }

  Future<void> updateEquipment(EquipmentItem item) async {
    await _client
        .from('equipment')
        .update(item.toJson())
        .eq('id', item.id);
  }

  Future<void> deleteEquipment(String id) async {
    await _client.from('equipment').delete().eq('id', id);
  }
}
