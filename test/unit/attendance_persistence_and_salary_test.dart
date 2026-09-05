import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/attendance/data/models/attendance_model.dart';
import 'package:ibuild/features/employees/data/models/employee_model.dart';
import 'package:ibuild/features/attendance/domain/repositories/attendance_repository.dart';

class InMemoryAttendanceRepo implements AttendanceRepository {
  final List<Attendance> records = [];

  @override
  Future<List<Attendance>> getAttendanceForDate(String date) async {
    return records.where((r) => r.date == date).toList();
  }

  @override
  Future<void> saveAttendance(Attendance attendance) async {
    records.removeWhere((r) => r.employeeId == attendance.employeeId && r.date == attendance.date);
    records.add(attendance);
  }

  @override
  Future<List<Attendance>> getAttendanceHistory(String employeeId) async {
    return records.where((r) => r.employeeId == employeeId).toList();
  }

  @override
  Future<List<Attendance>> getAttendanceForProject(String projectId, String date) async {
    return records.where((r) => r.projectId == projectId && r.date == date).toList();
  }

  @override
  Future<List<Attendance>> getAttendanceHistoryForProject(String projectId, {int days = 7}) async {
    return records.where((r) => r.projectId == projectId).toList();
  }

  @override
  Future<List<Attendance>> getAttendanceForDateRange(String startDate, String endDate) async {
    return records.where((r) => r.date.compareTo(startDate) >= 0 && r.date.compareTo(endDate) <= 0).toList();
  }

  @override
  Future<void> syncEmployeeSalaryExpense({
    required Employee employee,
    required String? projectId,
    required String date,
    required bool isPresent,
    double? wageRate,
  }) async {}

  @override
  Future<void> lockHistoricalWagesForEmployee({
    required String employeeId,
    required String beforeDate,
    required double previousWageRate,
    required double previousTeaAllowance,
  }) async {
    for (int i = 0; i < records.length; i++) {
      final a = records[i];
      if (a.employeeId == employeeId && a.date.compareTo(beforeDate) < 0) {
        if (a.wageRate == null || a.wageRate == 0) {
          records[i] = a.copyWith(
            wageRate: previousWageRate,
            teaAllowance: previousTeaAllowance,
          );
        }
      }
    }
  }
}

void main() {
  group('Attendance Persistence & Refresh Tests', () {
    test('Marking attendance and refreshing preserves Present status and wageRate snapshot', () async {
      final repo = InMemoryAttendanceRepo();

      final att = Attendance(
        id: 'att-1',
        employeeId: 'emp-soori',
        date: '2026-09-05',
        status: 'Present',
        wageRate: 800.0,
        teaAllowance: 20.0,
      );

      await repo.saveAttendance(att);

      // Simulate refresh by loading for that date
      final refreshed = await repo.getAttendanceForDate('2026-09-05');
      expect(refreshed.length, equals(1));
      expect(refreshed.first.status, equals('Present'));
      expect(refreshed.first.wageRate, equals(800.0));
      expect(refreshed.first.teaAllowance, equals(20.0));
    });

    test('Salary Revision locks past attendance records at old salary while new records take new salary', () async {
      final repo = InMemoryAttendanceRepo();

      // Abdul had salary of 500 in month 1 (Aug 1 to Aug 3)
      await repo.saveAttendance(Attendance(
        id: 'att-aug-1',
        employeeId: 'emp-abdul',
        date: '2026-08-01',
        status: 'Present',
        wageRate: 500.0,
        teaAllowance: 20.0,
      ));
      await repo.saveAttendance(Attendance(
        id: 'att-aug-2',
        employeeId: 'emp-abdul',
        date: '2026-08-02',
        status: 'Present',
        wageRate: null, // Legacy un-snapshotted log
      ));

      // In month 2 (Sep 1), salary is revised from 500 to 600
      await repo.lockHistoricalWagesForEmployee(
        employeeId: 'emp-abdul',
        beforeDate: '2026-09-01',
        previousWageRate: 500.0,
        previousTeaAllowance: 20.0,
      );

      // New log in Sep takes 600
      await repo.saveAttendance(Attendance(
        id: 'att-sep-1',
        employeeId: 'emp-abdul',
        date: '2026-09-01',
        status: 'Present',
        wageRate: 600.0,
        teaAllowance: 20.0,
      ));

      final allLogs = await repo.getAttendanceHistory('emp-abdul');
      final logAug1 = allLogs.firstWhere((a) => a.date == '2026-08-01');
      final logAug2 = allLogs.firstWhere((a) => a.date == '2026-08-02');
      final logSep1 = allLogs.firstWhere((a) => a.date == '2026-09-01');

      expect(logAug1.wageRate, equals(500.0));
      expect(logAug2.wageRate, equals(500.0)); // Locked at 500, not 600!
      expect(logSep1.wageRate, equals(600.0));
    });
  });
}
