import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Automatically ensures an active session exists (demo auto-login fallback)
/// so that accessing any new port, mobile device, or local server loads full project data seamlessly.
Future<void> ensureAutoAuth(SupabaseClient client) async {
  if (client.auth.currentSession == null) {
    try {
      await client.auth.signInWithPassword(
        email: 'admin@ibuild.in',
        password: 'admin@123',
      );
    } catch (_) {}
  }
}
