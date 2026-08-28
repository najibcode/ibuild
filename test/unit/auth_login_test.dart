import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';
import 'package:ibuild/features/auth/domain/repositories/auth_repository.dart';
import 'package:ibuild/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';

class MockAuthRepository implements AuthRepository {
  final Map<String, dynamic> profiles = {
    'admin-uid': {
      'id': 'admin-uid',
      'full_name': 'System Administrator',
      'email': 'admin@ibuild.in',
      'role_display': 'admin',
      'is_disabled': false,
    },
    'owner-uid': {
      'id': 'owner-uid',
      'full_name': 'Business Owner',
      'email': 'owner@ibuild.in',
      'role_display': 'owner',
      'is_disabled': false,
    },
    'supervisor-uid': {
      'id': 'supervisor-uid',
      'full_name': 'Site Supervisor',
      'email': 'supervisor@ibuild.in',
      'role_display': 'supervisor',
      'is_disabled': false,
    },
    'employee-uid': {
      'id': 'employee-uid',
      'full_name': 'Site Employee',
      'email': 'employee@ibuild.in',
      'role_display': 'employee',
      'is_disabled': false,
    },
    'disabled-uid': {
      'id': 'disabled-uid',
      'full_name': 'Disabled User',
      'email': 'disabled@ibuild.in',
      'role_display': 'employee',
      'is_disabled': true,
    },
  };

  Session? currentSession;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    if (password == 'wrong-password') {
      throw const AuthException('Invalid login credentials.');
    }
    if (email == 'unconfirmed@ibuild.in') {
      throw const AuthException('Email not confirmed');
    }
    if (email == 'disabled@ibuild.in') {
      final user = User(
        id: 'disabled-uid',
        appMetadata: {},
        userMetadata: {'full_name': 'Disabled User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: email,
      );
      currentSession = Session(
        accessToken: 'dummy-token',
        tokenType: 'bearer',
        user: user,
      );
      return AuthResponse(session: currentSession, user: user);
    }

    String uid = 'owner-uid';
    if (email.contains('admin')) uid = 'admin-uid';
    if (email.contains('supervisor')) uid = 'supervisor-uid';
    if (email.contains('employee')) uid = 'employee-uid';

    final user = User(
      id: uid,
      appMetadata: {},
      userMetadata: {'full_name': profiles[uid]!['full_name']},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );

    currentSession = Session(
      accessToken: 'dummy-token',
      tokenType: 'bearer',
      user: user,
    );

    return AuthResponse(session: currentSession, user: user);
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    currentSession = null;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Session? getCurrentSession() => currentSession;

  @override
  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    return profiles[uid];
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
    if (profiles.containsKey(uid)) {
      profiles[uid]!['full_name'] = fullName;
      if (avatarUrl != null) profiles[uid]!['avatar_url'] = avatarUrl;
    }
  }

  @override
  Future<UserResponse> updatePassword({required String newPassword}) async {
    return UserResponse.fromJson({'user': null});
  }
}

void main() {
  late MockAuthRepository mockRepo;
  late SupabaseClient dummyClient;

  setUpAll(() {
    dummyClient = SupabaseClient(
      'https://dxjvvashdbhlfvsjfdjq.supabase.co',
      'sb_publishable_mTs0l8WYewMHwLNPwV0wow_FZ6Nvmnd',
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  });

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('Authentication & Role Resolution Unit Tests', () {
    test('1. Owner login succeeds and resolves owner permissions', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(dummyClient),
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .signIn('owner@ibuild.in', 'secure-pwd-123');

      expect(success, isTrue);
      expect(container.read(currentRoleProvider), equals('owner'));
      expect(container.read(isOwnerProvider), isTrue);
      expect(container.read(isSupervisorProvider), isFalse);
      expect(container.read(isAdminProvider), isFalse);

      final perms = await container.read(userPermissionsProvider.future);
      expect(perms.contains('project.view'), isTrue);
      expect(perms.contains('billing.view'), isTrue);
      expect(perms.contains('settings.manage'), isFalse);
    });

    test('2. Supervisor login succeeds and resolves supervisor permissions', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(dummyClient),
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .signIn('supervisor@ibuild.in', 'secure-pwd-123');

      expect(success, isTrue);
      expect(container.read(currentRoleProvider), equals('supervisor'));
      expect(container.read(isSupervisorProvider), isTrue);
      expect(container.read(isOwnerProvider), isFalse);
      expect(container.read(isAdminProvider), isFalse);

      final perms = await container.read(userPermissionsProvider.future);
      expect(perms.contains('project.view'), isTrue);
      expect(perms.contains('attendance.create'), isTrue);
      expect(perms.contains('daily_progress.create'), isTrue);
      expect(perms.contains('billing.view'), isFalse);
    });

    test('3. Admin login succeeds and resolves admin permissions', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(dummyClient),
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .signIn('admin@ibuild.in', 'secure-pwd-123');

      expect(success, isTrue);
      expect(container.read(currentRoleProvider), equals('admin'));
      expect(container.read(isAdminProvider), isTrue);
      expect(container.read(isOwnerProvider), isFalse);
      expect(container.read(isSupervisorProvider), isFalse);

      final perms = await container.read(userPermissionsProvider.future);
      expect(perms.contains('settings.manage'), isTrue);
      expect(perms.contains('users.manage'), isTrue);
      expect(perms.contains('project.view'), isTrue);
    });

    test('4. Employee login succeeds and resolves employee permissions', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(dummyClient),
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .signIn('employee@ibuild.in', 'secure-pwd-123');

      expect(success, isTrue);
      expect(container.read(currentRoleProvider), equals('employee'));
      expect(container.read(isEmployeeProvider), isTrue);
      expect(container.read(isAdminProvider), isFalse);

      final perms = await container.read(userPermissionsProvider.future);
      expect(perms.contains('attendance.view'), isTrue);
      expect(perms.contains('settings.manage'), isFalse);
    });

    test('5. Invalid password fails with generic error message', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(dummyClient),
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .signIn('owner@ibuild.in', 'wrong-password');

      expect(success, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        equals('Incorrect email or password.'),
      );
    });

    test('6. Disabled account fails with deactivated account message', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(dummyClient),
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authControllerProvider.notifier)
          .signIn('disabled@ibuild.in', 'any-password');

      expect(success, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        equals('Your account has been deactivated. Please contact your administrator.'),
      );
      expect(mockRepo.currentSession, isNull);
    });
  });
}
