class ChecklistItem {
  final String id;
  final String projectId;
  final String title;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;

  ChecklistItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.category = 'General Inspection',
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'General Inspection',
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'category': category,
      'is_completed': isCompleted,
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? projectId,
    String? title,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
