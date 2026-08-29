import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ibuild/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository implements AuthRepository {
  Map<String, dynamic>? storedProfile = {
    'id': 'user_test_123',
    'full_name': 'Original Name',
    'phone': '9876543210',
    'company_name': 'IBUILD Construction',
    'avatar_url': 'https://ik.imagekit.io/ibuild/users/profile/original.jpg',
  };

  bool shouldThrowOnUpdate = false;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Session? getCurrentSession() => null;

  @override
  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    return storedProfile;
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
    if (shouldThrowOnUpdate) {
      throw const PostgrestException(message: 'RLS policy violated or simulated DB error');
    }
    storedProfile = {
      'id': uid,
      'full_name': fullName,
      'phone': phone,
      'company_name': companyName,
      'avatar_url': ?avatarUrl,
      'tagline': ?tagline,
      'gstin': ?gstin,
      'address': ?address,
      'upi_id': ?upiId,
      'logo_url': ?logoUrl,
    };
  }

  @override
  Future<UserResponse> updatePassword({required String newPassword}) async {
    throw UnimplementedError();
  }
}

void main() {
  group('User Profile Update & ImageKit Storage Tests', () {
    late MockAuthRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('updateUserProfile successfully updates avatar URL and user info', () async {
      final controller = container.read(authControllerProvider.notifier);

      final success = await controller.updateUserProfile(
        fullName: 'Er. Rajesh Sharma',
        phone: '9988776655',
        companyName: 'Apex Infrastructures',
        avatarUrl: 'https://ik.imagekit.io/ibuild/users/profile/photo_123.jpg',
      );

      expect(success, isTrue);
      final profile = container.read(authControllerProvider).profile;
      expect(profile?['full_name'], 'Er. Rajesh Sharma');
      expect(profile?['avatar_url'], 'https://ik.imagekit.io/ibuild/users/profile/photo_123.jpg');
      expect(profile?['company_name'], 'Apex Infrastructures');
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('updateUserProfile resiliently succeeds and preserves local avatar even when backend DB throws RLS/network error', () async {
      mockRepo.shouldThrowOnUpdate = true; // Simulate DB error
      final controller = container.read(authControllerProvider.notifier);

      final success = await controller.updateUserProfile(
        fullName: 'Er. Rajesh Sharma (Offline/Fallback)',
        phone: '9988776655',
        companyName: 'Apex Infrastructures',
        avatarUrl: 'https://ik.imagekit.io/ibuild/users/profile/photo_offline.jpg',
      );

      expect(success, isTrue, reason: 'Profile update must not fail or show red banner when DB fails');
      final profile = container.read(authControllerProvider).profile;
      expect(profile?['avatar_url'], 'https://ik.imagekit.io/ibuild/users/profile/photo_offline.jpg');
      expect(profile?['full_name'], 'Er. Rajesh Sharma (Offline/Fallback)');
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('updateUserProfile handles local guest session gracefully', () async {
      final controller = container.read(authControllerProvider.notifier);

      final success = await controller.updateUserProfile(
        fullName: 'Guest User',
        phone: '0000000000',
        companyName: 'Guest Builders',
        avatarUrl: 'https://ik.imagekit.io/ibuild/users/profile/guest.jpg',
      );

      expect(success, isTrue);
      final profile = container.read(authControllerProvider).profile;
      expect(profile?['full_name'], 'Guest User');
      expect(profile?['avatar_url'], 'https://ik.imagekit.io/ibuild/users/profile/guest.jpg');
    });
  });
}
