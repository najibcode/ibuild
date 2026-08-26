@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ibuild/core/supabase/supabase_client.provider.dart';
import 'package:ibuild/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  late SupabaseClient client;

  setUpAll(() {
    const supabaseUrl = 'https://dxjvvashdbhlfvsjfdjq.supabase.co';
    const supabaseAnonKey = 'sb_publishable_mTs0l8WYewMHwLNPwV0wow_FZ6Nvmnd';
    client = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
  });

  test('Owner login succeeds and resolves owner permissions', () async {
    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authControllerProvider.notifier)
        .signIn('owner@ibuild.in', 'owner@123');

    expect(success, isTrue);
    expect(container.read(currentRoleProvider), equals('owner'));
    expect(container.read(isOwnerProvider), isTrue);
    expect(container.read(isSupervisorProvider), isFalse);
    expect(container.read(isAdminProvider), isFalse);

    final perms = await container.read(userPermissionsProvider.future);
    expect(perms.contains('project.view'), isTrue);
    expect(perms.contains('billing.view'), isTrue);
    expect(perms.contains('settings.manage'), isFalse);
  });

  test('Supervisor login succeeds and resolves supervisor permissions', () async {
    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authControllerProvider.notifier)
        .signIn('supervisor@ibuild.in', 'supervisor@123');

    expect(success, isTrue);
    expect(container.read(currentRoleProvider), equals('supervisor'));
    expect(container.read(isSupervisorProvider), isTrue);
    expect(container.read(isOwnerProvider), isFalse);
    expect(container.read(isAdminProvider), isFalse);

    final perms = await container.read(userPermissionsProvider.future);
    expect(perms.contains('project.view'), isTrue);
    expect(perms.contains('attendance.create'), isTrue);
    expect(perms.contains('daily_progress.create'), isTrue);
    expect(perms.contains('billing.view'), isFalse);
  });

  test('Admin login succeeds and resolves admin permissions', () async {
    final container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authControllerProvider.notifier)
        .signIn('admin@ibuild.in', 'admin@123');

    expect(success, isTrue);
    expect(container.read(currentRoleProvider), equals('admin'));
    expect(container.read(isAdminProvider), isTrue);
    expect(container.read(isOwnerProvider), isFalse);
    expect(container.read(isSupervisorProvider), isFalse);

    final perms = await container.read(userPermissionsProvider.future);
    expect(perms.contains('settings.manage'), isTrue);
    expect(perms.contains('project.view'), isTrue);
  });
}
