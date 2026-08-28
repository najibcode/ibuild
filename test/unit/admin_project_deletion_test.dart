import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/features/projects/data/models/project_model.dart';
import 'package:ibuild/features/projects/domain/repositories/project_repository.dart';
import 'package:ibuild/features/projects/presentation/controllers/project_controller.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';

class MockProjectRepository implements ProjectRepository {
  List<Project> projectsList = [];

  MockProjectRepository(this.projectsList);

  @override
  Future<List<Project>> getProjects({
    String? search,
    String? statusFilter,
    String? sortBy,
    bool ascending = true,
    int limit = 20,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    return projectsList;
  }

  @override
  Future<int> getProjectCount({String? statusFilter, bool includeArchived = false}) async {
    return projectsList.length;
  }

  @override
  Future<Project?> getProjectById(String id) async {
    return projectsList.firstWhere((p) => p.id == id);
  }

  @override
  Future<Project> createProject(Project project) async {
    projectsList.add(project);
    return project;
  }

  @override
  Future<Project> updateProject(Project project) async {
    final idx = projectsList.indexWhere((p) => p.id == project.id);
    if (idx != -1) {
      projectsList[idx] = project;
    }
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    projectsList.removeWhere((p) => p.id == id);
    final cache = OfflineDataCache();
    final existing = cache.getCachedProjects() ?? [];
    existing.removeWhere((p) => p['id'] == id);
    cache.cacheProjects(existing);
  }

  @override
  Future<void> archiveProject(String id) async {
    final idx = projectsList.indexWhere((p) => p.id == id);
    if (idx != -1) {
      projectsList[idx] = projectsList[idx].copyWith(isArchived: true);
    }
  }
}

void main() {
  setUp(() {
    OfflineDataCache().cacheProjects([]);
  });

  group('Admin Project Deletion Feature Tests', () {
    test('isAdminProvider returns true for admin role and false for others', () {
      final containerAdmin = ProviderContainer(
        overrides: [
          currentRoleProvider.overrideWithValue('admin'),
        ],
      );
      expect(containerAdmin.read(isAdminProvider), isTrue);

      final containerSupervisor = ProviderContainer(
        overrides: [
          currentRoleProvider.overrideWithValue('supervisor'),
        ],
      );
      expect(containerSupervisor.read(isAdminProvider), isFalse);

      final containerEmployee = ProviderContainer(
        overrides: [
          currentRoleProvider.overrideWithValue('employee'),
        ],
      );
      expect(containerEmployee.read(isAdminProvider), isFalse);
    });

    test('removeProject deletes project and reloads state', () async {
      final initialProjects = [
        Project(
          id: 'proj_001',
          name: 'Greenfield Heights Block A',
          budget: 5000000,
          status: 'active',
        ),
        Project(
          id: 'proj_002',
          name: 'Palm Residency Villa 12',
          budget: 1200000,
          status: 'planning',
        ),
      ];

      final mockRepo = MockProjectRepository(List.from(initialProjects));
      final controller = ProjectController(mockRepo);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.projects.length, equals(2));

      // Admin deletes proj_001
      await controller.removeProject('proj_001');

      expect(controller.state.projects.length, equals(1));
      expect(controller.state.projects.first.id, equals('proj_002'));
      expect(mockRepo.projectsList.any((p) => p.id == 'proj_001'), isFalse);
    });

    test('Project.fromJson deserializes missing and dynamic fields defensively', () {
      final json = {
        'id': 'proj_999',
        'name': 'Skyline Commercial Tower',
        'budget': '45000000', // String from API
        'spent': 1500000,
        'status': 'active',
        'created_at': '2026-08-28T12:00:00Z',
        'updated_at': null,
      };

      final project = Project.fromJson(json);
      expect(project.id, equals('proj_999'));
      expect(project.name, equals('Skyline Commercial Tower'));
      expect(project.spent, equals(1500000.0));
      expect(project.status, equals('active'));
    });
  });
}
