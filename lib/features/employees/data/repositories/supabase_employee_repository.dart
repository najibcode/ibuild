import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final response = await _client.from('employees').select();
      if (response is List && response.isNotEmpty) {
        final remote = response.map((json) => Employee.fromJson(json)).toList();
        final Map<String, Employee> map = {for (var e in employees) e.id: e};
        for (var e in remote) {
          map[e.id] = e;
        }
        employees = map.values.toList();
        cache.cacheEmployees(employees.map((e) => e.toJson()).toList());
      }
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

    // Save to OfflineDataCache
    final cache = OfflineDataCache();
    final existing = cache.getCachedEmployees() ?? [];
    existing.removeWhere((e) => e['id'] == employee.id);
    existing.insert(0, employee.toJson());
    cache.cacheEmployees(existing);

    try {
      await _client.from('employees').insert(employee.toJson());
    } catch (e) {
      debugPrint('Supabase insert employee error: $e');
    }
    
    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'added_employee',
        entityType: 'Employee',
        entityId: employee.id,
        details: {'name': employee.name, 'role': employee.role},
      );
    } catch (_) {}
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    if (employee.teaSnackAllowance < 0) {
      throw ArgumentError('Tea and snacks allowance cannot be negative.');
    }

    // Update in OfflineDataCache
    final cache = OfflineDataCache();
    final existing = cache.getCachedEmployees() ?? [];
    final idx = existing.indexWhere((e) => e['id'] == employee.id);
    if (idx != -1) {
      existing[idx] = employee.toJson();
    } else {
      existing.insert(0, employee.toJson());
    }
    cache.cacheEmployees(existing);

    try {
      await _client
          .from('employees')
          .update(employee.toJson())
          .eq('id', employee.id);
    } catch (e) {
      debugPrint('Supabase update employee error: $e');
    }

    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'updated_employee',
        entityType: 'Employee',
        entityId: employee.id,
        details: {'name': employee.name},
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteEmployee(String id) async {
    final cache = OfflineDataCache();
    final existing = cache.getCachedEmployees() ?? [];
    existing.removeWhere((e) => e['id'] == id);
    cache.cacheEmployees(existing);

    try {
      await _client.from('employees').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase delete employee error: $e');
    }
    
    // Log activity
    try {
      await _activityRepo.logActivity(
        actionType: 'deleted_employee',
        entityType: 'Employee',
        entityId: id,
      );
    } catch (_) {}
  }
}
