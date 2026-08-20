class Subcontractor {
  final String id;
  final String name;
  final String? companyNameProp;
  final String? contactPersonProp;
  final String? specialization;
  final String? phone;
  final String? email;
  final String? address;
  final String? projectId;
  final String? siteNameProp;
  final String? scopeOfWork;
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
    this.projectId,
    this.siteNameProp,
    this.scopeOfWork,
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
  String get siteName => (siteNameProp != null && siteNameProp!.isNotEmpty) ? siteNameProp! : 'Unassigned';
  double get contractAmount => contractValue;
  double get retentionPending => contractValue > paidAmount ? (contractValue - paidAmount) : 0.0;
  double get outstandingAmount => contractValue > paidAmount ? (contractValue - paidAmount) : 0.0;
  bool get isOverpaid => paidAmount > contractValue && contractValue > 0;
  double get paymentProgress => contractValue > 0 ? (paidAmount / contractValue).clamp(0.0, 1.0) : 0.0;

  factory Subcontractor.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? json['company_name'] as String? ?? '';
    final pName = (json['projects'] as Map?)?['name'] as String? ?? json['site_name'] as String? ?? json['siteName'] as String?;

    return Subcontractor(
      id: json['id'] as String? ?? '',
      name: rawName,
      companyNameProp: json['company_name'] as String? ?? rawName,
      contactPersonProp: json['contact_person'] as String? ?? json['contactPerson'] as String? ?? rawName,
      specialization: json['specialization'] as String? ?? json['trade_specialization'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      projectId: json['project_id'] as String?,
      siteNameProp: pName,
      scopeOfWork: json['scope_of_work'] as String?,
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
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'project_id': (projectId != null && projectId!.isNotEmpty) ? projectId : null,
      'site_name': siteNameProp,
      'scope_of_work': scopeOfWork,
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
    String? projectId,
    String? siteNameProp,
    String? scopeOfWork,
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
      projectId: projectId ?? this.projectId,
      siteNameProp: siteNameProp ?? this.siteNameProp,
      scopeOfWork: scopeOfWork ?? this.scopeOfWork,
      gstNumber: gstNumber ?? this.gstNumber,
      contractValue: contractValue ?? this.contractValue,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
