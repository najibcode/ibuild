class AdminUserEntry {
  final String userId;
  final String email;
  final String fullName;
  final String phone;
  final String companyName;
  final String? avatarUrl;
  final String roleName;
  final String roleId;
  final bool isDisabled;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  AdminUserEntry({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.companyName,
    this.avatarUrl,
    required this.roleName,
    required this.roleId,
    required this.isDisabled,
    this.createdAt,
    this.lastSignInAt,
  });

  factory AdminUserEntry.fromMap({
    required Map<String, dynamic> profileMap,
    Map<String, dynamic>? userRoleMap,
    Map<String, dynamic>? authUserMap,
  }) {
    final userId = profileMap['id'] as String? ?? authUserMap?['id'] as String? ?? '';
    final roleObj = userRoleMap?['roles'] as Map<String, dynamic>?;
    final roleName = roleObj?['name'] as String? ?? profileMap['role_display'] as String? ?? 'employee';
    final roleId = userRoleMap?['role_id'] as String? ?? '';

    final email = authUserMap?['email'] as String? ??
        (profileMap['email'] as String?) ??
        (userId.length > 8 ? '$userId@ibuild.in' : 'user@ibuild.in');

    final fullName = profileMap['full_name'] as String? ??
        authUserMap?['user_metadata']?['full_name'] as String? ??
        (email.contains('@') ? email.split('@').first : 'User');

    final phone = profileMap['phone'] as String? ?? '';
    final companyName = profileMap['company_name'] as String? ?? 'IBUILD';
    final avatarUrl = profileMap['avatar_url'] as String?;
    final isDisabled = profileMap['is_disabled'] as bool? ?? false;

    DateTime? createdAt;
    if (profileMap['created_at'] != null) {
      createdAt = DateTime.tryParse(profileMap['created_at'].toString());
    } else if (authUserMap?['created_at'] != null) {
      createdAt = DateTime.tryParse(authUserMap!['created_at'].toString());
    }

    DateTime? lastSignInAt;
    if (authUserMap?['last_sign_in_at'] != null) {
      lastSignInAt = DateTime.tryParse(authUserMap!['last_sign_in_at'].toString());
    }

    return AdminUserEntry(
      userId: userId,
      email: email,
      fullName: fullName,
      phone: phone,
      companyName: companyName,
      avatarUrl: avatarUrl,
      roleName: roleName.toLowerCase(),
      roleId: roleId,
      isDisabled: isDisabled,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt,
    );
  }

  AdminUserEntry copyWith({
    String? email,
    String? fullName,
    String? phone,
    String? companyName,
    String? avatarUrl,
    String? roleName,
    String? roleId,
    bool? isDisabled,
  }) {
    return AdminUserEntry(
      userId: userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roleName: roleName ?? this.roleName,
      roleId: roleId ?? this.roleId,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt,
    );
  }
}
