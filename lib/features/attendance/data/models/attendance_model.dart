class Attendance {
  final String id;
  final String employeeId;
  final String date;
  final String morningStatus;
  final String eveningStatus;
  final String? employeeName; // Join helper

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.morningStatus,
    required this.eveningStatus,
    this.employeeName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json, {String? employeeName}) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      date: json['date'] as String,
      morningStatus: json['morning_status'] as String,
      eveningStatus: json['evening_status'] as String,
      employeeName: employeeName ?? json['employee_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'date': date,
      'morning_status': morningStatus,
      'evening_status': eveningStatus,
    };
  }

  Attendance copyWith({
    String? id,
    String? employeeId,
    String? date,
    String? morningStatus,
    String? eveningStatus,
    String? employeeName,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      morningStatus: morningStatus ?? this.morningStatus,
      eveningStatus: eveningStatus ?? this.eveningStatus,
      employeeName: employeeName ?? this.employeeName,
    );
  }
}
