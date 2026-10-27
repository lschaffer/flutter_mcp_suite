import 'dart:io';
import 'package:path/path.dart' as p;

/// Configuration and runtime limits for MCP conversations, tool calls, and sessions.
class McpExecutionLimits {
  /// Default: 500 conversation turns. Once 500 turns are reached, auto-save automatically rotates to a new session file.
  final int maxTurns;

  /// Default: 0 (unlimited). Restricts maximum conversational turns in a session.
  final int turnLimit;

  /// Default: 30 calls per turn (0 = unlimited). Restricts total tool invocations per prompt turn before synthesizing response.
  final int maxToolCalls;

  const McpExecutionLimits({
    this.maxTurns = 500,
    this.turnLimit = 0,
    this.maxToolCalls = 30,
  });

  /// Alias for [maxToolCalls] compatibility with earlier versions.
  int get maxToolIterations => maxToolCalls;

  McpExecutionLimits copyWith({
    int? maxTurns,
    int? turnLimit,
    int? maxToolCalls,
  }) {
    return McpExecutionLimits(
      maxTurns: maxTurns ?? this.maxTurns,
      turnLimit: turnLimit ?? this.turnLimit,
      maxToolCalls: maxToolCalls ?? this.maxToolCalls,
    );
  }

  Map<String, dynamic> toJson() => {
    'max_turns': maxTurns,
    'turn_limit': turnLimit,
    'max_tool_calls': maxToolCalls,
  };

  factory McpExecutionLimits.fromJson(Map<String, dynamic> json) {
    final maxTurnsVal = json['max_turns'] ?? json['maxTurns'];
    final turnLimitVal = json['turn_limit'] ?? json['turnLimit'];
    final maxToolCallsVal =
        json['max_tool_calls'] ??
        json['max_tool_iterations'] ??
        json['maxToolCalls'] ??
        json['maxToolIterations'];

    return McpExecutionLimits(
      maxTurns: maxTurnsVal is int ? maxTurnsVal : int.tryParse(maxTurnsVal?.toString() ?? '') ?? 500,
      turnLimit: turnLimitVal is int ? turnLimitVal : int.tryParse(turnLimitVal?.toString() ?? '') ?? 0,
      maxToolCalls: maxToolCallsVal is int
          ? maxToolCallsVal
          : int.tryParse(maxToolCallsVal?.toString() ?? '') ?? 30,
    );
  }
}

/// Helper for session auto-rotation when turn thresholds (e.g., [maxTurns]) or file size limits are exceeded.
class SessionRotator {
  final String sessionDir;
  final int maxTurns;
  final int maxSizeBytes;
  final String filePattern;

  String? _currentSessionFilePath;
  int _currentTurnCount = 0;

  SessionRotator({
    required this.sessionDir,
    this.maxTurns = 500,
    this.maxSizeBytes = 10 * 1024 * 1024, // 10MB
    this.filePattern = 'session_{timestamp}_{id}.json',
  });

  String? get currentSessionFilePath => _currentSessionFilePath;
  int get currentTurnCount => _currentTurnCount;

  /// Checks if rotation is needed and returns a valid session file path.
  String ensureSessionFile({required String sessionId, int? turnCount}) {
    if (turnCount != null) {
      _currentTurnCount = turnCount;
    }

    bool needsRotation = false;
    if (_currentSessionFilePath != null) {
      final file = File(_currentSessionFilePath!);
      if (file.existsSync()) {
        try {
          if (file.lengthSync() >= maxSizeBytes) {
            needsRotation = true;
          }
        } catch (_) {}
      }
    }

    if (_currentTurnCount >= maxTurns) {
      needsRotation = true;
    }

    if (_currentSessionFilePath == null || needsRotation) {
      final dir = Directory(sessionDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final ts = DateTime.now()
          .toIso8601String()
          .substring(0, 19)
          .replaceAll(':', '-')
          .replaceAll('T', '_');
      final shortId = sessionId.length >= 8 ? sessionId.substring(0, 8) : sessionId;
      final fileName = filePattern
          .replaceAll('{timestamp}', ts)
          .replaceAll('{id}', shortId);
      _currentSessionFilePath = p.join(sessionDir, fileName);
      _currentTurnCount = 0;
    }

    return _currentSessionFilePath!;
  }

  void incrementTurn() {
    _currentTurnCount++;
  }

  void reset() {
    _currentSessionFilePath = null;
    _currentTurnCount = 0;
  }
}
