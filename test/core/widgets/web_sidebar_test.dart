import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/widgets/web_sidebar.dart';
import 'package:ibuild/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';

class MockAuthController extends StateNotifier<AuthState> implements AuthController {
  MockAuthController()
      : super(AuthState(
          isLoading: false,
          profile: {'full_name': 'Test Admin', 'role': 'owner'},
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('WebSidebar renders, expands, and collapses smoothly without errors', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    int selectedTab = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRoleProvider.overrideWith((ref) => 'owner'),
          userPermissionsProvider.overrideWith(
            (ref) => Future.value({
              'dashboard.view',
              'project.view',
              'attendance.view',
              'employee.view',
              'inventory.view',
              'billing.view',
            }),
          ),
          authControllerProvider.overrideWith((ref) => MockAuthController()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                WebSidebar(
                  activeIndex: selectedTab,
                  onTabSelected: (index) {
                    selectedTab = index;
                  },
                ),
                const Expanded(
                  child: Center(child: Text('Main Content')),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify initial expanded state
    expect(find.byType(WebSidebar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Test Admin'), findsOneWidget);

    // Tap collapse button
    final collapseBtn = find.byTooltip('Collapse Sidebar');
    expect(collapseBtn, findsOneWidget);
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    // Verify collapsed state
    final expandTooltip = find.byTooltip('Expand Sidebar');
    expect(expandTooltip, findsOneWidget);

    // Tap to expand
    await tester.tap(expandTooltip);
    await tester.pumpAndSettle();

    // Verify expanded back
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byTooltip('Collapse Sidebar'), findsOneWidget);
  });
}
