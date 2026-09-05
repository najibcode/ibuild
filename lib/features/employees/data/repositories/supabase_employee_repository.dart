import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import '../../domain/repositories/employee_repository.dart';
import '../models/employee_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseEmployeeRepository implements EmployeeRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseEmployeeRepository(this._client, this._activityRepo);

  @override
  Future<List<Employee>> getEmployees() async {
    final cache = OfflineDataCache();
    final cached = cache.getCachedEmployees();
    List<Employee> employees = [];

    if (cached != null && cached.isNotEmpty) {
      employees = cached.map((json) => Employee.fromJson(json)).toList();
    }

    try {
      final response = await _client.from('employees').select().order('name');
      final remote = response.map((json) => Employee.fromJson(json)).toList();
      // Remote Supabase response is the canonical truth — purge deleted employees from cache
      employees = remote;
      cache.cacheEmployees(employees.map((e) => e.toMap()).toList());
    } catch (e) {
      debugPrint('Employees query note: $e');
    }

    return employees;
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final cache = OfflineDataCache();
    final cached = cache.getCachedEmployees();
    if (cached != null) {
      final found = cached.firstWhere((e) => e['id'] == id, orElse: () => {});
      if (found.isNotEmpty) return Employee.fromJson(found);
    }

    try {
      final response = await _client
          .from('employees')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null) return Employee.fromJson(response);
    } catch (_) {}
    return null;
  }

  @override
  Future<void> createEmployee(Employee employee) async {
    // Validate
    if (employee.name.trim().isEmpty) {
      throw ArgumentError('Employee name cannot be empty.');
    }
    if (employee.phone.trim().isEmpty) {
      throw ArgumentError('Employee phone number cannot be empty.');
    }
    if (employee.salary < 0) {
      throw ArgumentError('Employee salary cannot be negative.');
    }
    if (employee.teaSnackAllowance < 0) {
      throw ArgumentError('Tea and snacks allowance cannot be negative.');
    }

    // Assign valid UUID upfront if not present
    final assignedId = employee.id.isNotEmpty ? employee.id : const Uuid().v4();
    final empToSave = employee.copyWith(id: assignedId);

    // Save to OfflineDataCache immediately
    final cache = OfflineDataCache();
    final existing = cache.getCachedEmployees() ?? [];
    existing.removeWhere((e) => e['id'] == assignedId || e['id'] == employee.id);
    existing.insert(0, empToSave.toMap());
    cache.cacheEmployees(existing);

    String entityId = assignedId;

    try {
      final insertMap = Map<String, dynamic>.from(empToSave.toMap());
      final response = await _client.from('employees').insert(insertMap).select().maybeSingle();
      if (response != null) {
        final createdEmp = Employee.fromJson(response);
        entityId = createdEmp.id;

        // Update cache with server UUID
        final updatedList = cache.getCachedEmployees() ?? [];
        updatedList.removeWhere((e) => e['id'] == assignedId || e['id'] == createdEmp.id);
        updatedList.insert(0, createdEmp.toMap());
        cache.cacheEmployees(updatedList);
      }
    } catch (e) {
      debugPrint('Supabase insert employee error: $e. Retrying with basic fields.');
      try {
        final basicMap = {
          'id': assignedId,
          'name': empToSave.name,
          'phone': empToSave.phone,
          'role': empToSave.role,
          'salary': empToSave.salary,
          'daily_rate': empToSave.salary,
          'status': empToSave.status,
        };
        await _client.from('employees').insert(basicMap);
      } catch (e2) {
        debugPrint('Supabase insert employee fallback error: $e2');
      }
    }
    
    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'added_employee',
        entityType: 'Employee',
        entityId: entityId,
        details: {'name': empToSave.name, 'role': empToSave.role},
      );
    } catch (_) {}
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    if (employee.teaSnackAllowance < 0) {
      throw ArgumentError('Tea and snacks allowance cannot be negative.');
    }

    // 1. Update in OfflineDataCache immediately
    final cache = OfflineDataCache();
    final existing = cache.getCachedEmployees() ?? [];
    final idx = existing.indexWhere((e) => e['id'] == employee.id);
    if (idx != -1) {
      existing[idx] = employee.toMap();
    } else {
      existing.insert(0, employee.toMap());
    }
    cache.cacheEmployees(existing);

    // 2. Update in Supabase with resilient fallbacks
    try {
      await _client
          .from('employees')
          .update(employee.toJson())
          .eq('id', employee.id);
    } catch (e) {
      debugPrint('Supabase update employee error: $e. Retrying with basic fields.');
      try {
        final fallbackMap = {
          'name': employee.name,
          'phone': employee.phone,
          'role': employee.role,
          'salary': employee.salary,
          'daily_rate': employee.salary,
          'status': employee.status,
        };
        await _client.from('employees').update(fallbackMap).eq('id', employee.id);
      } catch (e2) {
        try {
          await _client.from('employees').update({
            'salary': employee.salary,
            'name': employee.name,
          }).eq('id', employee.id);
        } catch (_) {}
      }
    }

    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'updated_employee',
        entityType: 'Employee',
        entityId: employee.id,
        details: {'name': employee.name, 'salary': employee.salary},
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      // 1. First attempt atomic cascade delete via RPC if available, or delete child foreign keys
      try {
        await _client.rpc('delete_employee_cascade', params: {'p_employee_id': id});
      } catch (_) {
        // Fallback: delete attendance records first to satisfy foreign key constraints
        try { await _client.from('attendance').delete().eq('employee_id', id); } catch (_) {}
        await _client.from('employees').delete().eq('id', id);
      }

      // 2. Update local cache ONLY AFTER Supabase successfully confirms delete
      final cache = OfflineDataCache();
      final existing = cache.getCachedEmployees() ?? [];
      existing.removeWhere((e) => e['id'] == id);
      cache.cacheEmployees(existing);

      // 3. Log activity
      try {
        await _activityRepo.logActivity(
          actionType: 'deleted_employee',
          entityType: 'Employee',
          entityId: id,
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Supabase delete employee error: $e');
      rethrow;
    }
  }
}
