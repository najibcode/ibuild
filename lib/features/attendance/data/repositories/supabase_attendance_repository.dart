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
    try {
      final response = await _client
          .from('attendance')
          .select('*, employees(name), projects(name)')
          .eq('date', date);
      
      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        final projectName = (json['projects'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName, projectName: projectName);
      }).toList();
    } catch (_) {
      final response = await _client
          .from('attendance')
          .select('*, employees(name)')
          .eq('date', date);
      
      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName);
      }).toList();
    }
  }

  @override
  Future<void> saveAttendance(Attendance attendance) async {
    final payload = attendance.toJson();

    try {
      await _client.from('attendance').upsert(
        payload,
        onConflict: 'employee_id,date',
      );
    } catch (e) {
      final minimalPayload = <String, dynamic>{
        if (attendance.id.isNotEmpty) 'id': attendance.id,
        'employee_id': attendance.employeeId,
        'date': attendance.date,
        'status': attendance.status,
      };
      if (attendance.projectId != null && attendance.projectId!.isNotEmpty) {
        minimalPayload['project_id'] = attendance.projectId;
      }
      try {
        await _client.from('attendance').upsert(
          minimalPayload,
          onConflict: 'employee_id,date',
        );
      } catch (_) {
        minimalPayload.remove('project_id');
        await _client.from('attendance').upsert(
          minimalPayload,
          onConflict: 'employee_id,date',
        );
      }
    }

    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'updated_attendance',
        entityType: 'Attendance',
        entityId: attendance.employeeId,
        details: {
          'date': attendance.date,
          'status': attendance.status,
          'project_id': attendance.projectId ?? '',
          'employee_name': attendance.employeeName ?? '',
        },
      );
    } catch (_) {}
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
