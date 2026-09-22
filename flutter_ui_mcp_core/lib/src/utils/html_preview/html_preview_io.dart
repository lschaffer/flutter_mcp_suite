import 'dart:io' as io;
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Native (desktop/mobile) implementation for opening HTML previews via temporary file.
Future<void> openHtmlInBrowserPlatform(BuildContext context, String html) async {
  final dir = await getTemporaryDirectory();
  final file = io.File(
    '${dir.path}${io.Platform.pathSeparator}mcp_preview_${DateTime.now().millisecondsSinceEpoch}.html',
  );
  await file.writeAsString(html);
  final uri = Uri.file(file.path);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open browser. File saved to temp directory.',
          ),
        ),
      );
    }
  }
}
