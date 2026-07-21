class Role {
  final String id;
  final String name;
  final String? description;
  final String? createdAt;

  Role({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }

  bool get isAdmin => name == 'admin';
  bool get isOwner => name == 'owner';
  bool get isSupervisor => name == 'supervisor';
}
