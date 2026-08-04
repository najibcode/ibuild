class Employee {
  final String id;
  final String name;
  final String phone;
  final String role;
  final double salary; // Base Daily Rate in ₹/day
  final double teaSnackAllowance; // Daily Tea & Snacks budget in ₹/day
  final String status;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.salary,
    this.teaSnackAllowance = 20.0,
    required this.status,
    this.photoUrl,
  });

  // Daily Wage & Tea Allowance Getters
  double get dailyRate => salary;
  double get effectiveTeaSnackAllowance => teaSnackAllowance;
  double get totalDailyCost => salary + teaSnackAllowance;

  /// Returns a concise, user-friendly Employee ID (e.g. EMP-101 or EMP-A1B2C3)
  String get shortId {
    if (id.isEmpty) return 'EMP-000';
    final cleanId = id.replaceAll('-', '').toUpperCase();
    if (cleanId.startsWith('EMP')) {
      final code = cleanId.substring(3);
      return code.length > 6 ? 'EMP-${code.substring(0, 6)}' : 'EMP-$code';
    }
    return cleanId.length >= 6
        ? 'EMP-${cleanId.substring(0, 6)}'
        : 'EMP-$cleanId';
  }

  // Earnings & Cost Calculations
  double calculateTotalEarnings(int daysPresent) => daysPresent * dailyRate;
  double calculateBaseEarnings(int daysPresent) => daysPresent * salary;
  double calculateTeaSnackCost(int daysPresent) => daysPresent * teaSnackAllowance;
  double calculateTotalEmployerCost(int daysPresent) => daysPresent * totalDailyCost;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'Labor',
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      teaSnackAllowance: (json['tea_snack_allowance'] as num?)?.toDouble() ?? 20.0,
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
      'tea_snack_allowance': teaSnackAllowance,
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
    double? teaSnackAllowance,
    String? status,
    String? photoUrl,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      teaSnackAllowance: teaSnackAllowance ?? this.teaSnackAllowance,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

