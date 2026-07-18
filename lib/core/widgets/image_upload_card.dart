import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../services/image_compression_service.dart';

class ImageUploadCard extends StatefulWidget {
  final String? existingUrl;
  final String label;
  final void Function(Uint8List bytes, String extension) onImagePicked;
  final bool isUploading;
  final double uploadProgress;

  const ImageUploadCard({
    super.key,
    this.existingUrl,
    required this.label,
    required this.onImagePicked,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<ImageUploadCard> createState() => _ImageUploadCardState();
}

class _ImageUploadCardState extends State<ImageUploadCard> {
  Uint8List? _localBytes;

  Future<void> _pick() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
      ),
    );

    if (result == null) return;

    final image = result == 'camera'
        ? await ImageCompressionService.pickFromCamera()
        : await ImageCompressionService.pickFromGallery();

    if (image != null) {
      setState(() => _localBytes = image.bytes);
      widget.onImagePicked(image.bytes, image.extension);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _localBytes != null || (widget.existingUrl != null && widget.existingUrl!.isNotEmpty);

    return GestureDetector(
      onTap: widget.isUploading ? null : _pick,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.borderSubtle,
            style: hasImage ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_localBytes != null)
              Image.memory(_localBytes!, fit: BoxFit.cover)
            else if (widget.existingUrl != null && widget.existingUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.existingUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: AppColors.outline),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.outline.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            // Upload overlay
            if (widget.isUploading)
              Container(
                color: Colors.black38,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(value: widget.uploadProgress > 0 ? widget.uploadProgress : null, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '${(widget.uploadProgress * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
