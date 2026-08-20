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
      expect(worker.teaSnackAllowance, equals(20.0)); // Default ₹20/day
      expect(worker.totalDailyCost, equals(870.0)); // ₹850 base + ₹20 tea
      expect(worker.calculateTotalEarnings(22), equals(18700.0)); // 22 days worked * 850
      expect(worker.calculateBaseEarnings(22), equals(18700.0));
      expect(worker.calculateTeaSnackCost(22), equals(440.0)); // 22 days * ₹20
      expect(worker.calculateTotalEmployerCost(22), equals(19140.0)); // 18700 + 440
    });

    test('Custom tea and snacks allowance per employee', () {
      final seniorWorker = Employee(
        id: 'emp-102',
        name: 'Suresh Carpenter',
        phone: '+91 9876543211',
        role: 'Senior Carpenter',
        salary: 1000.0,
        teaSnackAllowance: 35.0, // Custom ₹35/day
        status: 'active',
      );

      expect(seniorWorker.teaSnackAllowance, equals(35.0));
      expect(seniorWorker.totalDailyCost, equals(1035.0));
      expect(seniorWorker.calculateBaseEarnings(10), equals(10000.0));
      expect(seniorWorker.calculateTeaSnackCost(10), equals(350.0));
      expect(seniorWorker.calculateTotalEmployerCost(10), equals(10350.0));

      final json = seniorWorker.toJson();
      expect(json['tea_snack_allowance'], equals(35.0));

      final restored = Employee.fromJson(json);
      expect(restored.teaSnackAllowance, equals(35.0));
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
      expect(json['morning_status'], equals('present'));
      expect(json['evening_status'], equals('present'));

      final leaveAttendance = Attendance.fromJson({
        'id': 'att-2',
        'employee_id': 'emp-102',
        'date': '2026-07-22',
        'status': 'Leave',
      });

      expect(leaveAttendance.status, equals('Absent'));
    });
  });
}
