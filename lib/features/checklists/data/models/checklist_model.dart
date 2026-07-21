class ChecklistItem {
  final String id;
  final String projectId;
  final String title;
  final String category;
  final String phaseGroup; // Foundation, Superstructure, MEP, Finishing, Safety, Handover
  final bool isCompleted;
  final DateTime? dueDate;
  final String? assignedPerson;
  final String? evidenceImageUrl;
  final String? notes;
  final String approvalStatus; // Not Started, In Progress, Submitted, Approved, Rejected, Blocked
  final DateTime createdAt;

  ChecklistItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.category = 'General Inspection',
    this.phaseGroup = 'Foundation',
    this.isCompleted = false,
    this.dueDate,
    this.assignedPerson,
    this.evidenceImageUrl,
    this.notes,
    this.approvalStatus = 'Not Started',
    required this.createdAt,
  });

  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isCompleted;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'General Inspection',
      phaseGroup: json['phase_group'] as String? ?? 'Foundation',
      isCompleted: json['is_completed'] as bool? ?? false,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      assignedPerson: json['assigned_person'] as String?,
      evidenceImageUrl: json['evidence_image_url'] as String?,
      notes: json['notes'] as String?,
      approvalStatus: json['approval_status'] as String? ?? (json['is_completed'] == true ? 'Approved' : 'Not Started'),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'category': category,
      'phase_group': phaseGroup,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'assigned_person': assignedPerson,
      'evidence_image_url': evidenceImageUrl,
      'notes': notes,
      'approval_status': approvalStatus,
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? projectId,
    String? title,
    String? category,
    String? phaseGroup,
    bool? isCompleted,
    DateTime? dueDate,
    String? assignedPerson,
    String? evidenceImageUrl,
    String? notes,
    String? approvalStatus,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      category: category ?? this.category,
      phaseGroup: phaseGroup ?? this.phaseGroup,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      assignedPerson: assignedPerson ?? this.assignedPerson,
      evidenceImageUrl: evidenceImageUrl ?? this.evidenceImageUrl,
      notes: notes ?? this.notes,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
