import '../../data/models/attendance_model.dart';

abstract class AttendanceRepository {
  Future<List<Attendance>> getAttendanceForDate(String date);
  Future<void> saveAttendance(Attendance attendance);
  Future<List<Attendance>> getAttendanceHistory(String employeeId);

  /// Fetches attendance records for a specific project on a given date.
  Future<List<Attendance>> getAttendanceForProject(String projectId, String date);

  /// Fetches the last [days] days of attendance records for a project.
  Future<List<Attendance>> getAttendanceHistoryForProject(String projectId, {int days = 7});
}
