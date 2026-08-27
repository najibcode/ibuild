import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/subcontractors/data/models/subcontractor_model.dart';

void main() {
  group('Subcontractor Site Assignment Unit Tests', () {
    test('Subcontractor model preserves projectId and siteName correctly', () {
      final sub = Subcontractor(
        id: 'sub_101',
        name: 'Apex Structural Contractors',
        specialization: 'RCC Structure',
        contractValue: 500000,
        paidAmount: 150000,
        status: 'Active',
        createdAt: DateTime(2026, 8, 1),
      );

      expect(sub.projectId, isNull);
      expect(sub.siteName, 'Unassigned');

      final assignedSub = sub.copyWith(
        projectId: 'proj_skyline_202',
        siteNameProp: 'Skyline Luxury Towers',
      );

      expect(assignedSub.projectId, 'proj_skyline_202');
      expect(assignedSub.siteName, 'Skyline Luxury Towers');

      final dbJson = assignedSub.toDbJson();
      expect(dbJson['project_id'], 'proj_skyline_202');
      expect(dbJson['site_name'], 'Skyline Luxury Towers');

      final parsed = Subcontractor.fromJson({
        'id': 'sub_101',
        'name': 'Apex Structural Contractors',
        'project_id': 'proj_skyline_202',
        'site_name': 'Skyline Luxury Towers',
        'contract_value': 500000,
        'paid_amount': 150000,
      });

      expect(parsed.projectId, 'proj_skyline_202');
      expect(parsed.siteName, 'Skyline Luxury Towers');
    });

    test('Subcontractor.fromJson resolves site name from joined projects relationship', () {
      final jsonWithJoin = {
        'id': 'sub_102',
        'company_name': 'AquaFlow Plumbing',
        'project_id': 'proj_lakeview_303',
        'projects': {'name': 'Lakeview Residency'},
        'contract_value': 200000,
        'paid_amount': 50000,
      };

      final sub = Subcontractor.fromJson(jsonWithJoin);
      expect(sub.projectId, 'proj_lakeview_303');
      expect(sub.siteName, 'Lakeview Residency');
    });
  });
}
