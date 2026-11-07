import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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

/// Production implementation using [ImagePicker] and [path_provider].
class ProfilePhotoServiceImpl implements ProfilePhotoService {
  final ImagePicker? imagePicker;

  ProfilePhotoServiceImpl({
    ImagePicker? imagePicker,
  }) : imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
    String? userId,
  }) async {
    try {
      final picker = imagePicker ?? ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final suffix = userId != null && userId.isNotEmpty ? '_$userId' : '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'nestora_avatar$suffix$timestamp.png';
      final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      return savedFile.path;
    } catch (e) {
      debugPrint('ProfilePhotoService: Error picking or saving photo: $e');
      return null;
    }
  }

  @override
  Future<void> deleteLocalImage(String? path) async {
    if (path == null || path.isEmpty) return;
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
