class SiteDrawing {
  final String id;
  final String projectId;
  final String title;
  final String category;
  final String version;
  final String fileUrl;
  final String? notes;
  final String? uploadedBy;
  final bool isArchived;
  final int fileSizeBytes;
  final DateTime createdAt;

  SiteDrawing({
    required this.id,
    required this.projectId,
    required this.title,
    required this.category,
    required this.version,
    required this.fileUrl,
    this.notes,
    this.uploadedBy,
    this.isArchived = false,
    this.fileSizeBytes = 0,
    required this.createdAt,
  });

  factory SiteDrawing.fromJson(Map<String, dynamic> json) {
    return SiteDrawing(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Architectural',
      version: json['version'] as String? ?? 'v1.0',
      fileUrl: json['file_url'] as String? ?? '',
      notes: json['notes'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'category': category,
      'version': version,
      'file_url': fileUrl,
      'notes': notes,
      'uploaded_by': uploadedBy,
      'is_archived': isArchived,
      'file_size_bytes': fileSizeBytes,
    };
  }

  SiteDrawing copyWith({
    String? id,
    String? projectId,
    String? title,
    String? category,
    String? version,
    String? fileUrl,
    String? notes,
    String? uploadedBy,
    bool? isArchived,
    int? fileSizeBytes,
    DateTime? createdAt,
  }) {
    return SiteDrawing(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      category: category ?? this.category,
      version: version ?? this.version,
      fileUrl: fileUrl ?? this.fileUrl,
      notes: notes ?? this.notes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isArchived: isArchived ?? this.isArchived,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
