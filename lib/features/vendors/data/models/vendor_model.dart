class Vendor {
  final String id;
  final String name;
  final String? companyName;
  final String? phone;
  final String? email;
  final String? gstNumber;
  final String? address;
  final String? category;
  final double balanceDue;
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
    required this.balanceDue,
    required this.createdAt,
  });

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
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0.0,
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
      'balance_due': balanceDue,
    };
  }
}
