import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/core/utils/avatar_helper.dart';
import 'package:ibuild/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient? _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('No Supabase backend connection available.');
    }
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('No Supabase backend connection available.');
    }
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    final client = _client;
    if (client != null) {
      await client.auth.resetPasswordForEmail(email);
    }
  }

  @override
  Session? getCurrentSession() {
    return _client?.auth.currentSession;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    final cached = OfflineDataCache().get<Map<String, dynamic>>('user_profile_$uid') ??
        OfflineDataCache().getCachedCompanyBranding();

    final client = _client;
    if (client == null) {
      return cached ?? {
        'id': uid,
        'company_name': 'IBUILD Construction Corp',
        'tagline': 'Premier Construction & Civil Engineering',
        'gstin': '27AAAAA0000A1Z5',
        'address': 'Bengaluru, Karnataka, India',
        'upi_id': 'ibuild@icici',
        'full_name': 'User',
      };
    }

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      final currentUser = client.auth.currentUser;
      final authMeta = currentUser?.userMetadata ?? {};

      final merged = <String, dynamic>{
        'id': uid,
        'company_name': 'IBUILD Construction Corp',
        'tagline': 'Premier Construction & Civil Engineering',
        'gstin': '27AAAAA0000A1Z5',
        'address': 'Bengaluru, Karnataka, India',
        'upi_id': 'ibuild@icici',
        'full_name': currentUser?.email?.split('@').first ?? 'User',
        'phone': '',
        'avatar_url': RoleAvatarHelper.getAvatarUrl(email: currentUser?.email ?? 'user'),
      };

      if (authMeta.isNotEmpty) merged.addAll(authMeta);
      if (response != null) merged.addAll(response);
      if (cached != null) merged.addAll(cached);

      OfflineDataCache().set('user_profile_$uid', merged);
      OfflineDataCache().cacheCompanyBranding(merged);
      return merged;
    } catch (e) {
      if (cached != null) return cached;
      return {
        'id': uid,
        'company_name': 'IBUILD Construction Corp',
        'tagline': 'Premier Construction & Civil Engineering',
        'gstin': '27AAAAA0000A1Z5',
        'address': 'Bengaluru, Karnataka, India',
        'upi_id': 'ibuild@icici',
        'full_name': 'User',
      };
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String companyName,
    String? avatarUrl,
    String? tagline,
    String? gstin,
    String? address,
    String? upiId,
    String? logoUrl,
  }) async {
    // Validate avatarUrl: must be https only, max 2048 chars, reject data/blob/base64
    String? sanitizedAvatarUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      final cleanUrl = avatarUrl.trim();
      if (cleanUrl.startsWith('https://') &&
          !cleanUrl.startsWith('data:') &&
          !cleanUrl.startsWith('blob:') &&
          cleanUrl.length <= 2048) {
        sanitizedAvatarUrl = cleanUrl;
      }
    }

    final payload = <String, dynamic>{
      'id': uid,
      'full_name': fullName,
      'phone': phone,
      'company_name': companyName,
      'tagline': tagline ?? 'Premier Construction & Civil Engineering',
      'gstin': gstin ?? '27AAAAA0000A1Z5',
      'address': address ?? 'Bengaluru, Karnataka, India',
      'upi_id': upiId ?? 'ibuild@icici',
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (sanitizedAvatarUrl != null) {
      payload['avatar_url'] = sanitizedAvatarUrl;
    }
    if (logoUrl != null && logoUrl.isNotEmpty && logoUrl.startsWith('https://') && logoUrl.length <= 2048) {
      payload['logo_url'] = logoUrl;
    }

    // Save to OfflineDataCache for instant local persistence
    OfflineDataCache().set('user_profile_$uid', payload);
    OfflineDataCache().cacheCompanyBranding(payload);

    final client = _client;
    if (client == null) return;

    // Save to Supabase profiles table
    try {
      await client.from('profiles').upsert(payload);
    } catch (e) {
      // Fallback: standard profile columns
      try {
        final basicPayload = <String, dynamic>{
          'id': uid,
          'full_name': fullName,
          'phone': phone,
          'company_name': companyName,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (sanitizedAvatarUrl != null) {
          basicPayload['avatar_url'] = sanitizedAvatarUrl;
        }
        await client.from('profiles').upsert(basicPayload);
      } catch (_) {}
    }

    // Keep auth metadata strictly lightweight (full_name only) to ensure compact JWT (<8KB)
    try {
      await client.auth.updateUser(UserAttributes(
        data: {'full_name': fullName},
      ));
    } catch (_) {}
  }

  @override
  Future<UserResponse> updatePassword({required String newPassword}) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('No Supabase client connection.');
    }
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
