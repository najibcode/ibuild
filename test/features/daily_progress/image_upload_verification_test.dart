import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/image/imagekit_auth_service.dart';
import 'package:ibuild/services/imagekit/imagekit_service.dart';
import 'package:ibuild/features/daily_progress/data/models/daily_progress_model.dart';
import 'package:ibuild/models/image_model.dart';

void main() {
  group('ImageKit Upload & Verification Unit Tests', () {
    test('ImageKitAuthResponse parses valid edge function credentials correctly', () {
      final json = {
        'token': 'test_token_12345',
        'signature': 'abcdef1234567890',
        'expire': 1723223000,
        'publicKey': 'public_test_key_xyz',
        'urlEndpoint': 'https://ik.imagekit.io/test',
      };

      final authResponse = ImageKitAuthResponse.fromJson(json);

      expect(authResponse.token, equals('test_token_12345'));
      expect(authResponse.signature, equals('abcdef1234567890'));
      expect(authResponse.expire, equals(1723223000));
      expect(authResponse.publicKey, equals('public_test_key_xyz'));
      expect(authResponse.urlEndpoint, equals('https://ik.imagekit.io/test'));
      expect(authResponse.isValid, isTrue);
    });

    test('ImageKitAuthResponse invalidates incomplete credentials', () {
      final json = {
        'token': '',
        'signature': 'abcdef1234567890',
        'expire': 0,
        'publicKey': '',
        'urlEndpoint': '',
      };

      final authResponse = ImageKitAuthResponse.fromJson(json);
      expect(authResponse.isValid, isFalse);
    });

    test('ImageKitUploadResult parses ImageKit API response accurately', () {
      final responseJson = {
        'fileId': 'file_morning_001',
        'url': 'https://ik.imagekit.io/ibuild/projects/before/img_morning.jpg',
        'filePath': '/projects/before/img_morning.jpg',
        'thumbnailUrl': 'https://ik.imagekit.io/ibuild/projects/before/tr:n-ik_ml_thumbnail/img_morning.jpg',
        'name': 'img_morning.jpg',
      };

      final result = ImageKitUploadResult.fromJson(responseJson);

      expect(result.fileId, equals('file_morning_001'));
      expect(result.url, contains('img_morning.jpg'));
      expect(result.thumbnailUrl, contains('tr:n-ik_ml_thumbnail'));
    });

    test('DailyProgress model collects morning & evening evidence URLs and notes', () {
      final progress = DailyProgress(
        id: 'dp-100',
        projectId: 'proj-001',
        date: '2026-08-09',
        morningImageUrl: 'https://ik.imagekit.io/ibuild/projects/before/morning.jpg',
        morningNotes: 'Foundation prep work started',
        eveningImageUrl: 'https://ik.imagekit.io/ibuild/projects/after/evening.jpg',
        eveningNotes: 'Foundation concrete poured successfully',
        progressPercentage: 65,
      );

      expect(progress.allImageUrls.length, equals(2));
      expect(progress.allImageUrls[0], equals('https://ik.imagekit.io/ibuild/projects/before/morning.jpg'));
      expect(progress.allImageUrls[1], equals('https://ik.imagekit.io/ibuild/projects/after/evening.jpg'));

      expect(progress.allNotes.length, equals(2));
      expect(progress.allNotes[0], equals('Foundation prep work started'));
      expect(progress.allNotes[1], equals('Foundation concrete poured successfully'));
    });

    test('ImageFolder path enum resolution', () {
      expect(ImageFolder.projectsBefore.path, equals('projects/before'));
      expect(ImageFolder.projectsAfter.path, equals('projects/after'));
    });
  });
}
