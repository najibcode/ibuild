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
      final list = (response as List).map((json) => EquipmentItem.fromJson(json)).toList();
      if (list.isNotEmpty) return list;
      return _defaultItems();
    } catch (_) {
      return _defaultItems();
    }
  }

  List<EquipmentItem> _defaultItems() {
    return [
      EquipmentItem(
        id: 'eq-001',
        name: 'Bosch Heavy Duty Drill Machine',
        category: 'Power Tools & Machines',
        tagNumber: 'TL-DRL-101',
        siteName: 'Lorry / Tool Kit Box',
        status: 'Operational',
        rentalCostPerDay: 250,
        fuelConsumptionLitersPerDay: 0,
        notes: 'Carried in lorry tool box for lorry maintenance & site drilling',
        createdAt: DateTime.now(),
      ),
      EquipmentItem(
        id: 'eq-002',
        name: '12ft Aluminum Extension Ladder',
        category: 'Ladders & Climbing',
        tagNumber: 'LD-12F-04',
        siteName: 'Skyline Towers Phase 1',
        status: 'In Use',
        rentalCostPerDay: 150,
        fuelConsumptionLitersPerDay: 0,
        notes: 'Heavy duty anti-slip steps',
        createdAt: DateTime.now(),
      ),
      EquipmentItem(
        id: 'eq-003',
        name: '3-Step Reinforced Steel Stool',
        category: 'Ladders & Climbing',
        tagNumber: 'ST-03S-09',
        siteName: 'Main Site Warehouse',
        status: 'Operational',
        rentalCostPerDay: 80,
        fuelConsumptionLitersPerDay: 0,
        notes: 'Foldable large step stool',
        createdAt: DateTime.now(),
      ),
      EquipmentItem(
        id: 'eq-004',
        name: 'JCB 3DX Backhoe Excavator',
        category: 'Heavy Machinery',
        tagNumber: 'EQ-JCB-909',
        siteName: 'Sunrise Towers Site',
        status: 'In Use',
        rentalCostPerDay: 4500,
        fuelConsumptionLitersPerDay: 45,
        notes: 'Includes heavy bucket attachment',
        createdAt: DateTime.now(),
      ),
      EquipmentItem(
        id: 'eq-005',
        name: 'Kirloskar 15kVA Power Generator',
        category: 'Generators & Power Units',
        tagNumber: 'GN-KIR-201',
        siteName: 'Main Site',
        status: 'Operational',
        rentalCostPerDay: 1200,
        fuelConsumptionLitersPerDay: 15,
        notes: 'Backup power generator',
        createdAt: DateTime.now(),
      ),
    ];
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
