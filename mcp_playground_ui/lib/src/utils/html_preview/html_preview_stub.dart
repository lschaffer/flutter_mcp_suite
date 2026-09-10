import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web/WASM implementation for opening HTML previews.
Future<void> openHtmlInBrowserPlatform(BuildContext context, String html) async {
  final uri = Uri.parse(
    'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}',
  );
  await launchUrl(uri);
}
