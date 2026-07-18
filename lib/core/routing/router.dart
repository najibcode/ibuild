import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../main.dart'; // We will point this to MainRouterScreen or Dashboard

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final client = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainRouterScreen(), // Our root routing wrapper
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = client.auth.currentSession != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/dashboard';
      }

      return null;
    },
  );
});
