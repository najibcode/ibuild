import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../data/repositories/supabase_attendance_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/models/attendance_model.dart';
import '../../../employees/presentation/controllers/employee_controller.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  return SupabaseAttendanceRepository(client, activityRepo);
});

class AttendanceState {
  final bool isLoading;
  final List<Attendance> attendanceList;
  final List<Employee> activeEmployees;
  final String? error;

  AttendanceState({
    required this.isLoading,
    required this.attendanceList,
    required this.activeEmployees,
    this.error,
  });

  factory AttendanceState.initial() => AttendanceState(
        isLoading: false,
        attendanceList: [],
        activeEmployees: [],
      );

  AttendanceState copyWith({
    bool? isLoading,
    List<Attendance>? attendanceList,
    List<Employee>? activeEmployees,
    String? error,
    bool clearError = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      attendanceList: attendanceList ?? this.attendanceList,
      activeEmployees: activeEmployees ?? this.activeEmployees,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AttendanceController extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final Ref _ref;

  AttendanceController(this._repository, this._ref) : super(AttendanceState.initial()) {
    loadAttendanceForToday();
  }

  Future<void> loadAttendanceForToday({bool showLoading = true}) async {
    if (showLoading && state.activeEmployees.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    try {
      // 1. Fetch active employees
      final employees = await _ref.read(employeeRepositoryProvider).getEmployees();
      final active = employees.where((e) => e.status.toLowerCase() == 'active').toList();

      // 2. Fetch logged attendance
      final logged = await _repository.getAttendanceForDate(todayStr);

      state = state.copyWith(
        isLoading: false,
        activeEmployees: active,
        attendanceList: logged,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAttendance({
    required String employeeId,
    required String status,
    String? projectId,
  }) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final normalizedStatus = status.toLowerCase() == 'present' ? 'Present' : 'Absent';

    // 1. Optimistic UI update
    final updatedList = List<Attendance>.from(state.attendanceList);
    final existingIdx = updatedList.indexWhere((a) => a.employeeId == employeeId);
    final currentRecord = existingIdx >= 0 ? updatedList[existingIdx] : null;

    final newRecord = Attendance(
      id: currentRecord?.id ?? '',
      employeeId: employeeId,
      date: todayStr,
      status: normalizedStatus,
      projectId: projectId ?? currentRecord?.projectId,
    );

    if (existingIdx >= 0) {
      updatedList[existingIdx] = newRecord;
    } else {
      updatedList.add(newRecord);
    }

    state = state.copyWith(attendanceList: updatedList);

    // 2. Persist to backend without triggering full-screen loading spinner
    try {
      await _repository.saveAttendance(newRecord);
      // Refresh dashboard stats so KPIs update (Workers Present, etc.)
      _ref.invalidate(dashboardStatsProvider);
      await loadAttendanceForToday(showLoading: false);
    } catch (e) {
      // Keep optimistic state but surface error
      state = state.copyWith(error: 'Attendance saved locally but failed to sync: $e');
    }
  }
}

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceController(repository, ref);
});

/// Data class holding project-scoped attendance (today + recent history).
class ProjectAttendanceData {
  final List<Attendance> todayRecords;
  final List<Attendance> recentHistory;

  ProjectAttendanceData({required this.todayRecords, required this.recentHistory});
}

/// Provider that fetches attendance scoped to a specific project.
/// Returns today's records + past history for the project, merged with in-memory state.
final projectAttendanceProvider =
    FutureProvider.family<ProjectAttendanceData, String>((ref, projectId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final todayStr = DateTime.now().toIso8601String().substring(0, 10);

  // Fetch DB records for today and past 365 days for this project
  final dbToday = await repo.getAttendanceForProject(projectId, todayStr);
  final dbHistory = await repo.getAttendanceHistoryForProject(projectId, days: 365);

  // Merge with in-memory attendanceControllerProvider state for instant UI updates
  final globalState = ref.watch(attendanceControllerProvider);
  final memoryToday = globalState.attendanceList.where((a) => a.projectId == projectId && (a.date.isEmpty || a.date == todayStr)).toList();

  final Map<String, Attendance> mergedTodayMap = {};
  for (final r in dbToday) {
    mergedTodayMap[r.employeeId] = r;
  }
  for (final r in memoryToday) {
    mergedTodayMap[r.employeeId] = r;
  }

  final Map<String, Attendance> mergedHistoryMap = {};
  for (final r in dbHistory) {
    mergedHistoryMap['${r.employeeId}_${r.date}'] = r;
  }
  for (final r in globalState.attendanceList) {
    if (r.projectId == projectId && r.date.isNotEmpty) {
      mergedHistoryMap['${r.employeeId}_${r.date}'] = r;
    }
  }

  return ProjectAttendanceData(
    todayRecords: mergedTodayMap.values.toList(),
    recentHistory: mergedHistoryMap.values.toList(),
  );
});

