import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_model.dart';
import '../controllers/project_controller.dart';
import 'project_dashboard_screen.dart';

final projectDetailProvider = FutureProvider.family<Project?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(projectRepositoryProvider);
  return await repo.getProjectById(id);
});

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Project not found')),
          );
        }
        return ProjectDashboardScreen(
          projectId: project.id,
          projectName: project.name,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
