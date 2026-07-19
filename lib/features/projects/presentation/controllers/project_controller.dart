import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../data/repositories/supabase_project_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/models/project_model.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProjectRepository(client);
});

class ProjectListState {
  final List<Project> projects;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? statusFilter;
  final String sortBy;
  final bool ascending;
  final int offset;
  final bool hasMore;

  ProjectListState({
    required this.projects,
    required this.isLoading,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter,
    this.sortBy = 'created_at',
    this.ascending = false,
    this.offset = 0,
    this.hasMore = true,
  });

  factory ProjectListState.initial() =>
      ProjectListState(projects: [], isLoading: false);

  ProjectListState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? statusFilter,
    String? sortBy,
    bool? ascending,
    int? offset,
    bool? hasMore,
    bool clearError = false,
  }) {
    return ProjectListState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ProjectController extends StateNotifier<ProjectListState> {
  final ProjectRepository _repository;
  static const _pageSize = 20;

  ProjectController(this._repository) : super(ProjectListState.initial()) {
    loadProjects();
  }

  Future<void> loadProjects({bool reset = true}) async {
    if (state.isLoading) return;

    final newOffset = reset ? 0 : state.offset;
    state = state.copyWith(
      isLoading: true,
      offset: newOffset,
      clearError: true,
    );
    if (reset) state = state.copyWith(projects: []);

    try {
      final results = await _repository.getProjects(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        statusFilter: state.statusFilter,
        sortBy: state.sortBy,
        ascending: state.ascending,
        limit: _pageSize,
        offset: newOffset,
      );

      final combined = reset ? results : [...state.projects, ...results];
      state = state.copyWith(
        projects: combined,
        isLoading: false,
        offset: newOffset + results.length,
        hasMore: results.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void loadMore() => loadProjects(reset: false);

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, offset: 0);
    loadProjects();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status, offset: 0);
    loadProjects();
  }

  void setSort(String sortBy) {
    state = state.copyWith(
      sortBy: sortBy,
      ascending: !state.ascending,
      offset: 0,
    );
    loadProjects();
  }

  Future<void> addProject(Project project) async {
    try {
      await _repository.createProject(project);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> editProject(Project project) async {
    try {
      await _repository.updateProject(project);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> removeProject(String id) async {
    try {
      await _repository.deleteProject(id);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> archive(String id) async {
    try {
      await _repository.archiveProject(id);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }
}

final projectControllerProvider =
    StateNotifierProvider<ProjectController, ProjectListState>((ref) {
      final repo = ref.watch(projectRepositoryProvider);
      return ProjectController(repo);
    });
