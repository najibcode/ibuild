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

    // Upload before/morning image if pending
    if (_morningPendingBytes != null) {
      final url = await storage.uploadImage(
        bucket: 'progress-images',
        fileBytes: _morningPendingBytes!,
        fileExtension: _morningPendingExt ?? 'jpg',
        folder: widget.projectId,
      );
      if (url != null) _morningImageUrl = url;
    }

    // Upload after/evening image if pending
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
          const SnackBar(content: Text('Site progress log saved successfully'), backgroundColor: AppColors.secondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save progress log: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Site Progress Log' : 'Log Site Work Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Site Completion Percentage Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Site Completion Progress',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text(context)),
                      ),
                      Text(
                        '$_progress%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primaryColor(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _progress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.primaryColor(context),
                    onChanged: (v) => setState(() => _progress = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BEFORE WORK EVIDENCE SECTION
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BEFORE WORK EVIDENCE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ImageUploadCard(
              existingUrl: _morningImageUrl,
              label: 'Tap to upload BEFORE-work photo (Initial Condition)',
              onImagePicked: (bytes, ext) {
                _morningPendingBytes = bytes;
                _morningPendingExt = ext;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _morningNotesCtrl,
              maxLines: 3,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                labelText: 'Before-Work Site Description / Preparation Notes',
                hintText: 'e.g. Initial site setup before brick wall construction on east wing...',
                hintStyle: TextStyle(color: AppColors.mutedText(context)),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

            // AFTER WORK EVIDENCE SECTION
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AFTER WORK EVIDENCE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ImageUploadCard(
              existingUrl: _eveningImageUrl,
              label: 'Tap to upload AFTER-work photo (Completed Execution)',
              onImagePicked: (bytes, ext) {
                _eveningPendingBytes = bytes;
                _eveningPendingExt = ext;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eveningNotesCtrl,
              maxLines: 3,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                labelText: 'Completed Work Description & Activity Log',
                hintText: 'e.g. Built 10ft brick wall, fitted conduit pipes, prepped for plastering tomorrow...',
                hintStyle: TextStyle(color: AppColors.mutedText(context)),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Save Progress Entry Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor(context),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Progress & Evidence Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
