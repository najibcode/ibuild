import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/widgets/app_logo.dart';

void main() {
  group('AppLogo Widget Tests', () {
    testWidgets('AppLogo renders with IBU wordmark and subtitle by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(size: 40, showText: true),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('CONSTRUCTION ERP'), findsOneWidget);

      final titleFinder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('IBUILD'),
      );
      expect(titleFinder, findsOneWidget);

      final richTextWidget = tester.widget<RichText>(titleFinder);
      final textSpan = richTextWidget.text as TextSpan;
      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, equals(2));

      final firstSpan = textSpan.children![0] as TextSpan;
      final secondSpan = textSpan.children![1] as TextSpan;

      expect(firstSpan.text, equals('IBU'));
      expect(secondSpan.text, equals('ILD'));
    });

    testWidgets('AppLogo renders mark only when showText is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(size: 32, showText: false),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('CONSTRUCTION ERP'), findsNothing);
      expect(find.textContaining('IBUILD'), findsNothing);
    });

    testWidgets('AppLogo renders custom subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(size: 36, subtitle: 'SITE MANAGEMENT'),
          ),
        ),
      );

      expect(find.text('SITE MANAGEMENT'), findsOneWidget);
    });
  });
}
