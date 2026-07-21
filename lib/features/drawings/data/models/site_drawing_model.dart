class SiteDrawing {
  final String id;
  final String projectId;
  final String title;
  final String category;
  final String version;
  final String fileUrl;
  final String? notes;
  final String? uploadedBy;
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
    };
  }
}
