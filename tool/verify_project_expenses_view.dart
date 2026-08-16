import '../lib/features/expenses/data/models/expense_model.dart';
import '../lib/core/utils/currency_formatter.dart';

void main() {
  print('════════════════════════════════════════════════════════════════════');
  print('  PROJECT EXPENSES & FINANCIALS HUB — DATA & BREAKDOWN VERIFICATION');
  print('════════════════════════════════════════════════════════════════════\n');

  final List<Expense> mockProjectExpenses = [
    Expense(
      id: 'exp-101',
      projectId: 'proj-skyline',
      projectName: 'Skyline Towers',
      category: 'Labour',
      amount: 1900.0,
      paymentMode: 'cash',
      expenseDate: '2026-08-15',
      notes: 'Daily wage for Rahul Sharma (Assigned to site)',
    ),
    Expense(
      id: 'exp-102',
      projectId: 'proj-skyline',
      projectName: 'Skyline Towers',
      category: 'Labour',
      amount: 2200.0,
      paymentMode: 'bank',
      expenseDate: '2026-08-15',
      notes: 'Daily wage for Amit Verma (Assigned to site)',
    ),
    Expense(
      id: 'exp-103',
      projectId: 'proj-skyline',
      projectName: 'Skyline Towers',
      category: 'Materials',
      amount: 19500.0,
      paymentMode: 'cash',
      expenseDate: '2026-08-15',
      notes: 'Received +50.0 bags of Ultratech PPC Cement from National Hardware Supply',
    ),
    Expense(
      id: 'exp-104',
      projectId: 'proj-skyline',
      projectName: 'Skyline Towers',
      category: 'Materials',
      amount: 11700.0,
      paymentMode: 'cash',
      expenseDate: '2026-08-15',
      notes: 'Issued 30.0 bags of Ultratech PPC Cement from Central Stock (Ground Floor Slab Casting)',
    ),
    Expense(
      id: 'exp-105',
      projectId: 'proj-skyline',
      projectName: 'Skyline Towers',
      category: 'Fuel',
      amount: 4500.0,
      paymentMode: 'upi',
      expenseDate: '2026-08-14',
      notes: 'Diesel for Site Generator 50L',
    ),
    Expense(
      id: 'exp-106',
      projectId: 'proj-skyline',
      projectName: 'Skyline Towers',
      category: 'Equipment',
      amount: 8500.0,
      paymentMode: 'bank',
      expenseDate: '2026-08-13',
      notes: 'Concrete Vibrator Needle & Mixer Machine Rental',
    ),
  ];

  final totalAmount = mockProjectExpenses.fold(0.0, (s, e) => s + e.amount);
  final labourAmount = mockProjectExpenses
      .where((e) => e.category.toLowerCase() == 'labour')
      .fold(0.0, (s, e) => s + e.amount);
  final materialAmount = mockProjectExpenses
      .where((e) =>
          e.category.toLowerCase().contains('mat') ||
          e.category.toLowerCase().contains('inven'))
      .fold(0.0, (s, e) => s + e.amount);
  final otherAmount =
      (totalAmount - labourAmount - materialAmount).clamp(0.0, double.infinity);

  print('Total Project Expenses: ₹${CurrencyFormatter.formatFullINR(totalAmount)} (${CurrencyFormatter.formatCompact(totalAmount)})');
  print('• Labour / Wages:       ₹${CurrencyFormatter.formatFullINR(labourAmount)}');
  print('• Materials / Stock:    ₹${CurrencyFormatter.formatFullINR(materialAmount)}');
  print('• Other Operations:     ₹${CurrencyFormatter.formatFullINR(otherAmount)}\n');

  print('Transactions Breakdown:');
  for (final exp in mockProjectExpenses) {
    print(' [${exp.expenseDate}] [${exp.category.padRight(10)}] [${exp.paymentMode.toUpperCase().padRight(4)}] -₹${CurrencyFormatter.formatFullINR(exp.amount).padLeft(9)} | ${exp.notes}');
  }

  final testPass = totalAmount == 48300.0 &&
      labourAmount == 4100.0 &&
      materialAmount == 31200.0 &&
      otherAmount == 13000.0;

  print('\nVerification Status: ${testPass ? "✓ ALL CHECKS PASSED (100%)" : "❌ FAILED"}');
}
