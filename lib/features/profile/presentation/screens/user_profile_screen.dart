import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _siteHubController;

  bool _isUploadingAvatar = false;
  String _devicePermissionStatus = 'default';
  bool _isSendingResetEmail = false;

  static const String _defaultAvatar =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCZnkMp8GaOnpeTS6OaCmsGI3BT-AMfqKQlZgzWl_1P_wcfcpgsueuBT4g62apzZaMM9KDkryd5NwO0zRN2_qLL3tVRv-tkiZRKLnT4yZ4jh501MqajmHWV3-Tb0c-i328KeaLVPjpouYAeHclbEWmGX3AUSDoVNlY9uR_PjZhazvKln1VD_OY2Heh8KEFXssZ8Xdam3ObeFuJxVLLzfu2zy1jVcOM0hcAKPmqxBIh6d75KpFm9T7V-oUnUvLYk5UEqRnVhrWXTfOc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final authState = ref.read(authControllerProvider);
    final profile = authState.profile;
    final user = authState.user;

    _checkDevicePermission();

    final defaultName = profile?['full_name'] as String? ??
        (user?.email != null && user!.email!.contains('@')
            ? user.email!.split('@').first
            : 'Business Owner');

    _nameController = TextEditingController(text: defaultName);
    _phoneController = TextEditingController(
      text: profile?['phone'] as String? ?? '+91 9876543210',
    );
    _companyController = TextEditingController(
      text: profile?['company_name'] as String? ?? 'IBUILD Construction & Infrastructure',
    );
    _avatarUrlController = TextEditingController(
      text: profile?['avatar_url'] as String? ?? _defaultAvatar,
    );
    _siteHubController = TextEditingController(
      text: profile?['assigned_hub'] as String? ?? 'Central Headquarters & Project Sites',
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
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _avatarUrlController.dispose();
    _siteHubController.dispose();
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
      final success = await ref.read(authControllerProvider.notifier).updateUserProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            companyName: _companyController.text.trim(),
            avatarUrl: _avatarUrlController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  success ? 'Profile updated successfully ✓' : 'Failed to update profile',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: success ? const Color(0xFF10B981) : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handlePasswordReset(String email) async {
    setState(() => _isSendingResetEmail = true);
    final success = await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    setState(() => _isSendingResetEmail = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Password reset email sent to $email ✓'
                : 'Failed to send password reset email',
          ),
          backgroundColor: success ? const Color(0xFF10B981) : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = ref.watch(currentRoleProvider);
    final authState = ref.watch(authControllerProvider);
    final notifPrefs = ref.watch(notificationPreferencesProvider);
    final userEmail = authState.user?.email ?? 'user@ibuild.in';
    final userId = authState.user?.id ?? 'usr-${userEmail.hashCode.abs().toString().padLeft(8, '0')}';
    final userCreatedAt = authState.user?.createdAt != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(authState.user!.createdAt))
        : 'Active Member';

    String roleDisplay;
    Color roleColor;
    IconData roleIcon;
    switch (roleName) {
      case 'admin':
        roleDisplay = 'Super Administrator';
        roleColor = const Color(0xFF6366F1); // Indigo
        roleIcon = Icons.admin_panel_settings_outlined;
        break;
      case 'owner':
        roleDisplay = 'Business Owner';
        roleColor = const Color(0xFFF59E0B); // Amber / Gold
        roleIcon = Icons.stars_outlined;
        break;
      case 'supervisor':
        roleDisplay = 'Site Supervisor';
        roleColor = const Color(0xFF10B981); // Emerald Green
        roleIcon = Icons.engineering_outlined;
        break;
      default:
        roleDisplay = 'Authorized User';
        roleColor = AppColors.primary;
        roleIcon = Icons.person_outline;
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
        title: const Text(
          'My Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () => showLogoutDialog(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor(context),
          unselectedLabelColor: AppColors.mutedText(context),
          indicatorColor: AppColors.primaryColor(context),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Identity & Info'),
            Tab(icon: Icon(Icons.notifications_active_outlined, size: 18), text: 'Alert Preferences'),
            Tab(icon: Icon(Icons.security_outlined, size: 18), text: 'Security & Access'),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          child: TabBarView(
            controller: _tabController,
            children: [
              // ── TAB 1: IDENTITY & INFO ──────────────────────────────────────────
              _buildIdentityTab(
                context,
                roleDisplay,
                roleColor,
                roleIcon,
                avatarUrl,
                userEmail,
                userId,
                userCreatedAt,
                authState.isLoading,
              ),

              // ── TAB 2: ALERT PREFERENCES ─────────────────────────────────────────
              _buildAlertPreferencesTab(
                context,
                notifPrefs,
              ),

              // ── TAB 3: SECURITY & ACCESS ─────────────────────────────────────────
              _buildSecurityAndAccessTab(
                context,
                roleName,
                roleDisplay,
                roleColor,
                roleIcon,
                userEmail,
                userId,
                userCreatedAt,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── TAB 1: IDENTITY & CONTACT INFO ────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildIdentityTab(
    BuildContext context,
    String roleDisplay,
    Color roleColor,
    IconData roleIcon,
    String avatarUrl,
    String userEmail,
    String userId,
    String userCreatedAt,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── EXECUTIVE HERO BANNER & AVATAR ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                children: [
                  // Gradient Cover Header
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                      gradient: LinearGradient(
                        colors: [
                          roleColor.withValues(alpha: 0.85),
                          AppColors.primary.withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(roleIcon, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                roleDisplay.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Joined: $userCreatedAt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar & Monogram Section
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.cardBg(context),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: roleColor.withValues(alpha: 0.2),
                                      child: Icon(roleIcon, size: 40, color: roleColor),
                                    ),
                                  ),
                                ),
                              ),
                              // Online Status Dot
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : 'User Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ImageKit Avatar Upload Trigger
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ImageUploadCard(
                            existingUrl: avatarUrl,
                            label: 'Tap to update profile avatar via ImageKit',
                            isUploading: _isUploadingAvatar,
                            onImagePicked: _onAvatarPicked,
                            onDeleteRequested: () {
                              _avatarUrlController.text = _defaultAvatar;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── PROFILE DETAILS FORM ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'PERSONAL & ENTERPRISE DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter full name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone / WhatsApp',
                      hintText: 'Enter phone number (+91...)',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Company / Firm Name
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Business Entity',
                      hintText: 'Enter organization name',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Primary Regional Hub
                  TextFormField(
                    controller: _siteHubController,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Site Location / Regional Base',
                      hintText: 'e.g. Central Project Hub, South Zone',
                      prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Profile Picture Image URL
                  TextFormField(
                    controller: _avatarUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Avatar Image URL (ImageKit / CDN)',
                      hintText: 'https://ik.imagekit.io/...',
                      prefixIcon: Icon(Icons.link_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Profile Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor(context),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Profile Changes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── TAB 2: ALERT PREFERENCES & PUSH NOTIFICATIONS ─────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAlertPreferencesTab(
    BuildContext context,
    NotificationPreferences notifPrefs,
  ) {
    final isGranted = _devicePermissionStatus == 'granted';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── DEVICE STATUS BANNER ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGranted
                            ? 'Native Push Alerts Active ✓'
                            : 'Push Permission Needed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isGranted ? const Color(0xFF047857) : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGranted
                            ? 'This device is receiving real-time site updates, stock alerts & payment logs.'
                            : 'Click "Enable Device Push" below to allow browser and OS notification popups.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.text(context).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── MASTER PUSH SWITCH ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: notifPrefs.masterPushEnabled,
                  activeThumbColor: AppColors.secondary,
                  title: Text(
                    'Master Push Notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  subtitle: Text(
                    'Master switch for all mobile push notifications & in-app alerts',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                  ),
                  onChanged: (val) {
                    ref.read(notificationPreferencesProvider.notifier).toggleMasterPush(val);
                  },
                ),
                const SizedBox(height: 12),

                // Priority Scope Selector
                DropdownButtonFormField<String>(
                  initialValue: notifPrefs.notificationScope,
                  decoration: const InputDecoration(
                    labelText: 'Operational Alert Scope',
                    prefixIcon: Icon(Icons.tune_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Operational Updates (Recommended)'),
                    ),
                    DropdownMenuItem(
                      value: 'financial',
                      child: Text('Financial & High Priority Only (Bills, Payments)'),
                    ),
                    DropdownMenuItem(
                      value: 'site',
                      child: Text('Site Operations Only (Muster, Snags, Drawings)'),
                    ),
                    DropdownMenuItem(
                      value: 'muted',
                      child: Text('Muted / Silent Mode'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(notificationPreferencesProvider.notifier).setScope(v);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── GRANULAR OPERATIONAL CATEGORIES ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GRANULAR CATEGORY ALERTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  value: notifPrefs.attendanceAlerts,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '👷 Attendance & Morning Muster Roll',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Worker check-ins, overtime alerts & morning workforce count',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: notifPrefs.masterPushEnabled
                      ? (v) => ref.read(notificationPreferencesProvider.notifier).toggleAttendance(v)
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: notifPrefs.inventoryAlerts,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '🧱 Low Stock & Material Runway Thresholds',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Cement, steel & brick minimum reorder alerts',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: notifPrefs.masterPushEnabled
                      ? (v) => ref.read(notificationPreferencesProvider.notifier).toggleInventory(v)
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: notifPrefs.paymentAlerts,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '💳 Client Payments, Invoices & Outflows',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Milestone collections, vendor bills & expense postings',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: notifPrefs.masterPushEnabled
                      ? (v) => ref.read(notificationPreferencesProvider.notifier).togglePayment(v)
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: notifPrefs.snagQualityAlerts,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '🔍 Quality Snags, Punchlist & Drawings',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Punchlist defect status updates & blueprint revisions',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: notifPrefs.masterPushEnabled
                      ? (v) => ref.read(notificationPreferencesProvider.notifier).toggleSnagQuality(v)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── ACTION BUTTONS: ENABLE & TEST ALERT ───────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final granted =
                        await ref.read(pushNotificationServiceProvider).requestDevicePermission();
                    final status =
                        await ref.read(pushNotificationServiceProvider).getDevicePermissionStatus();
                    if (context.mounted) {
                      setState(() => _devicePermissionStatus = status);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(granted
                              ? 'Device push notifications enabled ✓'
                              : 'Permission prompt finished ($status)'),
                          backgroundColor:
                              granted ? const Color(0xFF10B981) : AppColors.primary,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.security_update_good_outlined, size: 16),
                  label: const Text('Enable Device Push', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(pushNotificationServiceProvider).sendTestNotification(
                          context: context,
                          testTitle: 'iBuild Push Alert Test',
                          testMessage:
                              'Cross-device notification preferences verified on this device ✓',
                        );
                  },
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Send Test Alert', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── TAB 3: SECURITY, RBAC & SESSION ──────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSecurityAndAccessTab(
    BuildContext context,
    String roleName,
    String roleDisplay,
    Color roleColor,
    IconData roleIcon,
    String userEmail,
    String userId,
    String userCreatedAt,
  ) {
    final permissionsAsync = ref.watch(userPermissionsProvider);
    final permissions = permissionsAsync.valueOrNull ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── ROLE & PERMISSION MATRIX CARD ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(roleIcon, color: roleColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'ROLE-BASED ACCESS CONTROL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleDisplay.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Assigned Permissions for your account:',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: permissions.isNotEmpty
                      ? permissions.map((p) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            avatar: const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
                            label: Text(
                              p,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: AppColors.bg(context),
                          );
                        }).toList()
                      : [
                          const Chip(
                            label: Text('Full System Access (Admin)', style: TextStyle(fontSize: 10)),
                          ),
                        ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── SECURITY & SESSION METADATA ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'CREDENTIALS & SECURITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // User UUID with Copy button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bg(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint, size: 18, color: AppColors.mutedText(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'USER ID (UUID)',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                            Text(
                              userId,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy UUID',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: userId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User ID copied to clipboard ✓'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Password Reset Button
                OutlinedButton.icon(
                  onPressed: _isSendingResetEmail ? null : () => _handlePasswordReset(userEmail),
                  icon: _isSendingResetEmail
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mail_outline, size: 16),
                  label: Text(
                    _isSendingResetEmail ? 'Sending Reset Email...' : 'Send Password Reset Email',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── DANGER ZONE & LOGOUT ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCOUNT SESSION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign out of your active ERP session on this device.',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Logout / Sign Out',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
