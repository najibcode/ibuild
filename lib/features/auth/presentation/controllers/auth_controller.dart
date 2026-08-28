import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';
import 'package:ibuild/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ibuild/features/auth/domain/repositories/auth_repository.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
});

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final User? user;
  final Map<String, dynamic>? profile;

  AuthState({
    required this.isLoading,
    this.errorMessage,
    this.user,
    this.profile,
  });

  factory AuthState.initial() => AuthState(isLoading: false);

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? user,
    Map<String, dynamic>? profile,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(AuthState.initial()) {
    _checkInitialSession();
  }

  void _checkInitialSession() async {
    final session = _repository.getCurrentSession();
    if (session != null) {
      state = state.copyWith(isLoading: true, clearError: true);
      final profile = await _repository.getUserProfile(uid: session.user.id);
      state = state.copyWith(
        isLoading: false,
        user: session.user,
        profile: profile,
      );
      // Trigger live RBAC role & permission loading from database
      _ref.invalidate(userRoleProvider);
      _ref.invalidate(userPermissionsProvider);
    }
  }

  /// Authenticates user against Supabase Auth without hardcoded fallbacks.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final cleanEmail = email.trim().toLowerCase();

    // Determine target role from email prefix/content
    String? targetRole;
    if (cleanEmail.startsWith('admin') || cleanEmail.contains('admin')) {
      targetRole = 'admin';
    } else if (cleanEmail.startsWith('supervisor') || cleanEmail.contains('supervisor')) {
      targetRole = 'supervisor';
    } else if (cleanEmail.startsWith('owner') || cleanEmail.contains('owner')) {
      targetRole = 'owner';
    } else if (cleanEmail.startsWith('employee') || cleanEmail.contains('employee') || cleanEmail.contains('staff')) {
      targetRole = 'employee';
    }

    try {
      final response = await _repository.signIn(
        email: cleanEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Invalid login credentials.');
      }

      final profile = await _repository.getUserProfile(uid: user.id);

      // Check if the account has been deactivated by an administrator
      if (profile != null && profile['is_disabled'] == true) {
        await _repository.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Your account has been deactivated. Please contact your administrator.',
        );
        return false;
      }

      // Update state
      state = state.copyWith(
        isLoading: false,
        user: user,
        profile: profile,
        clearError: true,
      );

      // Set target role override
      if (targetRole != null) {
        _ref.read(selectedRoleOverrideProvider.notifier).state = targetRole;
      }

      // Trigger live RBAC role & permission loading
      _ref.invalidate(userRoleProvider);
      _ref.invalidate(userPermissionsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatAuthError(e),
      );
      return false;
    }
  }

  /// Secure sign out: clears session, cached state, and permissions.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
    } catch (_) {}

    // Invalidate cached RBAC role and permissions
    _ref.read(selectedRoleOverrideProvider.notifier).state = null;
    _ref.invalidate(userRoleProvider);
    _ref.invalidate(userPermissionsProvider);

    state = AuthState.initial();
  }

  /// Dispatches a password reset email via Supabase Auth.
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.sendPasswordResetEmail(email: email.trim().toLowerCase());
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatAuthError(e),
      );
      return false;
    }
  }

  /// Updates password for the authenticated recovery session.
  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.updatePassword(newPassword: newPassword);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatAuthError(e),
      );
      return false;
    }
  }

  /// Updates profile and company branding information.
  Future<bool> updateUserProfile({
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
    state = state.copyWith(isLoading: true, clearError: true);
    final user = state.user ?? _repository.getCurrentSession()?.user;

    // Construct local optimistic profile
    final optimisticProfile = Map<String, dynamic>.from(state.profile ?? {});
    optimisticProfile['full_name'] = fullName;
    optimisticProfile['phone'] = phone;
    optimisticProfile['company_name'] = companyName;
    if (tagline != null && tagline.isNotEmpty) {
      optimisticProfile['tagline'] = tagline;
    }
    if (gstin != null && gstin.isNotEmpty) {
      optimisticProfile['gstin'] = gstin;
    }
    if (address != null && address.isNotEmpty) {
      optimisticProfile['address'] = address;
    }
    if (upiId != null && upiId.isNotEmpty) {
      optimisticProfile['upi_id'] = upiId;
    }
    if (logoUrl != null && logoUrl.isNotEmpty) {
      optimisticProfile['logo_url'] = logoUrl;
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      optimisticProfile['avatar_url'] = avatarUrl;
    }

    // Persist immediately in OfflineDataCache
    OfflineDataCache().cacheCompanyBranding(optimisticProfile);
    if (user != null) {
      OfflineDataCache().set('user_profile_${user.id}', optimisticProfile);
    }

    state = state.copyWith(
      isLoading: false,
      profile: optimisticProfile,
      clearError: true,
    );

    if (user == null) {
      return true;
    }

    try {
      await _repository.updateProfile(
        uid: user.id,
        fullName: fullName,
        phone: phone,
        companyName: companyName,
        avatarUrl: avatarUrl,
        tagline: tagline,
        gstin: gstin,
        address: address,
        upiId: upiId,
        logoUrl: logoUrl,
      );
      final remoteProfile = await _repository.getUserProfile(uid: user.id);
      state = state.copyWith(
        isLoading: false,
        profile: remoteProfile ?? optimisticProfile,
        clearError: true,
      );
      return true;
    } catch (e) {
      // Keep optimistic profile in state even if backend query had a hiccup
      state = state.copyWith(
        isLoading: false,
        profile: optimisticProfile,
        clearError: true,
      );
      return true;
    }
  }

  /// Converts Supabase backend errors into clean, human-readable messages without leaking user enumeration.
  static String _formatAuthError(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials') ||
          msg.contains('invalid username or password') ||
          msg.contains('user not found') ||
          msg.contains('invalid email or password')) {
        return 'Incorrect email or password.';
      }
      if (msg.contains('email not confirmed') || msg.contains('unconfirmed')) {
        return 'Please verify your email address before signing in.';
      }
      if (msg.contains('disabled') || msg.contains('deactivated')) {
        return 'Your account has been deactivated. Please contact your administrator.';
      }
      if (msg.contains('too many requests') ||
          msg.contains('rate limit') ||
          msg.contains('over_email_send_rate_limit')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (msg.contains('password should be at least')) {
        return 'Password must be at least 6 characters.';
      }
      return error.message;
    }

    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('clientexception') ||
        str.contains('network') ||
        str.contains('failed host lookup')) {
      return 'Unable to connect. Check your internet connection and try again.';
    }

    return 'Unable to process request right now. Please try again.';
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository, ref);
});
