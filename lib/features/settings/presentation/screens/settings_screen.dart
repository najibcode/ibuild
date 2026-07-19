import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.containerMargin,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Profile Section
            const Text(
              'COMPANY PROFILE',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.business, color: AppColors.outline),
                    title: Text('Company Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('BuildSense Enterprise Ltd.'),
                  ),
                  Divider(height: 1, color: AppColors.borderSubtle, indent: 52),
                  ListTile(
                    leading: Icon(Icons.receipt_long_outlined, color: AppColors.outline),
                    title: Text('GSTIN Number', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('27AAPCS1234F1Z5'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences
            const Text(
              'PREFERENCES',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, color: AppColors.outline),
                    title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('System default (Light Mode)'),
                    trailing: Switch(
                      value: false,
                      onChanged: (val) {},
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle, indent: 52),
                  const ListTile(
                    leading: Icon(Icons.backup_outlined, color: AppColors.outline),
                    title: Text('Backup Database', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Last backed up: Today, 04:00 AM'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account & Support
            const Text(
              'ABOUT',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: AppColors.outline),
                    title: Text('App Version', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('v1.0.0 (Phase 1 Build)'),
                  ),
                  Divider(height: 1, color: AppColors.borderSubtle, indent: 52),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: AppColors.outline),
                    title: Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('support@ibuild.com'),
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
                backgroundColor: AppColors.error.withOpacity(0.08),
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
