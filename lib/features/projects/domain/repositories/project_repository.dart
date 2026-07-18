import '../../data/models/project_model.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects({
    String? search,
    String? statusFilter,
    String? sortBy,
    bool ascending = true,
    int limit = 20,
    int offset = 0,
    bool includeArchived = false,
  });
  Future<Project?> getProjectById(String id);
  Future<void> createProject(Project project);
  Future<void> updateProject(Project project);
  Future<void> deleteProject(String id);
  Future<void> archiveProject(String id);
  Future<int> getProjectCount({String? statusFilter, bool includeArchived = false});
}
