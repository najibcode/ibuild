class Property {
  final String id;
  final String propertyName;
  final String location;
  final String propertyType;
  final double amount;
  final String? remarks;
  final String? imageUrl;
  final String? agentName;
  final String? agentCompany;
  final String? agentMobile;
  final String status;
  final DateTime createdAt;

  Property({
    required this.id,
    required this.propertyName,
    required this.location,
    this.propertyType = 'Residential Plot',
    required this.amount,
    this.remarks,
    this.imageUrl,
    this.agentName,
    this.agentCompany,
    this.agentMobile,
    this.status = 'Available',
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String? ?? '',
      propertyName: json['property_name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      propertyType: json['property_type'] as String? ?? 'Residential Plot',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks'] as String?,
      imageUrl: json['image_url'] as String?,
      agentName: json['agent_name'] as String?,
      agentCompany: json['agent_company'] as String?,
      agentMobile: json['agent_mobile'] as String?,
      status: json['status'] as String? ?? 'Available',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_name': propertyName,
      'location': location,
      'property_type': propertyType,
      'amount': amount,
      'remarks': remarks,
      'image_url': imageUrl,
      'agent_name': agentName,
      'agent_company': agentCompany,
      'agent_mobile': agentMobile,
      'status': status,
    };
  }
}
