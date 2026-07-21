class ProjectPayment {
  final String id;
  final String projectId;
  final String title;
  final String paymentType; // 'Received' or 'Paid'
  final double amount;
  final String paymentMethod;
  final String? referenceNo;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  ProjectPayment({
    required this.id,
    required this.projectId,
    required this.title,
    this.paymentType = 'Received',
    required this.amount,
    this.paymentMethod = 'Bank Transfer',
    this.referenceNo,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
  });

  factory ProjectPayment.fromJson(Map<String, dynamic> json) {
    return ProjectPayment(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      paymentType: json['payment_type'] as String? ?? 'Received',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Bank Transfer',
      referenceNo: json['reference_no'] as String?,
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date'] as String) : DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'title': title,
      'payment_type': paymentType,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference_no': referenceNo,
      'payment_date': paymentDate.toIso8601String().split('T').first,
      'notes': notes,
    };
  }
}
