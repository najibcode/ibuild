import '../lib/features/employees/data/models/employee_model.dart';
import '../lib/features/expenses/data/models/expense_model.dart';

void main() {
  print('════════════════════════════════════════════════════════════════════');
  print('  EMPLOYEE & EXPENSE SHORT ID GENERATION VERIFICATION');
  print('════════════════════════════════════════════════════════════════════\n');

  final empUuid = Employee(
    id: 'c8d1e2f3-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
    name: 'Rahul Sharma',
    phone: '9876543210',
    role: 'Mason',
    salary: 1900,
    status: 'active',
  );

  final empNum = Employee(
    id: 'emp-101',
    name: 'Amit Verma',
    phone: '9876543210',
    role: 'Supervisor',
    salary: 2200,
    status: 'active',
  );

  final empShort = Employee(
    id: '15',
    name: 'Ramesh',
    phone: '9876543210',
    role: 'Labour',
    salary: 1500,
    status: 'active',
  );

  final expUuid = Expense(
    id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    expenseDate: '2026-08-15',
    category: 'Materials',
    amount: 5000,
    paymentMode: 'cash',
  );

  final expNum = Expense(
    id: 'exp-502',
    expenseDate: '2026-08-15',
    category: 'Labour',
    amount: 1900,
    paymentMode: 'bank',
  );

  final expShort = Expense(
    id: '42',
    expenseDate: '2026-08-15',
    category: 'Fuel',
    amount: 800,
    paymentMode: 'upi',
  );

  print('Employee ID Tests:');
  print(' UUID (${empUuid.id}) -> ${empUuid.shortId}');
  print(' Pre-fixed (${empNum.id}) -> ${empNum.shortId}');
  print(' Numeric (${empShort.id}) -> ${empShort.shortId}\n');

  print('Expense ID Tests:');
  print(' UUID (${expUuid.id}) -> ${expUuid.shortId}');
  print(' Pre-fixed (${expNum.id}) -> ${expNum.shortId}');
  print(' Numeric (${expShort.id}) -> ${expShort.shortId}\n');

  assert(empUuid.shortId == 'EMP-C8D1');
  assert(empNum.shortId == 'EMP-101');
  assert(empShort.shortId == 'EMP-15');

  assert(expUuid.shortId == 'EXP-F47A');
  assert(expNum.shortId == 'EXP-502');
  assert(expShort.shortId == 'EXP-42');

  print('Verification Status: ✓ ALL SHORT ID TESTS PASSED (100%)');
}
