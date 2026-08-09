import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/supabase/supabase_client.provider.dart';
import '../core/utils/logger.dart';
import '../models/image_model.dart';
import '../repositories/image_repository.dart';
import '../services/imagekit/imagekit_service.dart';

class ImageUploadState {
  final bool isUploading;
  final double progress;
  final String? error;
  final AppImage? lastUploadedImage;

  const ImageUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.error,
    this.lastUploadedImage,
  });

  ImageUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
    AppImage? lastUploadedImage,
  }) {
    return ImageUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error,
      lastUploadedImage: lastUploadedImage ?? this.lastUploadedImage,
    );
  }
}

class ImageNotifier extends StateNotifier<ImageUploadState> {
  final ImageKitService _imageKitService;
  final ImageRepository _imageRepository;
  final Ref _ref;
  static const _uuid = Uuid();

  ImageNotifier(this._imageKitService, this._imageRepository, this._ref)
      : super(const ImageUploadState());

  /// Uploads image bytes using a 3-tier strategy:
  ///  1. ImageKit CDN (if edge function is configured)
  ///  2. Supabase Storage (direct bucket upload)
  ///  3. Base64 Data URI (guaranteed fallback — always succeeds)
  Future<String?> uploadImage({
    required Uint8List bytes,
    required String fileExtension,
    required ImageFolder folder,
    String? projectId,
    String? employeeId,
    String? inventoryId,
    String? billId,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.05, error: null);

    try {
      final fileName = 'img_${_uuid.v4()}.$fileExtension';
      String? finalUrl;
      String fileId = '';
      String filePath = '';

      // ── Tier 1: ImageKit CDN ──
      try {
        final result = await _imageKitService.uploadImage(
          bytes: bytes,
          fileName: fileName,
          folder: folder,
          onProgress: (p) => state = state.copyWith(progress: p * 0.7),
        );
        if (result != null && result.url.isNotEmpty) {
          finalUrl = result.url;
          fileId = result.fileId;
          filePath = result.filePath;
          appLogger.i('✅ Tier 1 Success (ImageKit): $finalUrl');
        }
      } catch (e) {
        appLogger.w('⚠️ Tier 1 (ImageKit) failed: $e');
      }

      // ── Tier 2: Supabase Storage ──
      if (finalUrl == null) {
        state = state.copyWith(progress: 0.4);
        try {
          final client = _ref.read(supabaseClientProvider);
          final storagePath = '${folder.path}/$fileName';
          await client.storage.from('site-progress').uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(
                  contentType: 'image/$fileExtension',
                  upsert: true,
                ),
              );
          final publicUrl = client.storage
              .from('site-progress')
              .getPublicUrl(storagePath);
          if (publicUrl.isNotEmpty) {
            finalUrl = publicUrl;
            filePath = storagePath;
            appLogger.i('✅ Tier 2 Success (Supabase Storage): $finalUrl');
          }
        } catch (e) {
          appLogger.w('⚠️ Tier 2 (Supabase Storage) failed: $e');
        }
      }

      // ── Tier 3: Base64 Data URI (guaranteed) ──
      if (finalUrl == null) {
        state = state.copyWith(progress: 0.8);
        final base64String = base64Encode(bytes);
        final mimeType = (fileExtension == 'png')
            ? 'image/png'
            : (fileExtension == 'webp')
                ? 'image/webp'
                : 'image/jpeg';
        finalUrl = 'data:$mimeType;base64,$base64String';
        filePath = 'embedded/$fileName';
        appLogger.i('✅ Tier 3 Success (Base64 Data URI): ${bytes.length} bytes embedded');
      }

      state = state.copyWith(progress: 0.9);

      // Save metadata (non-blocking — failure here must NOT lose the URL)
      final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
      final appImage = AppImage(
        id: _uuid.v4(),
        fileId: fileId,
        imageUrl: finalUrl,
        imagePath: filePath,
        folder: folder.path,
        uploadedBy: userId,
        uploadedAt: DateTime.now(),
        projectId: projectId,
        employeeId: employeeId,
        inventoryId: inventoryId,
        billId: billId,
      );

      try {
        await _imageRepository.saveImageMetadata(appImage);
      } catch (e) {
        // Metadata save is optional — the image URL is what matters
        appLogger.w('Image metadata save failed (non-critical): $e');
      }

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        lastUploadedImage: appImage,
      );

      return finalUrl;
    } catch (e) {
      appLogger.e('ImageNotifier upload error: $e');
      state = state.copyWith(
        isUploading: false,
        error: 'Upload error: $e',
      );
      return null;
    }
  }

  /// Replaces an existing image: uploads new image and deletes the old one from ImageKit.
  Future<String?> replaceImage({
    required Uint8List newBytes,
    required String newExtension,
    required ImageFolder folder,
    String? oldFileId,
    String? projectId,
    String? employeeId,
  }) async {
    final newUrl = await uploadImage(
      bytes: newBytes,
      fileExtension: newExtension,
      folder: folder,
      projectId: projectId,
      employeeId: employeeId,
    );

    if (newUrl != null && oldFileId != null && oldFileId.isNotEmpty) {
      await _imageKitService.deleteImage(oldFileId);
    }

    return newUrl;
  }

  /// Deletes image file from ImageKit and removes metadata record.
  Future<bool> deleteImage({
    required String imageId,
    required String fileId,
  }) async {
    final deletedRemote = await _imageKitService.deleteImage(fileId);
    final deletedDb = await _imageRepository.deleteImageMetadata(imageId);
    return deletedRemote && deletedDb;
  }
}

final imageNotifierProvider =
    StateNotifierProvider<ImageNotifier, ImageUploadState>((ref) {
  final imageKitService = ref.watch(imageKitServiceProvider);
  final imageRepository = ref.watch(imageRepositoryProvider);
  return ImageNotifier(imageKitService, imageRepository, ref);
});
