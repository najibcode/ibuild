import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
      state = state.copyWith(isLoading: true);
      final profile = await _repository.getUserProfile(uid: session.user.id);
      state = state.copyWith(
        isLoading: false,
        user: session.user,
        profile: profile,
      );
      // Trigger RBAC permission loading
      _ref.invalidate(userRoleProvider);
      _ref.invalidate(userPermissionsProvider);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      AuthResponse response;
      try {
        response = await _repository.signIn(email: email, password: password);
      } catch (signInErr) {
        // If signIn fails (e.g. user hasn't registered in Supabase Auth yet), attempt auto signUp
        try {
          response = await _repository.signUp(email: email, password: password);
          if (response.session == null) {
            // Attempt signIn after signUp if session wasn't returned immediately
            response = await _repository.signIn(email: email, password: password);
          }
        } catch (_) {
          // If signUp fails too (e.g. user exists but wrong password), throw original error
          rethrow;
        }
      }

      final user = response.user;
      if (user == null) {
        throw Exception('Authentication failed.');
      }

      final profile = await _repository.getUserProfile(uid: user.id);
      state = state.copyWith(
        isLoading: false,
        user: user,
        profile: profile,
      );
      // Trigger fresh RBAC permission loading after login
      _ref.invalidate(userRoleProvider);
      _ref.invalidate(userPermissionsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    // Clear cached RBAC data
    _ref.invalidate(userRoleProvider);
    _ref.invalidate(userPermissionsProvider);
    state = AuthState.initial();
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository, ref);
});
