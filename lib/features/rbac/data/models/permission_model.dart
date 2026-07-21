class Permission {
  final String id;
  final String key;       // e.g. 'employee.create'
  final String? description;
  final String module;    // e.g. 'employee'
  final String? createdAt;

  Permission({
    required this.id,
    required this.key,
    this.description,
    required this.module,
    this.createdAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as String,
      key: json['key'] as String,
      description: json['description'] as String?,
      module: json['module'] as String,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'description': description,
      'module': module,
    };
  }
}
