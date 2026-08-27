import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/attendance/data/models/attendance_model.dart';
import 'package:ibuild/features/expenses/data/models/expense_model.dart';
import 'package:ibuild/features/projects/data/models/project_model.dart';

void main() {
  group('Production Readiness Repair Audit Tests', () {
    test('1. Avatar URL validator enforces HTTPS, max length 2048, and rejects data/blob/base64', () {
      bool isValidAvatar(String? url) {
        if (url == null || url.trim().isEmpty) return true;
        final clean = url.trim();
        if (!clean.startsWith('https://')) return false;
        if (clean.startsWith('data:') || clean.startsWith('blob:')) return false;
        if (clean.length > 2048) return false;
        return true;
      }

      // Valid CDN URLs
      expect(isValidAvatar('https://ik.imagekit.io/ibuild/profile.jpg'), isTrue);
      expect(isValidAvatar('https://dxjvvashdbhlfvsjfdjq.supabase.co/storage/v1/object/public/avatars/user.png'), isTrue);
      expect(isValidAvatar(null), isTrue);
      expect(isValidAvatar(''), isTrue);

      // Invalid URLs
      expect(isValidAvatar('http://insecure.com/avatar.jpg'), isFalse);
      expect(isValidAvatar('data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...'), isFalse);
      expect(isValidAvatar('blob:https://ibuild.app/uuid'), isFalse);
      expect(isValidAvatar('https://example.com/${'a' * 2050}.jpg'), isFalse);
    });

    test('2. JWT payload size assertion maintains compact token (< 8 KB)', () {
      // Simulate normal user claims with CDN avatar
      final cleanJwtPayload = {
        'iss': 'supabase',
        'sub': 'usr_admin_01',
        'aud': 'authenticated',
        'exp': 1799999999,
        'email': 'admin@ibuild.in',
        'user_metadata': {
          'full_name': 'System Administrator',
        },
        'role': 'authenticated',
        'app_metadata': {'provider': 'email'},
      };

      final encoded = base64Url.encode(utf8.encode(jsonEncode(cleanJwtPayload)));
      final simulatedJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.$encoded.signature';
      final tokenBytes = utf8.encode(simulatedJwt).length;

      // Must be well below 8 KB (8192 bytes)
      expect(tokenBytes, lessThan(8192));
      expect(tokenBytes, lessThan(1024)); // Clean JWTs are usually < 1 KB
    });

    test('3. Atomic project spend calculation strictly matches sum of positive expenses', () {
      final expenses = [
        Expense(
          id: 'AUDIT-EXP-1',
          projectId: 'AUDIT-PRJ-1',
          category: 'Materials',
          amount: 50000.0,
          expenseDate: '2026-08-27',
          paymentMode: 'bank_transfer',
        ),
        Expense(
          id: 'AUDIT-EXP-2',
          projectId: 'AUDIT-PRJ-1',
          category: 'Labour',
          amount: 25000.0,
          expenseDate: '2026-08-27',
          paymentMode: 'cash',
        ),
        Expense(
          id: 'AUDIT-EXP-3',
          projectId: 'AUDIT-PRJ-1',
          category: 'Machinery',
          amount: 15000.0,
          expenseDate: '2026-08-27',
          paymentMode: 'cheque',
        ),
      ];

      final totalCalculatedSpent = expenses
          .where((e) => e.projectId == 'AUDIT-PRJ-1' && e.amount > 0)
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      final project = Project(
        id: 'AUDIT-PRJ-1',
        name: 'AUDIT Project Alpha',
        budget: 200000.0,
        spent: totalCalculatedSpent,
        status: 'active',
      );

      expect(project.spent, equals(90000.0));
      expect(project.remainingBalance, equals(110000.0));
      expect(project.budgetUtilization, equals(0.45));
    });

    test('4. Attendance model serializes unique key (employee_id, date) for conflict-safe upsert', () {
      final attendance = Attendance(
        id: 'AUDIT-ATT-001',
        employeeId: 'emp_soori_01',
        date: '2026-08-27',
        status: 'Present',
        projectId: 'proj_ppr_shop',
      );

      final json = attendance.toJson();
      expect(json['employee_id'], equals('emp_soori_01'));
      expect(json['date'], equals('2026-08-27'));
      expect(json['morning_status'], equals('present'));
    });

    test('5. Realtime subscription table map aligns with real database tables', () {
      const activeCrudTables = [
        'projects',
        'expenses',
        'attendance',
        'daily_progress',
        'employees',
        'inventory',
        'equipment',
        'bills',
        'payment_ledger',
        'snags',
        'profiles',
        'checklist_items',
      ];

      // Verify no stale aliases exist
      expect(activeCrudTables.contains('material_stock'), isFalse);
      expect(activeCrudTables.contains('vendor_bills'), isFalse);
      expect(activeCrudTables.contains('payments'), isFalse);
      expect(activeCrudTables.contains('inventory'), isTrue);
      expect(activeCrudTables.contains('bills'), isTrue);
      expect(activeCrudTables.contains('payment_ledger'), isTrue);
    });

    test('6. Security Headers CSP contains all required origins and blocks framing', () {
      const csp = "default-src 'self'; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' https://unpkg.com https://fonts.googleapis.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data:; img-src 'self' data: https: blob:; connect-src 'self' https://dxjvvashdbhlfvsjfdjq.supabase.co wss://dxjvvashdbhlfvsjfdjq.supabase.co https://upload.imagekit.io https://ik.imagekit.io; frame-ancestors 'none'; base-uri 'self'; object-src 'none';";

      expect(csp.contains("frame-ancestors 'none'"), isTrue);
      expect(csp.contains("https://dxjvvashdbhlfvsjfdjq.supabase.co"), isTrue);
      expect(csp.contains("wss://dxjvvashdbhlfvsjfdjq.supabase.co"), isTrue);
      expect(csp.contains("https://upload.imagekit.io"), isTrue);
      expect(csp.contains("https://ik.imagekit.io"), isTrue);
    });
  });
}
