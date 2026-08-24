import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';

void main() {
  group('OfflineDataCache Tests', () {
    final cache = OfflineDataCache();

    setUp(() {
      cache.clear();
    });

    test('stores and retrieves projects cache', () {
      final projects = [
        {'id': 'p1', 'name': 'Downtown Commercial Tower'},
        {'id': 'p2', 'name': 'Highway Flyover Site'},
      ];

      cache.cacheProjects(projects);
      expect(cache.has('projects_master'), isTrue);

      final retrieved = cache.getCachedProjects();
      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved.first['name'], 'Downtown Commercial Tower');
    });

    test('stores and retrieves attendance for specific dates', () {
      final records = [
        {'id': 'a1', 'employee_id': 'e1', 'status': 'present', 'date': '2026-08-24'},
      ];

      cache.cacheAttendanceForDate('2026-08-24', records);
      expect(cache.has('attendance_2026-08-24'), isTrue);

      final retrieved = cache.getCachedAttendanceForDate('2026-08-24');
      expect(retrieved, isNotNull);
      expect(retrieved!.first['status'], 'present');
    });

    test('handles non-existent keys gracefully', () {
      expect(cache.get('non_existent'), isNull);
      expect(cache.getCachedProjects(), isNull);
      expect(cache.has('non_existent'), isFalse);
    });

    test('removes specific keys and clears cache', () {
      cache.set('test_key', {'data': 123});
      expect(cache.has('test_key'), isTrue);

      cache.remove('test_key');
      expect(cache.has('test_key'), isFalse);

      cache.cacheInventory([{'id': 'i1', 'name': 'Cement 50kg'}]);
      cache.clear();
      expect(cache.getCachedInventory(), isNull);
    });
  });
}
