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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Progress: $projectName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(dailyProgressListProvider(projectId)),
          ),
        ],
      ),
      body: progressAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.outline.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No progress entries yet.', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context, ref, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Today\'s Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            itemCount: entries.length,
            itemBuilder: (context, index) => _ProgressCard(
              entry: entries[index],
              onEdit: entries[index].isToday
                  ? () => _openForm(context, ref, entries[index])
                  : null,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: const Icon(Icons.add_a_photo),
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

  @override
  Widget build(BuildContext context) {
    final isReadOnly = onEdit == null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Text(entry.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${entry.progressPercentage}%',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  if (!isReadOnly) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onEdit,
                      child: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                    ),
                  ],
                  if (isReadOnly) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: entry.progressPercentage / 100,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // Side-by-side images
          Row(
            children: [
              Expanded(child: _imageColumn('Morning', entry.morningImageUrl, entry.morningNotes)),
              const SizedBox(width: 12),
              Expanded(child: _imageColumn('Evening', entry.eveningImageUrl, entry.eveningNotes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageColumn(String label, String? imageUrl, String? notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.defaultValue),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: AppColors.outline)),
                )
              : const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.outline, size: 28)),
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}
