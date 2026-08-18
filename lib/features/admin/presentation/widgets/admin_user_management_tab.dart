import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/theme/app_colors.dart';
import 'package:ibuild/core/utils/avatar_helper.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';
import 'package:ibuild/features/admin/data/models/admin_user_model.dart';
import 'package:ibuild/features/admin/presentation/providers/admin_providers.dart';

class AdminUserManagementTab extends ConsumerStatefulWidget {
  const AdminUserManagementTab({super.key});

  @override
  ConsumerState<AdminUserManagementTab> createState() => _AdminUserManagementTabState();
}

class _AdminUserManagementTabState extends ConsumerState<AdminUserManagementTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = ref.watch(filteredAdminUsersProvider);
    final usersAsync = ref.watch(adminUsersProvider);

    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);
    final mutedText = AppColors.mutedText(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Controls Header: Search, Filter, Add User ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => ref.read(adminUserSearchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search users by name, email, phone...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(adminUserSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add New User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Role Filter Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'All Users (${usersAsync.valueOrNull?.length ?? 0})'),
                const SizedBox(width: 8),
                _filterChip('admin', 'Admins'),
                const SizedBox(width: 8),
                _filterChip('owner', 'Business Owners'),
                const SizedBox(width: 8),
                _filterChip('supervisor', 'Supervisors'),
                const SizedBox(width: 8),
                _filterChip('employee', 'Employees'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Users List / Data Grid ──
          usersAsync.when(
            data: (_) {
              if (filteredUsers.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.person_search_outlined, size: 48, color: mutedText),
                      const SizedBox(height: 12),
                      Text(
                        'No matching users found',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 4),
                      Text('Try adjusting your search query or role filter.', style: TextStyle(color: mutedText)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredUsers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return _userCard(context, user);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error loading users: $e', style: const TextStyle(color: AppColors.error))),
                  TextButton(
                    onPressed: () => ref.invalidate(adminUsersProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String roleKey, String label) {
    final activeFilter = ref.watch(adminUserRoleFilterProvider);
    final isSelected = activeFilter == roleKey;
    final primaryColor = AppColors.primaryColor(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(adminUserRoleFilterProvider.notifier).state = roleKey,
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : AppColors.mutedText(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: AppColors.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? primaryColor : AppColors.border(context),
        ),
      ),
    );
  }

  Widget _userCard(BuildContext context, AdminUserEntry user) {
    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);
    final mutedText = AppColors.mutedText(context);

    Color roleColor;
    switch (user.roleName) {
      case 'admin':
        roleColor = Colors.redAccent;
        break;
      case 'owner':
        roleColor = Colors.blueAccent;
        break;
      case 'supervisor':
        roleColor = Colors.green;
        break;
      case 'employee':
      default:
        roleColor = Colors.amber.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: user.isDisabled ? cardBg.withValues(alpha: 0.6) : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: user.isDisabled ? AppColors.error.withValues(alpha: 0.3) : borderCol),
      ),
      child: Row(
        children: [
          // Avatar
          Builder(
            builder: (context) {
              final avatar = RoleAvatarHelper.getAvatarUrl(
                customAvatarUrl: user.avatarUrl,
                role: user.roleName,
                email: user.email,
              );
              return CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(avatar),
                backgroundColor: roleColor.withValues(alpha: 0.15),
              );
            },
          ),
          const SizedBox(width: 14),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: user.isDisabled ? mutedText : AppColors.text(context),
                          decoration: user.isDisabled ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        user.roleName.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (user.isDisabled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'DISABLED',
                          style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 13, color: mutedText),
                    const SizedBox(width: 4),
                    Text(user.email, style: TextStyle(color: mutedText, fontSize: 12)),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.phone_outlined, size: 13, color: mutedText),
                      const SizedBox(width: 4),
                      Text(user.phone, style: TextStyle(color: mutedText, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Change Password Button
              IconButton(
                icon: const Icon(Icons.key_outlined, size: 18),
                tooltip: 'Reset / Change Password',
                onPressed: () => _showPasswordDialog(context, user),
              ),

              // Edit User Profile / Role
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Profile & Role',
                onPressed: () => _showEditUserDialog(context, user),
              ),

              // Enable/Disable Switch
              Tooltip(
                message: user.isDisabled ? 'Enable User Access' : 'Disable User Access',
                child: Switch(
                  value: !user.isDisabled,
                  activeThumbColor: Colors.green,
                  onChanged: (active) async {
                    final shouldProceed = await _confirmActionDialog(
                      context,
                      title: active ? 'Enable User?' : 'Disable User Access?',
                      message: active
                          ? 'User ${user.fullName} will regain portal access.'
                          : 'User ${user.fullName} will be prevented from logging in or making changes.',
                    );
                    if (shouldProceed == true) {
                      final repo = ref.read(adminRepositoryProvider);
                      final ok = await repo.toggleUserDisabled(
                        userId: user.userId,
                        isDisabled: !active,
                        userName: user.fullName,
                      );
                      if (ok) {
                        ref.invalidate(adminUsersProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User ${user.fullName} ${active ? "enabled" : "disabled"}'),
                              backgroundColor: active ? AppColors.secondary : Colors.orange,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Add User Dialog ──
  void _showAddUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController(text: _generateRandomPassword());
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController(text: 'IBUILD');
    String selectedRole = 'supervisor';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Provision New User Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Creates an authenticated login credential in Supabase and provisions their operational ERP permissions.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Login Email Address *',
                      hintText: 'e.g. supervisor1@ibuild.in',
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password with generator
                  TextField(
                    controller: pwdCtrl,
                    decoration: InputDecoration(
                      labelText: 'Initial Password *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.autorenew, size: 18),
                        tooltip: 'Generate Strong Password',
                        onPressed: () {
                          setDialogState(() {
                            pwdCtrl.text = _generateRandomPassword();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Full Name
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Ramesh Kumar',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone Number',
                      hintText: '+91 98765 43210',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Company / Firm Name
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company / Firm Name',
                      hintText: 'IBUILD Construction Corp',
                      prefixIcon: Icon(Icons.business_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role Selector Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Assign Role & Access Scope *',
                      prefixIcon: Icon(Icons.shield_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin (Full System Control)')),
                      DropdownMenuItem(value: 'owner', child: Text('Business Owner (Commercial & Financials)')),
                      DropdownMenuItem(value: 'supervisor', child: Text('Site Supervisor (Daily Logs & Snags)')),
                      DropdownMenuItem(value: 'employee', child: Text('Employee (Restricted Field View)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedRole = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      final password = pwdCtrl.text.trim();
                      final fullName = nameCtrl.text.trim();

                      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in email, password, and full name.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final repo = ref.read(adminRepositoryProvider);
                      final res = await repo.createUser(
                        email: email,
                        password: password,
                        fullName: fullName,
                        roleName: selectedRole,
                        phone: phoneCtrl.text.trim(),
                        companyName: companyCtrl.text.trim(),
                      );

                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }

                      ref.invalidate(adminUsersProvider);
                      ref.invalidate(systemHealthProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success ? AppColors.secondary : AppColors.error,
                          ),
                        );
                      }
                    },
              icon: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 16),
              label: Text(isSubmitting ? 'Provisioning...' : 'Create Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit User Profile & Role Dialog ──
  void _showEditUserDialog(BuildContext context, AdminUserEntry user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    final companyCtrl = TextEditingController(text: user.companyName);
    String selectedRole = user.roleName.isEmpty ? 'employee' : user.roleName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.manage_accounts_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Edit User: ${user.fullName}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Login Email Address *',
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company / Firm Name',
                      prefixIcon: Icon(Icons.business_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Role *',
                      prefixIcon: Icon(Icons.shield_outlined, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'owner', child: Text('Business Owner')),
                      DropdownMenuItem(value: 'supervisor', child: Text('Site Supervisor')),
                      DropdownMenuItem(value: 'employee', child: Text('Employee')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedRole = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final repo = ref.read(adminRepositoryProvider);

                      // 1. Update profile
                      await repo.updateUserProfile(
                        userId: user.userId,
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        companyName: companyCtrl.text.trim(),
                      );

                      // 2. Update email if changed
                      if (emailCtrl.text.trim() != user.email && emailCtrl.text.trim().isNotEmpty) {
                        await repo.updateUserEmail(
                          userId: user.userId,
                          newEmail: emailCtrl.text.trim(),
                        );
                      }

                      // 3. Update role if changed
                      if (selectedRole != user.roleName) {
                        final roleRow = await ref.read(roleRepositoryProvider).fetchAllRoles();
                        final match = roleRow.firstWhere(
                          (r) => r.name.toLowerCase() == selectedRole.toLowerCase(),
                          orElse: () => roleRow.first,
                        );
                        await repo.changeUserRole(
                          userId: user.userId,
                          newRoleId: match.id,
                          newRoleName: selectedRole,
                          userName: nameCtrl.text.trim(),
                        );
                      }

                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }

                      ref.invalidate(adminUsersProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User profile & permissions updated successfully ✓'),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      }
                    },
              icon: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 16),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Password Management Dialog ──
  void _showPasswordDialog(BuildContext context, AdminUserEntry user) {
    final pwdCtrl = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.key, color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                'Password Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage login credentials for ${user.fullName} (${user.email}).',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Option 1: Direct password change
                const Text(
                  'OPTION 1: SET NEW PASSWORD DIRECTLY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pwdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter at least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.autorenew, size: 18),
                      tooltip: 'Generate Password',
                      onPressed: () {
                        pwdCtrl.text = _generateRandomPassword();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final newPwd = pwdCtrl.text.trim();
                            if (newPwd.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password must be at least 6 characters.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isProcessing = true);
                            final repo = ref.read(adminRepositoryProvider);
                            final res = await repo.setUserPassword(
                              userId: user.userId,
                              newPassword: newPwd,
                            );

                            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.message),
                                  backgroundColor: res.success ? AppColors.secondary : AppColors.error,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Update Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const Divider(height: 28),

                // Option 2: Send Reset Email
                const Text(
                  'OPTION 2: DISPATCH RESET EMAIL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sends an email with a secure link allowing the user to reset their own password.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() => isProcessing = true);
                          final repo = ref.read(adminRepositoryProvider);
                          final res = await repo.sendPasswordResetEmail(email: user.email);

                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: res.success ? AppColors.secondary : AppColors.error,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Send Reset Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmActionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%*';
    final rand = Random.secure();
    return List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
