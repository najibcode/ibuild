class Employee {
  final String id;
  final String name;
  final String phone;
  final String role;
  final double salary; // Daily Rate in ₹/day
  final String status;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.salary,
    required this.status,
    this.photoUrl,
  });

  // Daily Wage getters
  double get dailyRate => salary;
  double calculateTotalEarnings(int daysPresent) => daysPresent * dailyRate;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'Labor',
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'salary': salary,
      'status': status,
      'photo_url': photoUrl,
    };
  }

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    double? salary,
    String? status,
    String? photoUrl,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
