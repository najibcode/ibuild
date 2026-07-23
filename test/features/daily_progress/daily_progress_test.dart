import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/daily_progress/data/models/daily_progress_model.dart';

void main() {
  group('Daily Progress & Work Evidence Unit Tests', () {
    test('DailyProgress model serialization with Before and After evidence notes', () {
      final progress = DailyProgress(
        id: 'prog-001',
        projectId: 'proj-101',
        date: '2026-07-23',
        morningImageUrl: 'https://example.com/before.jpg',
        morningNotes: 'Initial site setup before wall construction',
        eveningImageUrl: 'https://example.com/after.jpg',
        eveningNotes: 'Built 10ft brick wall, fitted conduit pipes, ready for plastering',
        progressPercentage: 45,
        supervisorId: 'sup-123',
      );

      expect(progress.progressPercentage, equals(45));
      expect(progress.morningNotes, contains('Initial site setup'));
      expect(progress.eveningNotes, contains('Built 10ft brick wall'));

      final json = progress.toJson();
      expect(json['project_id'], equals('proj-101'));
      expect(json['morning_image_url'], equals('https://example.com/before.jpg'));
      expect(json['evening_image_url'], equals('https://example.com/after.jpg'));

      final reconstructed = DailyProgress.fromJson({
        'id': 'prog-001',
        'project_id': 'proj-101',
        'date': '2026-07-23',
        'morning_image_url': 'https://example.com/before.jpg',
        'morning_notes': 'Initial site setup before wall construction',
        'evening_image_url': 'https://example.com/after.jpg',
        'evening_notes': 'Built 10ft brick wall, fitted conduit pipes, ready for plastering',
        'progress_percentage': 45,
        'supervisor_id': 'sup-123',
      });

      expect(reconstructed.date, equals('2026-07-23'));
      expect(reconstructed.progressPercentage, equals(45));
    });
  });
}
