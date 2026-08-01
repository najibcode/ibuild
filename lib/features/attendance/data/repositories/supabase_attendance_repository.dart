import 'package:flutter/foundation.dart';
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
      // Try with project join first
      final response = await _client
          .from('attendance')
          .select('*, employees(name), projects(name)')
          .eq('date', date);

      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        final projectName = (json['projects'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName, projectName: projectName);
      }).toList();
    } catch (e) {
      debugPrint('[Attendance] getAttendanceForDate with project join failed: $e');
      // Fallback without project join (project_id column may not exist)
      try {
        final response = await _client
            .from('attendance')
            .select('*, employees(name)')
            .eq('date', date);

        return (response as List).map((json) {
          final employeeName = (json['employees'] as Map?)?['name'] as String?;
          return Attendance.fromJson(json, employeeName: employeeName);
        }).toList();
      } catch (e2) {
        debugPrint('[Attendance] getAttendanceForDate fallback also failed: $e2');
        return [];
      }
    }
  }

  @override
  Future<void> saveAttendance(Attendance attendance) async {
    final payload = attendance.toJson();
    debugPrint('[Attendance] saveAttendance payload: $payload');

    // ── Strategy: Try upsert with full payload. If project_id column doesn't
    //    exist, retry without it. NEVER silently swallow the final error. ──

    try {
      await _client.from('attendance').upsert(
        payload,
        onConflict: 'employee_id,date',
      );
      debugPrint('[Attendance] saveAttendance SUCCESS with full payload');
    } catch (e) {
      debugPrint('[Attendance] saveAttendance full payload failed: $e');

      // Retry without project_id (column may not exist)
      final fallbackPayload = Map<String, dynamic>.from(payload);
      fallbackPayload.remove('project_id');
      fallbackPayload.remove('id');

      try {
        await _client.from('attendance').upsert(
          fallbackPayload,
          onConflict: 'employee_id,date',
        );
        debugPrint('[Attendance] saveAttendance SUCCESS with fallback (no project_id)');
      } catch (e2) {
        debugPrint('[Attendance] saveAttendance FINAL FAILURE: $e2');
        // Re-throw so the controller can surface the error to the user
        rethrow;
      }
    }

    // Log activity (non-critical — don't let failures here break attendance)
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

  @override
  Future<List<Attendance>> getAttendanceForProject(String projectId, String date) async {
    try {
      final response = await _client
          .from('attendance')
          .select('*, employees(name), projects(name)')
          .eq('project_id', projectId)
          .eq('date', date);

      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        final projectName = (json['projects'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName, projectName: projectName);
      }).toList();
    } catch (_) {
      try {
        final response = await _client
            .from('attendance')
            .select('*, employees(name)')
            .eq('project_id', projectId)
            .eq('date', date);

        return (response as List).map((json) {
          final employeeName = (json['employees'] as Map?)?['name'] as String?;
          return Attendance.fromJson(json, employeeName: employeeName);
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<List<Attendance>> getAttendanceHistoryForProject(String projectId, {int days = 7}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final startStr = startDate.toIso8601String().substring(0, 10);

    try {
      final response = await _client
          .from('attendance')
          .select('*, employees(name), projects(name)')
          .eq('project_id', projectId)
          .gte('date', startStr)
          .order('date', ascending: false);

      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        final projectName = (json['projects'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName, projectName: projectName);
      }).toList();
    } catch (_) {
      try {
        final response = await _client
            .from('attendance')
            .select('*, employees(name)')
            .eq('project_id', projectId)
            .gte('date', startStr)
            .order('date', ascending: false);

        return (response as List).map((json) {
          final employeeName = (json['employees'] as Map?)?['name'] as String?;
          return Attendance.fromJson(json, employeeName: employeeName);
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }
}
