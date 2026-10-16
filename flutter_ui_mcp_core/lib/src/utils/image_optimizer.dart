import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Utility for automatically optimizing and downscaling images for on-device SLMs
/// (e.g. Gemini Nano on Android, Apple FoundationModels) and multimodal LLMs.
class ImageOptimizer {
  /// Default optimal max dimension (width or height) for on-device and mobile models.
  /// 768px provides rich visual fidelity while keeping payload sizes under ~100 KB
  /// and avoiding mobile NPU memory bottlenecks / OOM.
  static const int defaultMaxDimension = 768;

  /// Determines whether a MIME type represents a supported image format.
  static bool isImageMime(String? mimeType) {
    if (mimeType == null) return false;
    final clean = mimeType.toLowerCase().trim();
    return clean.startsWith('image/');
  }

  /// Downscales [inputBytes] so that neither width nor height exceeds [maxDimension],
  /// preserving the original aspect ratio.
  ///
  /// Uses Flutter's native platform hardware decoder (`instantiateImageCodec`) for
  /// maximum speed and minimal memory overhead, even on 100MP+ mobile camera photos.
  static Future<Uint8List> shrinkToOptimalSize(
    Uint8List inputBytes, {
    int maxDimension = defaultMaxDimension,
  }) async {
    if (inputBytes.isEmpty) return inputBytes;

    try {
      // 1. Inspect original dimensions
      final initialCodec = await ui.instantiateImageCodec(inputBytes);
      final initialFrame = await initialCodec.getNextFrame();
      final origWidth = initialFrame.image.width;
      final origHeight = initialFrame.image.height;

      // If already within bounds, return original bytes without re-encoding
      if (origWidth <= maxDimension && origHeight <= maxDimension) {
        return inputBytes;
      }

      // 2. Compute proportional target dimensions
      int targetWidth;
      int targetHeight;
      if (origWidth >= origHeight) {
        targetWidth = maxDimension;
        targetHeight = (origHeight * maxDimension / origWidth).round();
      } else {
        targetHeight = maxDimension;
        targetWidth = (origWidth * maxDimension / origHeight).round();
      }

      if (targetWidth < 1) targetWidth = 1;
      if (targetHeight < 1) targetHeight = 1;

      // 3. Hardware-accelerated decode and resize
      final scaledCodec = await ui.instantiateImageCodec(
        inputBytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final scaledFrame = await scaledCodec.getNextFrame();
      final byteData = await scaledFrame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final optimized = byteData.buffer.asUint8List();
        final origKb = (inputBytes.length / 1024).round();
        final newKb = (optimized.length / 1024).round();
        debugPrint(
          '[ImageOptimizer] Optimized image: ${origWidth}x$origHeight (${origKb}KB) -> '
          '${targetWidth}x$targetHeight (${newKb}KB)',
        );
        return optimized;
      }
    } catch (e) {
      debugPrint('[ImageOptimizer] Downscaling failed: $e. Using original bytes.');
    }

    return inputBytes;
  }
}
