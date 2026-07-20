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
    return Activity(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      actionType: json['action_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      details: json['details'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: userName,
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
