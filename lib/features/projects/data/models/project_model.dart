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

  // Extended Site-Centered Attributes (IBUILD Specifications)
  final double builtUpArea;
  final double flatArea;
  final String? duration;
  final String? customerName;
  final String? customerMobile;
  final String? customerEmail;
  final String? customerDob;
  final String? customerAddress;
  final String? imageUrl;

  // Operational & Activity Attributes
  final double? physicalProgress;
  final DateTime? lastUpdatedDate;
  final String? lastUpdatedBy;

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
    this.builtUpArea = 0.0,
    this.flatArea = 0.0,
    this.duration,
    this.customerName,
    this.customerMobile,
    this.customerEmail,
    this.customerDob,
    this.customerAddress,
    this.imageUrl,
    this.physicalProgress,
    this.lastUpdatedDate,
    this.lastUpdatedBy,
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
      builtUpArea: (json['built_up_area'] as num?)?.toDouble() ?? 0.0,
      flatArea: (json['flat_area'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as String?,
      customerName: json['customer_name'] as String?,
      customerMobile: json['customer_mobile'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerDob: json['customer_dob'] as String?,
      customerAddress: json['customer_address'] as String?,
      imageUrl: json['image_url'] as String?,
      physicalProgress: (json['physical_progress'] as num?)?.toDouble(),
      lastUpdatedDate: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      lastUpdatedBy:
          json['updated_by_name'] as String? ?? json['updated_by'] as String?,
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
      'built_up_area': builtUpArea,
      'flat_area': flatArea,
      'duration': duration,
      'customer_name': customerName,
      'customer_mobile': customerMobile,
      'customer_email': customerEmail,
      'customer_dob': customerDob,
      'customer_address': customerAddress,
      'image_url': imageUrl,
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
    double? builtUpArea,
    double? flatArea,
    String? duration,
    String? customerName,
    String? customerMobile,
    String? customerEmail,
    String? customerDob,
    String? customerAddress,
    String? imageUrl,
    double? physicalProgress,
    DateTime? lastUpdatedDate,
    String? lastUpdatedBy,
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
      builtUpArea: builtUpArea ?? this.builtUpArea,
      flatArea: flatArea ?? this.flatArea,
      duration: duration ?? this.duration,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      customerEmail: customerEmail ?? this.customerEmail,
      customerDob: customerDob ?? this.customerDob,
      customerAddress: customerAddress ?? this.customerAddress,
      imageUrl: imageUrl ?? this.imageUrl,
      physicalProgress: physicalProgress ?? this.physicalProgress,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
    );
  }

  double get budgetUtilization =>
      budget > 0 ? (spent / budget).clamp(0.0, 2.0) : 0.0;
  double get remainingBalance => budget - spent;

  double get computedProgress {
    if (physicalProgress != null) return physicalProgress!.clamp(0.0, 100.0);
    if (status == 'completed') return 100.0;
    if (budget > 0) return (spent / budget * 100).clamp(0.0, 100.0);
    return 0.0;
  }

  DateTime? get targetDueDate {
    final str = expectedCompletion ?? deadline;
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  bool get isOverdue {
    if (status == 'completed') return false;
    final due = targetDueDate;
    if (due == null) return false;
    final today = DateTime.now();
    final todayTruncated = DateTime(today.year, today.month, today.day);
    final dueTruncated = DateTime(due.year, due.month, due.day);
    return todayTruncated.isAfter(dueTruncated);
  }

  bool get isAtRisk {
    if (status == 'at_risk' || status == 'delayed') return true;
    if (isOverdue) return true;
    final budgetUsedPct = budget > 0 ? (spent / budget * 100) : 0.0;
    final variance = budgetUsedPct - computedProgress;
    return variance > 15.0;
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    final due = targetDueDate;
    if (due == null) return 0;
    return DateTime.now().difference(due).inDays;
  }

  String get formattedDueDate {
    final due = targetDueDate;
    if (due == null) return 'Not set';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${due.day} ${months[due.month - 1]} ${due.year}';
  }

  String get formattedLastUpdated {
    if (lastUpdatedDate == null) return 'Recently';
    final dt = lastUpdatedDate!;
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes.clamp(1, 59);
      return '${mins}m ago';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minStr = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minStr $amPm';
    } else if (diff.inDays < 2) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    }
  }
}
