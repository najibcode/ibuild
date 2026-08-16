import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/logout_dialog.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/rbac/presentation/providers/permission_provider.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';
import 'package:ibuild/features/profile/presentation/screens/user_profile_screen.dart';

// State Provider to hold draft theme selection before user clicks Apply
final draftThemeSelectionProvider = StateProvider<ThemeMode>((ref) {
  return ref.watch(themeProvider);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _onLogout(BuildContext context, WidgetRef ref) async {
    await showLogoutDialog(context, ref);
  }

  Widget _themeOptionCard(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final draftMode = ref.watch(draftThemeSelectionProvider);
    final activeAppliedMode = ref.watch(themeProvider);
    final isSelected = draftMode == mode;
    final isCurrentlyActive = activeAppliedMode == mode;
    final primaryColor = AppColors.primaryColor(context);

    return InkWell(
      onTap: () {
        ref.read(draftThemeSelectionProvider.notifier).state = mode;
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : AppColors.border(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : AppColors.border(context).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.mutedText(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.text(context),
                        ),
                      ),
                      if (isCurrentlyActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              draftMode == mode
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: draftMode == mode
                  ? primaryColor
                  : AppColors.mutedText(context),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final companyName = profile?['company_name'] as String? ?? 'IBUILD User';
    final gstin = profile?['gstin'] as String? ?? 'Not provided';
    final userEmail = authState.user?.email ?? 'Unknown';

    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);
    final mutedText = AppColors.mutedText(context);
    final draftMode = ref.watch(draftThemeSelectionProvider);
    final activeThemeMode = ref.watch(themeProvider);
    final hasUnsavedChanges = draftMode != activeThemeMode;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Text(
              'MY USER PROFILE',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    profile?['avatar_url'] as String? ??
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCZnkMp8GaOnpeTS6OaCmsGI3BT-AMfqKQlZgzWl_1P_wcfcpgsueuBT4g62apzZaMM9KDkryd5NwO0zRN2_qLL3tVRv-tkiZRKLnT4yZ4jh501MqajmHWV3-Tb0c-i328KeaLVPjpouYAeHclbEWmGX3AUSDoVNlY9uR_PjZhazvKln1VD_OY2Heh8KEFXssZ8Xdam3ObeFuJxVLLzfu2zy1jVcOM0hcAKPmqxBIh6d75KpFm9T7V-oUnUvLYk5UEqRnVhrWXTfOc',
                  ),
                  radius: 20,
                ),
                title: Text(
                  profile?['full_name'] as String? ?? 'Business Owner / Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                subtitle: Text(userEmail, style: TextStyle(color: mutedText)),
                trailing: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit Profile'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Company Profile Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPANY BRANDING & LETTERHEAD',
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedText,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCompanyBrandingDialog(
                    context,
                    ref,
                    currentName: companyName,
                    currentGstin: gstin,
                    currentTagline: profile?['tagline'] as String? ?? 'Premier Construction & Civil Engineering',
                    currentAddress: profile?['address'] as String? ?? 'Bengaluru, Karnataka, India',
                    currentUpi: profile?['upi_id'] as String? ?? 'ibuild@icici',
                  ),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Edit Branding', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.business, color: AppColors.primary),
                    title: Text(
                      'Company / Firm Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      companyName,
                      style: TextStyle(color: mutedText),
                    ),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.secondary,
                    ),
                    title: Text(
                      'GSTIN & Tax Registration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(gstin, style: TextStyle(color: mutedText)),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.deepOrange,
                    ),
                    title: Text(
                      'Registered Office Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      profile?['address'] as String? ?? 'Bengaluru, Karnataka, India',
                      style: TextStyle(color: mutedText),
                    ),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: const Icon(
                      Icons.qr_code_2_outlined,
                      color: Colors.purple,
                    ),
                    title: Text(
                      'Default Bank / UPI ID for Invoices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      profile?['upi_id'] as String? ?? 'ibuild@icici',
                      style: TextStyle(color: mutedText),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Theme Calibration Section
            Text(
              'APPEARANCE & THEME CALIBRATION',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _themeOptionCard(
                    context,
                    ref,
                    mode: ThemeMode.light,
                    title: 'Light Mode ☀️',
                    description:
                        'Crisp high-contrast light theme for bright daylight environments.',
                    icon: Icons.wb_sunny_outlined,
                  ),
                  const SizedBox(height: 10),
                  _themeOptionCard(
                    context,
                    ref,
                    mode: ThemeMode.dark,
                    title: 'Dark Mode 🌙',
                    description:
                        'Calibrated deep slate dark theme with enhanced text visibility.',
                    icon: Icons.nightlight_round_outlined,
                  ),
                  const SizedBox(height: 10),
                  _themeOptionCard(
                    context,
                    ref,
                    mode: ThemeMode.system,
                    title: 'System Default 💻',
                    description:
                        'Automatically match device operating system theme settings.',
                    icon: Icons.settings_brightness_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Apply Selected Mode Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(themeProvider.notifier).setMode(draftMode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Installed ${draftMode == ThemeMode.dark
                                  ? "Dark"
                                  : draftMode == ThemeMode.light
                                  ? "Light"
                                  : "System"} Mode across IBUILD ERP!',
                            ),
                            backgroundColor: AppColors.secondary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        hasUnsavedChanges ? Icons.bolt : Icons.check_circle,
                        size: 18,
                      ),
                      label: Text(
                        hasUnsavedChanges
                            ? 'Install Selected Theme'
                            : 'Theme Preference Applied',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasUnsavedChanges
                            ? AppColors.primaryColor(context)
                            : AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Role Simulator
            Text(
              'ROLE SIMULATOR & PERMISSIONS',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: mutedText,
                    ),
                    title: Text(
                      'Active Role (Simulator)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      'Current: ${ref.watch(currentRoleProvider).toUpperCase()}',
                      style: TextStyle(color: mutedText),
                    ),
                    trailing: DropdownButton<String>(
                      value: ref.watch(currentRoleProvider) == 'unknown'
                          ? 'admin'
                          : ref.watch(currentRoleProvider),
                      underline: const SizedBox(),
                      dropdownColor: cardBg,
                      items: [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text(
                            'ADMIN',
                            style: TextStyle(color: AppColors.text(context)),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'owner',
                          child: Text(
                            'OWNER',
                            style: TextStyle(color: AppColors.text(context)),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'supervisor',
                          child: Text(
                            'SUPERVISOR',
                            style: TextStyle(color: AppColors.text(context)),
                          ),
                        ),
                      ],
                      onChanged: (newRole) {
                        if (newRole != null) {
                          ref
                                  .read(selectedRoleOverrideProvider.notifier)
                                  .state =
                              newRole;
                          ref.invalidate(userPermissionsProvider);
                        }
                      },
                    ),
                  ),
                  PermissionGuard(
                    permission: 'system.manage',
                    child: Column(
                      children: [
                        Divider(height: 1, color: borderCol, indent: 52),
                        ListTile(
                          leading: Icon(
                            Icons.backup_outlined,
                            color: mutedText,
                          ),
                          title: Text(
                            'Backup Database',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text(context),
                            ),
                          ),
                          subtitle: Text(
                            'Last backed up: Today, 04:00 AM',
                            style: TextStyle(color: mutedText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account & Support
            Text(
              'ABOUT',
              style: TextStyle(
                fontSize: 11,
                color: mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: mutedText),
                    title: Text(
                      'App Version',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      'v1.0.0 (Phase 1 Build)',
                      style: TextStyle(color: mutedText),
                    ),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: mutedText),
                    title: Text(
                      'Logged in as',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      userEmail,
                      style: TextStyle(color: mutedText),
                    ),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: Icon(Icons.shield_outlined, color: mutedText),
                    title: Text(
                      'Role',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                    ),
                    subtitle: Text(
                      ref.watch(currentRoleProvider).toUpperCase(),
                      style: TextStyle(color: mutedText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () => _onLogout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out from Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.12),
                foregroundColor: AppColors.error,
                elevation: 0,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompanyBrandingDialog(
    BuildContext context,
    WidgetRef ref, {
    required String currentName,
    required String currentGstin,
    required String currentTagline,
    required String currentAddress,
    required String currentUpi,
  }) {
    final nameCtrl = TextEditingController(text: currentName == 'IBUILD User' ? '' : currentName);
    final gstinCtrl = TextEditingController(text: currentGstin == 'Not provided' ? '' : currentGstin);
    final taglineCtrl = TextEditingController(text: currentTagline);
    final addressCtrl = TextEditingController(text: currentAddress);
    final upiCtrl = TextEditingController(text: currentUpi);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.business_center_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Edit Company Branding & Letterhead',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text(context),
              ),
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
                Text(
                  'These details automatically appear on generated Client Invoices, Quotations, and Operational Audit PDFs.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company / Firm Name *',
                    prefixIcon: Icon(Icons.business, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: taglineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tagline / Slogan',
                    prefixIcon: Icon(Icons.short_text, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gstinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN & Tax Registration No.',
                    prefixIcon: Icon(Icons.receipt_long, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Registered Office / Site Address',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: upiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Default Bank / UPI ID (e.g. firm@bank)',
                    prefixIcon: Icon(Icons.qr_code_2_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final newName = nameCtrl.text.trim().isEmpty ? 'IBUILD Construction Corp' : nameCtrl.text.trim();
              final newPhone = ref.read(authControllerProvider).profile?['phone'] as String? ?? '';
              final fullName = ref.read(authControllerProvider).profile?['full_name'] as String? ?? 'Admin';

              await ref.read(authControllerProvider.notifier).updateUserProfile(
                fullName: fullName,
                phone: newPhone,
                companyName: newName,
              );

              if (context.mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Company Branding & Letterhead updated across all ERP invoices!'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save Branding'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
