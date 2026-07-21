class UserRole {
  final String userId;
  final String roleId;
  final String roleName;
  final String? roleDescription;

  UserRole({
    required this.userId,
    required this.roleId,
    required this.roleName,
    this.roleDescription,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    final role = json['roles'] as Map<String, dynamic>?;
    return UserRole(
      userId: json['user_id'] as String,
      roleId: json['role_id'] as String,
      roleName: role?['name'] as String? ?? 'unknown',
      roleDescription: role?['description'] as String?,
    );
  }

  bool get isAdmin => roleName == 'admin';
  bool get isOwner => roleName == 'owner';
  bool get isSupervisor => roleName == 'supervisor';
}
