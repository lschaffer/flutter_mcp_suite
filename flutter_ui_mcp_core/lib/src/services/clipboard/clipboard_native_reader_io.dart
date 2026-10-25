import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../utils/image_optimizer.dart';
import '../../utils/mime_utils.dart';
import '../clipboard_content_service.dart';

/// Reads Windows native clipboard formats (Bitmap and FileDropList) via PowerShell.
Future<List<ClipboardPayload>> readWindowsNativeClipboard() async {
  if (!Platform.isWindows) return const [];

  const script = '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    \$img = [System.Windows.Forms.Clipboard]::GetImage()
    \$ms = New-Object System.IO.MemoryStream
    \$img.Save(\$ms, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output ("IMG:" + [Convert]::ToBase64String(\$ms.ToArray()))
} elseif ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
    \$files = [System.Windows.Forms.Clipboard]::GetFileDropList()
    Write-Output ("FILES:" + [string]::Join("|", \$files))
} else {
    Write-Output "NONE"
}
''';

  // Encode to UTF-16LE base64 for PowerShell -EncodedCommand to avoid shell escaping issues
  final utf16leBytes = <int>[];
  for (final b in script.codeUnits) {
    utf16leBytes.add(b & 0xFF);
    utf16leBytes.add((b >> 8) & 0xFF);
  }
  final encodedCmd = base64.encode(utf16leBytes);

  try {
    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-EncodedCommand', encodedCmd],
    );

    if (result.exitCode != 0) return const [];

    final output = result.stdout.toString().trim();

    // Native Image
    if (output.startsWith('IMG:')) {
      final b64 = output.substring(4).trim();
      if (b64.isNotEmpty) {
        final rawBytes = base64.decode(b64);
        final optBytes = await ImageOptimizer.shrinkToOptimalSize(rawBytes);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return [
          ClipboardPayload(
            type: ClipboardContentType.image,
            name: 'clipboard_screenshot_$timestamp.png',
            mimeType: 'image/png',
            bytes: optBytes,
          ),
        ];
      }
    }

    // Native File Drop List
    if (output.startsWith('FILES:')) {
      final rawPaths = output.substring(6).trim();
      final paths = rawPaths.split('|').where((p) => p.trim().isNotEmpty);
      final payloads = <ClipboardPayload>[];

      for (final p in paths) {
        final file = File(p.trim());
        if (await file.exists()) {
          final name = p.trim().split(RegExp(r'[/\\]')).last;
          final mime = mimeFromExtension(name);
          final bytes = await file.readAsBytes();

          if (ImageOptimizer.isImageMime(mime)) {
            final opt = await ImageOptimizer.shrinkToOptimalSize(bytes);
            payloads.add(
              ClipboardPayload(
                type: ClipboardContentType.image,
                name: name,
                mimeType: mime,
                bytes: opt,
                filePath: file.path,
              ),
            );
          } else {
            String? textContent;
            if (isTextFile(mime, name)) {
              try {
                textContent = await file.readAsString();
              } catch (_) {}
            }
            payloads.add(
              ClipboardPayload(
                type: ClipboardContentType.document,
                name: name,
                mimeType: mime,
                bytes: bytes,
                text: textContent,
                filePath: file.path,
              ),
            );
          }
        }
      }
      return payloads;
    }
  } catch (e) {
    debugPrint('[ClipboardContentService] Windows native check failed: $e');
  }

  return const [];
}
