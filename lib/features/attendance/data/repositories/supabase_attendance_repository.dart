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
      final response = await _client
          .from('attendance')
          .select('*, employees(name), projects(name)')
          .eq('date', date);

      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName);
      }).toList();
    } catch (e) {
      debugPrint('[Attendance] getAttendanceForDate with project join failed: $e');
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
        debugPrint('[Attendance] getAttendanceForDate fallback failed: $e2');
        return [];
      }
    }
  }

  @override
  Future<void> saveAttendance(Attendance attendance) async {
    final payload = attendance.toJson();
    debugPrint('[Attendance] saveAttendance payload: $payload');

    try {
      // Step 1: Check if a record already exists for this employee + date
      final response = await _client
          .from('attendance')
          .select('id')
          .eq('employee_id', attendance.employeeId)
          .eq('date', attendance.date);

      final existingList = response as List;

      if (existingList.isNotEmpty) {
        // UPDATE the existing record
        final existingId = existingList.first['id'] as String;
        final updateData = attendance.toUpdateJson();

        try {
          await _client
              .from('attendance')
              .update(updateData)
              .eq('id', existingId);
        } catch (updateError) {
          debugPrint('[Attendance] update with project_id failed: $updateError. Trying without project_id.');
          final fallbackData = Map<String, dynamic>.from(updateData)..remove('project_id');
          await _client
              .from('attendance')
              .update(fallbackData)
              .eq('id', existingId);
        }

        debugPrint('[Attendance] saveAttendance UPDATED record id=$existingId');

        // Clean up any duplicate records
        if (existingList.length > 1) {
          for (int i = 1; i < existingList.length; i++) {
            final dupId = existingList[i]['id'] as String;
            try {
              await _client.from('attendance').delete().eq('id', dupId);
              debugPrint('[Attendance] Cleaned duplicate id=$dupId');
            } catch (_) {}
          }
        }
      } else {
        // INSERT new record
        try {
          await _client.from('attendance').insert(payload);
        } catch (insertError) {
          debugPrint('[Attendance] insert with project_id failed: $insertError. Trying without project_id.');
          final fallbackPayload = Map<String, dynamic>.from(payload)..remove('project_id');
          await _client.from('attendance').insert(fallbackPayload);
        }
        debugPrint('[Attendance] saveAttendance INSERTED new record');
      }
    } catch (e) {
      debugPrint('[Attendance] saveAttendance FAILED: $e');
      rethrow; // Let controller surface the real error
    }

    // Log activity (best-effort, never block on failure)
    try {
      await _activityRepo.logActivity(
        actionType: 'updated_attendance',
        entityType: 'Attendance',
        entityId: attendance.employeeId,
        details: {
          'date': attendance.date,
          'status': attendance.status,
          'employee_name': attendance.employeeName ?? '',
        },
      );
    } catch (_) {}
  }

  @override
  Future<List<Attendance>> getAttendanceHistory(String employeeId) async {
    try {
      final response = await _client
          .from('attendance')
          .select('*, employees(name)')
          .eq('employee_id', employeeId)
          .order('date', ascending: false);
      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName);
      }).toList();
    } catch (_) {
      final response = await _client
          .from('attendance')
          .select()
          .eq('employee_id', employeeId)
          .order('date', ascending: false);
      return (response as List).map((json) => Attendance.fromJson(json)).toList();
    }
  }

  @override
  Future<List<Attendance>> getAttendanceForProject(String projectId, String date) async {
    // NOTE: The attendance table does NOT have a project_id column.
    // This method returns an empty list since we can't filter by project at DB level.
    // Project assignment is handled at the UI/memory level only.
    debugPrint('[Attendance] getAttendanceForProject called but project_id column does not exist in DB — returning empty list');
    return [];
  }

  @override
  Future<List<Attendance>> getAttendanceHistoryForProject(String projectId, {int days = 7}) async {
    // NOTE: The attendance table does NOT have a project_id column.
    debugPrint('[Attendance] getAttendanceHistoryForProject called but project_id column does not exist in DB — returning empty list');
    return [];
  }

  @override
  Future<List<Attendance>> getAttendanceForDateRange(String startDate, String endDate) async {
    try {
      final response = await _client
          .from('attendance')
          .select('*, employees(name), projects(name)')
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', ascending: false);

      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName);
      }).toList();
    } catch (e) {
      debugPrint('[Attendance] getAttendanceForDateRange failed: $e');
      try {
        final response = await _client
            .from('attendance')
            .select('*, employees(name)')
            .gte('date', startDate)
            .lte('date', endDate)
            .order('date', ascending: false);

        return (response as List).map((json) {
          final employeeName = (json['employees'] as Map?)?['name'] as String?;
          return Attendance.fromJson(json, employeeName: employeeName);
        }).toList();
      } catch (e2) {
        debugPrint('[Attendance] getAttendanceForDateRange fallback failed: $e2');
        return [];
      }
    }
  }
}

