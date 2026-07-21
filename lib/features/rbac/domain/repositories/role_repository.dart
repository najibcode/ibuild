import 'package:ibuild/features/rbac/data/models/role_model.dart';
import 'package:ibuild/features/rbac/data/models/user_role_model.dart';

abstract class RoleRepository {
  /// Fetch the current user's role (joined with roles table).
  Future<UserRole?> fetchUserRole(String userId);

  /// Fetch all permission keys for a given role.
  Future<Set<String>> fetchPermissionsForRole(String roleId);

  /// Fetch all available roles (for admin user management).
  Future<List<Role>> fetchAllRoles();

  /// Assign a role to a user. Replaces existing role if any.
  Future<void> assignRole(String userId, String roleId);

  /// Remove a user's role assignment.
  Future<void> removeRole(String userId);
}
