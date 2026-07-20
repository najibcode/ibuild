import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class SupabaseAttendanceRepository implements AttendanceRepository {
  final SupabaseClient _client;

  SupabaseAttendanceRepository(this._client);

  @override
  Future<List<Attendance>> getAttendanceForDate(String date) async {
    final response = await _client
        .from('attendance')
        .select('*, employees(name)')
        .eq('date', date);
    
    return (response as List).map((json) {
      final employeeName = (json['employees'] as Map?)?['name'] as String?;
      return Attendance.fromJson(json, employeeName: employeeName);
    }).toList();
  }

  @override
  Future<void> saveAttendance(Attendance attendance) async {
    // Upsert logic based on unique constraint (employee_id, date)
    await _client.from('attendance').upsert(
      attendance.toJson(),
      onConflict: 'employee_id,date',
    );
  }

  @override
  Future<List<Attendance>> getAttendanceHistory(String employeeId) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .order('date', ascending: false);
    return (response as List).map((json) => Attendance.fromJson(json)).toList();
  }
}
