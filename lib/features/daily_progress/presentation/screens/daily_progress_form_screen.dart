import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/image_upload_card.dart';
import '../../data/models/daily_progress_model.dart';
import '../controllers/daily_progress_controller.dart';

class DailyProgressFormScreen extends ConsumerStatefulWidget {
  final String projectId;
  final DailyProgress? existing;

  const DailyProgressFormScreen({
    super.key,
    required this.projectId,
    this.existing,
  });

  @override
  ConsumerState<DailyProgressFormScreen> createState() => _DailyProgressFormScreenState();
}

class _DailyProgressFormScreenState extends ConsumerState<DailyProgressFormScreen> {
  late final TextEditingController _morningNotesCtrl;
  late final TextEditingController _eveningNotesCtrl;
  late int _progress;
  bool _isSaving = false;

  String? _morningImageUrl;
  String? _eveningImageUrl;
  Uint8List? _morningPendingBytes;
  String? _morningPendingExt;
  Uint8List? _eveningPendingBytes;
  String? _eveningPendingExt;

  @override
  void initState() {
    super.initState();
    _morningNotesCtrl = TextEditingController(text: widget.existing?.morningNotes ?? '');
    _eveningNotesCtrl = TextEditingController(text: widget.existing?.eveningNotes ?? '');
    _progress = widget.existing?.progressPercentage ?? 0;
    _morningImageUrl = widget.existing?.morningImageUrl;
    _eveningImageUrl = widget.existing?.eveningImageUrl;
  }

  @override
  void dispose() {
    _morningNotesCtrl.dispose();
    _eveningNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final storage = ref.read(storageServiceProvider);
    final repo = ref.read(dailyProgressRepositoryProvider);

    // Upload morning image if pending
    if (_morningPendingBytes != null) {
      final url = await storage.uploadImage(
        bucket: 'progress-images',
        fileBytes: _morningPendingBytes!,
        fileExtension: _morningPendingExt ?? 'jpg',
        folder: widget.projectId,
      );
      if (url != null) _morningImageUrl = url;
    }

    // Upload evening image if pending
    if (_eveningPendingBytes != null) {
      final url = await storage.uploadImage(
        bucket: 'progress-images',
        fileBytes: _eveningPendingBytes!,
        fileExtension: _eveningPendingExt ?? 'jpg',
        folder: widget.projectId,
      );
      if (url != null) _eveningImageUrl = url;
    }

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final entry = DailyProgress(
      id: widget.existing?.id ?? '',
      projectId: widget.projectId,
      date: widget.existing?.date ?? todayStr,
      morningImageUrl: _morningImageUrl,
      morningNotes: _morningNotesCtrl.text.trim().isEmpty ? null : _morningNotesCtrl.text.trim(),
      eveningImageUrl: _eveningImageUrl,
      eveningNotes: _eveningNotesCtrl.text.trim().isEmpty ? null : _eveningNotesCtrl.text.trim(),
      progressPercentage: _progress,
    );

    try {
      await repo.upsertProgress(entry);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress saved'), backgroundColor: AppColors.secondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.existing != null ? 'Edit Progress' : 'Add Progress')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Slider
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress Percentage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('$_progress%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _progress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _progress = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Morning Section
            const Text('MORNING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ImageUploadCard(
              existingUrl: _morningImageUrl,
              label: 'Tap to add morning photo',
              onImagePicked: (bytes, ext) {
                _morningPendingBytes = bytes;
                _morningPendingExt = ext;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _morningNotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Morning notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Evening Section
            const Text('EVENING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ImageUploadCard(
              existingUrl: _eveningImageUrl,
              label: 'Tap to add evening photo',
              onImagePicked: (bytes, ext) {
                _eveningPendingBytes = bytes;
                _eveningPendingExt = ext;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eveningNotesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Evening notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.defaultValue)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
