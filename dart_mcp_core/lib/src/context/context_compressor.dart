import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../llm/llm_service.dart';

/// Result returned after a context compression pass.
class CompressionResult {
  /// The updated message list with older turns replaced by a summary.
  final List<ChatMessage> compressedMessages;

  /// Estimated tokens in the message history before compression.
  final int originalTokens;

  /// Estimated tokens in the message history after compression.
  final int compressedTokens;

  /// The generated summary text.
  final String summary;

  /// The number of conversation turns that were compressed into the summary.
  final int compressedTurnCount;

  const CompressionResult({
    required this.compressedMessages,
    required this.originalTokens,
    required this.compressedTokens,
    required this.summary,
    required this.compressedTurnCount,
  });

  /// Ratio of compressed tokens to original tokens (e.g. 0.35 means 65% reduction).
  double get compressionRatio =>
      originalTokens > 0 ? compressedTokens / originalTokens : 1.0;
}

/// Context window auto-compressor for long-running agent workflows and SLMs.
///
/// Monitors the estimated token count of conversation history. When the
/// token threshold is exceeded, it prompts the model to summarize earlier
/// conversation turns into a compact summary, preserving key facts, user intents,
/// tool results, and decisions while keeping the most recent turns untouched.
class ContextCompressor {
  /// Estimated token count threshold above which auto-compression is triggered.
  /// Defaults to 4000 tokens (ideal for 8k on-device models like Gemini Nano).
  final int tokenThreshold;

  /// Number of most recent messages to keep uncompressed.
  /// Defaults to 4 (e.g. latest user prompt, tool call, and responses).
  final int preserveRecentCount;

  /// Custom prompt instructions for generating the summary.
  final String? customSummaryPrompt;

  static const Uuid _uuid = Uuid();

  const ContextCompressor({
    this.tokenThreshold = 4000,
    this.preserveRecentCount = 4,
    this.customSummaryPrompt,
  });

  /// Fast pure-Dart estimation of token count (~4 characters per token average).
  int estimateTokens(List<ChatMessage> messages, {String? systemPrompt}) {
    int charCount = systemPrompt?.length ?? 0;
    for (final m in messages) {
      charCount += m.content.length;
      if (m.toolName != null) charCount += m.toolName!.length + 10;
      if (m.toolResult != null) {
        charCount += m.toolResult!.text.length;
      }
    }
    return (charCount / 4).ceil();
  }

  /// Determines whether [messages] exceed [tokenThreshold] and can be compressed.
  bool shouldCompress(List<ChatMessage> messages, {String? systemPrompt}) {
    if (messages.length <= preserveRecentCount + 1) return false;
    final tokens = estimateTokens(messages, systemPrompt: systemPrompt);
    return tokens >= tokenThreshold;
  }

  /// Compresses [messages] by asking [LLMService.generate] to summarize the older portion
  /// (from index 0 to `messages.length - preserveRecentCount`).
  ///
  /// Returns a [CompressionResult] with the new messages list:
  /// 1. A summary system message containing the distilled historical context.
  /// 2. The untouched [preserveRecentCount] latest messages.
  Future<CompressionResult> compress({
    required List<ChatMessage> messages,
    required LlmConfig llmConfig,
    String? systemPrompt,
  }) async {
    final totalMessages = messages.length;
    final splitIndex = totalMessages - preserveRecentCount;
    if (splitIndex <= 0) {
      final currentTokens = estimateTokens(messages, systemPrompt: systemPrompt);
      return CompressionResult(
        compressedMessages: List.of(messages),
        originalTokens: currentTokens,
        compressedTokens: currentTokens,
        summary: '',
        compressedTurnCount: 0,
      );
    }

    final oldMessages = messages.sublist(0, splitIndex);
    final recentMessages = messages.sublist(splitIndex);

    final originalTokens = estimateTokens(messages, systemPrompt: systemPrompt);

    // Build the transcript text for older messages
    final buffer = StringBuffer();
    for (final msg in oldMessages) {
      final roleStr = msg.role.name.toUpperCase();
      buffer.writeln('[$roleStr]: ${msg.content}');
      if (msg.toolName != null) {
        buffer.writeln('[TOOL CALLED: ${msg.toolName}]');
      }
      if (msg.toolResult != null) {
        final t = msg.toolResult!.text;
        final snippet = t.length > 400 ? '${t.substring(0, 400)}...[truncated]' : t;
        buffer.writeln('[TOOL RESULT]: $snippet');
      }
    }

    final instructions = customSummaryPrompt ??
        'Summarize the following conversation history concisely in bullet points. '
        'Retain all key facts, user goals, decisions, constraints, and tool results. '
        'Do not add commentary, output only the bulleted summary:';
    final promptText = '$instructions\n\n$buffer';

    final summaryRequest = [
      ChatMessage(
        id: _uuid.v4(),
        content: promptText,
        role: ChatRole.user,
        timestamp: DateTime.now(),
      ),
    ];

    String summary;
    try {
      final response = await LLMService.generate(
        config: llmConfig,
        messages: summaryRequest,
        tools: const [],
        systemPrompt:
            'You are a conversation summarizer. Distill history into dense, factual bullet points.',
      );
      summary = response.text.trim();
    } catch (_) {
      // Fallback: create a basic truncated outline if model call fails
      summary = oldMessages
          .where((m) => m.content.isNotEmpty)
          .take(5)
          .map((m) {
            final preview = m.content.length > 80
                ? '${m.content.substring(0, 80)}...'
                : m.content;
            return '- ${m.role.name}: ${preview.replaceAll('\n', ' ')}';
          })
          .join('\n');
    }

    final summaryMessage = ChatMessage(
      id: _uuid.v4(),
      content: '[Prior Conversation Summary]:\n$summary',
      role: ChatRole.system,
      type: MessageType.log,
      timestamp: DateTime.now(),
    );

    final compressedList = <ChatMessage>[
      summaryMessage,
      ...recentMessages,
    ];

    final compressedTokens = estimateTokens(compressedList, systemPrompt: systemPrompt);

    return CompressionResult(
      compressedMessages: compressedList,
      originalTokens: originalTokens,
      compressedTokens: compressedTokens,
      summary: summary,
      compressedTurnCount: oldMessages.length,
    );
  }
}
