import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/image_upload_card.dart';
import '../../../../models/image_model.dart';
import '../../../../providers/image_provider.dart';
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
  String? _saveError;

  String? _selectedPhase;
  String? _selectedCondition;

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
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final imageNotifier = ref.read(imageNotifierProvider.notifier);
    final repo = ref.read(dailyProgressRepositoryProvider);

    try {
      // Upload before/morning image to ImageKit if pending
      if (_morningPendingBytes != null) {
        final url = await imageNotifier.uploadImage(
          bytes: _morningPendingBytes!,
          fileExtension: _morningPendingExt ?? 'jpg',
          folder: ImageFolder.projectsBefore,
          projectId: widget.projectId,
        );
        if (url != null) {
          _morningImageUrl = url;
          _morningPendingBytes = null;
          _morningPendingExt = null;
        } else {
          // Upload failed — show detailed error but continue saving other data
          final uploadError = ref.read(imageNotifierProvider).error;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  uploadError ?? 'Morning image upload failed. Please try again.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Upload after/evening image to ImageKit if pending
      if (_eveningPendingBytes != null) {
        final url = await imageNotifier.uploadImage(
          bytes: _eveningPendingBytes!,
          fileExtension: _eveningPendingExt ?? 'jpg',
          folder: ImageFolder.projectsAfter,
          projectId: widget.projectId,
        );
        if (url != null) {
          _eveningImageUrl = url;
          _eveningPendingBytes = null;
          _eveningPendingExt = null;
        } else {
          final uploadError = ref.read(imageNotifierProvider).error;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  uploadError ?? 'Evening image upload failed. Please try again.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      String eveningText = _eveningNotesCtrl.text.trim();
      final metaTags = <String>[];
      if (_selectedPhase != null) metaTags.add('🏗️ Phase: $_selectedPhase');
      if (_selectedCondition != null) metaTags.add('Conditions: $_selectedCondition');

      if (metaTags.isNotEmpty) {
        final metaHeader = metaTags.join(' • ');
        eveningText = eveningText.isEmpty ? metaHeader : '$metaHeader\n$eveningText';
      }

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final entry = DailyProgress(
        id: widget.existing?.id ?? '',
        projectId: widget.projectId,
        date: widget.existing?.date ?? todayStr,
        morningImageUrl: _morningImageUrl,
        morningNotes: _morningNotesCtrl.text.trim().isEmpty ? null : _morningNotesCtrl.text.trim(),
        eveningImageUrl: _eveningImageUrl,
        eveningNotes: eveningText.isEmpty ? null : eveningText,
        progressPercentage: _progress,
      );

      await repo.upsertProgress(entry);

      // Invalidate the list provider so the display screen reloads fresh data
      ref.invalidate(dailyProgressListProvider(widget.projectId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site progress log saved successfully ✓'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saveError = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save progress log: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(imageNotifierProvider);

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
            // Site Execution & Work Evidence Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryColor(context).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor(context).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primaryColor(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Work & Site Evidence Entry',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Attach Before & After photos and work notes for this site shift. Project progress is tracked dynamically by milestone.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Construction Phase Selection
            Text('ACTIVE CONSTRUCTION PHASE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryColor(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Foundation & Footing',
                'RCC Structure & Columns',
                'Brickwork & Masonry',
                'Electrical & Plumbing',
                'Plastering & Painting',
                'Finishing & Handover',
              ].map((phase) {
                final isSelected = _selectedPhase == phase;
                return ChoiceChip(
                  label: Text(phase, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.text(context))),
                  selected: isSelected,
                  selectedColor: AppColors.primaryColor(context),
                  backgroundColor: AppColors.cardBg(context),
                  onSelected: (val) => setState(() => _selectedPhase = val ? phase : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Site & Weather Condition Selection
            Text('WEATHER & SITE CONDITIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryColor(context), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '☀️ Clear / Good Work',
                '🌧️ Rainy / Work Delayed',
                '⚠️ Material Delay',
                '🚧 Normal Work Day',
              ].map((cond) {
                final isSelected = _selectedCondition == cond;
                return ChoiceChip(
                  label: Text(cond, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.text(context))),
                  selected: isSelected,
                  selectedColor: AppColors.secondary,
                  backgroundColor: AppColors.cardBg(context),
                  onSelected: (val) => setState(() => _selectedCondition = val ? cond : null),
                );
              }).toList(),
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
              isUploading: _isSaving && _morningPendingBytes != null && uploadState.isUploading,
              uploadProgress: uploadState.progress,
              onImagePicked: (bytes, ext) {
                _morningPendingBytes = bytes;
                _morningPendingExt = ext;
              },
              onDeleteRequested: () {
                setState(() {
                  _morningImageUrl = null;
                  _morningPendingBytes = null;
                  _morningPendingExt = null;
                });
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
              isUploading: _isSaving && _eveningPendingBytes != null && uploadState.isUploading,
              uploadProgress: uploadState.progress,
              onImagePicked: (bytes, ext) {
                _eveningPendingBytes = bytes;
                _eveningPendingExt = ext;
              },
              onDeleteRequested: () {
                setState(() {
                  _eveningImageUrl = null;
                  _eveningPendingBytes = null;
                  _eveningPendingExt = null;
                });
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
            const SizedBox(height: 16),

            // Error display
            if (_saveError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _saveError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text(
                          uploadState.isUploading
                              ? 'Uploading image... ${(uploadState.progress * 100).toInt()}%'
                              : 'Saving progress...',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    )
                  : const Text('Save Progress & Evidence Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
