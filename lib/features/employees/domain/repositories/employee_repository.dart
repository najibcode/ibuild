import '../../data/models/employee_model.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees();
  Future<Employee?> getEmployeeById(String id);
  Future<void> createEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
  Future<void> applySalaryRevision({
    required String employeeId,
    required double newSalary,
    required double newTeaAllowance,
    required DateTime effectiveDate,
    String? reason,
  });
}
