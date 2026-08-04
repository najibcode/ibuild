class AppImage {
  final String id;
  final String fileId;
  final String imageUrl;
  final String imagePath;
  final String folder;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? projectId;
  final String? employeeId;
  final String? inventoryId;
  final String? billId;

  const AppImage({
    required this.id,
    required this.fileId,
    required this.imageUrl,
    required this.imagePath,
    required this.folder,
    this.uploadedBy,
    required this.uploadedAt,
    this.projectId,
    this.employeeId,
    this.inventoryId,
    this.billId,
  });

  factory AppImage.fromJson(Map<String, dynamic> json) {
    return AppImage(
      id: json['id'] as String,
      fileId: json['file_id'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      imagePath: json['image_path'] as String? ?? '',
      folder: json['folder'] as String? ?? 'general',
      uploadedBy: json['uploaded_by'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : DateTime.now(),
      projectId: json['project_id'] as String?,
      employeeId: json['employee_id'] as String?,
      inventoryId: json['inventory_id'] as String?,
      billId: json['bill_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_id': fileId,
      'image_url': imageUrl,
      'image_path': imagePath,
      'folder': folder,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
      if (projectId != null) 'project_id': projectId,
      if (employeeId != null) 'employee_id': employeeId,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (billId != null) 'bill_id': billId,
    };
  }
}

/// Enumeration of all system ImageKit folder paths
enum ImageFolder {
  employeesProfile('employees/profile'),
  projectsSiteProgress('projects/site-progress'),
  projectsDocuments('projects/documents'),
  projectsBefore('projects/before'),
  projectsAfter('projects/after'),
  inventory('inventory'),
  bills('bills'),
  reports('reports'),
  company('company'),
  settings('settings');

  final String path;
  const ImageFolder(this.path);
}
