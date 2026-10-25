import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/platform_file/platform_file.dart';
import '../utils/mime_utils.dart';
import '../utils/image_optimizer.dart';
import 'clipboard/clipboard_native_reader.dart';

/// The recognized category of content extracted from the system clipboard.
enum ClipboardContentType {
  image,
  document,
  text,
}

/// A structured representation of data extracted from the clipboard.
class ClipboardPayload {
  final ClipboardContentType type;
  final String name;
  final String mimeType;
  final Uint8List? bytes;
  final String? text;
  final String? filePath;

  const ClipboardPayload({
    required this.type,
    required this.name,
    required this.mimeType,
    this.bytes,
    this.text,
    this.filePath,
  });

  /// True if this payload represents media (image or document) rather than plain text.
  bool get isMedia =>
      type == ClipboardContentType.image || type == ClipboardContentType.document;
}

/// Unified service for extracting images, documents, and rich content from
/// the system clipboard across desktop (Windows/macOS/Linux) and mobile platforms.
class ClipboardContentService {
  /// Reads the current system clipboard and identifies if it holds:
  /// 1. A native bitmap image (Windows clipboard CF_BITMAP/PNG)
  /// 2. Native file drop list (files copied in Explorer)
  /// 3. A file path pointing to an existing file (image or document)
  /// 4. A base64 data URI (data:image/...;base64,...)
  /// 5. Normal text
  static Future<List<ClipboardPayload>> readClipboard() async {
    // 1. On desktop platforms, check for native clipboard image or file drop list
    if (!kIsWeb) {
      try {
        final nativePayloads = await readWindowsNativeClipboard();
        if (nativePayloads.isNotEmpty) {
          return nativePayloads;
        }
      } catch (e) {
        debugPrint('[ClipboardContentService] Native clipboard check failed: $e');
      }
    }

    // 2. Check standard text clipboard for Base64 Data URIs, file paths, or text
    try {
      final textData = await Clipboard.getData(Clipboard.kTextPlain);
      if (textData?.text != null && textData!.text!.trim().isNotEmpty) {
        final raw = textData.text!.trim();

        // 2a. Base64 Data URI (e.g. data:image/png;base64,iVBOR...)
        if (raw.startsWith('data:image/')) {
          final uriPayload = await _parseDataUri(raw);
          if (uriPayload != null) return [uriPayload];
        }

        // 2b. Check if raw text represents existing file paths on disk
        if (!kIsWeb) {
          final filePayloads = await _parsePotentialFilePaths(raw);
          if (filePayloads.isNotEmpty) return filePayloads;
        }

        // 2c. Normal text fallback
        return [
          ClipboardPayload(
            type: ClipboardContentType.text,
            name: 'text',
            mimeType: 'text/plain',
            text: raw,
          ),
        ];
      }
    } catch (e) {
      debugPrint('[ClipboardContentService] Text clipboard check failed: $e');
    }

    return const [];
  }



  /// Parses a base64 Data URI into a [ClipboardPayload].
  static Future<ClipboardPayload?> _parseDataUri(String uri) async {
    try {
      final commaIdx = uri.indexOf(',');
      if (commaIdx == -1) return null;

      final header = uri.substring(0, commaIdx);
      final dataStr = uri.substring(commaIdx + 1);

      // Determine mime
      var mime = 'image/png';
      final mimeMatch = RegExp(r'data:([^;]+);').firstMatch(header);
      if (mimeMatch != null) {
        mime = mimeMatch.group(1) ?? 'image/png';
      }

      final rawBytes = base64.decode(dataStr);
      final optBytes = await ImageOptimizer.shrinkToOptimalSize(rawBytes);

      return ClipboardPayload(
        type: ClipboardContentType.image,
        name: 'clipboard_image_${DateTime.now().millisecondsSinceEpoch}.png',
        mimeType: mime,
        bytes: optBytes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks if a string contains local file paths.
  static Future<List<ClipboardPayload>> _parsePotentialFilePaths(String input) async {
    // Might be single path or multiple paths separated by newlines
    final lines = input
        .split('\n')
        .map((l) => l.trim().replaceAll(RegExp(r'^["' "'" r']|["' "'" r']$'), ''))
        .where((l) => l.isNotEmpty);

    final payloads = <ClipboardPayload>[];

    for (var path in lines) {
      if (path.startsWith('file:///')) {
        path = Uri.parse(path).toFilePath();
      } else if (path.startsWith('file://')) {
        path = Uri.parse(path).toFilePath();
      }

      final bytes = await readLocalFileBytes(path);
      if (bytes != null) {
        final name = path.split(RegExp(r'[/\\]')).last;
        final mime = mimeFromExtension(name);

        if (ImageOptimizer.isImageMime(mime)) {
          final opt = await ImageOptimizer.shrinkToOptimalSize(bytes);
          payloads.add(
            ClipboardPayload(
              type: ClipboardContentType.image,
              name: name,
              mimeType: mime,
              bytes: opt,
              filePath: path,
            ),
          );
        } else {
          String? textContent;
          if (isTextFile(mime, name)) {
            textContent = await readLocalFileString(path);
          }
          payloads.add(
            ClipboardPayload(
              type: ClipboardContentType.document,
              name: name,
              mimeType: mime,
              bytes: bytes,
              text: textContent,
              filePath: path,
            ),
          );
        }
      }
    }

    return payloads;
  }
}
