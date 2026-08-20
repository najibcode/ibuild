import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/subcontractors/data/models/subcontractor_model.dart';

void main() {
  group('Subcontractor Model & Project Sync Tests', () {
    test('Subcontractor serialization preserves project_id and site_name in toDbJson and fromJson', () {
      final sub = Subcontractor(
        id: 'sub-101',
        name: 'Apex Electricals',
        companyNameProp: 'Apex Electricals Pvt Ltd',
        contactPersonProp: 'Rajesh Sharma',
        specialization: 'Electrical & MEP',
        phone: '9876543210',
        email: 'rajesh@apexelectricals.com',
        address: 'Sector 4, Industrial Area',
        projectId: 'proj-001',
        siteNameProp: 'Skyline Towers Phase 1',
        scopeOfWork: 'Complete conduit & wiring for Block A',
        gstNumber: '27AAAAA0000A1Z5',
        contractValue: 500000.0,
        paidAmount: 200000.0,
        status: 'Active',
        createdAt: DateTime(2026, 8, 20),
      );

      expect(sub.projectId, equals('proj-001'));
      expect(sub.siteName, equals('Skyline Towers Phase 1'));
      expect(sub.contactPerson, equals('Rajesh Sharma'));
      expect(sub.tradeSpecialization, equals('Electrical & MEP'));
      expect(sub.retentionPending, equals(300000.0));
      expect(sub.outstandingAmount, equals(300000.0));
      expect(sub.paymentProgress, equals(0.4));
      expect(sub.isOverpaid, isFalse);

      final dbJson = sub.toDbJson();
      expect(dbJson['project_id'], equals('proj-001'));
      expect(dbJson['site_name'], equals('Skyline Towers Phase 1'));
      expect(dbJson['contact_person'], equals('Rajesh Sharma'));
      expect(dbJson['scope_of_work'], equals('Complete conduit & wiring for Block A'));
      expect(dbJson['contract_value'], equals(500000.0));
      expect(dbJson['paid_amount'], equals(200000.0));

      final restored = Subcontractor.fromJson(dbJson);
      expect(restored.projectId, equals('proj-001'));
      expect(restored.siteName, equals('Skyline Towers Phase 1'));
      expect(restored.contactPerson, equals('Rajesh Sharma'));
      expect(restored.scopeOfWork, equals('Complete conduit & wiring for Block A'));
      expect(restored.contractValue, equals(500000.0));
      expect(restored.paidAmount, equals(200000.0));
    });

    test('Subcontractor correctly handles project join structure from Supabase', () {
      final joinedJson = {
        'id': 'sub-202',
        'name': 'Sri Laxmi Plumbing',
        'specialization': 'Plumbing & Drainage',
        'project_id': 'proj-999',
        'projects': {
          'name': 'Greenfield Metro Depot',
        },
        'contract_value': 1200000.0,
        'paid_amount': 600000.0,
        'status': 'Active',
      };

      final sub = Subcontractor.fromJson(joinedJson);
      expect(sub.projectId, equals('proj-999'));
      expect(sub.siteName, equals('Greenfield Metro Depot'));
      expect(sub.paymentProgress, equals(0.5));
      expect(sub.retentionPending, equals(600000.0));
    });

    test('Subcontractor copyWith updates paid amount and project properly', () {
      final sub = Subcontractor(
        id: 'sub-303',
        name: 'Apex Fabrication',
        contractValue: 800000.0,
        paidAmount: 300000.0,
        status: 'Active',
        createdAt: DateTime.now(),
      );

      final updated = sub.copyWith(
        paidAmount: 500000.0,
        projectId: 'proj-777',
        siteNameProp: 'City Mall Renovation',
      );

      expect(updated.paidAmount, equals(500000.0));
      expect(updated.projectId, equals('proj-777'));
      expect(updated.siteName, equals('City Mall Renovation'));
      expect(updated.retentionPending, equals(300000.0));
      expect(updated.paymentProgress, equals(0.625));
    });
  });
}
