class Bill {
  final String id;
  final String projectId;
  final String? projectName;
  final String billNumber;
  final String billDate;
  final double amount;
  final String status; // pending, paid, overdue, cancelled
  final String? notes;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  Bill({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.billNumber,
    required this.billDate,
    required this.amount,
    required this.status,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      projectName: json['projects']?['name'] as String?,
      billNumber: json['bill_number'] as String,
      billDate: json['bill_date'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'bill_number': billNumber,
      'bill_date': billDate,
      'amount': amount,
      'status': status,
      'notes': notes,
    };
  }

  Bill copyWith({
    String? projectId,
    String? projectName,
    String? billNumber,
    String? billDate,
    double? amount,
    String? status,
    String? notes,
  }) {
    return Bill(
      id: id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      billNumber: billNumber ?? this.billNumber,
      billDate: billDate ?? this.billDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
