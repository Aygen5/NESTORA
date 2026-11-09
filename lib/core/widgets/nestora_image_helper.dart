import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper function providing an [ImageProvider] for any supported image source:
/// - Base64 Data URLs (`data:image/png;base64,...` or raw base64)
/// - Local Flutter assets (`assets/...`)
/// - Remote network URLs (`https://...`)
/// - Local file system paths on desktop/mobile (`/path/to/img.jpg`)
ImageProvider? resolveImageProvider(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final trimmed = path.trim();

  // 1. Base64 Data URL or raw base64 string
  if (trimmed.startsWith('data:image') ||
      (trimmed.length > 100 && !trimmed.contains('/') && !trimmed.contains('\\'))) {
    try {
      final base64Content = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
      return MemoryImage(base64Decode(base64Content));
    } catch (e) {
      debugPrint('resolveImageProvider base64 decode error: $e');
      return null;
    }
  }

  // 2. Local Asset
  if (trimmed.startsWith('assets/')) {
    return AssetImage(trimmed);
  }

  // 3. Network URL
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }

  // 4. File system path (Mobile & Desktop only, safe against Web UnsupportedError)
  if (!kIsWeb) {
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (e) {
      debugPrint('resolveImageProvider file error: $e');
    }
  }

  return null;
}

/// Robust image widget rendering photos across all platforms (Web, Mobile, Desktop).
/// Seamlessly resolves assets, base64 data URLs, network URLs, and local files.
Widget buildNestoraImage(
  String? path, {
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
  Widget? errorWidget,
  double? width,
  double? height,
}) {
  if (path == null || path.trim().isEmpty) {
    return placeholder ?? const SizedBox.shrink();
  }
  final trimmed = path.trim();

  // 1. Base64 Data URL or raw base64 string
  if (trimmed.startsWith('data:image') ||
      (trimmed.length > 100 && !trimmed.contains('/') && !trimmed.contains('\\'))) {
    try {
      final base64Content = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
      final bytes = base64Decode(base64Content);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (ctx, err, stack) =>
            errorWidget ?? placeholder ?? const SizedBox.shrink(),
      );
    } catch (e) {
      debugPrint('buildNestoraImage memory error: $e');
      return errorWidget ?? placeholder ?? const SizedBox.shrink();
    }
  }

  // 2. Bundled Asset
  if (trimmed.startsWith('assets/')) {
    return Image.asset(
      trimmed,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (ctx, err, stack) =>
          errorWidget ?? placeholder ?? const SizedBox.shrink(),
    );
  }

  // 3. Network URL
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Image.network(
      trimmed,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (ctx, err, stack) =>
          errorWidget ?? placeholder ?? const SizedBox.shrink(),
    );
  }

  // 4. Local File (Mobile & Desktop)
  if (!kIsWeb) {
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (ctx, err, stack) =>
              errorWidget ?? placeholder ?? const SizedBox.shrink(),
        );
      }
    } catch (e) {
      debugPrint('buildNestoraImage file error: $e');
    }
  }

  return errorWidget ?? placeholder ?? const SizedBox.shrink();
}

