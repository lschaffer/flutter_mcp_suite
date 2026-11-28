/// Represents a tool call requested by the LLM.
class LLMToolCall {
  /// Unique identifier of the tool call instance.
  final String id;

  /// The name of the tool function to call.
  final String name;

  /// The input parameters mapped as arguments for the tool execution.
  final Map<String, dynamic> arguments;

  /// Creates a new [LLMToolCall] instance.
  const LLMToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

/// Token usage report for an LLM turn.
class LLMUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const LLMUsage({
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
  });

  Map<String, dynamic> toJson() => {
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'totalTokens': totalTokens,
      };

  factory LLMUsage.fromJson(Map<String, dynamic> json) => LLMUsage(
        promptTokens: json['promptTokens'] as int? ?? 0,
        completionTokens: json['completionTokens'] as int? ?? 0,
        totalTokens: json['totalTokens'] as int? ?? 0,
      );
}

/// Represents the completion response returned by the LLM.
class LLMResponse {
  /// The textual response content from the LLM.
  final String text;

  /// The list of tool calls requested by the LLM in this response.
  final List<LLMToolCall> toolCalls;

  /// Optional token usage reported by provider.
  final LLMUsage? usage;

  /// Creates a new [LLMResponse] instance.
  const LLMResponse({
    required this.text,
    this.toolCalls = const [],
    this.usage,
  });
}

/// Exception thrown when an LLM streaming response terminates prematurely
/// (e.g., socket drop, stream error, or inactivity timeout) before a clean
/// completion marker (`finish_reason` / `isDone`) is received.
class IncompleteStreamException implements Exception {
  /// Human-readable description of why the stream was considered incomplete.
  final String message;

  /// Any partial text accumulated before the stream terminated prematurely.
  final String partialText;

  /// Optional underlying transport or timeout error that caused the drop.
  final Object? cause;

  const IncompleteStreamException(
    this.message, {
    this.partialText = '',
    this.cause,
  });

  @override
  String toString() =>
      'IncompleteStreamException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Represents a chunk of text or progress emitted during a streaming LLM call.
class LLMStreamChunk {
  /// The incremental text piece.
  final String textDelta;

  /// True when this is the final chunk in the stream.
  final bool isDone;

  /// The final full response containing the accumulated text and tool calls.
  /// This field is only non-null when [isDone] is true.
  final LLMResponse? finalResponse;

  /// Optional non-content progress or heartbeat message emitted while the model
  /// is reasoning or buffering tool call arguments (e.g. `'Model reasoning...'`).
  final String? statusMessage;

  /// Creates a new [LLMStreamChunk] instance.
  const LLMStreamChunk({
    required this.textDelta,
    this.isDone = false,
    this.finalResponse,
    this.statusMessage,
  });
}
