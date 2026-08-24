import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/offline/offline_sync_service.dart';
import 'package:ibuild/core/widgets/offline_sync_indicator.dart';

void main() {
  testWidgets('OfflineSyncIndicator renders Online state by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineSyncProvider.overrideWith((ref) => OfflineSyncService(null, false)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineSyncIndicator(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Online'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('OfflineSyncIndicator renders Pending badge when actions queued', (tester) async {
    final syncService = OfflineSyncService(null, false);
    syncService.setOnline(false);
    syncService.enqueueAction(
      type: SyncActionType.attendanceSave,
      payload: {'data': 'test'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineSyncProvider.overrideWith((ref) => syncService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: OfflineSyncIndicator(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 Pending'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
