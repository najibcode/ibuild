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
    final payload = item.toJson();
    try {
      final response = await _client
          .from('equipment')
          .insert(payload)
          .select()
          .single();
      return EquipmentItem.fromJson(response);
    } catch (e) {
      if (e.toString().contains("'notes'") || e.toString().contains("PGRST204")) {
        payload.remove('notes');
        final response = await _client
            .from('equipment')
            .insert(payload)
            .select()
            .single();
        return EquipmentItem.fromJson(response);
      }
      rethrow;
    }
  }

  Future<void> updateEquipment(EquipmentItem item) async {
    final payload = item.toJson();
    try {
      await _client
          .from('equipment')
          .update(payload)
          .eq('id', item.id);
    } catch (e) {
      if (e.toString().contains("'notes'") || e.toString().contains("PGRST204")) {
        payload.remove('notes');
        await _client
            .from('equipment')
            .update(payload)
            .eq('id', item.id);
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteEquipment(String id) async {
    await _client.from('equipment').delete().eq('id', id);
  }
}
