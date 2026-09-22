import 'dart:convert';

import 'package:genui/genui.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart' as mp;
import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';

import 'genui_catalog.dart';

/// The kind of an entry in the GenUI chat transcript.
enum GenuiChatEntryKind {
  /// A message written by the user.
  user,

  /// A message produced by the model (streamed text).
  assistant,

  /// An error produced while handling a request.
  error,

  /// An active GenUI surface widget.
  surface,
}

/// A single entry in the GenUI chat transcript.
class GenuiChatEntry {
  /// Creates a [GenuiChatEntry].
  const GenuiChatEntry({
    required this.id,
    required this.kind,
    required this.text,
    this.surfaceId,
    this.attachments,
  });

  /// Stable unique identifier.
  final String id;

  /// The kind of the entry.
  final GenuiChatEntryKind kind;

  /// The text content of the entry.
  final String text;

  /// The surface ID if this is a surface entry.
  final String? surfaceId;

  /// Optional attachments attached to this message.
  final List<mp.MessageAttachment>? attachments;
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
  /// default catalog with standard GenUI widgets is created.
  McpGenuiChatController({
    required this._llmConfig,
    List<mp.McpLocalTool> tools = const [],
    Catalog? catalog,
    List<GenuiCatalogItemDefinition>? catalogItems,
    String? catalogJson,
    List<ClientFunction>? clientFunctions,
    this._systemPrompt,
    this.maxToolIterations = 10,
    this._playgroundController,
  }) : _tools = List.unmodifiable(tools),
       _catalog =
           catalog != null
               ? (clientFunctions != null
                   ? catalog.copyWith(newFunctions: clientFunctions)
                   : catalog)
               : buildGenuiCatalog(
                 catalogJson: catalogJson,
                 catalogItems: catalogItems,
                 clientFunctions: clientFunctions,
               ) {
    _transport = A2uiTransportAdapter(onSend: _handleSend);
    _surfaceController = SurfaceController(catalogs: [_catalog]);
    _conversation = Conversation(
      controller: _surfaceController,
      transport: _transport,
    );
  }

  final PlaygroundController? _playgroundController;
  final mp.LlmConfig _llmConfig;
  final List<mp.McpLocalTool> _tools;
  final String? _systemPrompt;
  final Catalog _catalog;
  final int maxToolIterations;

  late final A2uiTransportAdapter _transport;
  late final SurfaceController _surfaceController;
  late final Conversation _conversation;

  final List<GenuiChatEntry> _entries = [];
  final List<mp.ChatMessage> _history = [];
  final Set<String> _knownSurfaces = {};
  String? _cachedSystemPrompt;
  List<mp.MessageAttachment>? _pendingAttachments;

  bool _isGenerating = false;

  void _syncSurfaces() {
    for (final sId in _surfaceController.activeSurfaceIds) {
      if (_knownSurfaces.add(sId)) {
        _entries.add(
          GenuiChatEntry(
            id: 'surface_$sId',
            kind: GenuiChatEntryKind.surface,
            text: '',
            surfaceId: sId,
          ),
        );
      }
    }
  }

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
  void sendMessage(String text, {List<mp.MessageAttachment>? attachments}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (attachments == null || attachments.isEmpty)) return;
    if (_isGenerating) return;

    _pendingAttachments = attachments != null && attachments.isNotEmpty
        ? List.unmodifiable(attachments)
        : null;

    final entryText = trimmed.isNotEmpty
        ? trimmed
        : (attachments != null && attachments.isNotEmpty
              ? 'Attached: ${attachments.map((a) => a.name).join(', ')}'
              : '');

    _entries.add(
      GenuiChatEntry(
        id: _newId(),
        kind: GenuiChatEntryKind.user,
        text: entryText,
        attachments: attachments != null
            ? List.unmodifiable(attachments)
            : null,
      ),
    );
    notifyListeners();

    _conversation.sendRequest(ChatMessage.user(entryText));
  }

  Future<void> _handleSend(ChatMessage message) async {
    if (_isGenerating) return;
    _isGenerating = true;
    notifyListeners();

    final atts = _pendingAttachments;
    _pendingAttachments = null;

    final prompt = _messageToPrompt(message);
    final userDisplay = _messageToDisplayJson(message);
    if (message.text.isEmpty && userDisplay.isNotEmpty) {
      _entries.add(
        GenuiChatEntry(
          id: _newId(),
          kind: GenuiChatEntryKind.user,
          text: userDisplay,
        ),
      );
    }

    // Preprocess text files and images directly into effective prompt & vision attachments
    String effectivePrompt = prompt;
    final List<mp.MessageAttachment> visionAttachments = [];

    if (atts != null && atts.isNotEmpty) {
      final buffer = StringBuffer(effectivePrompt);
      for (final att in atts) {
        final mime = att.mimeType.toLowerCase();
        final name = att.name.toLowerCase();
        final isText = isTextFile(mime, name);

        if (isText && att.bytes != null) {
          try {
            final content = utf8.decode(att.bytes!);
            buffer.writeln('\n\n[Attached File: ${att.name}]');
            buffer.writeln('--- CONTENT START ---');
            buffer.writeln(content);
            buffer.writeln('--- CONTENT END ---');
          } catch (_) {}
        } else if (att.bytes != null &&
            (mime.startsWith('image/') ||
                name.endsWith('.jpg') ||
                name.endsWith('.jpeg') ||
                name.endsWith('.png') ||
                name.endsWith('.webp') ||
                name.endsWith('.gif'))) {
          visionAttachments.add(att);
          buffer.writeln('\n\n[Attached Image: ${att.name}]');
        }
      }
      effectivePrompt = buffer.toString();
    }

    final userMsg = mp.ChatMessage(
      id: _newId(),
      content: userDisplay.isNotEmpty ? userDisplay : effectivePrompt,
      role: mp.ChatRole.user,
      timestamp: DateTime.now(),
      attachments: visionAttachments.isNotEmpty ? visionAttachments : null,
    );
    _history.add(
      mp.ChatMessage(
        id: userMsg.id,
        content: effectivePrompt,
        role: mp.ChatRole.user,
        timestamp: userMsg.timestamp,
        attachments: visionAttachments.isNotEmpty ? visionAttachments : null,
      ),
    );
    _playgroundController?.addMessage(userMsg);

    final actionInfo = _extractUserAction(message);
    if (actionInfo != null) {
      mp.McpLocalTool? directTool;
      for (final t in _tools) {
        if (t.name == actionInfo.name) {
          directTool = t;
          break;
        }
      }
      if (directTool != null) {
        final toolCallId =
            'call_${directTool.name}_${DateTime.now().microsecondsSinceEpoch}';
        final toolCallMsg = mp.ChatMessage(
          id: toolCallId,
          content: '',
          role: mp.ChatRole.assistant,
          timestamp: DateTime.now(),
          type: mp.MessageType.toolCall,
          toolName: directTool.name,
          toolArguments: actionInfo.context,
        );
        _history.add(toolCallMsg);
        _playgroundController?.addMessage(toolCallMsg);

        final result = await _executeTool(
          mp.LLMToolCall(
            id: toolCallId,
            name: directTool.name,
            arguments: actionInfo.context,
          ),
        );
        final toolRespMsg = mp.ChatMessage(
          id: toolCallId,
          content: result.content.map((c) => c.text ?? '').join('\n'),
          role: mp.ChatRole.tool,
          timestamp: DateTime.now(),
          type: mp.MessageType.toolResponse,
          toolName: directTool.name,
          toolResult: result,
        );
        _history.add(toolRespMsg);
        _playgroundController?.addMessage(toolRespMsg);
      }
    }

    try {
      for (var iteration = 0; iteration < maxToolIterations; iteration++) {
        mp.LLMResponse? finalResponse;
        final mcpTools = <mp.MCPTool>[
          ..._tools.map((t) => t.toMCPTool()),
          for (final func in _catalog.functions)
            mp.MCPTool(
              name: func.name,
              description: func.description,
              inputSchema:
                  Map<String, dynamic>.from(func.argumentSchema.value),
            ),
        ];
        final iterationBuffer = StringBuffer();
        final iterationEntryId = _newId();

        await for (final chunk in mp.LLMService.generateStream(
          config: _llmConfig,
          messages: List.unmodifiable(_history),
          tools: mcpTools,
          systemPrompt: _effectiveSystemPrompt,
        )) {
          if (chunk.textDelta.isNotEmpty) {
            iterationBuffer.write(chunk.textDelta);
            _transport.addChunk(chunk.textDelta);
            _syncSurfaces();
            final cleanText = _sanitizeAssistantText(
              iterationBuffer.toString(),
            );
            if (cleanText.isNotEmpty) {
              _upsertEntry(
                iterationEntryId,
                cleanText,
                GenuiChatEntryKind.assistant,
              );
            } else {
              _removeEntry(iterationEntryId);
            }
          }
          if (chunk.isDone) {
            finalResponse = chunk.finalResponse;
            _syncSurfaces();
          }
        }

        _syncSurfaces();
        final rawIterationText = iterationBuffer.toString();
        if (rawIterationText.isNotEmpty) {
          final assistantMsg = mp.ChatMessage(
            id: iterationEntryId,
            content: rawIterationText,
            role: mp.ChatRole.assistant,
            timestamp: DateTime.now(),
          );
          _history.add(assistantMsg);
          _playgroundController?.addMessage(assistantMsg);
        }

        final cleanText = _sanitizeAssistantText(rawIterationText);
        if (cleanText.isNotEmpty) {
          _upsertEntry(
            iterationEntryId,
            cleanText,
            GenuiChatEntryKind.assistant,
          );
        } else {
          _removeEntry(iterationEntryId);
        }

        final toolCalls = finalResponse?.toolCalls ?? const <mp.LLMToolCall>[];
        if (toolCalls.isEmpty) break;

        for (final call in toolCalls) {
          final toolCallMsg = mp.ChatMessage(
            id: call.id.isNotEmpty ? call.id : _newId(),
            content: '',
            role: mp.ChatRole.assistant,
            timestamp: DateTime.now(),
            type: mp.MessageType.toolCall,
            toolName: call.name,
            toolArguments: call.arguments,
          );
          _history.add(toolCallMsg);
          _playgroundController?.addMessage(toolCallMsg);
        }

        for (final call in toolCalls) {
          final result = await _executeTool(call);
          final toolRespMsg = mp.ChatMessage(
            id: call.id.isNotEmpty ? call.id : _newId(),
            content: result.content.map((c) => c.text ?? '').join('\n'),
            role: mp.ChatRole.tool,
            timestamp: DateTime.now(),
            type: mp.MessageType.toolResponse,
            toolName: call.name,
            toolResult: result,
          );
          _history.add(toolRespMsg);
          _playgroundController?.addMessage(toolRespMsg);
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

    for (final func in _catalog.functions) {
      final matchesName = func.name == call.name ||
          func.name.toLowerCase() ==
              call.name.toLowerCase().replaceAll('_', '');
      if (matchesName) {
        try {
          final dataModel = _surfaceController.activeSurfaceIds.isNotEmpty
              ? _surfaceController
                  .contextFor(_surfaceController.activeSurfaceIds.first)
                  .dataModel
              : InMemoryDataModel();
          final context = DataContext(
            dataModel,
            DataPath('/'),
            functions: _catalog.functions,
          );

          final Object? result;
          if (func is SynchronousClientFunction) {
            result = func.executeSync(call.arguments, context);
          } else {
            result = await func.execute(call.arguments, context).first;
          }

          return mp.MCPToolResult(
            content: [
              mp.MCPContent(
                type: 'text',
                text: result is String ? result : jsonEncode(result),
              ),
            ],
          );
        } catch (error) {
          return mp.MCPToolResult(
            content: [
              mp.MCPContent(type: 'text', text: 'Function error: $error'),
            ],
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
    final activeSkill = _playgroundController?.activeSkill;
    if (activeSkill != null && activeSkill.skillDef.trim().isNotEmpty) {
      buffer.writeln('\n\n### Active Skill (${activeSkill.name}):');
      buffer.writeln(activeSkill.skillDef.trim());
    }
    final allTools = <mp.MCPTool>[
      ..._tools.map((t) => t.toMCPTool()),
      for (final func in _catalog.functions)
        mp.MCPTool(
          name: func.name,
          description: func.description,
          inputSchema:
              Map<String, dynamic>.from(func.argumentSchema.value),
        ),
    ];
    if (allTools.isNotEmpty && !_llmConfig.useNativeToolCall) {
      buffer.writeln('\n\nAvailable Tools:');
      for (final tool in allTools) {
        buffer.writeln('- Tool Name: ${tool.name}');
        if (tool.description != null && tool.description!.isNotEmpty) {
          buffer.writeln('  Description: ${tool.description}');
        }
        buffer.writeln('  Input Schema: ${jsonEncode(tool.inputSchema)}');
      }
    }
    return _cachedSystemPrompt = buffer.toString();
  }

  static final RegExp _a2uiJsonBlockRegex = RegExp(
    r'```(?:json)?\s*[\s\S]*?```|\{\s*"version"\s*:\s*"v0\.9"[\s\S]*\}',
    caseSensitive: false,
  );

  /// Strips A2UI JSON code blocks so they are not displayed in the chat view.
  static String _sanitizeAssistantText(String raw) {
    return raw.replaceAll(_a2uiJsonBlockRegex, '').trim();
  }

  /// Extracts user action name and context parameters from a GenUI [ChatMessage].
  ({String name, Map<String, dynamic> context})? _extractUserAction(
    ChatMessage message,
  ) {
    for (final part in message.parts) {
      if (part is DataPart &&
          part.mimeType == UiPartConstants.interactionMimeType) {
        try {
          final outer =
              jsonDecode(utf8.decode(part.bytes)) as Map<String, Object?>;
          final interactionStr = outer['interaction'] is String
              ? outer['interaction'] as String
              : null;
          final decoded = interactionStr != null
              ? jsonDecode(interactionStr) as Map<String, Object?>
              : outer;
          final action = decoded['action'] is Map<String, Object?>
              ? decoded['action'] as Map<String, Object?>
              : decoded;
          final name =
              action['name']?.toString() ?? decoded['name']?.toString();
          final rawContext = action['context'] is Map<String, Object?>
              ? action['context'] as Map<String, Object?>
              : (decoded['context'] is Map<String, Object?>
                    ? decoded['context'] as Map<String, Object?>
                    : null);
          if (name != null && name.isNotEmpty) {
            final Map<String, dynamic> cleanContext = {};
            if (rawContext != null) {
              rawContext.forEach((k, v) => cleanContext[k] = v);
            }
            return (name: name, context: cleanContext);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Converts an incoming GenUI [ChatMessage] into a prompt string for the LLM.
  String _messageToPrompt(ChatMessage message) {
    final buffer = StringBuffer();
    if (message.text.trim().isNotEmpty) {
      buffer.writeln(message.text);
    }

    final action = _extractUserAction(message);
    if (action != null) {
      final paramsStr = jsonEncode(action.context);
      buffer.writeln(
        'The user submitted the UI form for action "${action.name}" with arguments: $paramsStr.\n'
        'Call the tool "${action.name}" now with these arguments to fetch the result.',
      );
    }

    final prompt = buffer.toString().trim();
    return prompt.isEmpty ? message.text : prompt;
  }

  /// Extracts structured summary for displaying form/action parameters in the user chat bubble.
  String _messageToDisplayJson(ChatMessage message) {
    if (message.text.trim().isNotEmpty) {
      return message.text.trim();
    }
    final action = _extractUserAction(message);
    if (action != null) {
      final context = action.context;
      final city = context['city']?.toString() ?? '';
      final hours = context['hours']?.toString() ?? '';
      final channels = context['channels'] is List
          ? (context['channels'] as List).join(', ')
          : '';
      final parts = <String>[
        if (city.isNotEmpty) 'City: $city',
        if (hours.isNotEmpty) 'Duration: ${hours}h',
        if (channels.isNotEmpty) 'Channels: $channels',
      ];
      if (parts.isNotEmpty) {
        return 'Forecast request: ${parts.join(' | ')}';
      }
      if (context.isNotEmpty) {
        return const JsonEncoder.withIndent('  ').convert(context);
      }
      return 'Action: ${action.name}';
    }
    return '';
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

  void _removeEntry(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _entries.removeAt(index);
      notifyListeners();
    }
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
