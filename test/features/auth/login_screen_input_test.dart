import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/features/auth/domain/repositories/auth_repository.dart';
import 'package:ibuild/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ibuild/features/auth/presentation/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepo implements AuthRepository {
  @override
  Session? getCurrentSession() => null;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return AuthResponse(
      user: User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return AuthResponse();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<UserResponse> updatePassword({required String newPassword}) async {
    return UserResponse.fromJson({'user': null});
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    return {
      'id': uid,
      'full_name': 'Test User',
      'email': 'test@example.com',
      'role_display': 'owner',
      'is_disabled': false,
    };
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
  }) async {}
}

void main() {
  testWidgets('LoginScreen allows typing, editing, backspacing, and clearing password',
      (WidgetTester tester) async {
    final mockRepo = MockAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify presence of email and password fields
    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;

    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);

    // 1. Enter email
    await tester.enterText(emailField, 'owner@ibuild.in');
    await tester.pumpAndSettle();
    expect(find.text('owner@ibuild.in'), findsOneWidget);

    // 2. Type initial password
    await tester.enterText(passwordField, 'secret123');
    await tester.pumpAndSettle();
    expect(find.text('secret123'), findsOneWidget);

    // 3. Edit password (simulating user typing and backspacing)
    await tester.enterText(passwordField, 'secret');
    await tester.pumpAndSettle();
    expect(find.text('secret'), findsOneWidget);

    // 4. Test password clear button
    final clearButton = find.byTooltip('Clear password');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();
    expect(find.text('secret'), findsNothing);

    // 5. Retype new password
    await tester.enterText(passwordField, 'OwnerPass@2026');
    await tester.pumpAndSettle();
    expect(find.text('OwnerPass@2026'), findsOneWidget);

    // 6. Test password visibility toggle
    final toggleVisibility = find.byTooltip('Show password');
    expect(toggleVisibility, findsOneWidget);
    await tester.tap(toggleVisibility);
    await tester.pumpAndSettle();

    final hideVisibility = find.byTooltip('Hide password');
    expect(hideVisibility, findsOneWidget);
  });
}
