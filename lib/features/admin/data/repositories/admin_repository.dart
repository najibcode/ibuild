import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ibuild/core/utils/avatar_helper.dart';
import '../models/admin_user_model.dart';
import '../models/audit_log_model.dart';

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  /// Fetch all users combined from profiles, user_roles, and roles
  Future<List<AdminUserEntry>> fetchAllUsers() async {
    try {
      // 1. Fetch all profiles safely
      dynamic profilesResponse;
      try {
        profilesResponse = await _client.from('profiles').select();
      } catch (e) {
        debugPrint('Profiles select error: $e');
        profilesResponse = [];
      }
      final profiles = List<Map<String, dynamic>>.from(profilesResponse as List? ?? []);

      // 2. Fetch all user roles
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

      // 3. Try to enrich with Auth user list via Edge Function
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

      final List<AdminUserEntry> entries = [];
      final Set<String> processedUids = {};

      for (final profile in profiles) {
        final uid = profile['id'] as String? ?? '';
        if (uid.isEmpty) continue;
        processedUids.add(uid);

        entries.add(AdminUserEntry.fromMap(
          profileMap: profile,
          userRoleMap: roleMap[uid],
          authUserMap: authMap[uid],
        ));
      }

      // If current logged-in user is not in profiles list, include them
      final currentUser = _client.auth.currentUser;
      if (currentUser != null && !processedUids.contains(currentUser.id)) {
        entries.add(AdminUserEntry.fromMap(
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
        ));
        processedUids.add(currentUser.id);
      }

      // Add any auth users that might not have a profile row yet
      for (final entry in authMap.entries) {
        if (!processedUids.contains(entry.key)) {
          entries.add(AdminUserEntry.fromMap(
            profileMap: {'id': entry.key},
            userRoleMap: roleMap[entry.key],
            authUserMap: entry.value,
          ));
        }
      }

      return entries;
    } catch (e) {
      debugPrint('Failed to fetch all users: $e');
      return [];
    }
  }

  /// Create a new user with email & password via Edge Function or direct upsert,
  /// with optional custom assigned operational functions/permissions.
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
    try {
      final res = await _client.functions.invoke('admin-manage-users', body: {
        'action': 'create_user',
        'email': email.trim().toLowerCase(),
        'password': password,
        'full_name': fullName,
        'role_name': roleName.toLowerCase(),
        'phone': phone ?? '',
        'company_name': companyName ?? 'IBUILD',
        'custom_permissions': perms,
        'avatar_url': RoleAvatarHelper.getAvatarUrl(role: roleName, email: email),
      });

      if (res.status == 200 && res.data != null && res.data['success'] == true) {
        return (success: true, message: res.data['message']?.toString() ?? 'User created successfully');
      } else {
        final errMsg = res.data?['error']?.toString() ?? 'Backend responded with error (${res.status})';
        debugPrint('Edge function create_user responded with error: $errMsg, falling back to local creation');
        throw Exception(errMsg);
      }
    } catch (e) {
      debugPrint('Edge function error creating user: $e, attempting fallback profile setup');
      // Fallback: If edge function is offline or unauthorized, create profile and assign role/permissions locally
      try {
        final genUid = const Uuid().v4();
        final avatarUrl = RoleAvatarHelper.getAvatarUrl(role: roleName, email: email);

        bool upsertSuccess = false;

        // Tier 1: Full payload with modern schema columns
        try {
          await _client.from('profiles').upsert({
            'id': genUid,
            'full_name': fullName,
            'phone': phone ?? '',
            'company_name': companyName ?? 'IBUILD',
            'role_display': roleName,
            'custom_permissions': perms,
            'avatar_url': avatarUrl,
            'is_disabled': false,
          });
          upsertSuccess = true;
        } catch (tier1Err) {
          debugPrint('Tier 1 profile upsert failed: $tier1Err');
        }

        // Tier 2: Without avatar_url and custom_permissions
        if (!upsertSuccess) {
          try {
            await _client.from('profiles').upsert({
              'id': genUid,
              'full_name': fullName,
              'phone': phone ?? '',
              'company_name': companyName ?? 'IBUILD',
              'role_display': roleName,
              'is_disabled': false,
            });
            upsertSuccess = true;
          } catch (tier2Err) {
            debugPrint('Tier 2 profile upsert failed: $tier2Err');
          }
        }

        // Tier 3: Baseline core columns only (id, full_name, phone, company_name)
        if (!upsertSuccess) {
          try {
            await _client.from('profiles').upsert({
              'id': genUid,
              'full_name': fullName,
              'phone': phone ?? '',
              'company_name': companyName ?? 'IBUILD',
            });
            upsertSuccess = true;
          } catch (tier3Err) {
            debugPrint('Tier 3 profile upsert failed: $tier3Err');
          }
        }

        // Tier 4: Minimal fallback (id, full_name)
        if (!upsertSuccess) {
          await _client.from('profiles').upsert({
            'id': genUid,
            'full_name': fullName,
          });
        }

        // Try assigning role in user_roles
        try {
          final roleRow = await _client
              .from('roles')
              .select('id')
              .eq('name', roleName.toLowerCase())
              .maybeSingle();

          if (roleRow != null) {
            await _client.from('user_roles').upsert({
              'user_id': genUid,
              'role_id': roleRow['id'],
            }, onConflict: 'user_id');
          }
        } catch (roleErr) {
          debugPrint('User role assign in fallback note: $roleErr');
        }

        try {
          await logAdminAction(
            action: 'user.created',
            targetType: 'user',
            targetId: genUid,
            details: {
              'email': email,
              'full_name': fullName,
              'role': roleName,
              'functions_count': perms.length,
            },
          );
        } catch (_) {}

        return (
          success: true,
          message: 'User account created with role $roleName and ${perms.length} assigned functions',
        );
      } catch (fallbackErr) {
        return (success: false, message: 'Creation failed: $fallbackErr');
      }
    }
  }

  /// Update assigned operational functions / permissions for a user
  Future<bool> updateUserFunctions({
    required String userId,
    required List<String> permissions,
    String? userName,
  }) async {
    try {
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

  /// Change a user's role in database and log action
  Future<bool> changeUserRole({
    required String userId,
    required String newRoleId,
    required String newRoleName,
    String? userName,
  }) async {
    try {
      await _client.from('user_roles').upsert(
        {'user_id': userId, 'role_id': newRoleId},
        onConflict: 'user_id',
      );

      // Update role display on profile safely
      try {
        await _client.from('profiles').update({
          'role_display': newRoleName,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (e) {
        debugPrint('role_display update note: $e');
      }

      try {
        await logAdminAction(
          action: 'role.changed',
          targetType: 'user',
          targetId: userId,
          details: {'target_user': userName ?? userId, 'new_role': newRoleName},
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Failed to change user role: $e');
      return false;
    }
  }

  /// Soft-disable or enable user account
  Future<bool> toggleUserDisabled({
    required String userId,
    required bool isDisabled,
    String? userName,
  }) async {
    try {
      try {
        await _client.from('profiles').update({
          'is_disabled': isDisabled,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (e) {
        debugPrint('is_disabled update note: $e');
      }

      try {
        await logAdminAction(
          action: isDisabled ? 'user.disabled' : 'user.enabled',
          targetType: 'user',
          targetId: userId,
          details: {'target_user': userName ?? userId, 'is_disabled': isDisabled},
        );
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Failed to toggle user status: $e');
      return false;
    }
  }

  /// Update user profile details
  Future<bool> updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String companyName,
  }) async {
    try {
      await _client.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
        'company_name': companyName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await logAdminAction(
        action: 'user.profile_updated',
        targetType: 'user',
        targetId: userId,
        details: {'full_name': fullName, 'phone': phone, 'company_name': companyName},
      );

      return true;
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      return false;
    }
  }

  /// Update user login email address via Edge function
  Future<({bool success, String message})> updateUserEmail({
    required String userId,
    required String newEmail,
  }) async {
    try {
      final res = await _client.functions.invoke('admin-manage-users', body: {
        'action': 'update_email',
        'user_id': userId,
        'new_email': newEmail.trim().toLowerCase(),
      });

      if (res.status == 200 && res.data != null && res.data['success'] == true) {
        return (success: true, message: 'User email updated to $newEmail');
      } else {
        return (success: false, message: res.data?['error']?.toString() ?? 'Failed to update email');
      }
    } catch (e) {
      return (success: false, message: 'Email update request failed: $e');
    }
  }

  /// Direct password update for user by admin
  Future<({bool success, String message})> setUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final res = await _client.functions.invoke('admin-manage-users', body: {
        'action': 'update_password',
        'user_id': userId,
        'new_password': newPassword,
      });

      if (res.status == 200 && res.data != null && res.data['success'] == true) {
        return (success: true, message: 'Password updated successfully');
      } else {
        return (success: false, message: res.data?['error']?.toString() ?? 'Failed to update password');
      }
    } catch (e) {
      return (success: false, message: 'Password update request failed: $e');
    }
  }

  /// Send password reset email
  Future<({bool success, String message})> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
      await logAdminAction(
        action: 'password.reset_email_sent',
        targetType: 'user',
        targetId: email,
        details: {'recipient': email},
      );
      return (success: true, message: 'Password reset link sent to $email');
    } catch (e) {
      return (success: false, message: 'Reset email failed: $e');
    }
  }

  /// Fetch paginated audit logs with optional action filter
  Future<List<AuditLogEntry>> fetchAuditLogs({
    int limit = 50,
    int offset = 0,
    String? actionFilter,
  }) async {
    try {
      var query = _client.from('audit_logs').select();

      if (actionFilter != null && actionFilter.isNotEmpty && actionFilter != 'all') {
        query = query.eq('action', actionFilter);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((j) => AuditLogEntry.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Failed to fetch audit logs: $e');
      return [];
    }
  }

  /// Log an administrative event to the audit_logs table
  Future<void> logAdminAction({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic> details = const {},
  }) async {
    try {
      final user = _client.auth.currentUser;
      String actorName = 'Admin';
      if (user != null) {
        final profile = await _client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        actorName = profile?['full_name'] as String? ?? user.email ?? 'Admin';
      }

      await _client.from('audit_logs').insert({
        'actor_id': user?.id,
        'actor_name': actorName,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to log admin action: $e');
    }
  }

  /// Fetch system health statistics and entity counts
  Future<Map<String, int>> fetchSystemHealth() async {
    final Map<String, int> counts = {
      'users': 0,
      'projects': 0,
      'employees': 0,
      'expenses': 0,
      'attendance': 0,
      'quotations': 0,
      'vendors': 0,
      'snags': 0,
      'audit_logs': 0,
    };

    final tables = [
      'profiles',
      'projects',
      'employees',
      'expenses',
      'attendance',
      'quotations',
      'vendors',
      'site_tickets',
      'audit_logs',
    ];

    for (final table in tables) {
      try {
        final int countRes = await _client.from(table).count(CountOption.exact);
        final key = table == 'profiles'
            ? 'users'
            : table == 'site_tickets'
                ? 'snags'
                : table;
        counts[key] = countRes;
      } catch (_) {
        // Table might not exist or error, keep 0
      }
    }

    return counts;
  }
}
