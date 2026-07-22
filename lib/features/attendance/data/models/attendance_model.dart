class Attendance {
  final String id;
  final String employeeId;
  final String date;
  final String status; // Present, Absent, Leave
  final String? employeeName; // Join helper

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.employeeName,
  });

  // Backward compatibility getters
  String get morningStatus => status;
  String get eveningStatus => status;

  factory Attendance.fromJson(Map<String, dynamic> json, {String? employeeName}) {
    final statusVal = json['status'] as String? ?? 
        (json['morning_status'] == 'present' || json['morning_status'] == 'Present' ? 'Present' : 'Absent');
    return Attendance(
      id: json['id'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: statusVal,
      employeeName: employeeName ?? json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'date': date,
      'status': status,
      'morning_status': status.toLowerCase(),
      'evening_status': status.toLowerCase(),
    };
  }

  Attendance copyWith({
    String? id,
    String? employeeId,
    String? date,
    String? status,
    String? employeeName,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      status: status ?? this.status,
      employeeName: employeeName ?? this.employeeName,
    );
  }
}
