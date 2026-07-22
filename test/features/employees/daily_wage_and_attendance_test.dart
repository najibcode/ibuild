import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/employees/data/models/employee_model.dart';
import 'package:ibuild/features/attendance/data/models/attendance_model.dart';

void main() {
  group('Daily Wage & Single-Day Attendance Unit Tests', () {
    test('Employee daily rate wage calculation without monthly division', () {
      final worker = Employee(
        id: 'emp-101',
        name: 'Ramesh Kumar',
        phone: '+91 9876543210',
        role: 'Mason',
        salary: 850.0, // ₹850/day
        status: 'active',
      );

      expect(worker.dailyRate, equals(850.0));
      expect(worker.calculateTotalEarnings(22), equals(18700.0)); // 22 days worked * 850
      expect(worker.calculateTotalEarnings(28), equals(23800.0)); // 28 days worked * 850
    });

    test('Single-Day Attendance model serialization and backward compatibility', () {
      final attendance = Attendance(
        id: 'att-1',
        employeeId: 'emp-101',
        date: '2026-07-22',
        status: 'Present',
      );

      expect(attendance.status, equals('Present'));
      expect(attendance.morningStatus, equals('Present'));
      expect(attendance.eveningStatus, equals('Present'));

      final json = attendance.toJson();
      expect(json['status'], equals('Present'));
      expect(json['morning_status'], equals('present'));

      final leaveAttendance = Attendance.fromJson({
        'id': 'att-2',
        'employee_id': 'emp-102',
        'date': '2026-07-22',
        'status': 'Leave',
      });

      expect(leaveAttendance.status, equals('Leave'));
    });
  });
}
