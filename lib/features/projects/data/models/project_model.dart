class Project {
  final String id;
  final String name;
  final String? clientName;
  final String? projectCode;
  final String? address;
  final double budget;
  final double estimatedCost;
  final double currentCost;
  final double spent;
  final String status; // planning, active, completed, delayed
  final String? startDate;
  final String? expectedCompletion;
  final String? supervisorId;
  final String? notes;
  final String? description;
  final bool isArchived;
  final String? deadline;
  final String? createdAt;

  Project({
    required this.id,
    required this.name,
    this.clientName,
    this.projectCode,
    this.address,
    required this.budget,
    this.estimatedCost = 0.0,
    this.currentCost = 0.0,
    this.spent = 0.0,
    required this.status,
    this.startDate,
    this.expectedCompletion,
    this.supervisorId,
    this.notes,
    this.description,
    this.isArchived = false,
    this.deadline,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      clientName: json['client_name'] as String?,
      projectCode: json['project_code'] as String?,
      address: json['address'] as String?,
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      currentCost: (json['current_cost'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'planning',
      startDate: json['start_date'] as String?,
      expectedCompletion: json['expected_completion'] as String?,
      supervisorId: json['supervisor_id'] as String?,
      notes: json['notes'] as String?,
      description: json['description'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      deadline: json['deadline'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'client_name': clientName,
      'project_code': projectCode,
      'address': address,
      'budget': budget,
      'estimated_cost': estimatedCost,
      'current_cost': currentCost,
      'spent': spent,
      'status': status,
      'start_date': startDate,
      'expected_completion': expectedCompletion,
      'supervisor_id': supervisorId,
      'notes': notes,
      'description': description,
      'is_archived': isArchived,
      'deadline': deadline,
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? clientName,
    String? projectCode,
    String? address,
    double? budget,
    double? estimatedCost,
    double? currentCost,
    double? spent,
    String? status,
    String? startDate,
    String? expectedCompletion,
    String? supervisorId,
    String? notes,
    String? description,
    bool? isArchived,
    String? deadline,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      projectCode: projectCode ?? this.projectCode,
      address: address ?? this.address,
      budget: budget ?? this.budget,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      currentCost: currentCost ?? this.currentCost,
      spent: spent ?? this.spent,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      expectedCompletion: expectedCompletion ?? this.expectedCompletion,
      supervisorId: supervisorId ?? this.supervisorId,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      deadline: deadline ?? this.deadline,
    );
  }

  double get budgetUtilization => budget > 0 ? (spent / budget).clamp(0.0, 2.0) : 0.0;
}
