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

  /// Returns a concise, user-friendly Employee ID (e.g. EMP-01, EMP-101, or EMP-A1B2)
  String get shortId {
    if (id.isEmpty) return 'EMP-01';
    if (RegExp(r'^EMP-?\d+$', caseSensitive: false).hasMatch(id)) {
      final numPart = id.replaceAll(RegExp(r'[^0-9]'), '');
      return 'EMP-$numPart';
    }
    final clean = id.replaceAll('-', '').replaceAll(RegExp(r'EMP', caseSensitive: false), '').toUpperCase();
    final code = clean.length > 4 ? clean.substring(0, 4) : clean;
    return 'EMP-$code';
  }

  // Earnings & Cost Calculations
  double calculateTotalEarnings(int daysPresent) => daysPresent * dailyRate;
  double calculateBaseEarnings(int daysPresent) => daysPresent * salary;
  double calculateTeaSnackCost(int daysPresent) => daysPresent * teaSnackAllowance;
  double calculateTotalEmployerCost(int daysPresent) => daysPresent * totalDailyCost;

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawSalary = json['salary'] ??
        json['daily_rate'] ??
        json['daily_wage'] ??
        json['wage'] ??
        json['rate'];
    final rawTea = json['tea_snack_allowance'] ??
        json['tea_allowance'] ??
        json['tea_snacks'] ??
        json['allowance'];

    return Employee(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? json['designation'] as String? ?? 'Labor',
      salary: (rawSalary as num?)?.toDouble() ?? 0.0,
      teaSnackAllowance: (rawTea as num?)?.toDouble() ?? 20.0,
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
      'daily_rate': salary,
      'tea_snack_allowance': teaSnackAllowance,
      'status': status,
      'photo_url': photoUrl,
    };
  }

  Map<String, dynamic> toMap() {
    final map = toJson();
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
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

