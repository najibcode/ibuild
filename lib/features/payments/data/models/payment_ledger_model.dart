class PaymentLedgerEntry {
  final String id;
  final String projectId;
  final String counterpartyType; // 'Supplier', 'Trade Partner', 'Client', 'Other'
  final String? counterpartyId;
  final String counterpartyName;
  final String paymentType; // 'Paid' or 'Received'
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final double runningBalance;
  final String? remarks;
  final DateTime createdAt;

  PaymentLedgerEntry({
    required this.id,
    required this.projectId,
    required this.counterpartyType,
    this.counterpartyId,
    required this.counterpartyName,
    this.paymentType = 'Paid',
    required this.amount,
    this.paymentMethod = 'Bank Transfer',
    required this.paymentDate,
    this.runningBalance = 0.0,
    this.remarks,
    required this.createdAt,
  });

  factory PaymentLedgerEntry.fromJson(Map<String, dynamic> json) {
    return PaymentLedgerEntry(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      counterpartyType: json['counterparty_type'] as String? ?? 'Supplier',
      counterpartyId: json['counterparty_id'] as String?,
      counterpartyName: json['counterparty_name'] as String? ?? '',
      paymentType: json['payment_type'] as String? ?? 'Paid',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Bank Transfer',
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date'] as String) : DateTime.now(),
      runningBalance: (json['running_balance'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'counterparty_type': counterpartyType,
      'counterparty_id': counterpartyId,
      'counterparty_name': counterpartyName,
      'payment_type': paymentType,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String().split('T').first,
      'running_balance': runningBalance,
      'remarks': remarks,
    };
  }
}
