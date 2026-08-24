import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/offline/offline_sync_service.dart';

void main() {
  group('OfflineSyncService Tests', () {
    late OfflineSyncService syncService;

    setUp(() {
      syncService = OfflineSyncService();
    });

    tearDown(() {
      syncService.dispose();
    });

    test('initial state has zero pending actions and is online', () {
      expect(syncService.state.isOnline, isTrue);
      expect(syncService.state.isSyncing, isFalse);
      expect(syncService.state.pendingCount, 0);
      expect(syncService.queue.isEmpty, isTrue);
    });

    test('enqueuing action increments pending count', () {
      final actionId = syncService.enqueueAction(
        type: SyncActionType.attendanceSave,
        payload: {
          'employee_id': 'emp_123',
          'date': '2026-08-24',
          'status': 'present',
        },
      );

      expect(actionId, isNotEmpty);
      expect(syncService.state.pendingCount, 1);
      expect(syncService.queue.length, 1);
      expect(syncService.queue.first.type, SyncActionType.attendanceSave);
    });

    test('toggling online mode updates state properly', () {
      syncService.setOnline(false);
      expect(syncService.state.isOnline, isFalse);

      syncService.setOnline(true);
      expect(syncService.state.isOnline, isTrue);
    });

    test('removing action decrements pending count', () {
      final id1 = syncService.enqueueAction(
        type: SyncActionType.snagCreate,
        payload: {'title': 'Wall crack in Basement B2'},
      );

      final id2 = syncService.enqueueAction(
        type: SyncActionType.dprCreate,
        payload: {'notes': 'Completed column casting'},
      );

      expect(syncService.state.pendingCount, 2);

      syncService.removeAction(id1);
      expect(syncService.state.pendingCount, 1);
      expect(syncService.queue.first.id, id2);

      syncService.clearQueue();
      expect(syncService.state.pendingCount, 0);
    });

    test('SyncAction serialization roundtrip works', () {
      final now = DateTime.now();
      final action = SyncAction(
        id: 'test-uuid-1',
        type: SyncActionType.inventoryTransact,
        payload: {'item_id': 'mat_45', 'quantity': 100},
        createdAt: now,
        retryCount: 1,
        lastError: 'Timeout',
      );

      final json = action.toJson();
      final deserialized = SyncAction.fromJson(json);

      expect(deserialized.id, 'test-uuid-1');
      expect(deserialized.type, SyncActionType.inventoryTransact);
      expect(deserialized.payload['quantity'], 100);
      expect(deserialized.retryCount, 1);
      expect(deserialized.lastError, 'Timeout');
    });
  });
}
