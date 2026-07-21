import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/projects/data/models/project_model.dart';
import 'package:ibuild/features/checklists/data/models/checklist_model.dart';
import 'package:ibuild/features/sales_bills/data/models/sales_bill_model.dart';
import 'package:ibuild/features/payments/data/models/payment_model.dart';

void main() {
  group('Project Operations & Site-Centered Model Tests', () {
    test('Project serialization with extended site properties', () {
      final json = {
        'id': 'proj-101',
        'name': 'Skyline Towers Phase 1',
        'client_name': 'Acme Infrastructure',
        'project_code': 'PRJ-101',
        'address': 'Plot 45, Cyber City',
        'budget': 50000000.0,
        'estimated_cost': 45000000.0,
        'current_cost': 12000000.0,
        'spent': 12000000.0,
        'status': 'active',
        'start_date': '2026-01-15',
        'expected_completion': '2027-06-30',
        'built_up_area': 125000.0,
        'flat_area': 95000.0,
        'duration': '18 Months',
        'customer_name': 'Rajesh Sharma',
        'customer_mobile': '+91 9876543210',
        'customer_email': 'rajesh@acme.com',
        'image_url': 'https://storage.supabase.co/sites/site1.jpg',
      };

      final project = Project.fromJson(json);

      expect(project.id, equals('proj-101'));
      expect(project.name, equals('Skyline Towers Phase 1'));
      expect(project.builtUpArea, equals(125000.0));
      expect(project.flatArea, equals(95000.0));
      expect(project.duration, equals('18 Months'));
      expect(project.customerName, equals('Rajesh Sharma'));
      expect(project.customerMobile, equals('+91 9876543210'));
      expect(project.remainingBalance, equals(38000000.0));

      final serialized = project.toJson();
      expect(serialized['built_up_area'], equals(125000.0));
      expect(serialized['duration'], equals('18 Months'));
      expect(serialized['customer_name'], equals('Rajesh Sharma'));
    });

    test('ChecklistItem model serialization & toggle logic', () {
      final item = ChecklistItem(
        id: 'chk-1',
        projectId: 'proj-101',
        title: 'Foundation Concrete Strength Test',
        category: 'Quality Control',
        isCompleted: false,
        createdAt: DateTime.parse('2026-07-21T10:00:00Z'),
      );

      expect(item.isCompleted, isFalse);

      final toggled = item.copyWith(isCompleted: true);
      expect(toggled.isCompleted, isTrue);

      final json = toggled.toJson();
      expect(json['project_id'], equals('proj-101'));
      expect(json['is_completed'], isTrue);
    });

    test('SalesBill model serialization & status logic', () {
      final bill = SalesBill(
        id: 'bill-501',
        projectId: 'proj-101',
        billNumber: 'INV-2026-001',
        clientName: 'Acme Infrastructure',
        amount: 500000.0,
        taxAmount: 90000.0,
        totalAmount: 590000.0,
        status: 'Unpaid',
        dueDate: DateTime.parse('2026-08-15'),
        createdAt: DateTime.now(),
      );

      expect(bill.totalAmount, equals(590000.0));
      expect(bill.status, equals('Unpaid'));

      final json = bill.toJson();
      expect(json['bill_number'], equals('INV-2026-001'));
      expect(json['total_amount'], equals(590000.0));
    });

    test('ProjectPayment model serialization', () {
      final payment = ProjectPayment(
        id: 'pay-901',
        projectId: 'proj-101',
        title: 'Milestone 1 Advance Received',
        paymentType: 'Received',
        amount: 250000.0,
        paymentMethod: 'Bank Transfer',
        referenceNo: 'TXN-987654321',
        paymentDate: DateTime.parse('2026-07-20'),
        createdAt: DateTime.now(),
      );

      expect(payment.paymentType, equals('Received'));
      expect(payment.amount, equals(250000.0));

      final json = payment.toJson();
      expect(json['payment_type'], equals('Received'));
      expect(json['reference_no'], equals('TXN-987654321'));
    });
  });
}
