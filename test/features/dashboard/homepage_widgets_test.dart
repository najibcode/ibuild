import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/features/dashboard/presentation/controllers/homepage_widgets_provider.dart';
import 'package:ibuild/features/dashboard/presentation/widgets/duolingo_widgets.dart';
import 'package:ibuild/features/dashboard/presentation/widgets/customize_dashboard_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Homepage Duolingo Widgets & Customization Tests', () {
    test('Default widgets contain all 7 core widgets and are enabled by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final widgets = container.read(homepageWidgetsProvider);
      expect(widgets.length, equals(7));

      final enabled = container.read(homepageWidgetsProvider.notifier).enabledWidgets;
      expect(enabled.length, equals(7));

      final types = widgets.map((w) => w.type).toList();
      expect(types, contains(DashboardWidgetType.dailyStreak));
      expect(types, contains(DashboardWidgetType.dailyQuests));
      expect(types, contains(DashboardWidgetType.powerActions));
      expect(types, contains(DashboardWidgetType.safetyShield));
      expect(types, contains(DashboardWidgetType.materialRadar));
      expect(types, contains(DashboardWidgetType.portfolioPulse));
      expect(types, contains(DashboardWidgetType.projectHealth));
    });

    test('Toggling widget disabled updates enabledWidgets list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(homepageWidgetsProvider.notifier);

      // Disable dailyStreak
      await notifier.toggleWidget(DashboardWidgetType.dailyStreak, false);

      final updated = container.read(homepageWidgetsProvider);
      final streakWidget = updated.firstWhere((w) => w.type == DashboardWidgetType.dailyStreak);
      expect(streakWidget.isEnabled, isFalse);

      final enabled = notifier.enabledWidgets;
      expect(enabled.length, equals(6));
      expect(enabled.any((w) => w.type == DashboardWidgetType.dailyStreak), isFalse);

      // Reset to defaults
      await notifier.resetToDefaults();
      expect(notifier.enabledWidgets.length, equals(7));
    });

    testWidgets('DuolingoStreakWidget renders flame, days, and weekly dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DuolingoStreakWidget(streakDays: 21),
          ),
        ),
      );

      expect(find.text('21'), findsOneWidget);
      expect(find.text('DAILY SITE STREAK'), findsOneWidget);
      expect(find.textContaining('Site active for 21 days'), findsOneWidget);
      expect(find.byType(DuolingoStreakWidget), findsOneWidget);
    });

    testWidgets('DuolingoDailyQuestsWidget allows checking quests and calculates progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DuolingoDailyQuestsWidget(),
          ),
        ),
      );

      expect(find.text('DAILY SITE QUESTS'), findsOneWidget);
      expect(find.textContaining('Mark Morning Attendance'), findsOneWidget);
      expect(find.textContaining('Upload Daily Progress Photo'), findsOneWidget);

      // Tap the third quest checkbox to complete it
      final checkboxes = find.byType(GestureDetector);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.last);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('CustomizeDashboardModal renders all widgets with toggle switches', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomizeDashboardModal(),
            ),
          ),
        ),
      );

      expect(find.text('Customize Homepage'), findsOneWidget);
      expect(find.text('🔥 Daily Site Streak'), findsOneWidget);
      expect(find.text('🎯 Daily Site Quests'), findsOneWidget);
      expect(find.text('⚡ Power Quick Actions'), findsOneWidget);
      expect(find.text('SAVE & APPLY'), findsOneWidget);
      expect(find.text('Reset Defaults'), findsOneWidget);
    });
  });
}
