import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/employees/data/models/employee_model.dart';
import 'package:ibuild/features/expenses/data/models/expense_model.dart';

void main() {
  group('Employee shortId verification', () {
    test('Shortens UUID employee id to 4 uppercase hex characters with EMP prefix', () {
      final emp = Employee(
        id: 'c8d1e2f3-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
        name: 'Rahul Sharma',
        phone: '9876543210',
        role: 'Mason',
        salary: 1900,
        status: 'active',
      );
      expect(emp.shortId, equals('EMP-C8D1'));
    });

    test('Preserves numeric employee id with EMP prefix', () {
      final emp1 = Employee(
        id: 'emp-101',
        name: 'Amit',
        phone: '9876543210',
        role: 'Supervisor',
        salary: 2200,
        status: 'active',
      );
      expect(emp1.shortId, equals('EMP-101'));

      final emp2 = Employee(
        id: '15',
        name: 'Ramesh',
        phone: '9876543210',
        role: 'Labour',
        salary: 1500,
        status: 'active',
      );
      expect(emp2.shortId, equals('EMP-15'));
    });

    test('Handles empty employee id safely', () {
      final emp = Employee(
        id: '',
        name: 'New',
        phone: '9876543210',
        role: 'Labour',
        salary: 1000,
        status: 'active',
      );
      expect(emp.shortId, equals('EMP-01'));
    });
  });

  group('Expense shortId verification', () {
    test('Shortens UUID expense id to 4 uppercase hex characters with EXP prefix', () {
      final exp = Expense(
        id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        expenseDate: '2026-08-15',
        category: 'Materials',
        amount: 5000,
        paymentMode: 'cash',
      );
      expect(exp.shortId, equals('EXP-F47A'));
    });

    test('Preserves numeric expense id with EXP prefix', () {
      final exp1 = Expense(
        id: 'exp-502',
        expenseDate: '2026-08-15',
        category: 'Labour',
        amount: 1900,
        paymentMode: 'bank',
      );
      expect(exp1.shortId, equals('EXP-502'));

      final exp2 = Expense(
        id: '42',
        expenseDate: '2026-08-15',
        category: 'Fuel',
        amount: 800,
        paymentMode: 'upi',
      );
      expect(exp2.shortId, equals('EXP-42'));
    });

    test('Handles empty expense id safely', () {
      final exp = Expense(
        id: '',
        expenseDate: '2026-08-15',
        category: 'Miscellaneous',
        amount: 100,
        paymentMode: 'cash',
      );
      expect(exp.shortId, equals('EXP-01'));
    });
  });
}
