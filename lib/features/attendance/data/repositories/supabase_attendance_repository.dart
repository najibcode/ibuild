import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

import 'package:ibuild/core/offline/offline_data_cache.dart';

class SupabaseAttendanceRepository implements AttendanceRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseAttendanceRepository(this._client, this._activityRepo);

  @override
  Future<List<Attendance>> getAttendanceForDate(String date) async {
    try {
      final response = await _client
          .from('attendance')
          .select('*, employees(name)')
          .eq('date', date);

      final list = (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName);
      }).toList();

      // Cache records locally for offline access
      OfflineDataCache().cacheAttendanceForDate(
        date,
        (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );

      return list;
    } catch (e) {
      debugPrint('[Attendance] getAttendanceForDate failed ($e), loading from offline cache');
      final cached = OfflineDataCache().getCachedAttendanceForDate(date);
      if (cached != null && cached.isNotEmpty) {
        return cached.map((json) {
          final employeeName = (json['employees'] as Map?)?['name'] as String?;
          return Attendance.fromJson(json, employeeName: employeeName);
        }).toList();
      }
      return [];
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
          .select('*, employees(name)')
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', ascending: false);

      return (response as List).map((json) {
        final employeeName = (json['employees'] as Map?)?['name'] as String?;
        return Attendance.fromJson(json, employeeName: employeeName);
      }).toList();
    } catch (e) {
      debugPrint('[Attendance] getAttendanceForDateRange failed: $e');
      return [];
    }
  }

  @override
  Future<void> syncEmployeeSalaryExpense({
    required Employee employee,
    required String? projectId,
    required String date,
    required bool isPresent,
  }) async {
    final noteTag = '[EMP:${employee.id}]';
    final salary = employee.salary;

    try {
      // Find existing auto-generated wage expense for this employee on this date
      final existingRows = await _client
          .from('expenses')
          .select('id, project_id, amount, notes')
          .eq('expense_date', date)
          .eq('category', 'Labour')
          .ilike('notes', '%$noteTag%');

      final existingList = (existingRows as List);

      if (!isPresent || projectId == null || projectId.isEmpty || salary <= 0) {
        // Employee is absent or unassigned or has zero salary: Remove any existing auto-wage expense(s)
        for (final row in existingList) {
          final expId = row['id'] as String;
          final pId = row['project_id'] as String?;
          final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;

          await _client.from('expenses').delete().eq('id', expId);
          if (pId != null && pId.isNotEmpty && amt > 0) {
            await _decrementProjectSpent(pId, amt);
          }
          debugPrint('[Attendance] Removed salary expense $expId for employee ${employee.name}');
        }
        return;
      }

      // Employee is Present at projectId with salary > 0
      final noteText = 'Daily salary for ${employee.name} (${employee.role}) $noteTag';

      if (existingList.isNotEmpty) {
        final first = existingList.first;
        final existingId = first['id'] as String;
        final currentProjId = first['project_id'] as String?;
        final currentAmount = (first['amount'] as num?)?.toDouble() ?? 0.0;

        if (currentProjId == projectId && currentAmount == salary) {
          debugPrint('[Attendance] Salary expense already up-to-date for ${employee.name} at project $projectId');
        } else {
          // Project or amount changed: update expense and adjust spent
          await _client.from('expenses').update({
            'project_id': projectId,
            'amount': salary,
            'notes': noteText,
          }).eq('id', existingId);

          if (currentProjId != projectId) {
            if (currentProjId != null && currentProjId.isNotEmpty && currentAmount > 0) {
              await _decrementProjectSpent(currentProjId, currentAmount);
            }
            await _incrementProjectSpent(projectId, salary);
          } else if (currentAmount != salary) {
            final diff = salary - currentAmount;
            if (diff > 0) {
              await _incrementProjectSpent(projectId, diff);
            } else if (diff < 0) {
              await _decrementProjectSpent(projectId, -diff);
            }
          }
          debugPrint('[Attendance] Updated salary expense $existingId for employee ${employee.name} to project $projectId');
        }

        // Clean up any duplicate rows if any exist
        if (existingList.length > 1) {
          for (int i = 1; i < existingList.length; i++) {
            final dupId = existingList[i]['id'] as String;
            final dupPid = existingList[i]['project_id'] as String?;
            final dupAmt = (existingList[i]['amount'] as num?)?.toDouble() ?? 0.0;
            await _client.from('expenses').delete().eq('id', dupId);
            if (dupPid != null && dupPid.isNotEmpty && dupAmt > 0) {
              await _decrementProjectSpent(dupPid, dupAmt);
            }
          }
        }
      } else {
        // No existing expense: Insert new expense
        await _client.from('expenses').insert({
          'project_id': projectId,
          'expense_date': date,
          'category': 'Labour',
          'amount': salary,
          'payment_mode': 'cash',
          'notes': noteText,
        });

        await _incrementProjectSpent(projectId, salary);
        debugPrint('[Attendance] Created salary expense of ₹$salary for employee ${employee.name} at project $projectId');

        try {
          await _activityRepo.logActivity(
            actionType: 'created_expense',
            entityType: 'Expense',
            entityId: projectId,
            details: {
              'category': 'Labour',
              'amount': salary,
              'employee_name': employee.name,
              'notes': noteText,
            },
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Attendance] syncEmployeeSalaryExpense FAILED: $e');
    }
  }

  Future<void> _incrementProjectSpent(String projectId, double amount) async {
    try {
      final row = await _client
          .from('projects')
          .select('spent')
          .eq('id', projectId)
          .maybeSingle();
      if (row != null) {
        final currentSpent = (row['spent'] as num?)?.toDouble() ?? 0.0;
        await _client
            .from('projects')
            .update({'spent': currentSpent + amount})
            .eq('id', projectId);
      }
    } catch (_) {}
  }

  Future<void> _decrementProjectSpent(String projectId, double amount) async {
    try {
      final row = await _client
          .from('projects')
          .select('spent')
          .eq('id', projectId)
          .maybeSingle();
      if (row != null) {
        final currentSpent = (row['spent'] as num?)?.toDouble() ?? 0.0;
        final newSpent = (currentSpent - amount).clamp(0.0, double.infinity);
        await _client
            .from('projects')
            .update({'spent': newSpent})
            .eq('id', projectId);
      }
    } catch (_) {}
  }
}

