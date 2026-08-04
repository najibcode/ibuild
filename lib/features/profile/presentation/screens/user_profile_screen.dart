import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/logout_dialog.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/rbac/presentation/providers/permission_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _avatarUrlController;
  String _notificationScope = 'all';
  bool _enablePushNotifications = true;

  static const String _defaultAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCZnkMp8GaOnpeTS6OaCmsGI3BT-AMfqKQlZgzWl_1P_wcfcpgsueuBT4g62apzZaMM9KDkryd5NwO0zRN2_qLL3tVRv-tkiZRKLnT4yZ4jh501MqajmHWV3-Tb0c-i328KeaLVPjpouYAeHclbEWmGX3AUSDoVNlY9uR_PjZhazvKln1VD_OY2Heh8KEFXssZ8Xdam3ObeFuJxVLLzfu2zy1jVcOM0hcAKPmqxBIh6d75KpFm9T7V-oUnUvLYk5UEqRnVhrWXTfOc';

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final profile = authState.profile;
    final user = authState.user;

    final defaultName =
        profile?['full_name'] as String? ??
        (user?.email != null && user!.email!.contains('@')
            ? user.email!.split('@').first
            : 'Business Owner');

    _nameController = TextEditingController(text: defaultName);
    _phoneController = TextEditingController(
      text: profile?['phone'] as String? ?? '+91 9876543210',
    );
    _companyController = TextEditingController(
      text: profile?['company_name'] as String? ?? 'IBUILD Construction',
    );
    _avatarUrlController = TextEditingController(
      text: profile?['avatar_url'] as String? ?? _defaultAvatar,
    );

    _avatarUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authControllerProvider.notifier)
          .updateUserProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            companyName: _companyController.text.trim(),
            avatarUrl: _avatarUrlController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Profile updated successfully'
                  : 'Failed to update profile',
            ),
            backgroundColor: success ? AppColors.secondary : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = ref.watch(currentRoleProvider);
    final authState = ref.watch(authControllerProvider);
    final userEmail = authState.user?.email ?? 'user@ibuild.in';

    String roleDisplay;
    switch (roleName) {
      case 'admin':
        roleDisplay = 'Administrator';
        break;
      case 'owner':
        roleDisplay = 'Business Owner';
        break;
      case 'supervisor':
        roleDisplay = 'Site Supervisor';
        break;
      default:
        roleDisplay = 'User';
    }

    final avatarUrl = _avatarUrlController.text.trim().isNotEmpty
        ? _avatarUrlController.text.trim()
        : _defaultAvatar;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Header & Avatar
                  CircleAvatar(
                    backgroundImage: NetworkImage(avatarUrl),
                    radius: 46,
                    backgroundColor: AppColors.primaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : 'User Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      roleDisplay.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.primaryColor(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Basic Profile Details Form
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'BASIC DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please enter full name'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter phone number',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company Name
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Firm Name',
                      hintText: 'Enter company name',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Picture URL
                  TextFormField(
                    controller: _avatarUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Profile Picture Image URL',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.image_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Notification Preferences & Role Scope
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NOTIFICATION PREFERENCES & SCOPE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: _notificationScope,
                    decoration: const InputDecoration(
                      labelText: 'ERP Notification Alert Scope',
                      prefixIcon: Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'All Site & Operational Updates (Recommended)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'financial',
                        child: Text(
                          'High-Priority & Financial Only (Bills, Payments)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'site',
                        child: Text(
                          'Site Execution Only (Drawings, Checklists)',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'muted',
                        child: Text('Muted / Silent'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _notificationScope = v!),
                  ),
                  const SizedBox(height: 14),

                  SwitchListTile(
                    value: _enablePushNotifications,
                    activeThumbColor: AppColors.secondary,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Mobile Push Banners & Unread Badges',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      'Receive live unread badges on mobile header bell icon',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => _enablePushNotifications = val),
                  ),
                  const SizedBox(height: 28),

                  // Save Profile Button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor(context),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Profile Changes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Account Session & Logout Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ACCOUNT SESSION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: () => showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text(
                      'Logout / Sign Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
