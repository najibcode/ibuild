import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Standard confirmation modal for Admin project deletion with permanent deletion warning.
Future<bool> showDeleteProjectConfirmationDialog(
  BuildContext context,
  String projectName,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
          SizedBox(width: 10),
          Text(
            'Delete Project',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to permanently delete "$projectName"?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action is irreversible. It permanently removes the project record, local offline caches, and all associated site telemetry.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'Delete Permanently',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
