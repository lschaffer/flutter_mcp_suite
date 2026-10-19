import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dart_mcp_core/dart_mcp_core.dart';

class EnvLoader {
  static final Map<String, String> _env = {};

  static Future<void> load() async {
    // 1. Walk up from the executable directory (for desktop Windows/macOS/Linux)
    try {
      Directory dir = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 7; i++) {
        final candidate = File('${dir.path}/.env');
        if (candidate.existsSync()) {
          _parseLines(candidate.readAsLinesSync());
          if (_env.isNotEmpty) return;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    // 2. Walk up from current working directory
    try {
      Directory dir = Directory.current;
      for (int i = 0; i < 6; i++) {
        final candidate = File('${dir.path}/.env');
        if (candidate.existsSync()) {
          _parseLines(candidate.readAsLinesSync());
          if (_env.isNotEmpty) return;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    // 3. Fallback relative paths
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
          if (_env.isNotEmpty) return;
        }
      } catch (_) {}
    }

    // 4. Asset bundle fallback
    try {
      final content = await rootBundle.loadString('../../../.env');
      _parseLines(content.split('\n'));
      if (_env.isNotEmpty) return;
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

  static LlmConfig getInitialLlmConfig() {
    final provider = getProvider();
    return LlmConfig(
      provider: provider != LlmProvider.none ? provider : LlmProvider.openai,
      model: get('LLM_MODEL', defaultValue: get('OPENAI_MODEL', defaultValue: 'gpt-4o')),
      apiKey: get('LLM_API_KEY', defaultValue: get('OPENAI_API_KEY', defaultValue: get('API_KEY'))),
      baseUrl: get('LLM_URL', defaultValue: get('OPENAI_BASE_URL', defaultValue: get('BASE_URL'))),
    );
  }
}
