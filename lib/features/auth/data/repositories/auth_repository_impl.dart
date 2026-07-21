import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (response == null) {
        final user = _client.auth.currentUser;
        final email = user?.email ?? 'User';
        final name = email.contains('@') ? email.split('@').first : 'User';
        final newProfile = {
          'id': uid,
          'company_name': 'IBUILD Construction',
          'gstin': '27AAAAA0000A1Z5',
          'full_name': name,
        };
        try {
          await _client.from('profiles').upsert(newProfile);
        } catch (_) {}
        return newProfile;
      }
      return response;
    } catch (e) {
      return null;
    }
  }
}
