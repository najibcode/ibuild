import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/core/offline/offline_sync_service.dart';
import 'package:ibuild/features/snags/presentation/screens/snag_list_screen.dart';

void main() {
  group('Site Snags Real Data & Offline Caching Unit Tests', () {
    late OfflineDataCache cache;
    late OfflineSyncService syncService;

    setUp(() {
      cache = OfflineDataCache();
      cache.clear();

      syncService = OfflineSyncService(null, false);
      syncService.clearQueue();
    });

    tearDown(() {
      syncService.dispose();
      cache.clear();
    });

    test('SnagItem serialization and deserialization preserves real values', () {
      final snag = SnagItem(
        id: 'SNAG-9988',
        title: 'Waterproofing membrane puncture on terrace slab',
        description: 'Punctured membrane during tile laying. Water seepage observed in slab below.',
        location: 'Tower 2 - Terrace North Corner',
        tradeCategory: 'Waterproofing & Insulation',
        severity: 'Critical',
        status: 'In Progress',
        assignedSubcontractor: 'Apex Structural Contractors',
        projectId: 'proj_apex_101',
        projectName: 'Apex Skyrise Residency',
        rectificationNotes: 'Patch work applied with polyurethane compound, water testing scheduled.',
        createdAt: DateTime(2026, 8, 20, 10, 30),
        resolvedAt: null,
      );

      final map = snag.toMap();
      expect(map['id'], 'SNAG-9988');
      expect(map['project_name'], 'Apex Skyrise Residency');
      expect(map['project_id'], 'proj_apex_101');
      expect(map['trade_category'], 'Waterproofing & Insulation');
      expect(map['assigned_subcontractor'], 'Apex Structural Contractors');
      expect(map['severity'], 'Critical');
      expect(map['status'], 'In Progress');

      final fromMapSnag = SnagItem.fromMap(map);
      expect(fromMapSnag.id, snag.id);
      expect(fromMapSnag.title, snag.title);
      expect(fromMapSnag.location, snag.location);
      expect(fromMapSnag.projectName, 'Apex Skyrise Residency');
      expect(fromMapSnag.assignedSubcontractor, 'Apex Structural Contractors');
      expect(fromMapSnag.rectificationNotes, snag.rectificationNotes);
    });

    test('OfflineDataCache persists and retrieves snags list without data loss', () {
      final snags = [
        SnagItem(
          id: 'SNAG-1',
          title: 'Plaster Unevenness',
          description: 'Putty required',
          location: 'Flat 101',
          tradeCategory: 'Plastering',
          severity: 'High',
          status: 'Open',
          projectName: 'Hilltop Enclave',
          assignedSubcontractor: 'Prime Plastering Co.',
          createdAt: DateTime.now(),
        ),
        SnagItem(
          id: 'SNAG-2',
          title: 'Tile Lippage',
          description: 'Re-grouting required',
          location: 'Kitchen',
          tradeCategory: 'Tiling',
          severity: 'Medium',
          status: 'Resolved',
          projectName: 'Hilltop Enclave',
          assignedSubcontractor: 'Prime Plastering Co.',
          createdAt: DateTime.now(),
          resolvedAt: DateTime.now(),
        ),
      ];

      cache.cacheSnags(snags.map((s) => s.toMap()).toList());

      final cachedList = cache.getCachedSnags();
      expect(cachedList, isNotNull);
      expect(cachedList!.length, 2);
      expect(cachedList[0]['id'], 'SNAG-1');
      expect(cachedList[0]['project_name'], 'Hilltop Enclave');
      expect(cachedList[1]['status'], 'Resolved');
    });

    test('OfflineSyncService enqueues snagCreate and snagUpdate actions', () {
      final actionId = syncService.enqueueAction(
        type: SyncActionType.snagCreate,
        payload: {
          'id': 'SNAG-TEST-001',
          'title': 'Door frame gap',
          'location': 'Master Bedroom',
          'severity': 'Low',
          'status': 'Open',
        },
      );

      expect(actionId, isNotEmpty);
      expect(syncService.queue.length, 1);
      expect(syncService.queue.first.type, SyncActionType.snagCreate);
      expect(syncService.queue.first.payload['title'], 'Door frame gap');

      syncService.enqueueAction(
        type: SyncActionType.snagUpdate,
        payload: {
          'id': 'SNAG-TEST-001',
          'status': 'Closed',
        },
      );

      expect(syncService.queue.length, 2);
      expect(syncService.queue.last.type, SyncActionType.snagUpdate);
    });
  });
}
