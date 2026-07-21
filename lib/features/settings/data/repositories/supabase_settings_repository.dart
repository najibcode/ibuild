import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSettingsRepository {
  final SupabaseClient _client;

  SupabaseSettingsRepository(this._client);

  Future<Map<String, dynamic>> fetchSetting(String key) async {
    try {
      final response = await _client
          .from('system_settings')
          .select('setting_value')
          .eq('setting_key', key)
          .maybeSingle();
      if (response != null && response['setting_value'] != null) {
        return Map<String, dynamic>.from(response['setting_value'] as Map);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> saveSetting(String key, Map<String, dynamic> value) async {
    try {
      await _client.from('system_settings').upsert({
        'setting_key': key,
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
