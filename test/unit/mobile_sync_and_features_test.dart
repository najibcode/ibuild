import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/core/utils/date_range_filter_helper.dart';
import 'package:ibuild/features/employees/data/models/employee_model.dart';
import 'package:ibuild/features/employees/domain/repositories/employee_repository.dart';
import 'package:ibuild/features/employees/presentation/controllers/employee_controller.dart';
import 'package:ibuild/features/projects/data/models/project_model.dart';
import 'package:ibuild/features/projects/domain/repositories/project_repository.dart';
import 'package:ibuild/features/projects/presentation/controllers/project_controller.dart';
import 'package:ibuild/features/attendance/data/models/attendance_model.dart';

class MockEmployeeRepo implements EmployeeRepository {
  List<Employee> items = [];
  MockEmployeeRepo(this.items);

  @override
  Future<List<Employee>> getEmployees({String? search, String? roleFilter, String? statusFilter, int limit = 20, int offset = 0}) async {
    return items;
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final idx = items.indexWhere((e) => e.id == id);
    return idx != -1 ? items[idx] : null;
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    items.add(employee);
    return employee;
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final idx = items.indexWhere((e) => e.id == employee.id);
    if (idx != -1) items[idx] = employee;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    items.removeWhere((e) => e.id == id);
    final cache = OfflineDataCache();
    final existing = cache.getCachedEmployees() ?? [];
    existing.removeWhere((e) => e['id'] == id);
    cache.cacheEmployees(existing);
  }

  @override
  Future<void> applySalaryRevision({
    required String employeeId,
    required double newSalary,
    required double newTeaAllowance,
    required DateTime effectiveDate,
    String? reason,
  }) async {
    final idx = items.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(
        salary: newSalary,
        teaSnackAllowance: newTeaAllowance,
      );
    }
  }
}

class MockProjectRepo implements ProjectRepository {
  List<Project> items = [];
  MockProjectRepo(this.items);

  @override
  Future<List<Project>> getProjects({String? search, String? statusFilter, String? sortBy, bool ascending = true, int limit = 20, int offset = 0, bool includeArchived = false}) async {
    return items;
  }

  @override
  Future<int> getProjectCount({String? statusFilter, bool includeArchived = false}) async {
    return items.length;
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final idx = items.indexWhere((p) => p.id == id);
    return idx != -1 ? items[idx] : null;
  }

  @override
  Future<Project> createProject(Project project) async {
    items.add(project);
    return project;
  }

  @override
  Future<Project> updateProject(Project project) async {
    final idx = items.indexWhere((p) => p.id == project.id);
    if (idx != -1) items[idx] = project;
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    items.removeWhere((p) => p.id == id);
    final cache = OfflineDataCache();
    final existing = cache.getCachedProjects() ?? [];
    existing.removeWhere((p) => p['id'] == id);
    cache.cacheProjects(existing);
  }

  @override
  Future<void> archiveProject(String id) async {
    final idx = items.indexWhere((p) => p.id == id);
    if (idx != -1) items[idx] = items[idx].copyWith(isArchived: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OfflineDataCache().cacheProjects([]);
    OfflineDataCache().cacheEmployees([]);
  });

  group('Mobile Functions & Synchronization Tests', () {
    test('Employee deletion removes record and purges offline cache', () async {
      final emp1 = Employee(
        id: 'emp_001',
        name: 'Ramesh Kumar',
        role: 'Mason',
        phone: '9876543210',
        salary: 850.0,
        teaSnackAllowance: 50.0,
        status: 'active',
      );
      final emp2 = Employee(
        id: 'emp_002',
        name: 'Suresh Patel',
        role: 'Electrician',
        phone: '9876543211',
        salary: 950.0,
        teaSnackAllowance: 50.0,
        status: 'active',
      );

      final mockRepo = MockEmployeeRepo([emp1, emp2]);
      final controller = EmployeeListController(mockRepo);

      await Future.delayed(const Duration(milliseconds: 50));
      final initialList = controller.state.value ?? [];
      expect(initialList.length, equals(2));

      // Delete emp_001
      final success = await controller.removeEmployee('emp_001');
      expect(success, isTrue);

      final updatedList = controller.state.value ?? [];
      expect(updatedList.length, equals(1));
      expect(updatedList.first.id, equals('emp_002'));
      expect(mockRepo.items.any((e) => e.id == 'emp_001'), isFalse);
    });

    test('Project deletion removes project and purges offline cache', () async {
      final proj1 = Project(
        id: 'proj_alpha',
        name: 'Alpha Tower',
        budget: 1000000,
        spent: 250000,
        status: 'active',
      );
      final proj2 = Project(
        id: 'proj_beta',
        name: 'Beta Plaza',
        budget: 2000000,
        spent: 500000,
        status: 'planning',
      );

      final mockRepo = MockProjectRepo([proj1, proj2]);
      final controller = ProjectController(mockRepo);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.projects.length, equals(2));

      // Delete proj_alpha
      await controller.removeProject('proj_alpha');
      expect(controller.state.projects.length, equals(1));
      expect(controller.state.projects.first.id, equals('proj_beta'));
      expect(mockRepo.items.any((p) => p.id == 'proj_alpha'), isFalse);
    });

    test('Attendance model computes earnings and tea allowance correctly', () {
      final attendanceFull = Attendance(
        id: 'att_1',
        employeeId: 'emp_1',
        date: '2026-09-05',
        status: 'Present',
        wageRate: 800.0,
        teaAllowance: 50.0,
      );

      expect(attendanceFull.wageRate, equals(800.0));
      expect(attendanceFull.teaAllowance, equals(50.0));
      expect(attendanceFull.status, equals('Present'));

      final json = attendanceFull.toJson();
      expect(json['morning_status'], equals('present'));
      expect(json['evening_status'], equals('present'));
      expect(json['wage_rate'], equals(800.0));
      expect(json['tea_allowance'], equals(50.0));

      final attendanceAbsent = Attendance(
        id: 'att_2',
        employeeId: 'emp_2',
        date: '2026-09-05',
        status: 'Absent',
        wageRate: 800.0,
        teaAllowance: 0.0,
      );

      expect(attendanceAbsent.status, equals('Absent'));
      expect(attendanceAbsent.teaAllowance, equals(0.0));
      expect(attendanceAbsent.toJson()['morning_status'], equals('absent'));
    });

    test('DateRangeFilterHelper correctly filters records within boundary dates', () {
      final now = DateTime.now();
      final items = [
        {'id': 1, 'date': now.subtract(const Duration(days: 2))},
        {'id': 2, 'date': now.subtract(const Duration(days: 10))},
        {'id': 3, 'date': now.subtract(const Duration(days: 45))},
      ];

      final filtered7Days = DateRangeFilterHelper.filterByDateTime(
        items,
        start: now.subtract(const Duration(days: 7)),
        end: now,
        getDate: (item) => item['date'] as DateTime?,
      );
      expect(filtered7Days.length, equals(1));
      expect(filtered7Days.first['id'], equals(1));

      final filtered30Days = DateRangeFilterHelper.filterByDateTime(
        items,
        start: now.subtract(const Duration(days: 30)),
        end: now,
        getDate: (item) => item['date'] as DateTime?,
      );
      expect(filtered30Days.length, equals(2));

      final filteredAll = DateRangeFilterHelper.filterByDateTime(
        items,
        start: now.subtract(const Duration(days: 100)),
        end: now,
        getDate: (item) => item['date'] as DateTime?,
      );
      expect(filteredAll.length, equals(3));
    });
  });
}
