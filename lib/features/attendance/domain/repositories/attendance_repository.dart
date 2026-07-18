import '../../data/models/attendance_model.dart';

abstract class AttendanceRepository {
  Future<List<Attendance>> getAttendanceForDate(String date);
  Future<void> saveAttendance(Attendance attendance);
  Future<List<Attendance>> getAttendanceHistory(String employeeId);
}
