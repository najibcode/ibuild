class Activity {
  final String id;
  final String? userId;
  final String actionType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final String? userName; // Joined from profiles/auth for display

  Activity({
    required this.id,
    this.userId,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    this.details = const {},
    required this.createdAt,
    this.userName,
  });

  factory Activity.fromJson(Map<String, dynamic> json, {String? userName}) {
    final actType = json['action_type'] as String? ?? json['action'] as String? ?? 'SYSTEM_EVENT';
    final entType = json['entity_type'] as String? ?? json['target_type'] as String? ?? 'SYSTEM';
    final entId = json['entity_id'] as String? ?? json['target_id'] as String? ?? '';
    final uName = userName ?? json['actor_name'] as String?;
    final dateStr = json['created_at'] as String? ?? DateTime.now().toIso8601String();

    Map<String, dynamic> det = {};
    if (json['details'] is Map<String, dynamic>) {
      det = json['details'] as Map<String, dynamic>;
    }

    return Activity(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      userId: json['user_id'] as String? ?? json['actor_id'] as String?,
      actionType: actType,
      entityType: entType,
      entityId: entId,
      details: det,
      createdAt: DateTime.tryParse(dateStr) ?? DateTime.now(),
      userName: uName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
    };
  }
}
