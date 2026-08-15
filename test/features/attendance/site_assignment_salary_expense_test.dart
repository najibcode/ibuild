import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/employees/data/models/employee_model.dart';
import 'package:ibuild/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:ibuild/features/attendance/data/models/attendance_model.dart';

/// In-memory fake repository to test syncEmployeeSalaryExpense logic
class FakeAttendanceExpenseRepository implements AttendanceRepository {
  final List<Attendance> attendanceStore = [];
  final List<Map<String, dynamic>> expenseStore = [];
  final Map<String, double> projectSpentStore = {};

  @override
  Future<List<Attendance>> getAttendanceForDate(String date) async {
    return attendanceStore.where((a) => a.date == date).toList();
  }

  @override
  Future<void> saveAttendance(Attendance attendance) async {
    attendanceStore.removeWhere(
      (a) => a.employeeId == attendance.employeeId && a.date == attendance.date,
    );
    attendanceStore.add(attendance);
  }

  @override
  Future<List<Attendance>> getAttendanceHistory(String employeeId) async {
    return attendanceStore.where((a) => a.employeeId == employeeId).toList();
  }

  @override
  Future<List<Attendance>> getAttendanceForProject(String projectId, String date) async {
    return attendanceStore.where((a) => a.projectId == projectId && a.date == date).toList();
  }

  @override
  Future<List<Attendance>> getAttendanceHistoryForProject(String projectId, {int days = 7}) async {
    return attendanceStore.where((a) => a.projectId == projectId).toList();
  }

  @override
  Future<List<Attendance>> getAttendanceForDateRange(String startDate, String endDate) async {
    return attendanceStore.where((a) => a.date.compareTo(startDate) >= 0 && a.date.compareTo(endDate) <= 0).toList();
  }

  @override
  Future<void> syncEmployeeSalaryExpense({
    required Employee employee,
    required String? projectId,
    required String date,
    required bool isPresent,
  }) async {
    final noteTag = '[EMP:${employee.id}]';
    final salary = employee.salary;

    // Find existing auto-generated wage expense
    final existing = expenseStore.where((e) {
      return e['expense_date'] == date &&
          e['category'] == 'Labour' &&
          (e['notes'] as String).contains(noteTag);
    }).toList();

    if (!isPresent || projectId == null || projectId.isEmpty || salary <= 0) {
      // Remove any existing expense
      for (final exp in existing) {
        expenseStore.remove(exp);
        final pId = exp['project_id'] as String?;
        final amt = (exp['amount'] as num?)?.toDouble() ?? 0.0;
        if (pId != null && amt > 0) {
          projectSpentStore[pId] = ((projectSpentStore[pId] ?? 0.0) - amt).clamp(0.0, double.infinity);
        }
      }
      return;
    }

    final noteText = 'Daily salary for ${employee.name} (${employee.role}) $noteTag';

    if (existing.isNotEmpty) {
      final first = existing.first;
      final currentProjId = first['project_id'] as String?;
      final currentAmount = (first['amount'] as num?)?.toDouble() ?? 0.0;

      if (currentProjId == projectId && currentAmount == salary) {
        // Already matching
        return;
      }

      first['project_id'] = projectId;
      first['amount'] = salary;
      first['notes'] = noteText;

      if (currentProjId != projectId) {
        if (currentProjId != null && currentAmount > 0) {
          projectSpentStore[currentProjId] =
              ((projectSpentStore[currentProjId] ?? 0.0) - currentAmount).clamp(0.0, double.infinity);
        }
        projectSpentStore[projectId] = (projectSpentStore[projectId] ?? 0.0) + salary;
      } else if (currentAmount != salary) {
        final diff = salary - currentAmount;
        projectSpentStore[projectId] = (projectSpentStore[projectId] ?? 0.0) + diff;
      }
    } else {
      expenseStore.add({
        'id': 'exp-${DateTime.now().microsecondsSinceEpoch}',
        'project_id': projectId,
        'expense_date': date,
        'category': 'Labour',
        'amount': salary,
        'payment_mode': 'cash',
        'notes': noteText,
      });
      projectSpentStore[projectId] = (projectSpentStore[projectId] ?? 0.0) + salary;
    }
  }
}

void main() {
  group('Site Assignment Salary Expense Synchronization Tests', () {
    late FakeAttendanceExpenseRepository repo;

    setUp(() {
      repo = FakeAttendanceExpenseRepository();
    });

    test('Assigning site to employee automatically adds salary expense to project', () async {
      final worker = Employee(
        id: 'emp-101',
        name: 'Ramesh Kumar',
        phone: '+91 9876543210',
        role: 'Mason',
        salary: 850.0,
        status: 'active',
      );

      await repo.syncEmployeeSalaryExpense(
        employee: worker,
        projectId: 'proj-green-villa',
        date: '2026-08-15',
        isPresent: true,
      );

      expect(repo.expenseStore.length, equals(1));
      final expense = repo.expenseStore.first;
      expect(expense['project_id'], equals('proj-green-villa'));
      expect(expense['amount'], equals(850.0));
      expect(expense['category'], equals('Labour'));
      expect(expense['expense_date'], equals('2026-08-15'));
      expect(expense['notes'], contains('Daily salary for Ramesh Kumar (Mason) [EMP:emp-101]'));
      expect(repo.projectSpentStore['proj-green-villa'], equals(850.0));
    });

    test('Re-assigning same employee to another site transfers expense and adjusts spent', () async {
      final worker = Employee(
        id: 'emp-101',
        name: 'Ramesh Kumar',
        phone: '+91 9876543210',
        role: 'Mason',
        salary: 850.0,
        status: 'active',
      );

      // 1. Assign to Site A
      await repo.syncEmployeeSalaryExpense(
        employee: worker,
        projectId: 'proj-site-a',
        date: '2026-08-15',
        isPresent: true,
      );

      expect(repo.expenseStore.length, equals(1));
      expect(repo.projectSpentStore['proj-site-a'], equals(850.0));

      // 2. Re-assign to Site B on same date
      await repo.syncEmployeeSalaryExpense(
        employee: worker,
        projectId: 'proj-site-b',
        date: '2026-08-15',
        isPresent: true,
      );

      expect(repo.expenseStore.length, equals(1));
      expect(repo.expenseStore.first['project_id'], equals('proj-site-b'));
      expect(repo.projectSpentStore['proj-site-a'], equals(0.0));
      expect(repo.projectSpentStore['proj-site-b'], equals(850.0));
    });

    test('Marking employee Absent removes the salary expense and decrements project spent', () async {
      final worker = Employee(
        id: 'emp-102',
        name: 'Suresh Carpenter',
        phone: '+91 9876543211',
        role: 'Carpenter',
        salary: 1000.0,
        status: 'active',
      );

      // 1. Assign to Site A
      await repo.syncEmployeeSalaryExpense(
        employee: worker,
        projectId: 'proj-site-a',
        date: '2026-08-15',
        isPresent: true,
      );

      expect(repo.expenseStore.length, equals(1));
      expect(repo.projectSpentStore['proj-site-a'], equals(1000.0));

      // 2. Mark Absent
      await repo.syncEmployeeSalaryExpense(
        employee: worker,
        projectId: 'proj-site-a',
        date: '2026-08-15',
        isPresent: false,
      );

      expect(repo.expenseStore.length, equals(0));
      expect(repo.projectSpentStore['proj-site-a'], equals(0.0));
    });

    test('Zero salary employee does not create an expense record', () async {
      final unpaidIntern = Employee(
        id: 'emp-103',
        name: 'Trainee Civil Engineer',
        phone: '+91 9876543212',
        role: 'Intern',
        salary: 0.0,
        status: 'active',
      );

      await repo.syncEmployeeSalaryExpense(
        employee: unpaidIntern,
        projectId: 'proj-site-a',
        date: '2026-08-15',
        isPresent: true,
      );

      expect(repo.expenseStore.length, equals(0));
      expect(repo.projectSpentStore['proj-site-a'], isNull);
    });

    test('Multiple workers assigned to same project aggregate salary expenses correctly', () async {
      final worker1 = Employee(
        id: 'emp-1',
        name: 'Worker 1',
        phone: '111',
        role: 'Mason',
        salary: 800.0,
        status: 'active',
      );
      final worker2 = Employee(
        id: 'emp-2',
        name: 'Worker 2',
        phone: '222',
        role: 'Helper',
        salary: 500.0,
        status: 'active',
      );

      await repo.syncEmployeeSalaryExpense(
        employee: worker1,
        projectId: 'proj-tower-1',
        date: '2026-08-15',
        isPresent: true,
      );
      await repo.syncEmployeeSalaryExpense(
        employee: worker2,
        projectId: 'proj-tower-1',
        date: '2026-08-15',
        isPresent: true,
      );

      expect(repo.expenseStore.length, equals(2));
      expect(repo.projectSpentStore['proj-tower-1'], equals(1300.0));
    });
  });
}
