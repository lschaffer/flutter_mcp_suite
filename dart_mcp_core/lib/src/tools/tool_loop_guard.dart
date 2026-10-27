import 'dart:convert';

/// Action to take based on tool loop evaluation.
enum LoopAction {
  /// The tool call is normal and permitted to execute.
  allow,

  /// Warning threshold reached (3x consecutive identical calls or alternating pattern).
  warn,

  /// Critical loop threshold reached (4x+ consecutive identical calls). Execution is blocked.
  block,
}

/// Evaluation result for an upcoming tool call.
class LoopEvaluation {
  final LoopAction action;
  final int repeatCount;
  final String? message;

  const LoopEvaluation({
    required this.action,
    this.repeatCount = 1,
    this.message,
  });

  bool get isBlocked => action == LoopAction.block;
  bool get isWarning => action == LoopAction.warn;
  bool get isAllowed => action == LoopAction.allow;
}

/// Built-in protection against model infinite loops and repetitive tool execution.
///
/// If the model invokes the exact same tool with identical arguments consecutively,
/// a loop warning is injected at 3x to force strategy adjustment, and execution is
/// completely blocked at 4x+.
///
/// Whenever a different tool or modified arguments are executed, this repetition
/// counter is automatically reset. Also detects 2-step alternating loops (A -> B -> A -> B -> A -> B).
class ToolLoopGuard {
  String _lastSignature = '';
  int _consecutiveRepeats = 0;
  final List<String> _history = [];

  /// Current number of consecutive executions with identical signature.
  int get consecutiveRepeats => _consecutiveRepeats;

  /// Evaluates an upcoming tool call against repetition thresholds.
  ///
  /// Resets the repetition counter to 1 if tool name or arguments differ.
  LoopEvaluation evaluate(String toolName, Map<String, dynamic> args) {
    // Canonicalize arguments JSON representation for exact comparison
    final signature = '$toolName::${_canonicalJson(args)}';
    _history.add(signature);
    if (_history.length > 12) _history.removeAt(0);

    if (signature == _lastSignature) {
      _consecutiveRepeats++;
    } else {
      // Different tool or modified arguments -> RESET counter!
      _lastSignature = signature;
      _consecutiveRepeats = 1;
    }

    if (_consecutiveRepeats >= 4) {
      return LoopEvaluation(
        action: LoopAction.block,
        repeatCount: _consecutiveRepeats,
        message:
            '⛔ [EXECUTION BLOCKED]: Infinite tool loop detected. Tool "$toolName" was invoked $_consecutiveRepeats times consecutively with identical parameters without making progress. Execution halted. Please analyze why this failed and summarize your answer to the user.',
      );
    } else if (_consecutiveRepeats == 3) {
      return LoopEvaluation(
        action: LoopAction.warn,
        repeatCount: _consecutiveRepeats,
        message:
            '⚠️ [LOOP WARNING]: You have executed "$toolName" with identical parameters 3 times consecutively and received the same result. Do NOT repeat this call. Modify your parameters, switch to a different tool, or provide your final response.',
      );
    }

    // Check for 2-step alternating loop (A -> B -> A -> B -> A -> B)
    if (_history.length >= 6) {
      final h = _history;
      final len = h.length;
      if (h[len - 1] == h[len - 3] &&
          h[len - 3] == h[len - 5] &&
          h[len - 2] == h[len - 4]) {
        return const LoopEvaluation(
          action: LoopAction.warn,
          repeatCount: 3,
          message:
              '⚠️ [ALTERNATING LOOP WARNING]: You are alternating between two repetitive tool calls. Please stop repeating these calls and proceed with an alternative approach or report to the user.',
        );
      }
    }

    return LoopEvaluation(action: LoopAction.allow, repeatCount: _consecutiveRepeats);
  }

  /// Sort map keys recursively for deterministic signature matching.
  static String _canonicalJson(dynamic obj) {
    if (obj is Map) {
      final sortedKeys = obj.keys.map((k) => k.toString()).toList()..sort();
      final sortedMap = <String, dynamic>{};
      for (final k in sortedKeys) {
        sortedMap[k] = obj[k];
      }
      return jsonEncode(sortedMap);
    }
    return jsonEncode(obj);
  }

  /// Resets the loop guard state.
  void reset() {
    _lastSignature = '';
    _consecutiveRepeats = 0;
    _history.clear();
  }
}
