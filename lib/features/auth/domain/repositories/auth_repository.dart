import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<AuthResponse> signIn({required String email, required String password});
  Future<AuthResponse> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({required String email});
  Session? getCurrentSession();
  Future<Map<String, dynamic>?> getUserProfile({required String uid});
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String companyName,
    String? avatarUrl,
  });
}

