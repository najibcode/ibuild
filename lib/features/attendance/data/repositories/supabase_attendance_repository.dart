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

    // ── Strategy: Manual select → update/insert.
    //    This avoids depending on a UNIQUE constraint on (employee_id, date)
    //    which may not exist in the Supabase table. ──

    try {
      // 1. Check if a record already exists for this employee + date
      final existing = await _client
          .from('attendance')
          .select('id')
          .eq('employee_id', attendance.employeeId)
          .eq('date', attendance.date)
          .maybeSingle();

      if (existing != null) {
        // 2a. UPDATE existing record
        final updatePayload = Map<String, dynamic>.from(payload);
        updatePayload.remove('id'); // Don't update the primary key
        updatePayload.remove('employee_id'); // Don't update the match key
        updatePayload.remove('date'); // Don't update the match key

        await _client
            .from('attendance')
            .update(updatePayload)
            .eq('id', existing['id'] as String);

        debugPrint('[Attendance] saveAttendance UPDATED existing record id=${existing['id']}');
      } else {
        // 2b. INSERT new record
        final insertPayload = Map<String, dynamic>.from(payload);
        insertPayload.remove('id'); // Let Supabase auto-generate UUID

        await _client.from('attendance').insert(insertPayload);
        debugPrint('[Attendance] saveAttendance INSERTED new record');
      }
    } catch (e) {
      debugPrint('[Attendance] saveAttendance with project_id failed: $e');

      // Retry without project_id (column may not exist in table)
      try {
        final minPayload = <String, dynamic>{
          'employee_id': attendance.employeeId,
          'date': attendance.date,
          'status': attendance.status,
        };

        final existing = await _client
            .from('attendance')
            .select('id')
            .eq('employee_id', attendance.employeeId)
            .eq('date', attendance.date)
            .maybeSingle();

        if (existing != null) {
          await _client
              .from('attendance')
              .update({'status': attendance.status})
              .eq('id', existing['id'] as String);
          debugPrint('[Attendance] saveAttendance UPDATED (fallback, no project_id)');
        } else {
          await _client.from('attendance').insert(minPayload);
          debugPrint('[Attendance] saveAttendance INSERTED (fallback, no project_id)');
        }
      } catch (e2) {
        debugPrint('[Attendance] saveAttendance FINAL FAILURE: $e2');
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
