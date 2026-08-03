class Subcontractor {
  final String id;
  final String name;
  final String? companyNameProp;
  final String? contactPersonProp;
  final String? specialization;
  final String? phone;
  final String? email;
  final String? address;
  final String? siteNameProp;
  final String? gstNumber;
  final double contractValue;
  final double paidAmount;
  final String status;
  final bool isArchived;
  final DateTime createdAt;

  Subcontractor({
    required this.id,
    required this.name,
    this.companyNameProp,
    this.contactPersonProp,
    this.specialization,
    this.phone,
    this.email,
    this.address,
    this.siteNameProp,
    this.gstNumber,
    required this.contractValue,
    required this.paidAmount,
    required this.status,
    this.isArchived = false,
    required this.createdAt,
  });

  String get companyName => (companyNameProp != null && companyNameProp!.isNotEmpty) ? companyNameProp! : name;
  String get contactPerson => (contactPersonProp != null && contactPersonProp!.isNotEmpty) ? contactPersonProp! : name;
  String get tradeSpecialization => specialization ?? 'General Contracting';
  String get siteName => siteNameProp ?? 'Active Construction Sites';
  double get contractAmount => contractValue;
  double get retentionPending => contractValue > paidAmount ? (contractValue - paidAmount) : 0.0;
  double get outstandingAmount => contractValue > paidAmount ? (contractValue - paidAmount) : 0.0;
  bool get isOverpaid => paidAmount > contractValue && contractValue > 0;

  factory Subcontractor.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? json['company_name'] as String? ?? '';
    return Subcontractor(
      id: json['id'] as String? ?? '',
      name: rawName,
      companyNameProp: json['company_name'] as String? ?? rawName,
      contactPersonProp: json['contact_person'] as String? ?? json['contactPerson'] as String? ?? rawName,
      specialization: json['specialization'] as String? ?? json['trade_specialization'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      siteNameProp: json['site_name'] as String? ?? json['siteName'] as String?,
      gstNumber: json['gst_number'] as String?,
      contractValue: (json['contract_value'] as num?)?.toDouble() ??
          (json['contractAmount'] as num?)?.toDouble() ??
          0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ??
          (json['paidAmount'] as num?)?.toDouble() ??
          0.0,
      status: json['status'] as String? ?? 'Active',
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Produce payload strictly matching physical Supabase `subcontractors` table columns
  Map<String, dynamic> toDbJson() {
    final map = <String, dynamic>{
      'name': companyName,
      'specialization': tradeSpecialization,
      'phone': phone,
      'email': email,
      'address': address,
      'gst_number': gstNumber,
      'contract_value': contractValue,
      'paid_amount': paidAmount,
      'status': status,
      'is_archived': isArchived,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Map<String, dynamic> toJson() => toDbJson();

  Subcontractor copyWith({
    String? id,
    String? name,
    String? companyNameProp,
    String? contactPersonProp,
    String? specialization,
    String? phone,
    String? email,
    String? address,
    String? siteNameProp,
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
      companyNameProp: companyNameProp ?? this.companyNameProp,
      contactPersonProp: contactPersonProp ?? this.contactPersonProp,
      specialization: specialization ?? this.specialization,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      siteNameProp: siteNameProp ?? this.siteNameProp,
      gstNumber: gstNumber ?? this.gstNumber,
      contractValue: contractValue ?? this.contractValue,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
