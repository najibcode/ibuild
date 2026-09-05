class Attendance {
  final String id;
  final String employeeId;
  final String date;
  final String status; // Present or Absent (app-side unified view)
  final String? projectId; // UI-only: kept in memory for site assignment display
  final String? employeeName;
  final String? projectName;
  final double? wageRate; // Historical daily wage rate snapshot at the time of attendance
  final double? teaAllowance; // Historical daily tea allowance snapshot

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.projectId,
    this.employeeName,
    this.projectName,
    this.wageRate,
    this.teaAllowance,
  });

  // Backward compatibility getters
  String get morningStatus => status;
  String get eveningStatus => status;

  factory Attendance.fromJson(Map<String, dynamic> json, {String? employeeName, String? projectName}) {
    // The actual DB columns are morning_status / evening_status (NOT "status")
    final rawStatus = json['morning_status'] as String?
        ?? json['status'] as String?
        ?? 'Absent';
    final normalizedStatus = (rawStatus.toLowerCase() == 'present') ? 'Present' : 'Absent';
    final pName = projectName ?? (json['projects'] as Map?)?['name'] as String? ?? json['project_name'] as String?;

    final wage = (json['wage_rate'] as num?)?.toDouble()
        ?? (json['daily_rate'] as num?)?.toDouble()
        ?? (json['salary'] as num?)?.toDouble();

    final tea = (json['tea_allowance'] as num?)?.toDouble()
        ?? (json['tea_snack_allowance'] as num?)?.toDouble();

    return Attendance(
      id: json['id'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: normalizedStatus,
      projectId: json['project_id'] as String?,
      employeeName: employeeName ?? json['employee_name'] as String?,
      projectName: pName,
      wageRate: wage,
      teaAllowance: tea,
    );
  }

  /// Produce the JSON payload for Supabase insert/update.
  Map<String, dynamic> toJson() {
    final lowerStatus = status.toLowerCase() == 'present' ? 'present' : 'absent';
    final capitalizedStatus = status.toLowerCase() == 'present' ? 'Present' : 'Absent';
    final map = <String, dynamic>{
      'employee_id': employeeId,
      'date': date,
      'status': capitalizedStatus,
      'morning_status': lowerStatus,
      'evening_status': lowerStatus,
      'afternoon_status': lowerStatus,
      'project_id': (projectId != null && projectId!.isNotEmpty) ? projectId : null,
    };
    if (wageRate != null) {
      map['wage_rate'] = wageRate;
    }
    if (teaAllowance != null) {
      map['tea_allowance'] = teaAllowance;
    }
    return map;
  }

  /// Minimal update payload (fields that change on attendance toggle or site assignment)
  Map<String, dynamic> toUpdateJson() {
    final lowerStatus = status.toLowerCase() == 'present' ? 'present' : 'absent';
    final capitalizedStatus = status.toLowerCase() == 'present' ? 'Present' : 'Absent';
    final map = <String, dynamic>{
      'status': capitalizedStatus,
      'morning_status': lowerStatus,
      'evening_status': lowerStatus,
      'afternoon_status': lowerStatus,
      'project_id': (projectId != null && projectId!.isNotEmpty) ? projectId : null,
    };
    if (wageRate != null) {
      map['wage_rate'] = wageRate;
    }
    if (teaAllowance != null) {
      map['tea_allowance'] = teaAllowance;
    }
    return map;
  }

  Attendance copyWith({
    String? id,
    String? employeeId,
    String? date,
    String? status,
    String? projectId,
    String? employeeName,
    String? projectName,
    double? wageRate,
    double? teaAllowance,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      employeeName: employeeName ?? this.employeeName,
      projectName: projectName ?? this.projectName,
      wageRate: wageRate ?? this.wageRate,
      teaAllowance: teaAllowance ?? this.teaAllowance,
    );
  }
}
