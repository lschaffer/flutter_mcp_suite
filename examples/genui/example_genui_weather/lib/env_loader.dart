import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mcp_playground_dart/mcp_playground_dart.dart';

class EnvLoader {
  static final Map<String, String> _env = {};

  static Future<void> load() async {
    final possiblePaths = [
      '../../../.env',
      '../../.env',
      '../.env',
      '.env',
    ];

    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        final lines = await file.readAsLines();
        _parseLines(lines);
        return;
      }
    }

    try {
      final content = await rootBundle.loadString('.env');
      _parseLines(content.split('\n'));
    } catch (_) {}
  }

  static void _parseLines(List<String> lines) {
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final idx = line.indexOf('=');
      if (idx > 0) {
        final key = line.substring(0, idx).trim();
        var val = line.substring(idx + 1).trim();
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }
        _env[key] = val;
      }
    }
  }

  static String get(String key, {String defaultValue = ''}) {
    return _env[key] ?? Platform.environment[key] ?? defaultValue;
  }

  static LlmProvider getProvider() {
    final p = get('LLM_PROVIDER').toLowerCase();
    switch (p) {
      case 'openai':
        return LlmProvider.openAi;
      case 'anthropic':
      case 'claude':
        return LlmProvider.anthropic;
      case 'gemini':
      case 'google':
        return LlmProvider.gemini;
      case 'ollama':
        return LlmProvider.ollama;
      case 'mistral':
        return LlmProvider.mistral;
      case 'custom':
        return LlmProvider.customOpenAi;
      default:
        return LlmProvider.none;
    }
  }
}
