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

  /// Optional archive ID referencing the stashed raw messages in [EpisodicMemoryStore].
  final String? archiveId;

  const CompressionResult({
    required this.compressedMessages,
    required this.originalTokens,
    required this.compressedTokens,
    required this.summary,
    required this.compressedTurnCount,
    this.archiveId,
  });

  /// Ratio of compressed tokens to original tokens (e.g. 0.35 means 65% reduction).
  double get compressionRatio =>
      originalTokens > 0 ? compressedTokens / originalTokens : 1.0;
}

/// Represents a stashed chunk of raw conversation turns in episodic memory.
class EpisodicMemoryEntry {
  final String archiveId;
  final int startTurnIndex;
  final int endTurnIndex;
  final DateTime timestamp;
  final List<ChatMessage> rawMessages;
  final String summary;

  const EpisodicMemoryEntry({
    required this.archiveId,
    required this.startTurnIndex,
    required this.endTurnIndex,
    required this.timestamp,
    required this.rawMessages,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'archiveId': archiveId,
        'startTurnIndex': startTurnIndex,
        'endTurnIndex': endTurnIndex,
        'timestamp': timestamp.toIso8601String(),
        'rawMessages': rawMessages.map((m) => m.toJson()).toList(),
        'summary': summary,
      };

  factory EpisodicMemoryEntry.fromJson(Map<String, dynamic> json) =>
      EpisodicMemoryEntry(
        archiveId: json['archiveId'] as String,
        startTurnIndex: json['startTurnIndex'] as int? ?? 0,
        endTurnIndex: json['endTurnIndex'] as int? ?? 0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        rawMessages: (json['rawMessages'] as List? ?? [])
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        summary: json['summary'] as String? ?? '',
      );
}

/// In-memory and indexable episodic memory store for compressed conversation turns.
class EpisodicMemoryStore {
  final List<EpisodicMemoryEntry> _entries = [];

  EpisodicMemoryStore([List<EpisodicMemoryEntry>? initialEntries]) {
    if (initialEntries != null) {
      _entries.addAll(initialEntries);
    }
  }

  List<EpisodicMemoryEntry> get entries => List.unmodifiable(_entries);

  void addEntry(EpisodicMemoryEntry entry) {
    _entries.add(entry);
  }

  /// Searches archived turns by keyword query across summary, message content, and tool results.
  List<EpisodicMemoryEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return _entries.where((e) {
      if (e.summary.toLowerCase().contains(q)) return true;
      for (final m in e.rawMessages) {
        if (m.content.toLowerCase().contains(q)) return true;
        if (m.toolName != null && m.toolName!.toLowerCase().contains(q)) {
          return true;
        }
        if (m.toolResult != null &&
            m.toolResult!.text.toLowerCase().contains(q)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Looks up an entry by its archive ID.
  EpisodicMemoryEntry? getById(String archiveId) {
    try {
      return _entries.firstWhere((e) => e.archiveId == archiveId);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _entries.clear();
  }

  /// Bulk loads entries into the episodic memory store.
  /// If [replace] is true (default is false), clears existing entries first.
  void loadEntries(List<EpisodicMemoryEntry> entries, {bool replace = false}) {
    if (replace) {
      _entries.clear();
    }
    _entries.addAll(entries);
  }

  /// Bulk loads entries from a serialized list of JSON maps (e.g. from DuckDB or disk).
  void loadFromJsonList(List<dynamic> jsonList, {bool replace = false}) {
    final parsed = jsonList
        .whereType<Map<String, dynamic>>()
        .map(EpisodicMemoryEntry.fromJson)
        .toList();
    loadEntries(parsed, replace: replace);
  }

  /// Serializes all entries to a list of JSON-encodable maps.
  List<Map<String, dynamic>> toJsonList() =>
      _entries.map((e) => e.toJson()).toList();

  /// Bulk serialization of all entries into a map.
  Map<String, dynamic> toJson() => {
        'entries': toJsonList(),
      };

  /// Restores an [EpisodicMemoryStore] from a serialized map.
  factory EpisodicMemoryStore.fromJson(Map<String, dynamic> json) {
    final store = EpisodicMemoryStore();
    final rawEntries = json['entries'];
    if (rawEntries is List) {
      store.loadFromJsonList(rawEntries, replace: true);
    }
    return store;
  }
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

  /// Optional episodic memory store for stashing raw conversation turns before compression.
  final EpisodicMemoryStore? memoryStore;

  static const Uuid _uuid = Uuid();

  const ContextCompressor({
    this.tokenThreshold = 4000,
    this.preserveRecentCount = 4,
    this.customSummaryPrompt,
    this.memoryStore,
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

    final archiveId = 'mem_${_uuid.v4().substring(0, 8)}';
    if (memoryStore != null) {
      final entry = EpisodicMemoryEntry(
        archiveId: archiveId,
        startTurnIndex: 0,
        endTurnIndex: oldMessages.length,
        timestamp: DateTime.now(),
        rawMessages: List.unmodifiable(oldMessages),
        summary: summary,
      );
      memoryStore!.addEntry(entry);
    }

    final summaryMessage = ChatMessage(
      id: _uuid.v4(),
      content:
          '[Prior Conversation Summary] (Archive ID: $archiveId):\n$summary\n\n'
          '(Tip: If verbatim details, code snippets, or parameters from earlier turns are needed, '
          'use retrieve_memory tool with archiveId: "$archiveId" or a search query.)',
      role: ChatRole.system,
      type: MessageType.log,
      timestamp: DateTime.now(),
    );

    final compressedList = <ChatMessage>[
      summaryMessage,
      ...recentMessages,
    ];

    final compressedTokens =
        estimateTokens(compressedList, systemPrompt: systemPrompt);

    return CompressionResult(
      compressedMessages: compressedList,
      originalTokens: originalTokens,
      compressedTokens: compressedTokens,
      summary: summary,
      compressedTurnCount: oldMessages.length,
      archiveId: archiveId,
    );
  }
}
