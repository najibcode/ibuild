class Subcontractor {
  final String id;
  final String name;
  final String? specialization;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final double contractValue;
  final double paidAmount;
  final String status;
  final bool isArchived;
  final DateTime createdAt;

  Subcontractor({
    required this.id,
    required this.name,
    this.specialization,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    required this.contractValue,
    required this.paidAmount,
    required this.status,
    this.isArchived = false,
    required this.createdAt,
  });

  double get outstandingAmount => contractValue > paidAmount ? (contractValue - paidAmount) : 0.0;
  bool get isOverpaid => paidAmount > contractValue && contractValue > 0;

  factory Subcontractor.fromJson(Map<String, dynamic> json) {
    return Subcontractor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      specialization: json['specialization'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstNumber: json['gst_number'] as String?,
      contractValue: (json['contract_value'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Active',
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'phone': phone,
      'email': email,
      'address': address,
      'gst_number': gstNumber,
      'contract_value': contractValue,
      'paid_amount': paidAmount,
      'status': status,
      'is_archived': isArchived,
    };
  }

  Subcontractor copyWith({
    String? id,
    String? name,
    String? specialization,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    double? contractValue,
    double? paidAmount,
    String? status,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Subcontractor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      contractValue: contractValue ?? this.contractValue,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
