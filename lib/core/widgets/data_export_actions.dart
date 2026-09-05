import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// Date range preset options for exports.
enum DateRangeOption { last7Days, last30Days, allTime, custom }

/// Reusable UI component providing Export PDF and Export Excel actions
/// with a date-range selection menu (Last 7 Days, Last 30 Days, All Time, Custom).
class DataExportActions extends StatelessWidget {
  /// New-style callback: receives (startDate, endDate) for date-filtered exports.
  final Future<void> Function(DateTime startDate, DateTime endDate)? onExportPdfWithDates;
  final Future<void> Function(DateTime startDate, DateTime endDate)? onExportExcelWithDates;

  /// Legacy callback (no date params). If the new callback is not provided, falls back to this.
  final Future<void> Function()? onExportPdf;
  final Future<void> Function()? onExportExcel;

  final bool compact;

  const DataExportActions({
    super.key,
    this.onExportPdf,
    this.onExportExcel,
    this.onExportPdfWithDates,
    this.onExportExcelWithDates,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (compact) {
      if (isMobile) {
        return PopupMenuButton<String>(
          tooltip: 'Export Data',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryColor(context).withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.file_download_outlined,
              color: AppColors.primaryColor(context),
              size: 20,
            ),
          ),
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (format) => _showDateRangeMenu(context, format),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'PDF',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.deepOrange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Export PDF Report',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Official formatted document',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'Excel',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF107C41).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.table_chart,
                      color: Color(0xFF107C41),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Export Excel (.xlsx)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Raw spreadsheet for analysis',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Export as PDF',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () => _showDateRangeMenu(context, 'PDF'),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.deepOrange, size: 19),
          ),
          IconButton(
            tooltip: 'Export as Excel (.xlsx)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () => _showDateRangeMenu(context, 'Excel'),
            icon: const Icon(Icons.table_chart, color: Colors.green, size: 19),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showDateRangeMenu(context, 'PDF'),
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
          onPressed: () => _showDateRangeMenu(context, 'Excel'),
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

  /// Shows a dialog to pick the date range, then triggers the export.
  void _showDateRangeMenu(BuildContext context, String formatName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _DateRangePickerDialog(
          formatName: formatName,
          onSelected: (DateTime start, DateTime end) {
            Navigator.of(dialogContext).pop();
            _executeExport(context, formatName, start, end);
          },
        );
      },
    );
  }

  Future<void> _executeExport(
    BuildContext context,
    String formatName,
    DateTime start,
    DateTime end,
  ) async {
    try {
      if (formatName == 'PDF') {
        if (onExportPdfWithDates != null) {
          await onExportPdfWithDates!(start, end);
        } else if (onExportPdf != null) {
          await onExportPdf!();
        }
      } else {
        if (onExportExcelWithDates != null) {
          await onExportExcelWithDates!(start, end);
        } else if (onExportExcel != null) {
          await onExportExcel!();
        }
      }
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

/// Internal dialog widget for date range selection.
class _DateRangePickerDialog extends StatefulWidget {
  final String formatName;
  final void Function(DateTime start, DateTime end) onSelected;

  const _DateRangePickerDialog({
    required this.formatName,
    required this.onSelected,
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateRangeOption _selected = DateRangeOption.last7Days;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy');
    final screenWidth = MediaQuery.of(context).size.width;
    final maxDialogWidth = (screenWidth - 32).clamp(280.0, 380.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxDialogWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.formatName == 'PDF'
                        ? Icons.picture_as_pdf
                        : Icons.table_chart,
                    color: widget.formatName == 'PDF'
                        ? Colors.deepOrange
                        : Colors.green.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export ${widget.formatName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select date range for report',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Options
              _buildOptionTile(
                icon: Icons.calendar_today,
                label: 'Last 7 Days',
                subtitle: '${dateFormat.format(now.subtract(const Duration(days: 7)))} – ${dateFormat.format(now)}',
                option: DateRangeOption.last7Days,
              ),
              const SizedBox(height: 8),
              _buildOptionTile(
                icon: Icons.date_range,
                label: 'Last 30 Days',
                subtitle: '${dateFormat.format(now.subtract(const Duration(days: 30)))} – ${dateFormat.format(now)}',
                option: DateRangeOption.last30Days,
              ),
              const SizedBox(height: 8),
              _buildOptionTile(
                icon: Icons.all_inclusive,
                label: 'All Time',
                subtitle: 'Export all available data',
                option: DateRangeOption.allTime,
              ),
              const SizedBox(height: 8),
              _buildOptionTile(
                icon: Icons.edit_calendar,
                label: 'Custom Range',
                subtitle: _customRange != null
                    ? '${dateFormat.format(_customRange!.start)} – ${dateFormat.format(_customRange!.end)}'
                    : 'Pick start and end dates',
                option: DateRangeOption.custom,
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: now,
                    initialDateRange: _customRange ??
                        DateTimeRange(
                          start: now.subtract(const Duration(days: 30)),
                          end: now,
                        ),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _customRange = picked;
                      _selected = DateRangeOption.custom;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final range = _getDateRange();
                    widget.onSelected(range.start, range.end);
                  },
                  icon: Icon(
                    widget.formatName == 'PDF'
                        ? Icons.download
                        : Icons.file_download,
                    size: 18,
                  ),
                  label: Text(
                    'Download ${widget.formatName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.formatName == 'PDF'
                        ? Colors.deepOrange
                        : Colors.green.shade700,
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
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required DateRangeOption option,
    VoidCallback? onTap,
  }) {
    final isSelected = _selected == option;

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() => _selected = option);
          if (onTap != null) onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selected) {
      case DateRangeOption.last7Days:
        return DateTimeRange(
          start: endOfDay.subtract(const Duration(days: 7)),
          end: endOfDay,
        );
      case DateRangeOption.last30Days:
        return DateTimeRange(
          start: endOfDay.subtract(const Duration(days: 30)),
          end: endOfDay,
        );
      case DateRangeOption.allTime:
        return DateTimeRange(
          start: DateTime(2020, 1, 1),
          end: endOfDay,
        );
      case DateRangeOption.custom:
        return _customRange ??
            DateTimeRange(
              start: endOfDay.subtract(const Duration(days: 30)),
              end: endOfDay,
            );
    }
  }
}
