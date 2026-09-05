import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';
import '../../../employees/data/models/employee_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/core/offline/offline_sync_service.dart';

class SupabaseAttendanceRepository implements AttendanceRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseAttendanceRepository(this._client, this._activityRepo);

  @override
  Future<List<Attendance>> getAttendanceForDate(String date) async {
    try {
      List<dynamic> responseList = [];
      try {
        final response = await _client
            .from('attendance')
            .select('*, employees(name, salary, tea_allowance)')
            .eq('date', date);
        responseList = response as List;
      } catch (joinErr) {
        debugPrint('[Attendance] getAttendanceForDate with relation failed ($joinErr), trying flat select');
        final flatResponse = await _client
            .from('attendance')
            .select()
            .eq('date', date);
        responseList = flatResponse as List;
      }

      final list = responseList.map((json) {
        final empMap = json['employees'] as Map?;
        final employeeName = empMap?['name'] as String?;
        final fallbackSalary = (empMap?['salary'] as num?)?.toDouble();
        final fallbackTea = (empMap?['tea_allowance'] as num?)?.toDouble()
            ?? (empMap?['tea_snack_allowance'] as num?)?.toDouble();

        final parsed = Attendance.fromJson(json, employeeName: employeeName);
        return parsed.copyWith(
          wageRate: parsed.wageRate ?? fallbackSalary,
          teaAllowance: parsed.teaAllowance ?? fallbackTea,
        );
      }).toList();

      // Cache records locally for offline access
      OfflineDataCache().cacheAttendanceForDate(
        date,
        responseList.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
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
      // Conflict-safe database upsert on unique (employee_id, date) constraint
      try {
        await _client.from('attendance').upsert(
          payload,
          onConflict: 'employee_id, date',
        );
      } catch (upsertErr) {
        debugPrint('[Attendance] upsert with all fields note: $upsertErr. Retrying with standard fields.');
        try {
          final standardPayload = Map<String, dynamic>.from(payload)
            ..remove('wage_rate')
            ..remove('tea_allowance');
          await _client.from('attendance').upsert(
            standardPayload,
            onConflict: 'employee_id, date',
          );
        } catch (_) {
          final basicPayload = Map<String, dynamic>.from(payload)
            ..remove('project_id')
            ..remove('wage_rate')
            ..remove('tea_allowance');
          await _client.from('attendance').upsert(
            basicPayload,
            onConflict: 'employee_id, date',
          );
        }
      }
      debugPrint('[Attendance] saveAttendance successfully synced via conflict-safe upsert ✓');
    } catch (e) {
      debugPrint('[Attendance] saveAttendance FAILED: $e, saving to offline cache and queueing for sync');
      
      // Optimistically update local cache
      final existingCached = OfflineDataCache().getCachedAttendanceForDate(attendance.date) ?? [];
      final updatedList = List<Map<String, dynamic>>.from(existingCached);
      final idx = updatedList.indexWhere((r) => r['employee_id'] == attendance.employeeId);
      if (idx != -1) {
        updatedList[idx] = attendance.toJson();
      } else {
        updatedList.add(attendance.toJson());
      }
      OfflineDataCache().cacheAttendanceForDate(attendance.date, updatedList);

      // Queue for auto-sync
      OfflineSyncService.instance.enqueueAction(
        type: SyncActionType.attendanceSave,
        payload: attendance.toJson(),
      );
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

  static final _uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  @override
  Future<List<Attendance>> getAttendanceHistory(String employeeId) async {
    if (employeeId.isEmpty || !_uuidPattern.hasMatch(employeeId)) {
      return [];
    }
    try {
      final response = await _client
          .from('attendance')
          .select('*, employees(name, salary, tea_allowance)')
          .eq('employee_id', employeeId)
          .order('date', ascending: false);
      return (response as List).map((json) {
        final empMap = json['employees'] as Map?;
        final employeeName = empMap?['name'] as String?;
        final fallbackSalary = (empMap?['salary'] as num?)?.toDouble();
        final fallbackTea = (empMap?['tea_allowance'] as num?)?.toDouble()
            ?? (empMap?['tea_snack_allowance'] as num?)?.toDouble();

        final parsed = Attendance.fromJson(json, employeeName: employeeName);
        return parsed.copyWith(
          wageRate: parsed.wageRate ?? fallbackSalary,
          teaAllowance: parsed.teaAllowance ?? fallbackTea,
        );
      }).toList();
    } catch (_) {
      try {
        final response = await _client
            .from('attendance')
            .select()
            .eq('employee_id', employeeId)
            .order('date', ascending: false);
        return (response as List).map((json) => Attendance.fromJson(json)).toList();
      } catch (e) {
        debugPrint('[Attendance] getAttendanceHistory fallback failed: $e');
        return [];
      }
    }
  }

  @override
  Future<void> lockHistoricalWagesForEmployee({
    required String employeeId,
    required String beforeDate,
    required double previousWageRate,
    required double previousTeaAllowance,
  }) async {
    if (employeeId.isEmpty || previousWageRate <= 0) return;
    try {
      debugPrint('[Attendance] Locking historical wages for employee $employeeId before $beforeDate at ₹$previousWageRate/day');
      await _client
          .from('attendance')
          .update({
            'wage_rate': previousWageRate,
            'tea_allowance': previousTeaAllowance,
          })
          .eq('employee_id', employeeId)
          .lt('date', beforeDate)
          .or('wage_rate.is.null,wage_rate.eq.0');
      debugPrint('[Attendance] Successfully locked historical wages for employee $employeeId ✓');
    } catch (e) {
      debugPrint('[Attendance] lockHistoricalWagesForEmployee error: $e');
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
    double? wageRate,
  }) async {
    final noteTag = '[EMP:${employee.id}]';
    final salary = wageRate ?? employee.salary;

    try {
      // Find existing auto-generated wage expense for this employee on this date
      final existingRows = await _client
          .from('expenses')
          .select('id, project_id, amount, notes')
          .eq('expense_date', date)
          .eq('category', 'Labour')
          .ilike('notes', '%$noteTag%');

      final existingList = (existingRows as List);

      if (!isPresent || projectId == null || projectId.isEmpty || !_uuidPattern.hasMatch(projectId) || salary <= 0) {
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

