import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/secure_image_service.dart';

/// Contract for managing local profile photos without requiring Cloud Storage.
/// Spark tier compliant: photos remain on the user's local device sandbox.
abstract class ProfilePhotoService {
  /// Picks an image from [source] (gallery or camera), copies it into the app's
  /// private documents directory, and returns the local file path.
  /// Returns `null` if the user cancels or picker returns no image.
  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
    String? userId,
  });

  /// Deletes a previously saved local photo file if it exists.
  Future<void> deleteLocalImage(String? path);
}

/// Production implementation using [SecureImageService].
class ProfilePhotoServiceImpl implements ProfilePhotoService {
  final SecureImageService secureImageService;

  ProfilePhotoServiceImpl({
    SecureImageService? secureImageService,
    ImagePicker? imagePicker,
  }) : secureImageService = secureImageService ?? SecureImageService(picker: imagePicker);

  @override
  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
    String? userId,
  }) async {
    final result = await secureImageService.pickAndSaveImage(
      source: source,
      targetPrefix: 'avatar_${userId ?? "usr"}',
    );
    if (result.isSuccess) {
      return result.savedPath;
    }
    return null;
  }

  @override
  Future<void> deleteLocalImage(String? path) async {
    if (path == null ||
        path.isEmpty ||
        kIsWeb ||
        path.startsWith('data:image') ||
        path.startsWith('assets/')) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('ProfilePhotoService: Error deleting photo: $e');
    }
  }
}
