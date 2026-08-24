import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/offline/offline_sync_service.dart';
import 'package:ibuild/core/widgets/offline_sync_indicator.dart';

void main() {
  testWidgets('OfflineSyncIndicator renders Online state by default', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
    final container = ProviderContainer();
    final notifier = container.read(offlineSyncProvider.notifier);

    notifier.setOnline(false);
    notifier.enqueueAction(
      type: SyncActionType.attendanceSave,
      payload: {'data': 'test'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
