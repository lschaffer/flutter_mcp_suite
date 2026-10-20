import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dart_mcp_core/dart_mcp_core.dart';

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
      try {
        final file = File(path);
        if (await file.exists()) {
          final lines = await file.readAsLines();
          _parseLines(lines);
          return;
        }
      } catch (_) {}
    }

    try {
      final content = await rootBundle.loadString('../../../.env');
      _parseLines(content.split('\n'));
      return;
    } catch (_) {}

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
    final val = get('LLM_PROVIDER').trim().toLowerCase();
    switch (val) {
      case 'openai':
        return LlmProvider.openai;
      case 'claude':
      case 'anthropic':
        return LlmProvider.claude;
      case 'gemini':
        return LlmProvider.gemini;
      case 'ollama':
        return LlmProvider.ollama;
      case 'openai-compatible':
      case 'openaicompatible':
        return LlmProvider.openaiCompatible;
      case 'mistral':
        return LlmProvider.mistral;
      default:
        return LlmProvider.none;
    }
  }
}
