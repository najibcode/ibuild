import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import 'package:ibuild/features/profile/presentation/screens/user_profile_screen.dart';
import '../../main.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final loc = state.matchedLocation;

      final isPublicRoute = loc == '/login' ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/splash';

      // 1. If not authenticated and trying to visit a protected route -> redirect to login
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // 2. If authenticated and visiting login or splash -> redirect to dashboard
      if (isAuthenticated && (loc == '/login' || loc == '/splash')) {
        return '/dashboard';
      }

      return null;
    },
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
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return MainRouterScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/attendance',
        redirect: (context, state) => '/dashboard?tab=attendance',
      ),
      GoRoute(
        path: '/projects',
        redirect: (context, state) => '/dashboard?tab=projects',
      ),
      GoRoute(
        path: '/dpr',
        redirect: (context, state) => '/dashboard?tab=dpr',
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => const MainRouterScreen(),
  );
});
