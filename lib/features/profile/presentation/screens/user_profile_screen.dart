import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/offline/offline_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/navigation/mobile_nav_helper.dart';
import '../../../../core/services/image_compression_service.dart';
import '../../../../core/utils/avatar_helper.dart';
import '../../../../core/widgets/image_upload_card.dart';
import '../../../../core/widgets/logout_dialog.dart';
import '../../../../core/providers/notification_preferences_provider.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/rbac/presentation/providers/permission_provider.dart';
import '../../../../models/image_model.dart';
import '../../../../providers/image_provider.dart';

/// Curated construction role persona avatar presets.
class _AvatarPreset {
  final String label;
  final String subtitle;
  final String url;
  final IconData icon;

  const _AvatarPreset({
    required this.label,
    required this.subtitle,
    required this.url,
    required this.icon,
  });
}

const List<_AvatarPreset> _kAvatarPresets = [
  _AvatarPreset(
    label: 'Managing Director',
    subtitle: 'Executive Leadership',
    url: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&auto=format&fit=crop&q=80',
    icon: Icons.business_center,
  ),
  _AvatarPreset(
    label: 'Lead Architect',
    subtitle: 'Design & Planning',
    url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
    icon: Icons.architecture,
  ),
  _AvatarPreset(
    label: 'Site Engineer',
    subtitle: 'Civil & Execution',
    url: 'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?w=400&auto=format&fit=crop&q=80',
    icon: Icons.engineering,
  ),
  _AvatarPreset(
    label: 'Project Manager',
    subtitle: 'Operations & SCM',
    url: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&auto=format&fit=crop&q=80',
    icon: Icons.assignment_ind,
  ),
  _AvatarPreset(
    label: 'Safety Officer',
    subtitle: 'Quality & Compliance',
    url: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&auto=format&fit=crop&q=80',
    icon: Icons.health_and_safety,
  ),
  _AvatarPreset(
    label: 'Field Supervisor',
    subtitle: 'Workforce & Muster',
    url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=400&auto=format&fit=crop&q=80',
    icon: Icons.construction,
  ),
];

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
  bool _isManualSyncing = false;

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
      text: profile?['company_name'] as String? ??
          'IBUILD Construction & Infrastructure',
    );
    final initialAvatar = RoleAvatarHelper.getAvatarUrl(
      customAvatarUrl: profile?['avatar_url'] as String?,
      role: profile?['role'] as String?,
      email: user?.email,
    );
    _avatarUrlController = TextEditingController(text: initialAvatar);
    _siteHubController = TextEditingController(
      text: profile?['assigned_hub'] as String? ??
          'Central Headquarters & Regional Project Sites',
    );

    _avatarUrlController.addListener(() => setState(() {}));
  }

  Future<void> _checkDevicePermission() async {
    final status = await ref
        .read(pushNotificationServiceProvider)
        .getDevicePermissionStatus();
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

  /// Uploads picked photo bytes to ImageKit CDN and persists to the user profile
  Future<void> _uploadAvatarBytes(Uint8List bytes, String ext) async {
    setState(() => _isUploadingAvatar = true);
    final imageNotifier = ref.read(imageNotifierProvider.notifier);

    try {
      final uploadedUrl = await imageNotifier.uploadImage(
        bytes: bytes,
        fileExtension: ext,
        folder: ImageFolder.userProfile,
      );

      if (uploadedUrl != null) {
        _avatarUrlController.text = uploadedUrl;

        // Auto-save to Supabase profile
        await ref.read(authControllerProvider.notifier).updateUserProfile(
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              companyName: _companyController.text.trim(),
              avatarUrl: uploadedUrl,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo uploaded and saved successfully ✓'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    final picked = await ImageCompressionService.pickFromCamera();
    if (picked != null) {
      await _uploadAvatarBytes(picked.bytes, picked.extension);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImageCompressionService.pickFromGallery();
    if (picked != null) {
      await _uploadAvatarBytes(picked.bytes, picked.extension);
    }
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
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
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  success
                      ? 'Profile updated successfully ✓'
                      : 'Failed to update profile',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor:
                success ? const Color(0xFF10B981) : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handlePasswordReset(String email) async {
    setState(() => _isSendingResetEmail = true);
    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email);
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

  void _handleManualSync() async {
    setState(() => _isManualSyncing = true);
    try {
      await ref.read(offlineSyncProvider.notifier).syncAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline queue synchronized with cloud database ✓'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isManualSyncing = false);
    }
  }

  void _showAvatarPickerModal(String currentAvatarUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload or Choose Profile Photo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Upload a photo to ImageKit CDN or select a construction persona preset:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText(context),
                ),
              ),
              const SizedBox(height: 16),

              // Direct Camera & Gallery Upload Actions
              Row(
                children: [
                  if (ImageCompressionService.isCameraAvailable) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pickFromCamera();
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Take Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pickFromGallery();
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('From Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              Text(
                'OR CHOOSE A PERSONA PRESET',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: AppColors.mutedText(context),
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _kAvatarPresets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, idx) {
                  final p = _kAvatarPresets[idx];
                  final isSelected = currentAvatarUrl == p.url;

                  return InkWell(
                    onTap: () {
                      _avatarUrlController.text = p.url;
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor(context).withValues(alpha: 0.1)
                            : AppColors.bg(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor(context)
                              : AppColors.border(context),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(p.url),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor(context),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.text(context),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            p.subtitle,
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.mutedText(context),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleName = ref.watch(currentRoleProvider);
    final authState = ref.watch(authControllerProvider);
    final notifPrefs = ref.watch(notificationPreferencesProvider);
    final syncState = ref.watch(offlineSyncProvider);
    final userEmail = authState.user?.email ?? 'user@ibuild.in';
    final userId = authState.user?.id ??
        'usr-${userEmail.hashCode.abs().toString().padLeft(8, '0')}';
    final userCreatedAt = authState.user?.createdAt != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(authState.user!.createdAt))
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

    final avatarUrl = RoleAvatarHelper.getAvatarUrl(
      customAvatarUrl: _avatarUrlController.text.trim(),
      role: roleName,
      email: userEmail,
    );

    final hasBack = widget.onBackPressed != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: MobileNavHelper.buildLeading(
          context,
          hasBack: hasBack,
          onBackPressed: widget.onBackPressed,
        ),
        titleSpacing: (hasBack || MediaQuery.of(context).size.width < 800) ? 0 : 16,
        title: const Text(
          'Executive Profile & Settings',
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
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.badge_outlined, size: 18),
              text: 'Identity & Info',
            ),
            Tab(
              icon: Icon(Icons.notifications_active_outlined, size: 18),
              text: 'Alert Preferences',
            ),
            Tab(
              icon: Icon(Icons.security_outlined, size: 18),
              text: 'Security & Access',
            ),
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
                roleName,
                roleDisplay,
                roleColor,
                roleIcon,
                avatarUrl,
                userEmail,
                userId,
                userCreatedAt,
                authState.isLoading,
                syncState,
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
                syncState,
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
    String roleName,
    String roleDisplay,
    Color roleColor,
    IconData roleIcon,
    String avatarUrl,
    String userEmail,
    String userId,
    String userCreatedAt,
    bool isLoading,
    SyncState syncState,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Gradient Cover Header
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          roleColor.withValues(alpha: 0.90),
                          AppColors.primary.withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Member Since $userCreatedAt',
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
                              GestureDetector(
                                onTap: () => _showAvatarPickerModal(avatarUrl),
                                child: Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.cardBg(context),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _isUploadingAvatar
                                        ? const Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(strokeWidth: 2.5),
                                            ),
                                          )
                                        : Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              color:
                                                  roleColor.withValues(alpha: 0.2),
                                              child: Icon(
                                                roleIcon,
                                                size: 40,
                                                color: roleColor,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              // Edit / Upload Icon Button Badge
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => _showAvatarPickerModal(avatarUrl),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor(context),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text
                              : 'Executive Member',
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

                        // Action Chips: Upload Photo & Choose Persona
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 14,
                                  color: AppColors.secondary,
                                ),
                                label: const Text(
                                  'Upload Profile Picture',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _showAvatarPickerModal(avatarUrl),
                                backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.palette_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  'Select Persona',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onPressed: () => _showAvatarPickerModal(avatarUrl),
                                backgroundColor: AppColors.bg(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: AppColors.border(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── EXECUTIVE QUICK KPI TILES ──────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickKpi(
                            context,
                            icon: Icons.hub_outlined,
                            label: 'Site Hub',
                            value: 'Active',
                            color: AppColors.primary,
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: AppColors.border(context),
                          ),
                          _buildQuickKpi(
                            context,
                            icon: Icons.sync,
                            label: 'Sync Status',
                            value: syncState.pendingCount == 0
                                ? 'Cloud Synced'
                                : '${syncState.pendingCount} Pending',
                            color: syncState.pendingCount == 0
                                ? const Color(0xFF10B981)
                                : Colors.orange,
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: AppColors.border(context),
                          ),
                          _buildQuickKpi(
                            context,
                            icon: Icons.shield_outlined,
                            label: 'Security Tier',
                            value: 'Enterprise',
                            color: const Color(0xFF6366F1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── PROFILE PHOTO & IMAGEKIT INTEGRATION CARD ──────────────────────
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
                      const Icon(Icons.add_a_photo_outlined,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'PROFILE PICTURE & IMAGEKIT CDN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: AppColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ImageUploadCard(
                    existingUrl: avatarUrl,
                    label: 'Tap to upload new profile photo to ImageKit',
                    isUploading: _isUploadingAvatar,
                    onImagePicked: (bytes, ext) => _uploadAvatarBytes(bytes, ext),
                    onDeleteRequested: () {
                      _avatarUrlController.text =
                          RoleAvatarHelper.getDefaultAvatarForRole(roleName);
                    },
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
                      const Icon(Icons.edit_note,
                          size: 20, color: AppColors.primary),
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
                      labelText: 'Full Name *',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please enter full name'
                        : null,
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
                      labelText: 'Avatar Image URL (Cloud / CDN)',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link_outlined, size: 20),
                    ),
                    validator: (val) {
                      final url = val?.trim() ?? '';
                      if (url.isEmpty) return null;
                      if (url.startsWith('https://') ||
                          url.startsWith('http://') ||
                          url.startsWith('data:image/')) {
                        return null;
                      }
                      return 'Please enter a valid image URL (https://) or upload a photo';
                    },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickKpi(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.mutedText(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.text(context),
          ),
        ),
      ],
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
                color: isGranted
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isGranted
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
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
                          color: isGranted
                              ? const Color(0xFF047857)
                              : const Color(0xFFB45309),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                  onChanged: (val) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .toggleMasterPush(val);
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
                      child: Text(
                        'Financial & High Priority Only (Bills, Payments)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'site',
                      child: Text(
                        'Site Operations Only (Muster, Snags, Drawings)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'muted',
                      child: Text('Muted / Silent Mode'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(notificationPreferencesProvider.notifier)
                          .setScope(v);
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
                      ? (v) => ref
                          .read(notificationPreferencesProvider.notifier)
                          .toggleAttendance(v)
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
                      ? (v) => ref
                          .read(notificationPreferencesProvider.notifier)
                          .toggleInventory(v)
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
                      ? (v) => ref
                          .read(notificationPreferencesProvider.notifier)
                          .togglePayment(v)
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
                      ? (v) => ref
                          .read(notificationPreferencesProvider.notifier)
                          .toggleSnagQuality(v)
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
                    final granted = await ref
                        .read(pushNotificationServiceProvider)
                        .requestDevicePermission();
                    final status = await ref
                        .read(pushNotificationServiceProvider)
                        .getDevicePermissionStatus();
                    if (context.mounted) {
                      setState(() => _devicePermissionStatus = status);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(granted
                              ? 'Device push notifications enabled ✓'
                              : 'Permission prompt finished ($status)'),
                          backgroundColor: granted
                              ? const Color(0xFF10B981)
                              : AppColors.primary,
                        ),
                      );
                    }
                  },
                  icon:
                      const Icon(Icons.security_update_good_outlined, size: 16),
                  label: const Text(
                    'Enable Device Push',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(pushNotificationServiceProvider)
                        .sendTestNotification(
                          context: context,
                          testTitle: 'iBuild Push Alert Test',
                          testMessage:
                              'Cross-device notification preferences verified on this device ✓',
                        );
                  },
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text(
                    'Send Test Alert',
                    style: TextStyle(fontSize: 12),
                  ),
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
  // ── TAB 3: SECURITY, RBAC & SYSTEM TELEMETRY ─────────────────────────────
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
    SyncState syncState,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: permissions.isNotEmpty
                      ? permissions.map((p) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            avatar: const Icon(
                              Icons.check,
                              size: 12,
                              color: Color(0xFF10B981),
                            ),
                            label: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.bg(context),
                          );
                        }).toList()
                      : [
                          const Chip(
                            label: Text(
                              'Full System Access (Admin)',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── SYSTEM & OFFLINE CACHE TELEMETRY CARD ────────────────────────
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
                        const Icon(
                          Icons.cloud_sync_outlined,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SYSTEM & OFFLINE SYNC',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: syncState.pendingCount == 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        syncState.pendingCount == 0
                            ? 'ONLINE & SYNCED'
                            : '${syncState.pendingCount} QUEUED',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: syncState.pendingCount == 0
                              ? const Color(0xFF10B981)
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'iBuild ERP stores site entries, attendance logs, and snag reports in a local offline buffer if the field connection drops, and auto-syncs when online.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isManualSyncing ? null : _handleManualSync,
                  icon: _isManualSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: Text(
                    _isManualSyncing ? 'Synchronizing...' : 'Force Sync Offline Queue',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 42),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── SECURITY & CREDENTIALS ──────────────────────────────────────
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
                    const Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
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
                      Icon(
                        Icons.fingerprint,
                        size: 18,
                        color: AppColors.mutedText(context),
                      ),
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
                  onPressed: _isSendingResetEmail
                      ? null
                      : () => _handlePasswordReset(userEmail),
                  icon: _isSendingResetEmail
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mail_outline, size: 16),
                  label: Text(
                    _isSendingResetEmail
                        ? 'Sending Reset Email...'
                        : 'Send Password Reset Email',
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
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Logout / Sign Out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
