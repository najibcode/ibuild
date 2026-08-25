import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/core/offline/offline_sync_service.dart';
import 'package:ibuild/features/attendance/data/models/attendance_model.dart';
import 'package:ibuild/features/attendance/data/repositories/supabase_attendance_repository.dart';
import 'package:ibuild/features/activities/data/repositories/supabase_activity_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeErrorSupabaseClient extends Fake implements SupabaseClient {
  @override
  SupabaseQueryBuilder from(String table) {
    throw const SocketException('No Internet Connection (Simulation)');
  }
}

class FakeActivityRepo extends Fake implements SupabaseActivityRepository {
  @override
  Future<void> logActivity({
    required String actionType,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {}
}

class SocketException implements Exception {
  final String message;
  const SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

void main() {
  group('Attendance Offline End-to-End Flow Tests', () {
    late OfflineDataCache cache;
    late OfflineSyncService syncService;
    late SupabaseAttendanceRepository repository;

    setUp(() {
      cache = OfflineDataCache();
      cache.clear();

      syncService = OfflineSyncService(null, false);
      syncService.clearQueue();

      repository = SupabaseAttendanceRepository(
        FakeErrorSupabaseClient(),
        FakeActivityRepo(),
      );
    });

    tearDown(() {
      syncService.dispose();
      cache.clear();
    });

    test('saveAttendance gracefully handles network failure by caching and queueing', () async {
      final attendance = Attendance(
        id: 'att_test_1',
        employeeId: 'emp_999',
        date: '2026-08-25',
        status: 'Present',
        projectId: 'proj_100',
        employeeName: 'Ramesh Kumar (Mason)',
      );

      // Should NOT throw despite FakeErrorSupabaseClient throwing SocketException
      await repository.saveAttendance(attendance);

      // 1. Verify cached locally
      final cachedRecords = cache.getCachedAttendanceForDate('2026-08-25');
      expect(cachedRecords, isNotNull);
      expect(cachedRecords!.length, 1);
      expect(cachedRecords.first['employee_id'], 'emp_999');
      expect(cachedRecords.first['morning_status'], 'present');

      // 2. Verify queued for sync
      expect(syncService.queue.length, 1);
      expect(syncService.queue.first.type, SyncActionType.attendanceSave);
      expect(syncService.queue.first.payload['employee_id'], 'emp_999');

      // 3. Verify getAttendanceForDate loads from cache when offline
      final loadedList = await repository.getAttendanceForDate('2026-08-25');
      expect(loadedList.length, 1);
      expect(loadedList.first.employeeId, 'emp_999');
      expect(loadedList.first.status, 'Present');
    });
  });
}
