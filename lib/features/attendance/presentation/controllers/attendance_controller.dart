import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../data/repositories/supabase_attendance_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/models/attendance_model.dart';
import '../../../employees/presentation/controllers/employee_controller.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../projects/presentation/controllers/project_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../settings/data/repositories/supabase_settings_repository.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  return SupabaseAttendanceRepository(client, activityRepo);
});

class AttendanceState {
  final bool isLoading;
  final String selectedDate;
  final List<Attendance> attendanceList;
  final List<Employee> activeEmployees;
  /// Key: "${employeeId}_${date}", Value: projectId
  final Map<String, String> siteAssignments;
  final String? error;
  final String? successMessage;

  AttendanceState({
    required this.isLoading,
    required this.selectedDate,
    required this.attendanceList,
    required this.activeEmployees,
    required this.siteAssignments,
    this.error,
    this.successMessage,
  });

  factory AttendanceState.initial() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return AttendanceState(
      isLoading: false,
      selectedDate: today,
      attendanceList: [],
      activeEmployees: [],
      siteAssignments: {},
    );
  }

  AttendanceState copyWith({
    bool? isLoading,
    String? selectedDate,
    List<Attendance>? attendanceList,
    List<Employee>? activeEmployees,
    Map<String, String>? siteAssignments,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      attendanceList: attendanceList ?? this.attendanceList,
      activeEmployees: activeEmployees ?? this.activeEmployees,
      siteAssignments: siteAssignments ?? this.siteAssignments,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AttendanceController extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final Ref _ref;

  AttendanceController(this._repository, this._ref) : super(AttendanceState.initial()) {
    loadAttendanceForDate(state.selectedDate);
  }

  Future<void> loadAttendanceForToday({bool showLoading = true}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await loadAttendanceForDate(today, showLoading: showLoading);
  }

  Future<void> loadAttendanceForDate(String date, {bool showLoading = true}) async {
    if (showLoading && state.activeEmployees.isEmpty) {
      state = state.copyWith(isLoading: true, selectedDate: date);
    } else {
      state = state.copyWith(selectedDate: date);
    }

    debugPrint('[AttendanceCtrl] Loading attendance for date: $date');
    try {
      // 0. Fetch persistent site assignments from Supabase DB system_settings if not loaded yet
      if (state.siteAssignments.isEmpty) {
        try {
          final settingsRepo = _ref.read(settingsRepositoryProvider);
          final savedMap = await settingsRepo.fetchSetting('site_assignments');
          if (savedMap.isNotEmpty) {
            final stringAssignments = savedMap.map((k, v) => MapEntry(k, v.toString()));
            state = state.copyWith(siteAssignments: stringAssignments);
          }
        } catch (e) {
          debugPrint('[AttendanceCtrl] Failed to fetch site_assignments from DB settings: $e');
        }
      }

      // 1. Fetch active employees
      final employees = await _ref.read(employeeRepositoryProvider).getEmployees();
      final active = employees.where((e) => e.status.toLowerCase() == 'active').toList();

      // 2. Fetch logged attendance from DB
      final logged = await _repository.getAttendanceForDate(date);
      debugPrint('[AttendanceCtrl] Logged DB records for $date: ${logged.length}');

      // 3. Get existing projects to resolve project names
      final projects = _ref.read(projectControllerProvider).projects;

      // 4. Merge DB attendance records with site assignments
      final Map<String, Attendance> mergedMap = {};

      for (final l in logged) {
        final key = '${l.employeeId}_$date';
        String? assignedProjId;
        if (l.status == 'Absent') {
          state.siteAssignments.remove(key);
          assignedProjId = null;
        } else {
          assignedProjId = l.projectId ?? state.siteAssignments[key];
          if (assignedProjId != null && assignedProjId.isNotEmpty) {
            state.siteAssignments[key] = assignedProjId;
          }
        }

        final projMatch = projects.where((p) => p.id == assignedProjId);
        final projName = projMatch.isNotEmpty ? projMatch.first.name : l.projectName;

        mergedMap[l.employeeId] = l.copyWith(
          projectId: assignedProjId,
          projectName: projName,
        );
      }

      state = state.copyWith(
        isLoading: false,
        activeEmployees: active,
        attendanceList: mergedMap.values.toList(),
        clearError: true,
      );
    } catch (e) {
      debugPrint('[AttendanceCtrl] loadAttendanceForDate FAILED: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load attendance: $e');
    }
  }

  Future<void> changeSelectedDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    await loadAttendanceForDate(dateStr, showLoading: true);
  }

  Future<bool> markAttendance({
    required String employeeId,
    required String status,
    String? projectId,
  }) async {
    final dateStr = state.selectedDate;
    final normalizedStatus = status.toLowerCase() == 'present' ? 'Present' : 'Absent';

    debugPrint('[AttendanceCtrl] markAttendance: employee=$employeeId, status=$normalizedStatus, date=$dateStr, project=$projectId');

    // 1. Update site assignments map
    final updatedAssignments = Map<String, String>.from(state.siteAssignments);
    final existingAssignmentKey = '${employeeId}_$dateStr';

    final updatedList = List<Attendance>.from(state.attendanceList);
    final existingIdx = updatedList.indexWhere((a) => a.employeeId == employeeId);
    final currentRecord = existingIdx >= 0 ? updatedList[existingIdx] : null;

    String? assignedProjId;
    String? projName;

    if (normalizedStatus == 'Absent') {
      // When marked Absent, clear site assignment so dropdown returns to default "Assign Site"
      updatedAssignments.remove(existingAssignmentKey);
      assignedProjId = null;
      projName = null;
    } else {
      // Prioritize explicit new projectId selection
      assignedProjId = projectId ?? updatedAssignments[existingAssignmentKey] ?? currentRecord?.projectId;
      if (assignedProjId != null && assignedProjId.isNotEmpty) {
        updatedAssignments[existingAssignmentKey] = assignedProjId;
        final projects = _ref.read(projectControllerProvider).projects;
        final projMatch = projects.where((p) => p.id == assignedProjId);
        projName = projMatch.isNotEmpty ? projMatch.first.name : currentRecord?.projectName;
      }
    }

    Employee? targetEmployee;
    for (final e in state.activeEmployees) {
      if (e.id == employeeId) {
        targetEmployee = e;
        break;
      }
    }

    final wageSnapshot = targetEmployee?.salary ?? currentRecord?.wageRate;
    final teaSnapshot = targetEmployee?.teaSnackAllowance ?? currentRecord?.teaAllowance;

    final newRecord = Attendance(
      id: currentRecord?.id ?? '',
      employeeId: employeeId,
      date: dateStr,
      status: normalizedStatus,
      projectId: assignedProjId,
      employeeName: targetEmployee?.name ?? currentRecord?.employeeName,
      projectName: projName,
      wageRate: wageSnapshot,
      teaAllowance: teaSnapshot,
    );

    if (existingIdx >= 0) {
      updatedList[existingIdx] = newRecord;
    } else {
      updatedList.add(newRecord);
    }

    // Apply immediate state update so UI shows updated status & clears site assignment INSTANTLY (<10ms)
    state = state.copyWith(
      attendanceList: updatedList,
      siteAssignments: updatedAssignments,
      clearError: true,
    );

    // Persist to backend asynchronously in background without blocking UI thread
    _repository.saveAttendance(newRecord).then((_) {
      debugPrint('[AttendanceCtrl] markAttendance PERSISTED successfully in background');
      _ref.invalidate(dashboardStatsProvider);
    }).catchError((e) {
      debugPrint('[AttendanceCtrl] markAttendance FAILED background persist: $e');
    });

    // Save site assignments to Supabase DB system_settings for permanent multi-device persistence
    _ref.read(settingsRepositoryProvider).saveSetting('site_assignments', updatedAssignments).then((_) {
      debugPrint('[AttendanceCtrl] site_assignments saved to DB system_settings');
    }).catchError((e) {
      debugPrint('[AttendanceCtrl] site_assignments save error: $e');
    });

    // Automatically sync employee salary to project expenses
    void doSyncExpense(Employee emp) {
      _repository.syncEmployeeSalaryExpense(
        employee: emp,
        projectId: assignedProjId,
        date: dateStr,
        isPresent: normalizedStatus == 'Present',
      ).then((_) {
        debugPrint('[AttendanceCtrl] syncEmployeeSalaryExpense completed for ${emp.name}');
        try {
          _ref.read(expenseControllerProvider.notifier).loadExpenses();
          _ref.invalidate(dashboardStatsProvider);
        } catch (_) {}
      }).catchError((e) {
        debugPrint('[AttendanceCtrl] syncEmployeeSalaryExpense error: $e');
      });
    }

    if (targetEmployee != null) {
      doSyncExpense(targetEmployee);
    } else {
      _ref.read(employeeRepositoryProvider).getEmployees().then((allEmps) {
        final match = allEmps.where((e) => e.id == employeeId);
        if (match.isNotEmpty) {
          doSyncExpense(match.first);
        }
      }).catchError((_) {});
    }

    return true;
  }

  /// Bulk action: Mark all currently active employees as Present
  Future<void> markAllPresent({String? defaultProjectId}) async {
    final active = state.activeEmployees;
    if (active.isEmpty) return;

    state = state.copyWith(isLoading: true);
    for (final emp in active) {
      await markAttendance(
        employeeId: emp.id,
        status: 'Present',
        projectId: defaultProjectId,
      );
    }
    state = state.copyWith(isLoading: false, successMessage: 'All workers marked Present! ✓');
  }

  /// Bulk action: Mark all currently active employees as Absent
  Future<void> markAllAbsent() async {
    final active = state.activeEmployees;
    if (active.isEmpty) return;

    state = state.copyWith(isLoading: true);
    for (final emp in active) {
      await markAttendance(
        employeeId: emp.id,
        status: 'Absent',
      );
    }
    state = state.copyWith(isLoading: false, successMessage: 'All workers marked Absent.');
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
final projectAttendanceProvider =
    FutureProvider.family<ProjectAttendanceData, String>((ref, projectId) async {
  final globalState = ref.watch(attendanceControllerProvider);
  final selectedDate = globalState.selectedDate;

  // 1. Get records from current attendance list for this project
  final todayRecords = globalState.attendanceList.where((a) {
    return a.projectId == projectId && (a.date.isEmpty || a.date == selectedDate);
  }).toList();

  // 2. Get history records for this project
  final historyRecords = globalState.attendanceList.where((a) {
    return a.projectId == projectId && a.date.isNotEmpty && a.date != selectedDate;
  }).toList();

  return ProjectAttendanceData(
    todayRecords: todayRecords,
    recentHistory: historyRecords,
  );
});
