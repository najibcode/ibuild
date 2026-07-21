class SalesBill {
  final String id;
  final String projectId;
  final String billNumber;
  final String clientName;
  final double amount;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;

  SalesBill({
    required this.id,
    required this.projectId,
    required this.billNumber,
    required this.clientName,
    required this.amount,
    this.taxAmount = 0.0,
    required this.totalAmount,
    this.status = 'Unpaid',
    this.dueDate,
    required this.createdAt,
  });

  factory SalesBill.fromJson(Map<String, dynamic> json) {
    return SalesBill(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      billNumber: json['bill_number'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Unpaid',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'bill_number': billNumber,
      'client_name': clientName,
      'amount': amount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
    };
  }
}
