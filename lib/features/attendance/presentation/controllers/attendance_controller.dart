import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../data/repositories/supabase_attendance_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/models/attendance_model.dart';
import '../../../employees/presentation/controllers/employee_controller.dart';
import '../../../employees/data/models/employee_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  return SupabaseAttendanceRepository(client, activityRepo);
});

class AttendanceState {
  final bool isLoading;
  final List<Attendance> attendanceList;
  final List<Employee> activeEmployees;

  AttendanceState({
    required this.isLoading,
    required this.attendanceList,
    required this.activeEmployees,
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
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      attendanceList: attendanceList ?? this.attendanceList,
      activeEmployees: activeEmployees ?? this.activeEmployees,
    );
  }
}

class AttendanceController extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repository;
  final Ref _ref;

  AttendanceController(this._repository, this._ref) : super(AttendanceState.initial()) {
    loadAttendanceForToday();
  }

  Future<void> loadAttendanceForToday() async {
    state = state.copyWith(isLoading: true);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    try {
      // 1. Fetch active employees
      final employees = await _ref.read(employeeRepositoryProvider).getEmployees();
      final active = employees.where((e) => e.status == 'active').toList();

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
    String? morningStatus,
    String? eveningStatus,
  }) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final attendance = Attendance(
      id: '',
      employeeId: employeeId,
      date: todayStr,
      status: status,
    );

    try {
      await _repository.saveAttendance(attendance);
      await loadAttendanceForToday();
    } catch (e) {
      // Handle error log
    }
  }
}

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceController(repository, ref);
});
