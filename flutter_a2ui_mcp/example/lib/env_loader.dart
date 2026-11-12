import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

class EnvLoader {
  static final Map<String, String> _env = {};

  static Future<void> load() async {
    // 1. Search candidate file paths relative to current execution directory
    final possiblePaths = [
      '../../.env',
      '../../../.env',
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

    // 2. Ascend from Directory.current up to drive root looking for .env
    try {
      var dir = Directory.current;
      for (int i = 0; i < 6; i++) {
        final f = File('${dir.path}/.env');
        if (f.existsSync()) {
          _parseLines(await f.readAsLines());
          if (_env.isNotEmpty) return;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    // 3. Ascend from Platform.resolvedExecutable (useful for compiled desktop builds)
    try {
      var dir = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 6; i++) {
        final f = File('${dir.path}/.env');
        if (f.existsSync()) {
          _parseLines(await f.readAsLines());
          if (_env.isNotEmpty) return;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    // 4. Flutter asset bundle fallbacks
    for (final assetPath in const ['../../.env', '.env', 'assets/.env']) {
      try {
        final content = await rootBundle.loadString(assetPath);
        if (content.trim().isNotEmpty) {
          _parseLines(content.split('\n'));
          if (_env.isNotEmpty) return;
        }
      } catch (_) {}
    }
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

  static bool has(String key) {
    return _env.containsKey(key) || Platform.environment.containsKey(key);
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
      case 'google':
        return LlmProvider.gemini;
      case 'ollama':
        return LlmProvider.ollama;
      case 'openai-compatible':
      case 'openaicompatible':
      case 'lmstudio':
      case 'vllm':
      case 'hypura':
        return LlmProvider.openaiCompatible;
      case 'mistral':
        return LlmProvider.mistral;
      default:
        return LlmProvider.none;
    }
  }
}

