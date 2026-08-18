class AuditLogEntry {
  final String id;
  final String? actorId;
  final String actorName;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    this.actorId,
    required this.actorName,
    required this.action,
    required this.targetType,
    this.targetId,
    required this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String? ?? '',
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String? ?? 'System Admin',
      action: json['action'] as String? ?? 'general.action',
      targetType: json['target_type'] as String? ?? 'system',
      targetId: json['target_id'] as String?,
      details: json['details'] != null && json['details'] is Map
          ? Map<String, dynamic>.from(json['details'] as Map)
          : {},
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actor_id': actorId,
      'actor_name': actorName,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionTitle {
    switch (action) {
      case 'user.created':
        return 'User Account Created';
      case 'role.changed':
        return 'Role Assigned / Modified';
      case 'user.disabled':
        return 'User Access Disabled';
      case 'user.enabled':
        return 'User Access Enabled';
      case 'user.email_updated':
        return 'User Email Changed';
      case 'password.reset_by_admin':
        return 'Password Changed by Admin';
      case 'password.reset_email_sent':
        return 'Password Reset Email Dispatched';
      case 'settings.updated':
        return 'System Configuration Updated';
      case 'branding.updated':
        return 'Company Letterhead Updated';
      default:
        return action.replaceAll('.', ' ').toUpperCase();
    }
  }
}
