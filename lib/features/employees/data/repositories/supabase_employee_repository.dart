import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/employee_repository.dart';
import '../models/employee_model.dart';

class SupabaseEmployeeRepository implements EmployeeRepository {
  final SupabaseClient _client;

  SupabaseEmployeeRepository(this._client);

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
    await _client.from('employees').insert(employee.toJson());
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await _client
        .from('employees')
        .update(employee.toJson())
        .eq('id', employee.id);
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _client.from('employees').delete().eq('id', id);
  }
}
