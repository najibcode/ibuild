import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['SUPABASE_URL']!;
  final key = dotenv.env['SUPABASE_ANON_KEY']!;

  final client = SupabaseClient(url, key);

  print('=== SUPABASE DATA VERIFICATION ===');

  try {
    final projects = await client.from('projects').select();
    print('Projects count: ${projects.length}');
    for (final p in projects) {
      print(' - [ID: ${p['id']}] Name: "${p['name']}" | Status: ${p['status']} | Budget: ₹${p['budget']} | Spent: ₹${p['spent']}');
    }

    final attendance = await client.from('attendance').select();
    print('Attendance count: ${attendance.length}');

    final expenses = await client.from('expenses').select();
    print('Expenses count: ${expenses.length}');

    final employees = await client.from('employees').select();
    print('Employees count: ${employees.length}');

    final inventory = await client.from('inventory').select();
    print('Inventory count: ${inventory.length}');
  } catch (e) {
    print('Error querying Supabase: $e');
  }
}
