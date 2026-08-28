import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/features/employees/data/models/employee_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee Salary Update and Reload Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      OfflineDataCache().clear();
    });

    test('1. Employee model properly parses salary and daily_rate fallbacks', () {
      // Test with 'salary'
      final emp1 = Employee.fromJson({
        'id': 'emp-1',
        'name': 'Ravi',
        'salary': 950.0,
        'tea_snack_allowance': 30.0,
      });
      expect(emp1.salary, equals(950.0));
      expect(emp1.dailyRate, equals(950.0));
      expect(emp1.teaSnackAllowance, equals(30.0));
      expect(emp1.totalDailyCost, equals(980.0));

      // Test with 'daily_rate' key
      final emp2 = Employee.fromJson({
        'id': 'emp-2',
        'name': 'Ganesh',
        'daily_rate': 1200.0,
        'tea_allowance': 40.0,
      });
      expect(emp2.salary, equals(1200.0));
      expect(emp2.dailyRate, equals(1200.0));
      expect(emp2.teaSnackAllowance, equals(40.0));

      // Test toJson contains both keys for database resilience
      final json = emp1.toJson();
      expect(json['salary'], equals(950.0));
      expect(json['daily_rate'], equals(950.0));
      expect(json['tea_snack_allowance'], equals(30.0));
    });

    test('2. Initializing OfflineDataCache seeds realistic daily wage rates and allows salary updates', () async {
      final cache = OfflineDataCache();
      await cache.init();

      final initialEmployees = cache.getCachedEmployees();
      expect(initialEmployees, isNotNull);
      expect(initialEmployees!.isNotEmpty, isTrue);

      // Verify Soori's daily salary is realistic (₹1200/day, not 32000)
      final soori = initialEmployees.firstWhere((e) => e['name'] == 'Soori');
      expect((soori['salary'] as num).toDouble(), equals(1200.0));

      // User updates Soori's daily wage to ₹1500/day
      final updatedSoori = Map<String, dynamic>.from(soori);
      updatedSoori['salary'] = 1500.0;
      updatedSoori['daily_rate'] = 1500.0;

      final updatedList = initialEmployees.map((e) {
        return e['id'] == soori['id'] ? updatedSoori : e;
      }).toList();

      cache.cacheEmployees(updatedList);

      // Verify update in current session
      final cachedNow = cache.getCachedEmployees()!;
      final verifiedSoori = cachedNow.firstWhere((e) => e['id'] == soori['id']);
      expect((verifiedSoori['salary'] as num).toDouble(), equals(1500.0));
    });

    test('3. Employee salary update is strictly preserved across simulated page reloads', () async {
      final cache = OfflineDataCache();
      await cache.init();

      final employees = cache.getCachedEmployees() ?? [];
      final soori = employees.firstWhere((e) => e['name'] == 'Soori');
      final sooriId = soori['id'] as String;

      // Update Soori's salary to ₹1750/day and snacks to ₹45/day
      final modifiedEmployees = employees.map((e) {
        if (e['id'] == sooriId) {
          final copy = Map<String, dynamic>.from(e);
          copy['salary'] = 1750.0;
          copy['daily_rate'] = 1750.0;
          copy['tea_snack_allowance'] = 45.0;
          return copy;
        }
        return e;
      }).toList();

      cache.cacheEmployees(modifiedEmployees);

      // ── SIMULATE APP / BROWSER RELOAD ──
      await cache.reloadFromStorage();

      final reloadedEmployees = cache.getCachedEmployees();
      expect(reloadedEmployees, isNotNull);

      final reloadedSoori = reloadedEmployees!.firstWhere((e) => e['id'] == sooriId);
      expect((reloadedSoori['salary'] as num).toDouble(), equals(1750.0),
          reason: 'Salary must not be reverted to default after reload');
      expect((reloadedSoori['tea_snack_allowance'] as num).toDouble(), equals(45.0),
          reason: 'Tea allowance must be preserved after reload');
    });

    test('4. Adding a new employee preserves custom salary across reloads', () async {
      final cache = OfflineDataCache();
      await cache.init();

      final existing = cache.getCachedEmployees() ?? [];
      final newEmp = Employee(
        id: '99999999-9999-4999-8999-999999999999',
        name: 'Kavitha Plumber',
        phone: '+91 9123456780',
        role: 'Plumber',
        salary: 1350.0,
        teaSnackAllowance: 30.0,
        status: 'active',
      );

      final updated = [newEmp.toMap(), ...existing];
      cache.cacheEmployees(updated);

      // Verify cached
      final retrieved = cache.getCachedEmployees()!;
      expect(retrieved.any((e) => e['name'] == 'Kavitha Plumber'), isTrue);

      // ── SIMULATE PAGE RELOAD ──
      await cache.reloadFromStorage();

      final afterReload = cache.getCachedEmployees()!;
      final kavitha = afterReload.firstWhere((e) => e['name'] == 'Kavitha Plumber');
      expect((kavitha['salary'] as num).toDouble(), equals(1350.0));
      expect((kavitha['tea_snack_allowance'] as num).toDouble(), equals(30.0));
    });

    test('5. Project budget and spend changes are also preserved across reloads', () async {
      final cache = OfflineDataCache();
      await cache.init();

      final projects = cache.getCachedProjects() ?? [];
      expect(projects.isNotEmpty, isTrue);

      final ppr = projects.firstWhere((p) => p['name'] == 'PPR shop');
      final pprId = ppr['id'] as String;

      // Update PPR shop budget
      final updatedProjects = projects.map((p) {
        if (p['id'] == pprId) {
          final copy = Map<String, dynamic>.from(p);
          copy['budget'] = 2500000.0;
          copy['spent'] = 650000.0;
          return copy;
        }
        return p;
      }).toList();

      cache.cacheProjects(updatedProjects);

      // ── SIMULATE RELOAD ──
      await cache.reloadFromStorage();

      final reloadedProjects = cache.getCachedProjects()!;
      final reloadedPpr = reloadedProjects.firstWhere((p) => p['id'] == pprId);
      expect((reloadedPpr['budget'] as num).toDouble(), equals(2500000.0));
      expect((reloadedPpr['spent'] as num).toDouble(), equals(650000.0));
    });
  });
}
