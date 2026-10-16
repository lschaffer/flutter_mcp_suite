import 'dart:convert';
import 'dart:io';

/// Inspect cached models via the `foundry` CLI on desktop.
/// Returns only models that are downloaded/cached locally on the user's PC.
Future<List<String>> getFoundryCachedModels() async {
  try {
    final proc = await Process.run('foundry', ['cache', 'list', '-o', 'json']);
    if (proc.exitCode == 0) {
      final out = proc.stdout.toString().trim();
      if (out.startsWith('{')) {
        final data = jsonDecode(out) as Map<String, dynamic>;
        final models = (data['models'] as List<dynamic>? ?? [])
            .map((m) => (m as Map<String, dynamic>)['id'] as String? ?? (m['alias'] as String? ?? ''))
            .where((id) => id.isNotEmpty)
            .toList();
        if (models.isNotEmpty) return models;
      }
    }
  } catch (_) {}

  // Fallback to loaded models check
  try {
    final proc = await Process.run('foundry', ['model', 'list', '--loaded', '-o', 'json']);
    if (proc.exitCode == 0) {
      final out = proc.stdout.toString().trim();
      if (out.startsWith('{')) {
        final data = jsonDecode(out) as Map<String, dynamic>;
        final models = (data['models'] as List<dynamic>? ?? [])
            .map((m) => (m as Map<String, dynamic>)['id'] as String? ?? (m['alias'] as String? ?? ''))
            .where((id) => id.isNotEmpty)
            .toList();
        if (models.isNotEmpty) return models;
      }
    }
  } catch (_) {}

  return [];
}

/// Query the live Foundry server URL via `foundry status -o json`.
Future<String?> getFoundryActiveUrl() async {
  try {
    final proc = await Process.run('foundry', ['status', '-o', 'json']);
    if (proc.exitCode == 0) {
      final out = proc.stdout.toString().trim();
      if (out.startsWith('{')) {
        final data = jsonDecode(out) as Map<String, dynamic>;
        final service = data['service'] as Map<String, dynamic>?;
        final urls = service?['webUrls'] as List<dynamic>?;
        if (urls != null && urls.isNotEmpty) {
          final firstUrl = urls.first.toString().replaceAll(RegExp(r'/+$'), '');
          return '$firstUrl/v1';
        }
      }
    }
  } catch (_) {}
  return null;
}

/// Explicitly load a downloaded model into Foundry daemon memory for inference.
Future<bool> loadFoundryModel(String model) async {
  try {
    final proc = await Process.run('foundry', ['model', 'load', model]);
    return proc.exitCode == 0;
  } catch (_) {
    return false;
  }
}
