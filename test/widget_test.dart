import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/features/projects/data/models/project_model.dart';

void main() {
  test('serializes project data for Supabase and calculates budget usage', () {
    final project = Project(
      id: 'project-1',
      name: 'Riverside Commercial Complex',
      clientName: 'Northstar Properties',
      projectCode: 'RCC-2026',
      address: 'Kochi, Kerala',
      budget: 12500000,
      estimatedCost: 11000000,
      spent: 2500000,
      status: 'active',
      startDate: '2026-07-01',
      expectedCompletion: '2027-03-31',
      description: 'Commercial construction and fit-out.',
      notes: 'Phase one is underway.',
    );

    final payload = project.toJson();

    expect(payload['name'], 'Riverside Commercial Complex');
    expect(payload['project_code'], 'RCC-2026');
    expect(payload['description'], 'Commercial construction and fit-out.');
    expect(payload.containsKey('id'), isFalse);
    expect(project.budgetUtilization, 0.2);
  });
}
