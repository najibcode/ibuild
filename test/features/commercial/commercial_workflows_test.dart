import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/vendors/data/models/vendor_model.dart';
import 'package:ibuild/features/subcontractors/data/models/subcontractor_model.dart';
import 'package:ibuild/features/payments/data/models/payment_ledger_model.dart';
import 'package:ibuild/features/properties/data/models/property_model.dart';

void main() {
  group('Commercial Workflows & Financial Integrity Tests', () {
    test('Supplier/Vendor outstanding balance and overpayment getters', () {
      final supplier = Vendor(
        id: 'v-101',
        name: 'UltraTech Cement Supplier',
        totalAmount: 100000.0,
        paidAmount: 40000.0,
        balanceDue: 60000.0,
        createdAt: DateTime.now(),
      );

      expect(supplier.outstandingBalance, equals(60000.0));
      expect(supplier.isOverpaid, isFalse);

      final overpaidSupplier = supplier.copyWith(paidAmount: 120000.0);
      expect(overpaidSupplier.isOverpaid, isTrue);
    });

    test('Trade Partner/Subcontractor contract and outstanding calculation', () {
      final partner = Subcontractor(
        id: 'sub-201',
        name: 'Supreme Electricals',
        specialization: 'Electrical',
        contractValue: 250000.0,
        paidAmount: 150000.0,
        status: 'Active',
        createdAt: DateTime.now(),
      );

      expect(partner.outstandingAmount, equals(100000.0));
      expect(partner.isOverpaid, isFalse);

      final fullyPaid = partner.copyWith(paidAmount: 250000.0);
      expect(fullyPaid.outstandingAmount, equals(0.0));
    });

    test('PaymentLedgerEntry serialization and running balance logic', () {
      final entry = PaymentLedgerEntry(
        id: 'ledg-1',
        projectId: 'proj-101',
        counterpartyType: 'Supplier',
        counterpartyName: 'UltraTech Cement',
        paymentType: 'Paid',
        amount: 25000.0,
        paymentMethod: 'Bank Transfer',
        paymentDate: DateTime.parse('2026-07-21'),
        runningBalance: 75000.0,
        createdAt: DateTime.now(),
      );

      expect(entry.paymentType, equals('Paid'));
      expect(entry.amount, equals(25000.0));
      expect(entry.runningBalance, equals(75000.0));

      final json = entry.toJson();
      expect(json['counterparty_type'], equals('Supplier'));
      expect(json['running_balance'], equals(75000.0));
    });

    test('Property model serialization', () {
      final prop = Property(
        id: 'prop-1',
        propertyName: 'Green Valley Plot #42',
        location: 'Cyber City, Sector 5',
        propertyType: 'Commercial Plot',
        amount: 8500000.0,
        agentName: 'Vikram Singh',
        agentCompany: 'Prime Realty',
        agentMobile: '+91 9876543210',
        status: 'Available',
        createdAt: DateTime.now(),
      );

      expect(prop.amount, equals(8500000.0));
      expect(prop.status, equals('Available'));

      final json = prop.toJson();
      expect(json['property_name'], equals('Green Valley Plot #42'));
      expect(json['agent_name'], equals('Vikram Singh'));
    });
  });
}
