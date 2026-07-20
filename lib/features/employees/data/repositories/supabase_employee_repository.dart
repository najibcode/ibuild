import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/employee_repository.dart';
import '../models/employee_model.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';

class SupabaseEmployeeRepository implements EmployeeRepository {
  final SupabaseClient _client;
  final SupabaseActivityRepository _activityRepo;

  SupabaseEmployeeRepository(this._client, this._activityRepo);

  @override
  Future<List<Employee>> getEmployees() async {
    final response = await _client.from('employees').select();
    return (response as List).map((json) => Employee.fromJson(json)).toList();
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final response = await _client
        .from('employees')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Employee.fromJson(response);
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

    await _client.from('employees').insert(employee.toJson());
    
    // Log activity
    await _activityRepo.logActivity(
      actionType: 'added_employee',
      entityType: 'Employee',
      entityId: employee.id,
      details: {'name': employee.name, 'role': employee.role},
    );
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await _client
        .from('employees')
        .update(employee.toJson())
        .eq('id', employee.id);
        
    // Log activity
    await _activityRepo.logActivity(
      actionType: 'updated_employee',
      entityType: 'Employee',
      entityId: employee.id,
      details: {'name': employee.name},
    );
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _client.from('employees').delete().eq('id', id);
    
    // Log activity
    await _activityRepo.logActivity(
      actionType: 'deleted_employee',
      entityType: 'Employee',
      entityId: id,
    );
  }
}
