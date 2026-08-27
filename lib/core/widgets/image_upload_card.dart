import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../widgets/cached_image.dart';
import '../theme/app_colors.dart';
import '../services/image_compression_service.dart';

class ImageUploadCard extends StatefulWidget {
  final String? existingUrl;
  final String label;
  final void Function(Uint8List bytes, String extension) onImagePicked;
  final VoidCallback? onDeleteRequested;
  final bool isUploading;
  final double uploadProgress;

  const ImageUploadCard({
    super.key,
    this.existingUrl,
    required this.label,
    required this.onImagePicked,
    this.onDeleteRequested,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<ImageUploadCard> createState() => _ImageUploadCardState();
}

class _ImageUploadCardState extends State<ImageUploadCard> {
  Uint8List? _localBytes;
  bool _isPicking = false;

  Future<void> _pick() async {
    if (_isPicking) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show camera option if supported on this platform
            if (ImageCompressionService.isCameraAvailable)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (widget.onDeleteRequested != null &&
                (_localBytes != null || widget.existingUrl != null))
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Remove Photo',
                    style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (result == 'delete') {
      setState(() => _localBytes = null);
      widget.onDeleteRequested?.call();
      return;
    }

    setState(() => _isPicking = true);

    try {
      final image = result == 'camera'
          ? await ImageCompressionService.pickFromCamera()
          : await ImageCompressionService.pickFromGallery();

      if (image != null) {
        setState(() => _localBytes = image.bytes);
        widget.onImagePicked(image.bytes, image.extension);
      } else if (mounted) {
        // Only show feedback if not a user cancellation (bytes would be null)
        // User cancellation is a normal flow, no need for error message
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        _localBytes != null ||
        (widget.existingUrl != null && widget.existingUrl!.isNotEmpty);

    return GestureDetector(
      onTap: (widget.isUploading || _isPicking) ? null : _pick,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.border(context),
            style: hasImage ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_localBytes != null)
              Image.memory(_localBytes!, fit: BoxFit.cover)
            else if (widget.existingUrl != null &&
                widget.existingUrl!.isNotEmpty)
              AppCachedImage(
                imageUrl: widget.existingUrl!,
                fit: BoxFit.cover,
                enableZoom: true,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isPicking)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.mutedText(context).withValues(alpha: 0.5),
                      ),
                    )
                  else
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 36,
                      color: AppColors.mutedText(context).withValues(alpha: 0.5),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _isPicking ? 'Selecting image...' : widget.label,
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            // Upload overlay
            if (widget.isUploading)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: widget.uploadProgress > 0
                            ? widget.uploadProgress
                            : null,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.uploadProgress > 0
                            ? 'Uploading... ${(widget.uploadProgress * 100).toInt()}%'
                            : 'Uploading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasImage && !widget.isUploading)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: _pick,
                    tooltip: 'Change / Delete Image',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
