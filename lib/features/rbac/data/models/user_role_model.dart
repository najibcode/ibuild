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
    Map<String, dynamic>? role;
    if (json['roles'] is Map<String, dynamic>) {
      role = json['roles'] as Map<String, dynamic>;
    } else if (json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      final first = (json['roles'] as List).first;
      if (first is Map<String, dynamic>) {
        role = first;
      }
    }

    return UserRole(
      userId: json['user_id'] as String? ?? '',
      roleId: json['role_id'] as String? ?? '',
      roleName: role?['name'] as String? ?? 'owner',
      roleDescription: role?['description'] as String?,
    );
  }

  bool get isAdmin => roleName == 'admin';
  bool get isOwner => roleName == 'owner';
  bool get isSupervisor => roleName == 'supervisor';
}
