class Subcontractor {
  final String id;
  final String name;
  final String? specialization;
  final String? phone;
  final double contractValue;
  final double paidAmount;
  final String status;
  final DateTime createdAt;

  Subcontractor({
    required this.id,
    required this.name,
    this.specialization,
    this.phone,
    required this.contractValue,
    required this.paidAmount,
    required this.status,
    required this.createdAt,
  });

  factory Subcontractor.fromJson(Map<String, dynamic> json) {
    return Subcontractor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String?,
      phone: json['phone'] as String?,
      contractValue: (json['contract_value'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'phone': phone,
      'contract_value': contractValue,
      'paid_amount': paidAmount,
      'status': status,
    };
  }
}
