import 'dart:convert';
import 'package:flutter/foundation.dart';

/// In-memory and key-value cache layer for storing master data offline.
/// Allows site supervisors to browse projects, employee rosters, attendance history,
/// inventory catalogs, and snags with zero internet connection.
class OfflineDataCache {
  static final OfflineDataCache _instance = OfflineDataCache._internal();
  factory OfflineDataCache() => _instance;
  OfflineDataCache._internal();

  final Map<String, dynamic> _memoryStore = {};
  final Map<String, DateTime> _lastUpdated = {};

  /// Store a list or map in cache under a specific key
  void set(String key, dynamic data) {
    if (data == null) return;
    _memoryStore[key] = data;
    _lastUpdated[key] = DateTime.now();
    debugPrint('[OfflineCache] Cached data for key "$key" at ${_lastUpdated[key]}');
  }

  /// Retrieve cached data. Returns null if not present.
  T? get<T>(String key) {
    final value = _memoryStore[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Check if data exists for key
  bool has(String key) => _memoryStore.containsKey(key) && _memoryStore[key] != null;

  /// Get time when key was last cached
  DateTime? getLastUpdated(String key) => _lastUpdated[key];

  /// Invalidate/remove a specific key
  void remove(String key) {
    _memoryStore.remove(key);
    _lastUpdated.remove(key);
  }

  /// Clear entire cache
  void clear() {
    _memoryStore.clear();
    _lastUpdated.clear();
  }

  // ── Convenience Helpers for Key IBUILD Entities ──

  // Projects
  void cacheProjects(List<Map<String, dynamic>> projects) => set('projects_master', projects);
  List<Map<String, dynamic>>? getCachedProjects() {
    final raw = get<List>('projects_master');
    return raw?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Employees
  void cacheEmployees(List<Map<String, dynamic>> employees) => set('employees_master', employees);
  List<Map<String, dynamic>>? getCachedEmployees() {
    final raw = get<List>('employees_master');
    return raw?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Attendance by Date
  void cacheAttendanceForDate(String date, List<Map<String, dynamic>> records) {
    set('attendance_$date', records);
  }

  List<Map<String, dynamic>>? getCachedAttendanceForDate(String date) {
    final raw = get<List>('attendance_$date');
    return raw?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Snags / Punch List
  void cacheSnags(List<Map<String, dynamic>> snags) => set('snags_master', snags);
  List<Map<String, dynamic>>? getCachedSnags() {
    final raw = get<List>('snags_master');
    return raw?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Inventory Catalog
  void cacheInventory(List<Map<String, dynamic>> inventory) => set('inventory_master', inventory);
  List<Map<String, dynamic>>? getCachedInventory() {
    final raw = get<List>('inventory_master');
    return raw?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
