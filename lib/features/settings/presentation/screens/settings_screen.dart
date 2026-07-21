import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/rbac/presentation/providers/permission_provider.dart';
import '../../../../features/rbac/presentation/widgets/permission_guard.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _onLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of IBUILD?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
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
            // Company Profile Section
            Text(
              'COMPANY PROFILE',
              style: TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                    leading: Icon(Icons.business, color: mutedText),
                    title: const Text('Company Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(companyName),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: Icon(Icons.receipt_long_outlined, color: mutedText),
                    title: const Text('GSTIN Number', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(gstin),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences
            Text(
              'PREFERENCES',
              style: TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                    leading: Icon(Icons.palette_outlined, color: mutedText),
                    title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(ref.watch(themeProvider) == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
                    trailing: Switch(
                      value: ref.watch(themeProvider) == ThemeMode.dark,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings_outlined, color: mutedText),
                    title: const Text('Active Role (Simulator)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Current: ${ref.watch(currentRoleProvider).toUpperCase()}'),
                    trailing: DropdownButton<String>(
                      value: ref.watch(currentRoleProvider) == 'unknown' ? 'admin' : ref.watch(currentRoleProvider),
                      underline: const SizedBox(),
                      dropdownColor: cardBg,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('ADMIN')),
                        DropdownMenuItem(value: 'owner', child: Text('OWNER')),
                        DropdownMenuItem(value: 'supervisor', child: Text('SUPERVISOR')),
                      ],
                      onChanged: (newRole) {
                        if (newRole != null) {
                          ref.read(selectedRoleOverrideProvider.notifier).state = newRole;
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
                          leading: Icon(Icons.backup_outlined, color: mutedText),
                          title: const Text('Backup Database', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Last backed up: Today, 04:00 AM'),
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
              style: TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                    title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('v1.0.0 (Phase 1 Build)'),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: mutedText),
                    title: const Text('Logged in as', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(userEmail),
                  ),
                  Divider(height: 1, color: borderCol, indent: 52),
                  ListTile(
                    leading: Icon(Icons.shield_outlined, color: mutedText),
                    title: const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(ref.watch(currentRoleProvider).toUpperCase()),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
