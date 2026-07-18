import '../../data/models/employee_model.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees();
  Future<Employee?> getEmployeeById(String id);
  Future<void> createEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
}
