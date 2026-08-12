import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:mcp_playground_dart/mcp_playground_dart.dart' as mp;

import 'genui_catalog.dart';

/// The kind of an entry in the GenUI chat transcript.
enum GenuiChatEntryKind {
  /// A message written by the user.
  user,

  /// A message produced by the model (streamed text).
  assistant,

  /// An error produced while handling a request.
  error,
}

/// A single entry in the GenUI chat transcript.
class GenuiChatEntry {
  /// Creates a [GenuiChatEntry].
  const GenuiChatEntry({
    required this.id,
    required this.kind,
    required this.text,
  });

  /// Stable unique identifier.
  final String id;

  /// The kind of the entry.
  final GenuiChatEntryKind kind;

  /// The text content of the entry.
  final String text;
}

/// A [ChangeNotifier] that bridges [`mcp_playground_dart`](https://pub.dev/packages/mcp_playground_dart)'s
/// [mp.LLMService] to a GenUI conversation pipeline.
///
/// It wires together a GenUI [SurfaceController], an [A2uiTransportAdapter] and
/// a [Conversation]. The transport's `onSend` callback routes each outgoing
/// message through [mp.LLMService.generateStream], streams the raw text chunks
/// back into GenUI (which parses embedded A2UI JSON), and executes any local
/// [mp.McpLocalTool] calls requested by the model in an agent loop.
class McpGenuiChatController extends ChangeNotifier {
  /// Creates a [McpGenuiChatController].
  ///
  /// Either [catalog] or [catalogJson] / [catalogItems] may be used to define
  /// the widgets the model is allowed to generate. When none are provided a
  /// default catalog is built containing the GenUI basic catalog plus the
  /// default chat-bubble item.
  McpGenuiChatController({
    required mp.LlmConfig llmConfig,
    List<mp.McpLocalTool> tools = const [],
    String? systemPrompt,
    Catalog? catalog,
    String? catalogJson,
    List<GenuiCatalogItemDefinition>? catalogItems,
    this.maxToolIterations = 10,
  }) {
    _llmConfig = llmConfig;
    _tools = List.of(tools);
    _systemPrompt = systemPrompt;
    _catalog =
        catalog ??
        buildGenuiCatalog(catalogJson: catalogJson, catalogItems: catalogItems);
    _surfaceController = SurfaceController(catalogs: [_catalog]);
    _transport = A2uiTransportAdapter(onSend: _handleSend);
    _conversation = Conversation(
      controller: _surfaceController,
      transport: _transport,
    );
  }

  late final mp.LlmConfig _llmConfig;
  late final List<mp.McpLocalTool> _tools;
  late final String? _systemPrompt;
  late final Catalog _catalog;

  /// Maximum number of tool-call round trips per user request.
  final int maxToolIterations;

  late final SurfaceController _surfaceController;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;

  final List<GenuiChatEntry> _entries = [];
  final List<mp.ChatMessage> _history = [];
  String? _cachedSystemPrompt;

  bool _isGenerating = false;

  /// The GenUI [SurfaceController] backing this chat.
  SurfaceController get surfaceController => _surfaceController;

  /// The GenUI [Conversation] facade.
  Conversation get conversation => _conversation;

  /// The [Catalog] in use.
  Catalog get catalog => _catalog;

  /// Whether a request is currently being generated.
  bool get isGenerating => _isGenerating;

  /// The chat transcript entries (user + assistant text).
  List<GenuiChatEntry> get entries => List.unmodifiable(_entries);

  /// The IDs of the currently active GenUI surfaces.
  Iterable<String> get activeSurfaceIds => _surfaceController.activeSurfaceIds;

  /// Returns the [SurfaceContext] for [surfaceId].
  SurfaceContext contextFor(String surfaceId) =>
      _surfaceController.contextFor(surfaceId);

  /// Sends a user message into the conversation.
  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isGenerating) return;

    _entries.add(
      GenuiChatEntry(
        id: _newId(),
        kind: GenuiChatEntryKind.user,
        text: trimmed,
      ),
    );
    notifyListeners();

    _conversation.sendRequest(ChatMessage.user(trimmed));
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    final prompt = _messageToPrompt(message);
    _history.add(
      mp.ChatMessage(
        id: _newId(),
        content: prompt,
        role: mp.ChatRole.user,
        timestamp: DateTime.now(),
      ),
    );

    final assistantEntryId = _newId();
    final assistantBuffer = StringBuffer();

    try {
      for (var iteration = 0; iteration < maxToolIterations; iteration++) {
        mp.LLMResponse? finalResponse;
        final mcpTools = _tools.map((t) => t.toMCPTool()).toList();

        await for (final chunk in mp.LLMService.generateStream(
          config: _llmConfig,
          messages: List.unmodifiable(_history),
          tools: mcpTools,
          systemPrompt: _effectiveSystemPrompt,
        )) {
          if (chunk.textDelta.isNotEmpty) {
            assistantBuffer.write(chunk.textDelta);
            _transport.addChunk(chunk.textDelta);
            _upsertEntry(
              assistantEntryId,
              assistantBuffer.toString(),
              GenuiChatEntryKind.assistant,
            );
          }
          if (chunk.isDone) {
            finalResponse = chunk.finalResponse;
          }
        }

        final assistantText = assistantBuffer.toString();
        if (assistantText.isNotEmpty) {
          _history.add(
            mp.ChatMessage(
              id: _newId(),
              content: assistantText,
              role: mp.ChatRole.assistant,
              timestamp: DateTime.now(),
            ),
          );
        }

        final toolCalls = finalResponse?.toolCalls ?? const <mp.LLMToolCall>[];
        if (toolCalls.isEmpty) break;

        for (final call in toolCalls) {
          _history.add(
            mp.ChatMessage(
              id: _newId(),
              content: '',
              role: mp.ChatRole.assistant,
              timestamp: DateTime.now(),
              type: mp.MessageType.toolCall,
              toolName: call.name,
              toolArguments: call.arguments,
            ),
          );
        }

        for (final call in toolCalls) {
          final result = await _executeTool(call);
          _history.add(
            mp.ChatMessage(
              id: _newId(),
              content: result.content.map((c) => c.text ?? '').join('\n'),
              role: mp.ChatRole.tool,
              timestamp: DateTime.now(),
              type: mp.MessageType.toolResponse,
              toolResult: result,
            ),
          );
        }
      }
    } catch (error) {
      _entries.add(
        GenuiChatEntry(
          id: _newId(),
          kind: GenuiChatEntryKind.error,
          text: 'Generation error: $error',
        ),
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<mp.MCPToolResult> _executeTool(mp.LLMToolCall call) async {
    for (final tool in _tools) {
      if (tool.name == call.name) {
        try {
          return await tool.execute(call.arguments);
        } catch (error) {
          return mp.MCPToolResult(
            content: [mp.MCPContent(type: 'text', text: 'Tool error: $error')],
            isError: true,
          );
        }
      }
    }
    return mp.MCPToolResult(
      content: [
        mp.MCPContent(type: 'text', text: 'Unknown tool: ${call.name}'),
      ],
      isError: true,
    );
  }

  String get _effectiveSystemPrompt {
    final cached = _cachedSystemPrompt;
    if (cached != null) return cached;

    final extra = _systemPrompt;
    final buffer = StringBuffer(
      PromptBuilder.chat(catalog: _catalog).systemPromptJoined(),
    );
    if (extra != null && extra.trim().isNotEmpty) {
      buffer.writeln('\n\n### Additional instructions');
      buffer.writeln(extra);
    }
    return _cachedSystemPrompt = buffer.toString();
  }

  /// Converts an incoming GenUI [ChatMessage] into a prompt string for the LLM.
  ///
  /// Plain text messages are passed through verbatim. UI interaction messages
  /// (emitted by [UserActionEvent]s such as a form submit) are translated into
  /// a natural-language instruction containing the submitted parameters.
  String _messageToPrompt(ChatMessage message) {
    final buffer = StringBuffer();
    if (message.text.trim().isNotEmpty) {
      buffer.writeln(message.text);
    }

    for (final part in message.parts) {
      if (part is DataPart &&
          part.mimeType == UiPartConstants.interactionMimeType) {
        try {
          final decoded =
              jsonDecode(utf8.decode(part.bytes)) as Map<String, Object?>;
          final action = decoded['action'] as Map<String, Object?>?;
          final name = action?['name']?.toString();
          final context = action?['context'] as Map<String, Object?>?;
          buffer.writeln(
            'A user action "$name" was submitted with the following '
            'parameters: ${jsonEncode(context ?? const <String, Object?>{})}. '
            'Use these parameters to call the appropriate tool and render the '
            'resulting widget.',
          );
        } catch (_) {
          // Ignore malformed interaction payloads.
        }
      }
    }

    final prompt = buffer.toString().trim();
    return prompt.isEmpty ? message.text : prompt;
  }

  void _upsertEntry(String id, String text, GenuiChatEntryKind kind) {
    final index = _entries.indexWhere((e) => e.id == id);
    final entry = GenuiChatEntry(id: id, kind: kind, text: text);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    notifyListeners();
  }

  String _newId() =>
      'genui_${DateTime.now().microsecondsSinceEpoch}_'
      '${_entries.length}_${_history.length}';

  @override
  void dispose() {
    _conversation.dispose();
    _transport.dispose();
    _surfaceController.dispose();
    super.dispose();
  }
}
