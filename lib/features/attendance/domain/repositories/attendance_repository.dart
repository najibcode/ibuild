import '../../data/models/attendance_model.dart';
import '../../../employees/data/models/employee_model.dart';

abstract class AttendanceRepository {
  Future<List<Attendance>> getAttendanceForDate(String date);
  Future<void> saveAttendance(Attendance attendance);
  Future<List<Attendance>> getAttendanceHistory(String employeeId);

  /// Fetches attendance records for a specific project on a given date.
  Future<List<Attendance>> getAttendanceForProject(String projectId, String date);

  /// Fetches the last [days] days of attendance records for a project.
  Future<List<Attendance>> getAttendanceHistoryForProject(String projectId, {int days = 7});

  /// Fetches all attendance records between [startDate] and [endDate] (inclusive, yyyy-MM-dd).
  Future<List<Attendance>> getAttendanceForDateRange(String startDate, String endDate);

  /// Synchronizes the employee's daily salary with the assigned project's expenses.
  /// When [isPresent] is true and [projectId] is set with salary > 0, an expense is added/updated.
  /// When [isPresent] is false or [projectId] is null, any auto-logged salary expense is removed.
  Future<void> syncEmployeeSalaryExpense({
    required Employee employee,
    required String? projectId,
    required String date,
    required bool isPresent,
  });
}
