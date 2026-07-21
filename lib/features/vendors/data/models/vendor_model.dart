class Vendor {
  final String id;
  final String name;
  final String? companyName;
  final String? phone;
  final String? email;
  final String? gstNumber;
  final String? address;
  final String? category;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final bool isArchived;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.name,
    this.companyName,
    this.phone,
    this.email,
    this.gstNumber,
    this.address,
    this.category,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    required this.balanceDue,
    this.isArchived = false,
    required this.createdAt,
  });

  double get outstandingBalance => totalAmount > 0 ? (totalAmount - paidAmount) : balanceDue;
  bool get isOverpaid => paidAmount > totalAmount && totalAmount > 0;

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      companyName: json['company_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gstNumber: json['gst_number'] as String?,
      address: json['address'] as String?,
      category: json['category'] as String?,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0.0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'company_name': companyName,
      'phone': phone,
      'email': email,
      'gst_number': gstNumber,
      'address': address,
      'category': category,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_due': balanceDue,
      'is_archived': isArchived,
    };
  }

  Vendor copyWith({
    String? id,
    String? name,
    String? companyName,
    String? phone,
    String? email,
    String? gstNumber,
    String? address,
    String? category,
    double? totalAmount,
    double? paidAmount,
    double? balanceDue,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      category: category ?? this.category,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
