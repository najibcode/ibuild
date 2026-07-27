class EquipmentItem {
  final String id;
  final String name;
  final String category;
  final String tagNumber;
  final String siteName;
  final String? projectId;
  final String status; // Operational, In Use, Maintenance, Idle
  final double rentalCostPerDay;
  final double fuelConsumptionLitersPerDay;
  final String? notes; // Storage / usage notes (e.g. Lorry tool box, 12ft aluminum ladder)
  final DateTime createdAt;

  EquipmentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.tagNumber,
    required this.siteName,
    this.projectId,
    required this.status,
    required this.rentalCostPerDay,
    required this.fuelConsumptionLitersPerDay,
    this.notes,
    required this.createdAt,
  });

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      tagNumber: json['tag_number'] as String? ?? json['tagNumber'] as String? ?? 'EQ-000',
      siteName: json['site_name'] as String? ?? json['siteName'] as String? ?? 'Main Site',
      projectId: json['project_id'] as String?,
      status: json['status'] as String? ?? 'Operational',
      rentalCostPerDay: (json['rental_cost_per_day'] as num?)?.toDouble() ??
          (json['rentalCostPerDay'] as num?)?.toDouble() ??
          0.0,
      fuelConsumptionLitersPerDay: (json['fuel_consumption_liters_per_day'] as num?)?.toDouble() ??
          (json['fuelConsumptionLitersPerDay'] as num?)?.toDouble() ??
          0.0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'category': category,
      'tag_number': tagNumber,
      'site_name': siteName,
      if (projectId != null && projectId!.isNotEmpty) 'project_id': projectId,
      'status': status,
      'rental_cost_per_day': rentalCostPerDay,
      'fuel_consumption_liters_per_day': fuelConsumptionLitersPerDay,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  EquipmentItem copyWith({
    String? id,
    String? name,
    String? category,
    String? tagNumber,
    String? siteName,
    String? projectId,
    String? status,
    double? rentalCostPerDay,
    double? fuelConsumptionLitersPerDay,
    String? notes,
    DateTime? createdAt,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      tagNumber: tagNumber ?? this.tagNumber,
      siteName: siteName ?? this.siteName,
      projectId: projectId ?? this.projectId,
      status: status ?? this.status,
      rentalCostPerDay: rentalCostPerDay ?? this.rentalCostPerDay,
      fuelConsumptionLitersPerDay: fuelConsumptionLitersPerDay ?? this.fuelConsumptionLitersPerDay,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

