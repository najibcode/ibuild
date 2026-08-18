import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/mobile_nav_helper.dart';
import '../../../../core/widgets/image_upload_card.dart';
import '../../../../core/widgets/logout_dialog.dart';
import '../../../../core/providers/notification_preferences_provider.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/rbac/presentation/providers/permission_provider.dart';
import '../../../../models/image_model.dart';
import '../../../../providers/image_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const UserProfileScreen({
    super.key,
    this.onBackPressed,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _avatarUrlController;
  bool _isUploadingAvatar = false;
  String _devicePermissionStatus = 'default';

  static const String _defaultAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCZnkMp8GaOnpeTS6OaCmsGI3BT-AMfqKQlZgzWl_1P_wcfcpgsueuBT4g62apzZaMM9KDkryd5NwO0zRN2_qLL3tVRv-tkiZRKLnT4yZ4jh501MqajmHWV3-Tb0c-i328KeaLVPjpouYAeHclbEWmGX3AUSDoVNlY9uR_PjZhazvKln1VD_OY2Heh8KEFXssZ8Xdam3ObeFuJxVLLzfu2zy1jVcOM0hcAKPmqxBIh6d75KpFm9T7V-oUnUvLYk5UEqRnVhrWXTfOc';

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final profile = authState.profile;
    final user = authState.user;

    _checkDevicePermission();

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
      text: profile?['company_name'] as String? ?? 'IBUild Construction',
    );
    _avatarUrlController = TextEditingController(
      text: profile?['avatar_url'] as String? ?? _defaultAvatar,
    );

    _avatarUrlController.addListener(() => setState(() {}));
  }

  Future<void> _checkDevicePermission() async {
    final status = await ref.read(pushNotificationServiceProvider).getDevicePermissionStatus();
    if (mounted) {
      setState(() => _devicePermissionStatus = status);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _onAvatarPicked(Uint8List bytes, String ext) async {
    setState(() => _isUploadingAvatar = true);
    final imageNotifier = ref.read(imageNotifierProvider.notifier);

    final uploadedUrl = await imageNotifier.uploadImage(
      bytes: bytes,
      fileExtension: ext,
      folder: ImageFolder.settings,
    );

    if (uploadedUrl != null) {
      _avatarUrlController.text = uploadedUrl;
    }
    setState(() => _isUploadingAvatar = false);
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
                  ? 'Profile updated with ImageKit avatar ✓'
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
    final notifPrefs = ref.watch(notificationPreferencesProvider);
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

    final hasBack = widget.onBackPressed != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: hasBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back',
                onPressed: () {
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: MobileNavHelper.openDrawer,
              ),
        titleSpacing: 0,
        title: const Text('My Profile'),
      ),
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
                  // Profile Avatar Card with ImageKit picker
                  ImageUploadCard(
                    existingUrl: avatarUrl,
                    label: 'Tap to change avatar via ImageKit',
                    isUploading: _isUploadingAvatar,
                    onImagePicked: _onAvatarPicked,
                    onDeleteRequested: () {
                      _avatarUrlController.text = _defaultAvatar;
                    },
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
                      labelText: 'Profile Picture Image URL (ImageKit)',
                      hintText: 'https://ik.imagekit.io/...',
                      prefixIcon: Icon(Icons.image_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Notification Preferences & Role Scope
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CROSS-DEVICE PUSH & NOTIFICATION PREFERENCES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _devicePermissionStatus == 'granted'
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _devicePermissionStatus == 'granted' ? 'DEVICE READY ✓' : 'PERMISSION NEEDED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _devicePermissionStatus == 'granted' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Master Push Switch
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: SwitchListTile(
                      value: notifPrefs.masterPushEnabled,
                      activeThumbColor: AppColors.secondary,
                      title: Text(
                        'Master Push Notifications (All Devices)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      subtitle: Text(
                        'Receive real-time alerts across mobile apps, tablets & web browsers',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                      ),
                      onChanged: (val) {
                        ref.read(notificationPreferencesProvider.notifier).toggleMasterPush(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: notifPrefs.notificationScope,
                    decoration: const InputDecoration(
                      labelText: 'ERP Alert Priority Scope',
                      prefixIcon: Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Site & Operational Updates (Recommended)'),
                      ),
                      DropdownMenuItem(
                        value: 'financial',
                        child: Text('High-Priority & Financial Only (Bills, Payments)'),
                      ),
                      DropdownMenuItem(
                        value: 'site',
                        child: Text('Site Execution Only (Drawings, Checklists)'),
                      ),
                      DropdownMenuItem(
                        value: 'muted',
                        child: Text('Muted / Silent'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(notificationPreferencesProvider.notifier).setScope(v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Granular Alert Switches Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: notifPrefs.attendanceAlerts,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Daily Attendance & Muster Roll Alerts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Staff deployment, morning muster & overtime updates', style: TextStyle(fontSize: 10)),
                          onChanged: notifPrefs.masterPushEnabled
                              ? (v) => ref.read(notificationPreferencesProvider.notifier).toggleAttendance(v)
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: notifPrefs.inventoryAlerts,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Low Stock & Material Runway Alerts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Material reorder thresholds & site usage deductions', style: TextStyle(fontSize: 10)),
                          onChanged: notifPrefs.masterPushEnabled
                              ? (v) => ref.read(notificationPreferencesProvider.notifier).toggleInventory(v)
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: notifPrefs.paymentAlerts,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Client Payments & Inflow Ledger Alerts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Milestone payments, invoice clears & expense records', style: TextStyle(fontSize: 10)),
                          onChanged: notifPrefs.masterPushEnabled
                              ? (v) => ref.read(notificationPreferencesProvider.notifier).togglePayment(v)
                              : null,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: notifPrefs.snagQualityAlerts,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Snags, Drawings & Quality Inspections', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Punchlist status changes, blueprint revisions & checks', style: TextStyle(fontSize: 10)),
                          onChanged: notifPrefs.masterPushEnabled
                              ? (v) => ref.read(notificationPreferencesProvider.notifier).toggleSnagQuality(v)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Push Permission & Test Trigger Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final granted = await ref.read(pushNotificationServiceProvider).requestDevicePermission();
                            final status = await ref.read(pushNotificationServiceProvider).getDevicePermissionStatus();
                            setState(() => _devicePermissionStatus = status);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(granted ? 'Device push notifications enabled ✓' : 'Permission prompt finished ($status)'),
                                  backgroundColor: granted ? const Color(0xFF10B981) : AppColors.primary,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.security_update_good_outlined, size: 14),
                          label: const Text('Enable Device Push', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await ref.read(pushNotificationServiceProvider).sendTestNotification(
                                  context: context,
                                  testTitle: 'iBuild Push Notification Test',
                                  testMessage: 'Cross-device notification preferences verified on this device ✓',
                                );
                          },
                          icon: const Icon(Icons.send_outlined, size: 14),
                          label: const Text('Send Test Alert', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
