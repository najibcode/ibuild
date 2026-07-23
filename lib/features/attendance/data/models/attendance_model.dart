class Attendance {
  final String id;
  final String employeeId;
  final String date;
  final String status; // Present or Absent
  final String? projectId; // Site/Project assigned for the day
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
    final rawStatus = json['status'] as String? ?? json['morning_status'] as String? ?? 'Absent';
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

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'date': date,
      'status': status,
      'morning_status': status.toLowerCase(),
      'evening_status': status.toLowerCase(),
      if (projectId != null && projectId!.isNotEmpty) 'project_id': projectId,
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
