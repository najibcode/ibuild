import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// In-memory and persistent key-value cache layer for storing master data offline.
/// Preserves real user projects (PPR shop, RVS Shop), employees (Soori, Abdul), and attendance records.
class OfflineDataCache {
  static final OfflineDataCache _instance = OfflineDataCache._internal();
  factory OfflineDataCache() => _instance;
  OfflineDataCache._internal();

  final Map<String, dynamic> _memoryStore = {};
  final Map<String, DateTime> _lastUpdated = {};
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize persistent storage and load cached keys into memory
  Future<void> init({bool forceReload = false}) async {
    if (_isInitialized && !forceReload) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith('ibuild_cache_')) {
          final cleanKey = key.replaceFirst('ibuild_cache_', '');
          final jsonString = _prefs?.getString(key);
          if (jsonString != null && jsonString.isNotEmpty) {
            try {
              final decoded = jsonDecode(jsonString);
              _memoryStore[cleanKey] = decoded;
              _lastUpdated[cleanKey] = DateTime.now();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Note: OfflineDataCache SharedPreferences init note: $e');
    }

    _ensureUserRealData();
    _isInitialized = true;
  }

  /// Reload all cached data from persistent storage (simulates cold app restart or page refresh)
  Future<void> reloadFromStorage() async {
    _memoryStore.clear();
    _lastUpdated.clear();
    _isInitialized = false;
    await init(forceReload: true);
  }

  static final _uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  static Map<String, dynamic> _safeMap(dynamic m) {
    if (m is! Map) return <String, dynamic>{};
    return m.map((k, v) => MapEntry(k?.toString() ?? '', v));
  }

  void _ensureUserRealData() {
    // ── 1. Clean & Migrate Existing Projects ──
    final rawProjects = getCachedProjects() ?? [];
    if (rawProjects.isEmpty) {
      final initialProjects = [
        {
          'id': '11111111-1111-4111-8111-111111111111',
          'name': 'PPR shop',
          'client_name': 'PPR Retail & Commercial Group',
          'project_code': 'PRJ-PPR-01',
          'address': 'Main Commercial Road',
          'budget': 1500000.0,
          'estimated_cost': 1400000.0,
          'spent': 450000.0,
          'status': 'active',
          'built_up_area': 3500.0,
          'flat_area': 1200.0,
          'physical_progress': 60.0,
          'duration': '6 Months',
          'deadline': '2026-11-30',
          'description': 'Commercial retail store construction and interior fit-out.',
          'notes': 'Structure complete, plastering and electrical work in progress.',
          'created_at': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        },
        {
          'id': '22222222-2222-4222-8222-222222222222',
          'name': 'RVS Shop',
          'client_name': 'RVS Enterprises',
          'project_code': 'PRJ-RVS-02',
          'address': 'Market Junction Complex',
          'budget': 1200000.0,
          'estimated_cost': 1100000.0,
          'spent': 320000.0,
          'status': 'active',
          'built_up_area': 2800.0,
          'flat_area': 950.0,
          'physical_progress': 45.0,
          'duration': '5 Months',
          'deadline': '2026-12-15',
          'description': 'Commercial showroom building and facade construction.',
          'notes': 'Brickwork finished, flooring and shuttering underway.',
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      ];
      _memoryStore['projects_master'] = initialProjects;
      _lastUpdated['projects_master'] = DateTime.now();
      _persistKey('projects_master', initialProjects);
    } else {
      // Preserve all existing projects while normalizing legacy IDs to valid UUIDs
      final cleanedProjects = rawProjects.map((p) {
        final map = _safeMap(p);
        final id = map['id']?.toString() ?? '';
        if (id == 'proj_ppr_shop') {
          map['id'] = '11111111-1111-4111-8111-111111111111';
        } else if (id == 'proj_rvs_shop') {
          map['id'] = '22222222-2222-4222-8222-222222222222';
        } else if (id.isEmpty || !_uuidPattern.hasMatch(id)) {
          // If project has no valid UUID, preserve or assign a deterministic UUID
          if (id.isEmpty) {
            map['id'] = const Uuid().v4();
          }
        }
        return map;
      }).toList();

      _memoryStore['projects_master'] = cleanedProjects;
      _lastUpdated['projects_master'] = DateTime.now();
      _persistKey('projects_master', cleanedProjects);
    }

    // ── 2. Clean & Migrate Existing Employees ──
    final rawEmployees = getCachedEmployees() ?? [];
    if (rawEmployees.isEmpty) {
      final initialEmployees = [
        {
          'id': '33333333-3333-4333-8333-333333333333',
          'name': 'Soori',
          'role': 'Site Supervisor / Lead Mason',
          'designation': 'Site Supervisor',
          'phone': '+91 98765 11223',
          'email': 'soori@ibuild.in',
          'salary': 1200.0,
          'daily_rate': 1200.0,
          'tea_snack_allowance': 50.0,
          'status': 'active',
          'created_at': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        },
        {
          'id': '44444444-4444-4444-8444-444444444444',
          'name': 'Abdul',
          'role': 'Structural Fabricator / Site Foreman',
          'designation': 'Site Foreman',
          'phone': '+91 98765 44556',
          'email': 'abdul@ibuild.in',
          'salary': 1100.0,
          'daily_rate': 1100.0,
          'tea_snack_allowance': 50.0,
          'status': 'active',
          'created_at': DateTime.now().subtract(const Duration(days: 55)).toIso8601String(),
        },
      ];
      _memoryStore['employees_master'] = initialEmployees;
      _lastUpdated['employees_master'] = DateTime.now();
      _persistKey('employees_master', initialEmployees);
    } else {
      // Preserve all user employee modifications while normalizing legacy IDs
      final cleanedEmployees = rawEmployees.map((e) {
        final map = _safeMap(e);
        final id = map['id']?.toString() ?? '';
        if (id == 'emp_soori_01') {
          map['id'] = '33333333-3333-4333-8333-333333333333';
        } else if (id == 'emp_abdul_02') {
          map['id'] = '44444444-4444-4444-8444-444444444444';
        } else if (id.isEmpty) {
          map['id'] = const Uuid().v4();
        }
        // Ensure salary is normalized
        final sal = (map['salary'] as num?)?.toDouble() ??
            (map['daily_rate'] as num?)?.toDouble() ??
            0.0;
        map['salary'] = sal;
        map['daily_rate'] = sal;
        return map;
      }).toList();

      _memoryStore['employees_master'] = cleanedEmployees;
      _lastUpdated['employees_master'] = DateTime.now();
      _persistKey('employees_master', cleanedEmployees);
    }
  }

  /// Store a list or map in cache under a specific key and persist to storage
  void set(String key, dynamic data) {
    if (data == null) return;
    _memoryStore[key] = data;
    _lastUpdated[key] = DateTime.now();
    debugPrint('[OfflineCache] Cached data for key "$key" at ${_lastUpdated[key]}');

    // Asynchronously persist to SharedPreferences
    _persistKey(key, data);
  }

  Future<void> _persistKey(String key, dynamic data) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await _prefs?.setString('ibuild_cache_$key', jsonString);
    } catch (_) {}
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
    try {
      _prefs?.remove('ibuild_cache_$key');
    } catch (_) {}
  }

  /// Clear entire cache
  void clear() {
    _memoryStore.clear();
    _lastUpdated.clear();
    _isInitialized = false;
    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final k in keys) {
        if (k.startsWith('ibuild_cache_')) {
          _prefs?.remove(k);
        }
      }
    } catch (_) {}
  }

  // ── Convenience Helpers for Key IBUILD Entities ──

  // Projects
  void cacheProjects(List<Map<String, dynamic>> projects) => set('projects_master', projects);
  List<Map<String, dynamic>>? getCachedProjects() {
    final raw = get<List>('projects_master');
    return raw?.map((e) => _safeMap(e)).toList();
  }

  // Employees
  void cacheEmployees(List<Map<String, dynamic>> employees) => set('employees_master', employees);
  List<Map<String, dynamic>>? getCachedEmployees() {
    final raw = get<List>('employees_master');
    return raw?.map((e) => _safeMap(e)).toList();
  }

  // Attendance by Date
  void cacheAttendanceForDate(String date, List<Map<String, dynamic>> records) {
    set('attendance_$date', records);
  }

  List<Map<String, dynamic>>? getCachedAttendanceForDate(String date) {
    final raw = get<List>('attendance_$date');
    return raw?.map((e) => _safeMap(e)).toList();
  }

  // Snags / Punch List
  void cacheSnags(List<Map<String, dynamic>> snags) => set('snags_master', snags);
  List<Map<String, dynamic>>? getCachedSnags() {
    final raw = get<List>('snags_master');
    return raw?.map((e) => _safeMap(e)).toList();
  }

  // Inventory Catalog
  void cacheInventory(List<Map<String, dynamic>> inventory) => set('inventory_master', inventory);
  List<Map<String, dynamic>>? getCachedInventory() {
    final raw = get<List>('inventory_master');
    return raw?.map((e) => _safeMap(e)).toList();
  }

  // Company Branding & Letterhead
  void cacheCompanyBranding(Map<String, dynamic> branding) => set('company_branding', branding);
  Map<String, dynamic>? getCachedCompanyBranding() {
    final raw = get<Map>('company_branding');
    return raw != null ? _safeMap(raw) : null;
  }

  // Subcontractors / Trade Partners
  void cacheSubcontractors(List<Map<String, dynamic>> subcontractors) => set('subcontractors_master', subcontractors);
  List<Map<String, dynamic>>? getCachedSubcontractors() {
    final raw = get<List>('subcontractors_master');
    return raw?.map((e) => _safeMap(e)).toList();
  }

  void cacheSubcontractorSiteAssignment(String subId, String projectId, String siteName) {
    set('sub_site_$subId', {
      'project_id': projectId,
      'site_name': siteName,
    });
  }

  Map<String, String>? getSubcontractorSiteAssignment(String subId) {
    final raw = get<Map>('sub_site_$subId');
    if (raw == null) return null;
    return {
      'project_id': raw['project_id']?.toString() ?? '',
      'site_name': raw['site_name']?.toString() ?? '',
    };
  }
}
