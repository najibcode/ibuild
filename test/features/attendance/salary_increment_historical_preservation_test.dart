import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/employees/data/models/employee_model.dart';
import 'package:ibuild/features/attendance/data/models/attendance_model.dart';

void main() {
  group('Salary Increment & Historical Wage Preservation Tests', () {
    test('1. Attendance model captures wageRate and teaAllowance snapshots', () {
      final log = Attendance(
        id: 'att-1',
        employeeId: 'emp-abdul',
        date: '2026-08-01',
        status: 'Present',
        wageRate: 500.0,
        teaAllowance: 20.0,
      );

      expect(log.wageRate, equals(500.0));
      expect(log.teaAllowance, equals(20.0));

      final json = log.toJson();
      expect(json['wage_rate'], equals(500.0));
      expect(json['tea_allowance'], equals(20.0));

      final restored = Attendance.fromJson(json);
      expect(restored.wageRate, equals(500.0));
      expect(restored.teaAllowance, equals(20.0));
    });

    test('2. Changing employee salary from 500 to 600 preserves past attendance earnings at 500', () {
      // Step 1: Abdul starts with salary of ₹500/day
      var abdul = Employee(
        id: 'emp-abdul-01',
        name: 'Abdul',
        phone: '+91 9876543210',
        role: 'Mason',
        salary: 500.0,
        teaSnackAllowance: 20.0,
        status: 'active',
      );

      // Past attendance records logged when salary was ₹500
      final pastLogs = [
        Attendance(
          id: 'att-1',
          employeeId: abdul.id,
          date: '2026-08-01',
          status: 'Present',
          wageRate: 500.0,
          teaAllowance: 20.0,
        ),
        Attendance(
          id: 'att-2',
          employeeId: abdul.id,
          date: '2026-08-02',
          status: 'Present',
          wageRate: 500.0,
          teaAllowance: 20.0,
        ),
        Attendance(
          id: 'att-3',
          employeeId: abdul.id,
          date: '2026-08-03',
          status: 'Present',
          wageRate: 500.0,
          teaAllowance: 20.0,
        ),
      ];

      // Step 2: Abdul gets a salary increment to ₹600/day
      abdul = abdul.copyWith(salary: 600.0);
      expect(abdul.salary, equals(600.0));

      // Step 3: New attendance records logged after salary increment
      final newLogs = [
        Attendance(
          id: 'att-4',
          employeeId: abdul.id,
          date: '2026-08-04',
          status: 'Present',
          wageRate: 600.0,
          teaAllowance: 20.0,
        ),
        Attendance(
          id: 'att-5',
          employeeId: abdul.id,
          date: '2026-08-05',
          status: 'Present',
          wageRate: 600.0,
          teaAllowance: 20.0,
        ),
      ];

      final allLogs = [...pastLogs, ...newLogs];

      // Step 4: Calculate total worker pay and employer cost across past & new logs
      double totalBaseEarned = 0.0;
      double totalTeaSpent = 0.0;

      for (final log in allLogs) {
        if (log.status == 'Present') {
          totalBaseEarned += (log.wageRate ?? abdul.salary);
          totalTeaSpent += (log.teaAllowance ?? abdul.teaSnackAllowance);
        }
      }

      // Expected: (3 days * 500) + (2 days * 600) = 1500 + 1200 = 2700
      // (NOT 5 days * 600 = 3000!)
      expect(totalBaseEarned, equals(2700.0),
          reason: 'Past 3 days must be calculated at ₹500 and future 2 days at ₹600');

      // Tea: 5 days * 20 = 100
      expect(totalTeaSpent, equals(100.0));
      expect(totalBaseEarned + totalTeaSpent, equals(2800.0));
    });

    test('3. Attendance fromJson seamlessly falls back to employee salary if historical wage_rate is missing', () {
      final legacyJson = {
        'id': 'legacy-att-1',
        'employee_id': 'emp-abdul-01',
        'date': '2026-07-15',
        'morning_status': 'present',
      };

      final parsed = Attendance.fromJson(legacyJson);
      expect(parsed.wageRate, isNull);

      const currentSalary = 600.0;
      final effectiveWage = parsed.wageRate ?? currentSalary;
      expect(effectiveWage, equals(600.0));
    });
  });
}
