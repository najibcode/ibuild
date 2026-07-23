import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/daily_progress_model.dart';
import '../controllers/daily_progress_controller.dart';
import 'daily_progress_form_screen.dart';

class DailyProgressScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const DailyProgressScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(dailyProgressListProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text('Site Progress Log: $projectName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh Progress Feed',
            onPressed: () => ref.invalidate(dailyProgressListProvider(projectId)),
          ),
        ],
      ),
      body: progressAsync.when(
        data: (entries) {
          final int totalEntries = entries.length;
          final int latestPercentage = entries.isNotEmpty ? entries.first.progressPercentage : 0;

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
                              style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$latestPercentage%',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryColor(context)),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(context, ref, null),
                          icon: const Icon(Icons.add_a_photo, size: 16),
                          label: const Text('Log Today\'s Progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: latestPercentage / 100,
                        backgroundColor: AppColors.border(context),
                        valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Past Progress Logs: $totalEntries Record${totalEntries == 1 ? '' : 's'} Available',
                      style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                    ),
                  ],
                ),
              ),

              // Progress Entries Feed
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_enhance_outlined, size: 64, color: AppColors.mutedText(context).withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'No site progress logs recorded yet.',
                              style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload Before & After photos and work notes to build site history.',
                              style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _openForm(context, ref, null),
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Log First Work Evidence'),
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
                        itemCount: entries.length,
                        itemBuilder: (context, index) => _ProgressCard(
                          entry: entries[index],
                          onEdit: entries[index].isToday ? () => _openForm(context, ref, entries[index]) : null,
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading progress logs: $e')),
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, DailyProgress? existing) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyProgressFormScreen(
          projectId: projectId,
          existing: existing,
        ),
      ),
    );
    ref.invalidate(dailyProgressListProvider(projectId));
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
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
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
          // Date & Progress Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_note_outlined, size: 18, color: AppColors.primaryColor(context)),
                  const SizedBox(width: 8),
                  Text(
                    'Log Date: ${entry.date}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.progressPercentage}% Completed',
                      style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  if (!isReadOnly) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      onPressed: onEdit,
                      tooltip: 'Edit Today\'s Progress Log',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Before & After Evidence Grid
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
          ),
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
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

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
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: hasImage ? () => _showImagePreview(context, imageUrl, badgeLabel) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: AppColors.outline)),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: AppColors.mutedText(context), size: 28),
                        const SizedBox(height: 4),
                        Text('No Image', style: TextStyle(fontSize: 10, color: AppColors.mutedText(context))),
                      ],
                    ),
                  ),
          ),
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Text(
              notes,
              style: TextStyle(fontSize: 11, color: AppColors.text(context), height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
