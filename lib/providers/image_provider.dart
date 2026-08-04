import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Uploads compressed image bytes to ImageKit and saves metadata to PostgreSQL.
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

      final result = await _imageKitService.uploadImage(
        bytes: bytes,
        fileName: fileName,
        folder: folder,
        onProgress: (p) => state = state.copyWith(progress: p),
      );

      if (result == null) {
        state = state.copyWith(
          isUploading: false,
          error: 'ImageKit upload failed. Please check network connection.',
        );
        return null;
      }

      final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id;

      final appImage = AppImage(
        id: _uuid.v4(),
        fileId: result.fileId,
        imageUrl: result.url,
        imagePath: result.filePath,
        folder: folder.path,
        uploadedBy: userId,
        uploadedAt: DateTime.now(),
        projectId: projectId,
        employeeId: employeeId,
        inventoryId: inventoryId,
        billId: billId,
      );

      await _imageRepository.saveImageMetadata(appImage);

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        lastUploadedImage: appImage,
      );

      return result.url;
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
