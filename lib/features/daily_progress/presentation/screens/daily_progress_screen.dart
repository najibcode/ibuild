import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_export_actions.dart';
import '../../../../core/services/excel_generator_service.dart';
import '../../../../core/services/generic_pdf_table_generator.dart';
import '../../../../core/utils/excel_download_helper.dart';
import '../../../../core/utils/pdf_download_helper.dart';
import '../../data/models/daily_progress_model.dart';
import '../controllers/daily_progress_controller.dart';
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

  void _shareDailySummary(BuildContext context, List<DailyProgress> entries) {
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
    buffer.writeln('🏗️ *DAILY SITE PROGRESS REPORT*');
    buffer.writeln('📍 *Project:* ${widget.projectName}');
    buffer.writeln('📅 *Date:* ${latest.date}');
    buffer.writeln('📊 *Overall Completion:* ${latest.progressPercentage}%');
    buffer.writeln('--------------------------------');

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

    buffer.writeln('--------------------------------');
    buffer.writeln('Generated via IBUILD Construction ERP');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied Site Progress Report to clipboard! ✓'),
        backgroundColor: AppColors.secondary,
      ),
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

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(
      dailyProgressListProvider(widget.projectId),
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

        final int totalEntries = entries.length;
        final int latestPercentage = entries.isNotEmpty
            ? entries.first.progressPercentage
            : 0;

        return Column(
          children: [
            // Summary Banner Card
            Container(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Site Completion',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$latestPercentage%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor(context),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _shareDailySummary(context, entries),
                            icon: const Icon(Icons.share_outlined, size: 20),
                            color: AppColors.primaryColor(context),
                            tooltip: 'Share Daily Progress Report',
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openForm(context, null),
                            icon: const Icon(Icons.add_a_photo, size: 16),
                            label: const Text('Log Progress'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: latestPercentage / 100,
                      backgroundColor: AppColors.border(context),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.secondary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Daily Site Progress History: $totalEntries Record${totalEntries == 1 ? '' : 's'} Logged',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

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
            onExportPdf: () async {
              final entries = ref.read(dailyProgressListProvider(widget.projectId)).value ?? [];
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
            onExportExcel: () async {
              final entries = ref.read(dailyProgressListProvider(widget.projectId)).value ?? [];
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
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.black.withValues(alpha: 0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, _) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 48,
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

    final bool hasMorningAndEvening =
        entry.morningImageUrl != null &&
        entry.eveningImageUrl != null &&
        entry.morningImageUrl != entry.eveningImageUrl;

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
          if (hasMorningAndEvening)
            Row(
              children: [
                Expanded(
                  child: _evidencePhotoCard(
                    context,
                    badgeLabel: 'BEFORE WORK',
                    badgeColor: Colors.orange,
                    imageUrl: entry.morningImageUrl,
                    notes: entry.morningNotes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _evidencePhotoCard(
                    context,
                    badgeLabel: 'AFTER WORK',
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
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, idx) {
                      final url = images[idx];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 180,
                        child: InkWell(
                          onTap: () => _showImagePreview(
                            context,
                            url,
                            'Site Progress Photo ${idx + 1}',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.bg(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border(context),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.broken_image,
                                    size: 36,
                                    color: AppColors.outline,
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
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
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, _, _) => const Icon(
                      Icons.broken_image,
                      size: 36,
                      color: AppColors.outline,
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
}
