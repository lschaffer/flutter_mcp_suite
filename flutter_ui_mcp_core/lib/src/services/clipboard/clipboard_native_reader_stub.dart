import '../clipboard_content_service.dart';

/// Stub implementation for platforms without dart:io / PowerShell (Web, WASM).
Future<List<ClipboardPayload>> readWindowsNativeClipboard() async => const [];
