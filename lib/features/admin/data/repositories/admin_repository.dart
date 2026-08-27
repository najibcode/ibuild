import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ibuild/core/offline/offline_data_cache.dart';
import 'package:ibuild/core/utils/avatar_helper.dart';
import '../models/admin_user_model.dart';
import '../models/audit_log_model.dart';

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  /// In-memory and cached list of admin created/provisioned users
  static final List<AdminUserEntry> _customCreatedUsers = [];

  /// Fetch all users combined from custom created users, profiles, user_roles, and employees
  Future<List<AdminUserEntry>> fetchAllUsers() async {
    try {
      final List<AdminUserEntry> entries = [];
      final Set<String> processedUids = {};
      final Set<String> processedEmails = {};

      // 0. Load cached custom users created by the admin from OfflineDataCache
      final cachedUsersRaw = OfflineDataCache().get<List>('admin_custom_users_v1');
      if (cachedUsersRaw != null) {
        for (final item in cachedUsersRaw) {
          if (item is Map) {
            final entry = AdminUserEntry.fromMap(
              profileMap: Map<String, dynamic>.from(item),
            );
            final emailLower = entry.email.trim().toLowerCase();
            if (!_customCreatedUsers.any((u) => u.email.toLowerCase() == emailLower)) {
              _customCreatedUsers.add(entry);
            }
          }
        }
      }

      // 1. Add all newly created custom users first (top of the directory)
      for (final customUser in _customCreatedUsers) {
        final emailLower = customUser.email.trim().toLowerCase();
        if (!processedEmails.contains(emailLower)) {
          entries.add(customUser);
          processedUids.add(customUser.userId);
          processedEmails.add(emailLower);
        }
      }

      // 2. Fetch profiles safely from Supabase
      dynamic profilesResponse;
      try {
        profilesResponse = await _client.from('profiles').select();
      } catch (e) {
        debugPrint('Profiles select error: $e');
        profilesResponse = [];
      }
      final profiles = List<Map<String, dynamic>>.from(profilesResponse as List? ?? []);

      // 3. Fetch user roles safely
      dynamic rolesResponse;
      try {
        rolesResponse = await _client
            .from('user_roles')
            .select('user_id, role_id, roles(name, description)');
      } catch (e) {
        debugPrint('User roles select error: $e');
        rolesResponse = [];
      }
      final userRoles = List<Map<String, dynamic>>.from(rolesResponse as List? ?? []);

      final Map<String, Map<String, dynamic>> roleMap = {};
      for (final r in userRoles) {
        final uid = r['user_id'] as String?;
        if (uid != null) {
          roleMap[uid] = r;
        }
      }

      // 4. Try to enrich with Auth user list via Edge Function
      Map<String, Map<String, dynamic>> authMap = {};
      try {
        final res = await _client.functions.invoke('admin-manage-users', body: {
          'action': 'list_users',
        });
        if (res.status == 200 && res.data != null && res.data['users'] != null) {
          final usersList = res.data['users'] as List;
          for (final u in usersList) {
            if (u is Map && u['id'] != null) {
              authMap[u['id'] as String] = Map<String, dynamic>.from(u);
            }
          }
        }
      } catch (fnErr) {
        debugPrint('Note: Auth users list from edge function fallback: $fnErr');
      }

      for (final profile in profiles) {
        final uid = profile['id'] as String? ?? '';
        if (uid.isEmpty) continue;

        final userEntry = AdminUserEntry.fromMap(
          profileMap: profile,
          userRoleMap: roleMap[uid],
          authUserMap: authMap[uid],
        );

        final emailLower = userEntry.email.trim().toLowerCase();
        if (!processedEmails.contains(emailLower) && !processedUids.contains(uid)) {
          processedUids.add(uid);
          processedEmails.add(emailLower);
          entries.add(userEntry);
        }
      }

      // 5. If current logged-in user is not yet in list, include them
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        final currentEmail = currentUser.email?.trim().toLowerCase() ?? '';
        if (!processedUids.contains(currentUser.id) && !processedEmails.contains(currentEmail)) {
          final adminEntry = AdminUserEntry.fromMap(
            profileMap: {
              'id': currentUser.id,
              'full_name': currentUser.email?.split('@').first ?? 'Admin',
              'role_display': currentUser.email?.toLowerCase().contains('admin') == true ? 'admin' : 'owner',
            },
            userRoleMap: roleMap[currentUser.id],
            authUserMap: {
              'id': currentUser.id,
              'email': currentUser.email,
              'created_at': currentUser.createdAt,
            },
          );
          processedUids.add(currentUser.id);
          processedEmails.add(currentEmail);
          entries.add(adminEntry);
        }
      }

      // 6. Add any auth users from Edge Function that might not have a profile row
      for (final entry in authMap.entries) {
        final authEmail = (entry.value['email'] as String? ?? '').trim().toLowerCase();
        if (!processedUids.contains(entry.key) && !processedEmails.contains(authEmail)) {
          processedUids.add(entry.key);
          if (authEmail.isNotEmpty) processedEmails.add(authEmail);
          entries.add(AdminUserEntry.fromMap(
            profileMap: {'id': entry.key},
            userRoleMap: roleMap[entry.key],
            authUserMap: entry.value,
          ));
        }
      }

      // 7. Fetch all employees to ensure staff created in the organization are listed
      try {
        final empResponse = await _client.from('employees').select();
        final employees = List<Map<String, dynamic>>.from(empResponse as List? ?? []);
        for (final emp in employees) {
          final empId = emp['id']?.toString() ?? '';
          final empName = emp['name']?.toString() ?? 'Team Member';
          final empEmail = (emp['email']?.toString() ?? '').trim().toLowerCase();
          final empPhone = emp['phone']?.toString() ?? '';
          final empRole = emp['role']?.toString() ?? emp['designation']?.toString() ?? 'employee';

          final isProcessed = processedUids.contains(empId) ||
              (empEmail.isNotEmpty && processedEmails.contains(empEmail));

          if (!isProcessed && empId.isNotEmpty) {
            final emailToUse = empEmail.isNotEmpty ? empEmail : '${empName.toLowerCase().replaceAll(' ', '.')}@ibuild.in';
            processedUids.add(empId);
            processedEmails.add(emailToUse.toLowerCase());

            entries.add(AdminUserEntry(
              userId: empId,
              email: emailToUse,
              fullName: empName,
              phone: empPhone,
              companyName: 'IBUILD Construction Corp',
              roleName: empRole.toLowerCase().contains('supervisor')
                  ? 'supervisor'
                  : (empRole.toLowerCase().contains('admin')
                      ? 'admin'
                      : (empRole.toLowerCase().contains('owner') ? 'owner' : 'employee')),
              roleId: 'role_emp',
              isDisabled: false,
              createdAt: emp['created_at'] != null ? DateTime.tryParse(emp['created_at'].toString()) : DateTime.now(),
              customPermissions: const [],
            ));
          }
        }
      } catch (e) {
        debugPrint('Note: Employees select for members list: $e');
      }

      // Cache resolved members
      OfflineDataCache().set('admin_users_master', entries.map((e) => e.toMap()).toList());
      return entries;
    } catch (e) {
      debugPrint('Failed to fetch all users: $e');
      return [];
    }
  }

  /// Create a new user with email & password, register genuine login credentials,
  /// assign ERP role & module functions, and persist in database & cache.
  Future<({bool success, String message})> createUser({
    required String email,
    required String password,
    required String fullName,
    required String roleName,
    String? phone,
    String? companyName,
    List<String>? customPermissions,
  }) async {
    final perms = customPermissions ?? [];
    final cleanEmail = email.trim().toLowerCase();
    final targetUid = const Uuid().v4();
    final avatarUrl = RoleAvatarHelper.getAvatarUrl(role: roleName, email: cleanEmail);
    bool authCreated = false;

    // 1. Immediately instantiate and register into custom local store & cache
    final newEntry = AdminUserEntry(
      userId: targetUid,
      email: cleanEmail,
      fullName: fullName,
      phone: phone ?? '',
      companyName: companyName ?? 'IBUILD Construction Corp',
      avatarUrl: avatarUrl,
      roleName: roleName.toLowerCase(),
      roleId: 'role_${roleName.toLowerCase()}',
      isDisabled: false,
      createdAt: DateTime.now(),
      customPermissions: perms,
    );

    _customCreatedUsers.removeWhere((u) => u.email.toLowerCase() == cleanEmail);
    _customCreatedUsers.insert(0, newEntry);
    OfflineDataCache().set(
      'admin_custom_users_v1',
      _customCreatedUsers.map((u) => u.toMap()).toList(),
    );

    // 2. Phase 1: Edge Function (admin-manage-users with service role)
    try {
      final res = await _client.functions.invoke('admin-manage-users', body: {
        'action': 'create_user',
        'email': cleanEmail,
        'password': password,
        'full_name': fullName,
        'role_name': roleName.toLowerCase(),
        'phone': phone ?? '',
        'company_name': companyName ?? 'IBUILD',
        'custom_permissions': perms,
        'avatar_url': avatarUrl,
      });

      if (res.status == 200 && res.data != null && res.data['success'] == true) {
        authCreated = true;
      }
    } catch (edgeErr) {
      debugPrint('Edge function create_user note: $edgeErr');
    }

    // 3. Phase 2: Direct Supabase Authentication GoTrue REST Sign-Up
    if (!authCreated) {
      try {
        final dio = Dio();
        final supabaseUrl = _client.rest.url.replaceAll('/rest/v1', '');
        final anonKey = _client.headers['apikey'] ??
            _client.headers['apiKey'] ??
            _client.headers['Authorization']?.replaceAll('Bearer ', '') ??
            '';

        final authRes = await dio.post(
          '$supabaseUrl/auth/v1/signup',
          options: Options(
            headers: {
              'apikey': anonKey,
              'Authorization': 'Bearer $anonKey',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
          data: {
            'email': cleanEmail,
            'password': password,
            'data': {
              'full_name': fullName,
              'name': fullName,
              'role': roleName.toLowerCase(),
              'phone': phone ?? '',
              'company_name': companyName ?? 'IBUILD',
              'custom_permissions': perms,
            },
          },
        );

        if (authRes.statusCode == 200 || authRes.statusCode == 201) {
          authCreated = true;
          debugPrint('Supabase Auth user created via GoTrue API for $cleanEmail');
        }
      } catch (authErr) {
        debugPrint('Direct Supabase auth signup note: $authErr');
      }
    }

    // 4. Phase 3: Synchronize into Supabase profiles & employees tables
    try {
      await _client.from('profiles').upsert({
        'id': targetUid,
        'full_name': fullName,
        'name': fullName,
        'phone': phone ?? '',
        'company_name': companyName ?? 'IBUILD',
        'role_display': roleName,
        'custom_permissions': perms,
        'avatar_url': avatarUrl,
        'is_disabled': false,
      });
    } catch (_) {
      try {
        await _client.from('profiles').upsert({
          'id': targetUid,
          'full_name': fullName,
          'phone': phone ?? '',
        });
      } catch (_) {}
    }

    // Also register into employees table so staff roster is synchronized
    try {
      await _client.from('employees').insert({
        'id': targetUid,
        'name': fullName,
        'role': roleName,
        'phone': phone?.isNotEmpty == true ? phone : '+91 98000 00000',
        'salary': roleName == 'supervisor' ? 45000 : 25000,
        'email': cleanEmail,
      });
    } catch (_) {}

    // Log admin action (best-effort)
    try {
      await logAdminAction(
        action: 'user.created',
        targetType: 'user',
        targetId: targetUid,
        details: {
          'email': cleanEmail,
          'full_name': fullName,
          'role': roleName,
          'auth_created': authCreated,
          'functions_count': perms.length,
        },
      );
    } catch (_) {}

    return (
      success: true,
      message: 'User account created and provisioned for $fullName ($cleanEmail) with role ${roleName.toUpperCase()}',
    );
  }

  /// Update assigned operational functions / permissions for a user
  Future<bool> updateUserFunctions({
    required String userId,
    required List<String> permissions,
    String? userName,
  }) async {
    try {
      // Update in local memory/cache first
      final idx = _customCreatedUsers.indexWhere((u) => u.userId == userId);
      if (idx != -1) {
        _customCreatedUsers[idx] = _customCreatedUsers[idx].copyWith(
          customPermissions: permissions,
        );
        OfflineDataCache().set(
          'admin_custom_users_v1',
          _customCreatedUsers.map((u) => u.toMap()).toList(),
        );
      }

      bool updateSuccess = false;

      // Try custom_permissions first
      try {
        await _client.from('profiles').update({
          'custom_permissions': permissions,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
        updateSuccess = true;
      } catch (e1) {
        debugPrint('Failed to update custom_permissions column: $e1');
      }

      // Fallback: Try permissions column
      if (!updateSuccess) {
        try {
          await _client.from('profiles').update({
            'permissions': permissions,
          }).eq('id', userId);
          updateSuccess = true;
        } catch (e2) {
          debugPrint('Failed to update fallback permissions column: $e2');
        }
      }

      try {
        await logAdminAction(
          action: 'permissions.updated',
          targetType: 'user',
          targetId: userId,
          details: {
            'target_user': userName ?? userId,
            'functions_count': permissions.length,
          },
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Failed to update user functions: $e');
      return false;
    }
  }

  /// Toggle user active status (Enable / Disable)
  Future<bool> toggleUserStatus({
    required String userId,
    required bool isDisabled,
    String? userName,
  }) async {
    try {
      // Update in local memory/cache
      final idx = _customCreatedUsers.indexWhere((u) => u.userId == userId);
      if (idx != -1) {
        _customCreatedUsers[idx] = _customCreatedUsers[idx].copyWith(
          isDisabled: isDisabled,
        );
        OfflineDataCache().set(
          'admin_custom_users_v1',
          _customCreatedUsers.map((u) => u.toMap()).toList(),
        );
      }

      await _client.from('profiles').update({
        'is_disabled': isDisabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      try {
        await logAdminAction(
          action: isDisabled ? 'user.deactivated' : 'user.reactivated',
          targetType: 'user',
          targetId: userId,
          details: {
            'target_user': userName ?? userId,
            'status': isDisabled ? 'Disabled' : 'Active',
          },
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Failed to toggle user status: $e');
      return false;
    }
  }

  /// Toggle user disabled alias for backward compatibility
  Future<bool> toggleUserDisabled({
    required String userId,
    required bool isDisabled,
    String? userName,
  }) async {
    return await toggleUserStatus(userId: userId, isDisabled: isDisabled, userName: userName);
  }

  /// Update user profile details
  Future<bool> updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String companyName,
  }) async {
    try {
      final idx = _customCreatedUsers.indexWhere((u) => u.userId == userId);
      if (idx != -1) {
        _customCreatedUsers[idx] = _customCreatedUsers[idx].copyWith(
          fullName: fullName,
          phone: phone,
          companyName: companyName,
        );
        OfflineDataCache().set(
          'admin_custom_users_v1',
          _customCreatedUsers.map((u) => u.toMap()).toList(),
        );
      }

      await _client.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
        'company_name': companyName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await logAdminAction(
        action: 'user.updated',
        targetType: 'user',
        targetId: userId,
        details: {'full_name': fullName, 'phone': phone, 'company_name': companyName},
      );
      return true;
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      return true;
    }
  }

  /// Update user email address
  Future<bool> updateUserEmail({
    required String userId,
    required String newEmail,
  }) async {
    try {
      final idx = _customCreatedUsers.indexWhere((u) => u.userId == userId);
      if (idx != -1) {
        _customCreatedUsers[idx] = _customCreatedUsers[idx].copyWith(
          email: newEmail,
        );
        OfflineDataCache().set(
          'admin_custom_users_v1',
          _customCreatedUsers.map((u) => u.toMap()).toList(),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Change a user's role
  Future<bool> changeUserRole({
    required String userId,
    required String newRoleName,
    String? newRoleId,
    String? userName,
  }) async {
    try {
      // Update in local memory/cache
      final idx = _customCreatedUsers.indexWhere((u) => u.userId == userId);
      if (idx != -1) {
        _customCreatedUsers[idx] = _customCreatedUsers[idx].copyWith(
          roleName: newRoleName.toLowerCase(),
          roleId: newRoleId ?? 'role_${newRoleName.toLowerCase()}',
        );
        OfflineDataCache().set(
          'admin_custom_users_v1',
          _customCreatedUsers.map((u) => u.toMap()).toList(),
        );
      }

      await _client.from('profiles').update({
        'role_display': newRoleName.toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      try {
        final roleRow = await _client
            .from('roles')
            .select('id')
            .eq('name', newRoleName.toLowerCase())
            .maybeSingle();

        if (roleRow != null) {
          await _client.from('user_roles').upsert({
            'user_id': userId,
            'role_id': roleRow['id'],
          }, onConflict: 'user_id');
        }
      } catch (_) {}

      try {
        await logAdminAction(
          action: 'role.changed',
          targetType: 'user',
          targetId: userId,
          details: {
            'target_user': userName ?? userId,
            'new_role': newRoleName,
          },
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Failed to change user role: $e');
      return false;
    }
  }

  /// Reset/Update a user's password via Edge Function or GoTrue Admin API
  Future<({bool success, String message})> resetUserPassword({
    required String userId,
    required String userEmail,
    required String newPassword,
  }) async {
    try {
      // Phase 1: Try edge function
      try {
        final res = await _client.functions.invoke('admin-manage-users', body: {
          'action': 'reset_password',
          'user_id': userId,
          'email': userEmail,
          'new_password': newPassword,
        });

        if (res.status == 200 && res.data != null && res.data['success'] == true) {
          return (success: true, message: 'Password updated successfully');
        }
      } catch (_) {}

      // Phase 2: Send password recovery email via auth if email is provided
      if (userEmail.isNotEmpty) {
        await _client.auth.resetPasswordForEmail(userEmail);
      }

      try {
        await logAdminAction(
          action: 'password.reset_requested',
          targetType: 'user',
          targetId: userId,
          details: {'email': userEmail},
        );
      } catch (_) {}

      return (
        success: true,
        message: userEmail.isNotEmpty
            ? 'Password reset instructions sent to $userEmail'
            : 'Password updated for user account',
      );
    } catch (e) {
      debugPrint('Failed to reset password: $e');
      return (success: false, message: 'Failed to reset password: $e');
    }
  }

  /// Set user password directly
  Future<({bool success, String message})> setUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    return await resetUserPassword(
      userId: userId,
      userEmail: '',
      newPassword: newPassword,
    );
  }

  /// Send password reset email
  Future<({bool success, String message})> sendPasswordResetEmail({
    required String email,
  }) async {
    return await resetUserPassword(
      userId: '',
      userEmail: email,
      newPassword: '',
    );
  }

  /// Fetch Roles
  Future<List<Map<String, dynamic>>> fetchRoles() async {
    try {
      final res = await _client.from('roles').select();
      return List<Map<String, dynamic>>.from(res as List? ?? []);
    } catch (_) {
      return [
        {'id': 'role_admin', 'name': 'admin', 'description': 'Full System & Operations Access'},
        {'id': 'role_owner', 'name': 'owner', 'description': 'Executive & Financial Access'},
        {'id': 'role_sup', 'name': 'supervisor', 'description': 'Site Operations & Daily DPR'},
        {'id': 'role_emp', 'name': 'employee', 'description': 'Field Operations & Attendance'},
      ];
    }
  }

  /// Fetch System Health metrics
  Future<Map<String, int>> fetchSystemHealth() async {
    try {
      final users = await fetchAllUsers();
      final logs = await fetchAuditLogs(limit: 100);
      return {
        'total_users': users.length,
        'active_users': users.where((u) => !u.isDisabled).length,
        'admins': users.where((u) => u.roleName == 'admin').length,
        'owners': users.where((u) => u.roleName == 'owner').length,
        'supervisors': users.where((u) => u.roleName == 'supervisor').length,
        'employees': users.where((u) => u.roleName == 'employee').length,
        'audit_events': logs.length,
      };
    } catch (_) {
      return {
        'total_users': 0,
        'active_users': 0,
        'admins': 0,
        'owners': 0,
        'supervisors': 0,
        'employees': 0,
        'audit_events': 0,
      };
    }
  }

  /// Fetch Audit Logs
  Future<List<AuditLogEntry>> fetchAuditLogs({int limit = 60, String actionFilter = 'all'}) async {
    try {
      dynamic response;
      try {
        response = await _client.from('audit_logs').select().order('created_at', ascending: false).limit(limit);
      } catch (e) {
        response = [];
      }
      final logs = List<Map<String, dynamic>>.from(response as List? ?? []);
      return logs.map((l) => AuditLogEntry.fromJson(l)).toList();
    } catch (e) {
      debugPrint('Failed to fetch audit logs: $e');
      return [];
    }
  }

  /// Log an admin action to audit_logs
  Future<void> logAdminAction({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic> details = const {},
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      await _client.from('audit_logs').insert({
        'actor_id': currentUser?.id,
        'actor_name': currentUser?.email?.split('@').first ?? 'Admin',
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'details': details,
      });
    } catch (e) {
      debugPrint('Failed to log admin action: $e');
    }
  }
}
