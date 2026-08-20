import 'erp_function_model.dart';

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
  final List<String> customPermissions;
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
    this.customPermissions = const [],
    this.createdAt,
    this.lastSignInAt,
  });

  /// Inferred or assigned operational function keys for this user.
  List<String> get activeFunctionKeys {
    if (customPermissions.isNotEmpty) {
      return ErpFunctionRegistry.permissionsToFunctionKeys(customPermissions);
    }
    return ErpFunctionRegistry.getDefaultFunctionKeysForRole(roleName);
  }

  /// List of ErpFunctionItem objects currently assigned to this user.
  List<ErpFunctionItem> get activeFunctionItems {
    final keys = activeFunctionKeys;
    return keys
        .map((k) => ErpFunctionRegistry.functionMap[k])
        .whereType<ErpFunctionItem>()
        .toList();
  }

  factory AdminUserEntry.fromMap({
    required Map<String, dynamic> profileMap,
    Map<String, dynamic>? userRoleMap,
    Map<String, dynamic>? authUserMap,
  }) {
    final userId = profileMap['id'] as String? ?? authUserMap?['id'] as String? ?? '';
    final roleObj = userRoleMap?['roles'] as Map<String, dynamic>?;
    final email = authUserMap?['email'] as String? ??
        (profileMap['email'] as String?) ??
        (userId.length > 8 ? '$userId@ibuild.in' : 'user@ibuild.in');

    String roleName = roleObj?['name'] as String? ?? profileMap['role_display'] as String? ?? '';
    if (roleName.isEmpty) {
      final cleanEmail = email.toLowerCase();
      if (cleanEmail.contains('admin')) {
        roleName = 'admin';
      } else if (cleanEmail.contains('owner')) {
        roleName = 'owner';
      } else if (cleanEmail.contains('supervisor')) {
        roleName = 'supervisor';
      } else {
        roleName = 'employee';
      }
    }

    final roleId = userRoleMap?['role_id'] as String? ?? '';

    final fullName = profileMap['full_name'] as String? ??
        authUserMap?['user_metadata']?['full_name'] as String? ??
        (email.contains('@') ? email.split('@').first : 'User');

    final phone = profileMap['phone'] as String? ?? '';
    final companyName = profileMap['company_name'] as String? ?? 'IBUILD';
    final avatarUrl = profileMap['avatar_url'] as String?;
    final isDisabled = profileMap['is_disabled'] as bool? ?? false;

    final customPermsRaw = profileMap['custom_permissions'] ?? profileMap['permissions'];
    final List<String> customPermissions = customPermsRaw is List
        ? List<String>.from(customPermsRaw.map((e) => e.toString()))
        : [];

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
      customPermissions: customPermissions,
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
    List<String>? customPermissions,
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
      customPermissions: customPermissions ?? this.customPermissions,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt,
    );
  }
}
