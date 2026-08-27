import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../widgets/cached_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/image_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../../../core/utils/date_range_filter_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../data/models/daily_progress_model.dart';
import '../controllers/daily_progress_controller.dart';
import '../../../projects/presentation/controllers/project_dashboard_controller.dart';
import '../../../projects/data/models/project_dashboard_model.dart';
import 'daily_progress_form_screen.dart';

class DailyProgressScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final bool showAppBar;

  const DailyProgressScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.showAppBar = true,
  });

  @override
  ConsumerState<DailyProgressScreen> createState() =>
      _DailyProgressScreenState();
}

class _DailyProgressScreenState extends ConsumerState<DailyProgressScreen> {
  String _searchQuery = '';

  void _shareDailySummary(BuildContext context, List<DailyProgress> entries) async {
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No site progress logs available to share.'),
        ),
      );
      return;
    }

    final latest = entries.first;
    final buffer = StringBuffer();
    buffer.writeln('*DAILY SITE PROGRESS REPORT*');
    buffer.writeln('*Project:* ${widget.projectName}');
    buffer.writeln('*Date:* ${latest.date}');
    buffer.writeln('*Overall Completion:* ${latest.progressPercentage}%');
    buffer.writeln('----------------------------------------');

    for (int i = 0; i < entries.length && i < 5; i++) {
      final entry = entries[i];
      buffer.writeln(
        '• *[${entry.date}]* (${entry.progressPercentage}% completion)',
      );
      final notes = entry.allNotes;
      if (notes.isNotEmpty) {
        for (final n in notes) {
          buffer.writeln('   "$n"');
        }
      }
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('_Generated via IBUILD Construction ERP_');

    await WhatsAppHelper.shareMessage(
      context: context,
      message: buffer.toString(),
      successNotice: 'Daily site progress report prepared',
    );
  }

  void _openForm(BuildContext context, DailyProgress? existing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyProgressFormScreen(
          projectId: widget.projectId,
          existing: existing,
        ),
      ),
    );
    ref.invalidate(dailyProgressListProvider(widget.projectId));
  }

  Widget _buildProgressPieChartCard(
    BuildContext context,
    ProjectDashboardStats? stats,
    List<DailyProgress> entries,
  ) {
    final double computedProgress = stats?.computedProgress ??
        (entries.isNotEmpty ? entries.first.progressPercentage.toDouble() : 0.0);
    final milestones = stats?.milestones ?? [];

    // Build Pie Chart Sections
    final List<PieChartSectionData> pieSections = [];

    if (milestones.isNotEmpty) {
      for (int i = 0; i < milestones.length; i++) {
        final m = milestones[i];
        final color = m.status == 'Completed'
            ? AppColors.secondary
            : (m.status == 'In Progress'
                ? AppColors.primaryColor(context)
                : AppColors.border(context));
        final weight = m.pct > 0 ? m.pct : 0.2;

        pieSections.add(
          PieChartSectionData(
            color: color,
            value: weight,
            title: '',
            radius: 18,
          ),
        );
      }
    } else {
      final double done = computedProgress.clamp(0.0, 100.0);
      final double remaining = (100.0 - done).clamp(0.0, 100.0);

      pieSections.add(
        PieChartSectionData(
          color: AppColors.secondary,
          value: done > 0 ? done : 0.1,
          title: '',
          radius: 18,
        ),
      );
      if (remaining > 0) {
        pieSections.add(
          PieChartSectionData(
            color: AppColors.border(context),
            value: remaining,
            title: '',
            radius: 18,
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Site Execution & Progress Breakdown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dynamic Milestone & Quality Progress',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    onPressed: () => _shareDailySummary(context, entries),
                    icon: const Icon(Icons.share_outlined, size: 20),
                    color: AppColors.primaryColor(context),
                    tooltip: 'Share Daily Progress Report',
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context, null),
                    icon: const Icon(Icons.add_a_photo, size: 16),
                    label: const Text('Log Evidence'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Donut / Pie Chart & Breakdown
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final chartWidget = SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2.5,
                        centerSpaceRadius: 44,
                        startDegreeOffset: -90,
                        sections: pieSections,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${computedProgress.toInt()}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text(context),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'COMPLETE',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final milestoneListWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (milestones.isNotEmpty) ...[
                    ...milestones.take(4).map((m) {
                      final isDone = m.status == 'Completed';
                      final isInProg = m.status == 'In Progress';
                      final color = isDone
                          ? AppColors.secondary
                          : (isInProg
                              ? AppColors.primaryColor(context)
                              : AppColors.mutedText(context));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m.status,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Executed Site Progress: ${computedProgress.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.border(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Remaining Handover Target: ${(100 - computedProgress).clamp(0, 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Center(child: chartWidget),
                    const SizedBox(height: 16),
                    milestoneListWidget,
                  ],
                );
              }

              return Row(
                children: [
                  chartWidget,
                  const SizedBox(width: 16),
                  Expanded(child: milestoneListWidget),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Daily Site Progress History: ${entries.length} Record${entries.length == 1 ? '' : 's'} Logged',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.mutedText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(
      dailyProgressListProvider(widget.projectId),
    );
    final dashboardAsync = ref.watch(
      projectDashboardProvider(widget.projectId),
    );

    final Widget bodyContent = progressAsync.when(
      data: (entries) {
        final filteredEntries = entries.where((e) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          final dateMatch = e.date.toLowerCase().contains(query);
          final notesMatch = e.allNotes.any(
            (n) => n.toLowerCase().contains(query),
          );
          return dateMatch || notesMatch;
        }).toList();

        final stats = dashboardAsync.valueOrNull;

        return Column(
          children: [
            // Interactive Pie / Donut Chart Progress Card
            _buildProgressPieChartCard(context, stats, entries),

            // Search Bar
            if (entries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search progress logs by date or description...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText(context),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.mutedText(context),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppColors.cardBg(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Daily Progress Feed
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_enhance_outlined,
                            size: 64,
                            color: AppColors.mutedText(
                              context,
                            ).withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            entries.isEmpty
                                ? 'No daily progress updates recorded yet.'
                                : 'No matching logs found.',
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entries.isEmpty
                                ? 'Upload site photos and daily work notes to track construction progress.'
                                : 'Try adjusting your search query.',
                            style: TextStyle(
                              color: AppColors.mutedText(context),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (entries.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _openForm(context, null),
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Log First Daily Progress'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) => _ProgressCard(
                        entry: filteredEntries[index],
                        onEdit: filteredEntries[index].isToday
                            ? () => _openForm(context, filteredEntries[index])
                            : null,
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading progress logs: $e')),
    );

    if (!widget.showAppBar) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text('Daily Progress: ${widget.projectName}'),
        actions: [
          DataExportActions(
            compact: true,
            onExportPdfWithDates: (start, end) async {
              final allEntries = ref.read(dailyProgressListProvider(widget.projectId)).value ?? [];
              final entries = DateRangeFilterHelper.filter(
                allEntries,
                start: start,
                end: end,
                getDate: (e) => e.date,
              );
              final pdfBytes = await GenericPdfTableGenerator.generatePdf(
                title: 'Site Daily Progress Report',
                subtitle: 'Site: ${widget.projectName}',
                headers: ['Date', 'Completion %', 'Logged By', 'Work Summary & Key Milestones', 'Images Count'],
                data: entries.map((e) => [
                  e.date,
                  '${e.progressPercentage}%',
                  e.supervisorId ?? 'Supervisor',
                  e.allNotes.join('; '),
                  '${e.allImageUrls.length} photos',
                ]).toList(),
              );
              await PdfDownloadHelper.downloadPdf(
                bytes: pdfBytes,
                filename: 'IBUILD_Daily_Progress_${widget.projectName.replaceAll(' ', '_')}.pdf',
              );
            },
            onExportExcelWithDates: (start, end) async {
              final allEntries = ref.read(dailyProgressListProvider(widget.projectId)).value ?? [];
              final entries = DateRangeFilterHelper.filter(
                allEntries,
                start: start,
                end: end,
                getDate: (e) => e.date,
              );
              final excelBytes = ExcelGeneratorService.generateTableExcel(
                sheetName: 'Daily_Progress',
                title: 'Daily Progress & Site Execution Feed',
                headers: ['Date', 'Project Site', 'Completion %', 'Recorded By', 'Work Notes', 'Photo Attachments Count'],
                rows: entries.map((e) => [
                  e.date,
                  widget.projectName,
                  e.progressPercentage,
                  e.supervisorId ?? 'Supervisor',
                  e.allNotes.join('; '),
                  e.allImageUrls.length,
                ]).toList(),
              );
              await ExcelDownloadHelper.downloadExcel(
                bytes: excelBytes,
                filename: 'IBUILD_Daily_Progress_${widget.projectName.replaceAll(' ', '_')}.xlsx',
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh Daily Progress Feed',
            onPressed: () =>
                ref.invalidate(dailyProgressListProvider(widget.projectId)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bodyContent,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final DailyProgress entry;
  final VoidCallback? onEdit;

  const _ProgressCard({required this.entry, this.onEdit});

  void _showImagePreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    tooltip: 'Download Image',
                    onPressed: () => _downloadImage(context, imageUrl, title),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, _) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, _, _) => Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.black54,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = onEdit == null;
    final images = entry.allImageUrls;
    final notesList = entry.allNotes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Progress Completion Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 18,
                    color: AppColors.primaryColor(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${entry.date}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.progressPercentage}% Completed',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (!isReadOnly) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Edit Today\'s Progress Record',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Photos & Evidence Section
          if (entry.morningImageUrl != null && entry.eveningImageUrl != null && entry.morningImageUrl != entry.eveningImageUrl)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _evidencePhotoCard(
                    context,
                    badgeLabel: 'BEFORE WORK (Morning)',
                    badgeColor: Colors.orange,
                    imageUrl: entry.morningImageUrl,
                    notes: entry.morningNotes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _evidencePhotoCard(
                    context,
                    badgeLabel: 'AFTER WORK (Evening)',
                    badgeColor: AppColors.secondary,
                    imageUrl: entry.eveningImageUrl,
                    notes: entry.eveningNotes,
                  ),
                ),
              ],
            )
          else if (entry.morningImageUrl != null || entry.eveningImageUrl != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.morningImageUrl != null)
                  Expanded(
                    child: _evidencePhotoCard(
                      context,
                      badgeLabel: 'BEFORE WORK (Morning)',
                      badgeColor: Colors.orange,
                      imageUrl: entry.morningImageUrl,
                      notes: entry.morningNotes,
                    ),
                  ),
                if (entry.morningImageUrl == null && entry.eveningImageUrl != null)
                  Expanded(
                    child: _evidencePhotoCard(
                      context,
                      badgeLabel: 'AFTER WORK (Evening)',
                      badgeColor: AppColors.secondary,
                      imageUrl: entry.eveningImageUrl,
                      notes: entry.eveningNotes,
                    ),
                  ),
              ],
            )
          else if (images.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SITE WORK PHOTO EVIDENCE',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, idx) {
                      final url = images[idx];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 200,
                        child: AppCachedImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                          enableZoom: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          // Notes Section
          if (notesList.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...notesList.map((text) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes,
                      size: 16,
                      color: AppColors.primaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text(context),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _evidencePhotoCard(
    BuildContext context, {
    required String badgeLabel,
    required Color badgeColor,
    required String? imageUrl,
    required String? notes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (imageUrl != null)
          InkWell(
            onTap: () => _showImagePreview(context, imageUrl, badgeLabel),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    enableZoom: true,
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: InkWell(
                      onTap: () => _downloadImage(context, imageUrl, badgeLabel),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            notes,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
        ],
      ],
    );
  }

  /// Downloads an image from the evidence photo card.
  void _downloadImage(BuildContext context, String imageUrl, String label) async {
    final sanitized = label.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'ibuild_${sanitized}_$timestamp';

    try {
      await ImageDownloadHelper.downloadImage(
        imageUrl: imageUrl,
        filename: filename,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image download started ✓'),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
