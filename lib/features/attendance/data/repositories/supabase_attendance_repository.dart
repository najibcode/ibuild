import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseAttendanceRepository implements AttendanceRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseAttendanceRepository(this._client, this._activityRepo);

  @override
  Future<List<Attendance>> getAttendanceForDate(String date) async {
    final response = await _client
        .from('attendance')
        .select('*, employees(name)')
        .eq('date', date);
    
    return (response as List).map((json) {
      final employeeName = (json['employees'] as Map?)?['name'] as String?;
      return Attendance.fromJson(json, employeeName: employeeName);
    }).toList();
  }

  @override
  Future<void> saveAttendance(Attendance attendance) async {
    // Upsert logic based on unique constraint (employee_id, date)
    await _client.from('attendance').upsert(
      attendance.toJson(),
      onConflict: 'employee_id,date',
    );

    // Log activity
    await _activityRepo.logActivity(
      actionType: 'updated_attendance',
      entityType: 'Attendance',
      entityId: attendance.employeeId,
      details: {
        'date': attendance.date,
        'morning_status': attendance.morningStatus,
        'evening_status': attendance.eveningStatus,
        'employee_name': attendance.employeeName ?? '',
      },
    );
  }

  @override
  Future<List<Attendance>> getAttendanceHistory(String employeeId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .order('date', ascending: false);
    return (response as List).map((json) => Attendance.fromJson(json)).toList();
  }
}
