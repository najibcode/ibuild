import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

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

  AuthController(this._repository) : super(AuthState.initial()) {
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
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.signIn(email: email, password: password);
      final profile = await _repository.getUserProfile(uid: response.user!.id);
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        profile: profile,
      );
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
  return AuthController(repository);
});
