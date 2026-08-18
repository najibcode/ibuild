/// Centralized role-based avatar helper providing distinct, high-resolution
/// profile pictures tailored for each ERP operational role.
class RoleAvatarHelper {
  // Super Admin: Senior Tech Executive / Platform Lead
  static const String adminAvatar =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80';

  // Business Owner: Managing Director / Construction Enterprise Executive
  static const String ownerAvatar =
      'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&auto=format&fit=crop&q=80';

  // Site Supervisor: Field Civil Engineer with Safety Hard Hat on Site
  static const String supervisorAvatar =
      'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?w=400&auto=format&fit=crop&q=80';

  // Employee / General Site Staff: Construction Trades & Operations Staff
  static const String employeeAvatar =
      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&auto=format&fit=crop&q=80';

  // Default Universal Fallback Avatar
  static const String defaultFallbackAvatar = ownerAvatar;

  /// Returns the appropriate profile picture URL based on custom URL, role, or user email.
  static String getAvatarUrl({
    String? customAvatarUrl,
    String? role,
    String? email,
  }) {
    // 1. If custom avatar URL is provided and valid (not default placeholder), use it
    if (customAvatarUrl != null &&
        customAvatarUrl.trim().isNotEmpty &&
        !customAvatarUrl.contains('aida-public') &&
        !customAvatarUrl.contains('default_avatar')) {
      return customAvatarUrl.trim();
    }

    // 2. Infer role from explicit role parameter or email prefix
    final cleanRole = (role ?? '').trim().toLowerCase();
    final cleanEmail = (email ?? '').trim().toLowerCase();

    if (cleanRole == 'admin' || cleanRole == 'super_admin' || cleanEmail.startsWith('admin')) {
      return adminAvatar;
    }

    if (cleanRole == 'owner' || cleanRole == 'business_owner' || cleanEmail.startsWith('owner')) {
      return ownerAvatar;
    }

    if (cleanRole == 'supervisor' || cleanRole == 'site_supervisor' || cleanEmail.startsWith('supervisor')) {
      return supervisorAvatar;
    }

    if (cleanRole == 'employee' || cleanRole == 'staff' || cleanEmail.startsWith('employee')) {
      return employeeAvatar;
    }

    // 3. Fallback to default
    return defaultFallbackAvatar;
  }

  /// Returns the default avatar for a given role (used when user resets their avatar).
  static String getDefaultAvatarForRole(String? role) {
    final cleanRole = (role ?? '').trim().toLowerCase();
    switch (cleanRole) {
      case 'admin':
      case 'super_admin':
        return adminAvatar;
      case 'owner':
      case 'business_owner':
        return ownerAvatar;
      case 'supervisor':
      case 'site_supervisor':
        return supervisorAvatar;
      case 'employee':
      case 'staff':
        return employeeAvatar;
      default:
        return defaultFallbackAvatar;
    }
  }
}
