import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Displays a confirmation dialog and logs out the active user session.
Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg(ctx),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.logout, color: AppColors.error, size: 22),
          const SizedBox(width: 8),
          Text(
            'Confirm Logout',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(ctx)),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to log out of your session?',
        style: TextStyle(color: AppColors.mutedText(ctx), fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.logout, size: 16),
          label: const Text('Log Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
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
