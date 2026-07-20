import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.provider.dart';
import '../../../activities/data/repositories/supabase_activity_repository.dart';
import '../../data/repositories/supabase_employee_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../data/models/employee_model.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final activityRepo = ref.watch(activityRepositoryProvider);
  return SupabaseEmployeeRepository(client, activityRepo);
});

class EmployeeListController extends StateNotifier<AsyncValue<List<Employee>>> {
  final EmployeeRepository _repository;

  EmployeeListController(this._repository) : super(const AsyncValue.loading()) {
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    state = const AsyncValue.loading();
    try {
      final employees = await _repository.getEmployees();
      state = AsyncValue.data(employees);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addEmployee(Employee employee) async {
    try {
      await _repository.createEmployee(employee);
      await loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editEmployee(Employee employee) async {
    try {
      await _repository.updateEmployee(employee);
      await loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeEmployee(String id) async {
    try {
      await _repository.deleteEmployee(id);
      await loadEmployees();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final employeeListControllerProvider =
    StateNotifierProvider<EmployeeListController, AsyncValue<List<Employee>>>((ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return EmployeeListController(repository);
});
