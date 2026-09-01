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

    test('Historical wage rate snapshot isolation when salary is increased from 500 to 600', () {
      // 1. Employee originally had salary = 500
      var worker = Employee(
        id: 'emp-201',
        name: 'Sunil Mason',
        phone: '+91 9888877777',
        role: 'Mason',
        salary: 500.0,
        teaSnackAllowance: 20.0,
        salaryEffectiveDate: '2026-08-01',
        status: 'active',
      );

      // 2. Attendance on Aug 30 was marked with wage rate = 500
      final yesterdayAttendance = Attendance(
        id: 'att-201',
        employeeId: worker.id,
        date: '2026-08-30',
        status: 'Present',
        wageRate: 500.0,
        teaAllowance: 20.0,
      );

      // 3. TODAY (Sept 1), employer updates salary from 500 to 600
      worker = worker.copyWith(
        salary: 600.0,
        salaryEffectiveDate: '2026-09-01',
      );

      // 4. Attendance for TODAY is marked with new salary = 600
      final todayAttendance = Attendance(
        id: 'att-202',
        employeeId: worker.id,
        date: '2026-09-01',
        status: 'Present',
        wageRate: worker.salary, // 600
        teaAllowance: worker.teaSnackAllowance,
      );

      // 5. Assert that yesterday's attendance strictly preserves 500
      expect(yesterdayAttendance.wageRate, equals(500.0));
      // 6. Assert that today's attendance has 600
      expect(todayAttendance.wageRate, equals(600.0));

      // 7. Verify total earnings across both days = 500 + 600 = 1100 (NOT 600 + 600 = 1200)
      final historyLogs = [yesterdayAttendance, todayAttendance];
      double totalEarned = 0.0;
      for (final log in historyLogs) {
        if (log.status == 'Present') {
          totalEarned += (log.wageRate ?? worker.salary);
        }
      }
      expect(totalEarned, equals(1100.0));
    });
  });
}
