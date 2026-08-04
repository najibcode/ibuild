import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable UI component providing Export PDF and Export Excel actions for table views & header toolbars.
class DataExportActions extends StatelessWidget {
  final Future<void> Function() onExportPdf;
  final Future<void> Function() onExportExcel;
  final bool compact;

  const DataExportActions({
    super.key,
    required this.onExportPdf,
    required this.onExportExcel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Export as PDF',
            onPressed: () async => _handleAction(context, onExportPdf, 'PDF'),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.deepOrange, size: 20),
          ),
          IconButton(
            tooltip: 'Export as Excel (.xlsx)',
            onPressed: () async => _handleAction(context, onExportExcel, 'Excel'),
            icon: const Icon(Icons.table_chart, color: Colors.green, size: 20),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () async => _handleAction(context, onExportPdf, 'PDF'),
          icon: const Icon(Icons.picture_as_pdf, size: 16),
          label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async => _handleAction(context, onExportExcel, 'Excel'),
          icon: const Icon(Icons.table_chart, size: 16),
          label: const Text('Export Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade800,
            side: BorderSide(color: Colors.green.shade600),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    Future<void> Function() action,
    String formatName,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$formatName file generated & downloaded successfully!'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export $formatName: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
