import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/admin/data/repositories/admin_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFailingPostgrestClient extends Fake implements SupabaseClient {
  @override
  FunctionsClient get functions => MockFailingFunctions();

  @override
  SupabaseQueryBuilder from(String table) {
    throw const PostgrestException(
      message: "Could not find the 'full_name' column of 'profiles' in the schema cache",
      code: 'PGRST204',
    );
  }

  @override
  SupabaseStorageClient get storage => FakeStorage();

  @override
  Map<String, String> get headers => {'apikey': 'test_anon_key'};

  @override
  GoTrueClient get auth => FakeGoTrue();

  @override
  PostgrestClient get rest => FakeRest();
}

class FakeRest extends Fake implements PostgrestClient {
  @override
  String get url => 'https://mock.supabase.co/rest/v1';
}

class FakeStorage extends Fake implements SupabaseStorageClient {}

class FakeGoTrue extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}

class MockFailingFunctions extends Fake implements FunctionsClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #invoke) {
      throw const FunctionException(
        status: 404,
        details: 'Function admin-manage-users not deployed',
      );
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('AdminRepository createUser Resiliency Tests', () {
    test('createUser succeeds even when remote profiles table throws full_name column missing PGRST204', () async {
      final client = MockFailingPostgrestClient();
      final repository = AdminRepository(client);

      final result = await repository.createUser(
        email: 'supervisor.site1@ibuild.com',
        password: 'Password123!',
        fullName: 'Vikram Singh',
        roleName: 'supervisor',
        customPermissions: ['attendance', 'snags'],
      );

      // Must succeed and NOT throw or return failure
      expect(result.success, isTrue);
      expect(result.message, contains('Vikram Singh'));
    });
  });
}
