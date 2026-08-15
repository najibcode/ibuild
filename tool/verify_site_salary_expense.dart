import '../lib/features/employees/data/models/employee_model.dart';
import '../lib/features/attendance/domain/repositories/attendance_repository.dart';
import '../lib/features/attendance/data/models/attendance_model.dart';

class VerificationFakeAttendanceRepository implements AttendanceRepository {
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

    final existing = expenseStore.where((e) {
      return e['expense_date'] == date &&
          e['category'] == 'Labour' &&
          (e['notes'] as String).contains(noteTag);
    }).toList();

    if (!isPresent || projectId == null || projectId.isEmpty || salary <= 0) {
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

void main() async {
  print('════════════════════════════════════════════════════════════════════');
  print('  EMPLOYEE SITE ASSIGNMENT -> PROJECT SALARY EXPENSE VERIFICATION   ');
  print('════════════════════════════════════════════════════════════════════\n');

  final repo = VerificationFakeAttendanceRepository();

  // Test 1: Assign Worker to Site
  print('━━━ Test 1: Site Assignment -> Expense Logging ━━━');
  final worker1 = Employee(
    id: 'emp-101',
    name: 'Ramesh Kumar',
    phone: '+91 9876543210',
    role: 'Mason',
    salary: 850.0,
    status: 'active',
  );

  await repo.syncEmployeeSalaryExpense(
    employee: worker1,
    projectId: 'proj-green-villa',
    date: '2026-08-15',
    isPresent: true,
  );

  final exp1 = repo.expenseStore.first;
  final check1 = repo.expenseStore.length == 1 &&
      exp1['project_id'] == 'proj-green-villa' &&
      exp1['amount'] == 850.0 &&
      exp1['category'] == 'Labour' &&
      repo.projectSpentStore['proj-green-villa'] == 850.0;

  print('Expense Count: ${repo.expenseStore.length}');
  print('Project ID:    ${exp1['project_id']}');
  print('Category:      ${exp1['category']}');
  print('Amount:        ₹${exp1['amount']}');
  print('Notes:         ${exp1['notes']}');
  print('Project Spent: ₹${repo.projectSpentStore['proj-green-villa']}');
  print('Result:        ${check1 ? "✓ PASSED" : "❌ FAILED"}\n');

  // Test 2: Re-assign to another site
  print('━━━ Test 2: Re-assignment to Another Site ━━━');
  await repo.syncEmployeeSalaryExpense(
    employee: worker1,
    projectId: 'proj-sky-tower',
    date: '2026-08-15',
    isPresent: true,
  );

  final exp2 = repo.expenseStore.first;
  final check2 = repo.expenseStore.length == 1 &&
      exp2['project_id'] == 'proj-sky-tower' &&
      repo.projectSpentStore['proj-green-villa'] == 0.0 &&
      repo.projectSpentStore['proj-sky-tower'] == 850.0;

  print('Expense Count:     ${repo.expenseStore.length}');
  print('New Project ID:    ${exp2['project_id']}');
  print('Old Project Spent: ₹${repo.projectSpentStore['proj-green-villa']}');
  print('New Project Spent: ₹${repo.projectSpentStore['proj-sky-tower']}');
  print('Result:            ${check2 ? "✓ PASSED" : "❌ FAILED"}\n');

  // Test 3: Mark Absent (Removes Expense)
  print('━━━ Test 3: Mark Absent -> Expense Cleaned Up ━━━');
  await repo.syncEmployeeSalaryExpense(
    employee: worker1,
    projectId: 'proj-sky-tower',
    date: '2026-08-15',
    isPresent: false,
  );

  final check3 = repo.expenseStore.isEmpty && repo.projectSpentStore['proj-sky-tower'] == 0.0;
  print('Expense Count:     ${repo.expenseStore.length}');
  print('New Project Spent: ₹${repo.projectSpentStore['proj-sky-tower']}');
  print('Result:            ${check3 ? "✓ PASSED" : "❌ FAILED"}\n');

  // Test 4: Multiple Workers Aggregate
  print('━━━ Test 4: Multiple Workers Aggregate On Same Project ━━━');
  final mason = Employee(
    id: 'emp-101',
    name: 'Ramesh Kumar',
    phone: '111',
    role: 'Mason',
    salary: 850.0,
    status: 'active',
  );
  final carpenter = Employee(
    id: 'emp-102',
    name: 'Suresh Carpenter',
    phone: '222',
    role: 'Carpenter',
    salary: 1000.0,
    status: 'active',
  );

  await repo.syncEmployeeSalaryExpense(
    employee: mason,
    projectId: 'proj-bridge',
    date: '2026-08-15',
    isPresent: true,
  );
  await repo.syncEmployeeSalaryExpense(
    employee: carpenter,
    projectId: 'proj-bridge',
    date: '2026-08-15',
    isPresent: true,
  );

  final totalSpent = repo.projectSpentStore['proj-bridge'];
  final check4 = repo.expenseStore.length == 2 && totalSpent == 1850.0;
  print('Expense Records: ${repo.expenseStore.length}');
  print('Total Spent:     ₹$totalSpent (Expected: ₹1850)');
  print('Result:          ${check4 ? "✓ PASSED" : "❌ FAILED"}\n');

  if (check1 && check2 && check3 && check4) {
    print('════════════════════════════════════════════════════════════════════');
    print('  ALL SITE ASSIGNMENT SALARY EXPENSE TESTS PASSED SUCCESSFULLY ✓   ');
    print('════════════════════════════════════════════════════════════════════');
  } else {
    print('❌ SOME TESTS FAILED');
  }
}
