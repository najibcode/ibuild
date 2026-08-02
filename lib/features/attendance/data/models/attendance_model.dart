class Attendance {
  final String id;
  final String employeeId;
  final String date;
  final String status; // Present or Absent (app-side unified view)
  final String? projectId; // UI-only: kept in memory for site assignment display
  final String? employeeName;
  final String? projectName;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.projectId,
    this.employeeName,
    this.projectName,
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

    return Attendance(
      id: json['id'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: normalizedStatus,
      projectId: json['project_id'] as String?,
      employeeName: employeeName ?? json['employee_name'] as String?,
      projectName: pName,
    );
  }

  /// Produce the minimal, safe JSON for Supabase insert/update.
  /// IMPORTANT: The actual DB columns are morning_status and evening_status,
  /// NOT "status" or "project_id".
  Map<String, dynamic> toJson() {
    final lowerStatus = status.toLowerCase() == 'present' ? 'present' : 'absent';
    return <String, dynamic>{
      'employee_id': employeeId,
      'date': date,
      'morning_status': lowerStatus,   // Must be lowercase to pass PostgreSQL check constraint
      'evening_status': lowerStatus,   // Must be lowercase to pass PostgreSQL check constraint
    };
  }

  /// Minimal update payload (only the fields that change on attendance toggle)
  Map<String, dynamic> toUpdateJson() {
    final lowerStatus = status.toLowerCase() == 'present' ? 'present' : 'absent';
    return <String, dynamic>{
      'morning_status': lowerStatus,
      'evening_status': lowerStatus,
    };
  }

  Attendance copyWith({
    String? id,
    String? employeeId,
    String? date,
    String? status,
    String? projectId,
    String? employeeName,
    String? projectName,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      employeeName: employeeName ?? this.employeeName,
      projectName: projectName ?? this.projectName,
    );
  }
}
