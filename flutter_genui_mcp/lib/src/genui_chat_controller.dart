import 'dart:async';
import 'dart:convert';

import 'package:a2ui_agent/a2ui_agent.dart' as a2ui_agent;
import 'package:a2ui_core/a2ui_core.dart' as a2ui_core;
import 'package:a2ui_flutter/a2ui_flutter.dart';
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
/// [mp.LLMService] to an A2UI conversation pipeline.
///
/// It prompts the model for the catalog with `package:a2ui_agent`, routes each
/// outgoing message through [mp.LLMService.generateStream], reads the A2UI JSON
/// in the streamed reply, renders it with an A2UI
/// [a2ui_core.MessageProcessor], and executes any local [mp.McpLocalTool]
/// calls requested by the model in an agent loop. Actions on the rendered
/// surfaces are sent back to the model.
class McpGenuiChatController extends ChangeNotifier {
  /// Creates a [McpGenuiChatController].
  ///
  /// Either [catalog] or [catalogJson] / [catalogItems] may be used to define
  /// the widgets the model is allowed to generate. When none are provided a
  /// default catalog with the A2UI v0.9 basic widgets is created.
  McpGenuiChatController({
    required this._llmConfig,
    List<mp.McpLocalTool> tools = const [],
    CatalogImplementation? catalog,
    List<GenuiCatalogItemDefinition>? catalogItems,
    String? catalogJson,
    List<a2ui_core.FunctionImplementation>? clientFunctions,
    this._systemPrompt,
    this.maxToolIterations = 10,
    this._playgroundController,
  }) : _tools = List.unmodifiable(tools),
       _catalog =
           catalog != null
               ? (clientFunctions != null
                   ? catalog.derive(
                       catalogId: catalog.id,
                       addFunctions: clientFunctions,
                       instructions: catalog.instructions,
                     )
                   : catalog)
               : buildGenuiCatalog(
                 catalogJson: catalogJson,
                 catalogItems: catalogItems,
                 clientFunctions: clientFunctions,
               ) {
    _processor = a2ui_core.MessageProcessor<ComponentImplementation>(
      catalogs: [_catalog],
      // A surface streams in over several messages, which the strict checks
      // would reject.
      validationConfig: a2ui_core.ValidationConfig.relaxed,
      // Report a rejected message on processor.model.onError instead of
      // throwing, and apply the other messages of a batch.
      reportErrorsOnly: true,
    );
    _subscriptions = [
      _processor.model.onSurfaceCreated.subscribe((_) => _syncSurfaces()),
      _processor.model.onAction.subscribe(_handleAction),
    ];
  }

  final PlaygroundController? _playgroundController;
  mp.LlmConfig _llmConfig;

  /// Returns the active LLM configuration, prioritizing the live config
  /// from the attached [PlaygroundController] if configured.
  mp.LlmConfig get llmConfig {
    final live = _playgroundController?.activeLlmConfig;
    if (live != null && live.isConfigured) {
      return live;
    }
    return _llmConfig;
  }

  /// Updates the LLM configuration and notifies listeners.
  set llmConfig(mp.LlmConfig config) {
    if (_llmConfig != config) {
      _llmConfig = config;
      notifyListeners();
    }
  }

  final List<mp.McpLocalTool> _tools;
  final String? _systemPrompt;
  final CatalogImplementation _catalog;
  final int maxToolIterations;

  late final a2ui_core.MessageProcessor<ComponentImplementation> _processor;
  late final List<a2ui_core.Subscription> _subscriptions;

  // Prompts the model for the catalog and reads the A2UI JSON in its replies.
  late final a2ui_agent.A2uiRequestProcessor _agent =
      a2ui_agent.A2uiGenerator(
        catalogs: [a2ui_agent.CatalogConfig(_catalog)],
        inferenceFormatFactory: const a2ui_agent.DirectJsonFormatFactory(
          // The model creates surfaces and fills them, as genui's chat prompt
          // allowed.
          allowedMessages: ['createSurface', 'updateComponents'],
          // Render whole components, as genui did.
          bufferIncompleteComponents: true,
        ),
      ).createProcessor(
        a2ui_core.A2uiRendererCapabilities.forCatalogIds([
          _catalog.id,
        ], version: a2ui_core.A2uiProtocolVersion.v0_9),
      );

  final List<GenuiChatEntry> _entries = [];
  final List<mp.ChatMessage> _history = [];
  final Set<String> _knownSurfaces = {};
  String? _cachedSystemPrompt;
  List<mp.MessageAttachment>? _pendingAttachments;

  bool _isGenerating = false;

  void _syncSurfaces() {
    var added = false;
    for (final sId in activeSurfaceIds) {
      if (_knownSurfaces.add(sId)) {
        _entries.add(
          GenuiChatEntry(
            id: 'surface_$sId',
            kind: GenuiChatEntryKind.surface,
            text: '',
            surfaceId: sId,
          ),
        );
        added = true;
      }
    }
    if (added) {
      notifyListeners();
    }
  }

  void _parseAndApplyA2uiBlocks(String text) {
    final matches =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').allMatches(text);
    final candidates = <String>[];
    for (final m in matches) {
      final s = m.group(1)?.trim();
      if (s != null && s.isNotEmpty) candidates.add(s);
    }

    // Also look for un-fenced JSON objects containing "component"
    if (candidates.isEmpty) {
      final jsonBlockRegex = RegExp(
        r'\{[\s\S]*?"component"\s*:[\s\S]*?\}',
        caseSensitive: false,
      );
      for (final m in jsonBlockRegex.allMatches(text)) {
        final s = m.group(0)?.trim();
        if (s != null && s.isNotEmpty) candidates.add(s);
      }
    }

    for (final jsonStr in candidates) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('version') &&
              (decoded.containsKey('createSurface') ||
                  decoded.containsKey('updateComponents') ||
                  decoded.containsKey('updateDataModel') ||
                  decoded.containsKey('deleteSurface'))) {
            if (decoded.containsKey('createSurface')) {
              final cs = decoded['createSurface'];
              if (cs is Map<String, dynamic> && !cs.containsKey('catalogId')) {
                cs['catalogId'] = _catalog.id;
              }
            }
            _processor.processMessages(decoded);
          } else if (decoded.containsKey('component')) {
            _applyDirectComponent(decoded);
          }
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic> && item.containsKey('component')) {
              _applyDirectComponent(item);
            }
          }
        }
      } catch (_) {}
    }
    _syncSurfaces();
  }

  void _applyDirectComponent(Map<String, dynamic> comp) {
    final compName = comp['component']?.toString() ?? '';
    if (compName.isEmpty) return;

    final surfaceId =
        'surface_${compName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
    final compId = comp['id']?.toString() ?? 'root';
    final compProps = Map<String, dynamic>.from(comp);
    compProps.remove('id');
    compProps.remove('component');

    try {
      _processor.processMessages({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': surfaceId,
          'catalogId': _catalog.id,
        },
      });

      _processor.processMessages({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': [
            {
              'id': compId,
              'component': compName,
              ...compProps,
            },
          ],
        },
      });
    } catch (_) {}
  }

  /// The A2UI [a2ui_core.MessageProcessor] that renders the model's surfaces.
  a2ui_core.MessageProcessor<ComponentImplementation> get processor =>
      _processor;

  /// The [CatalogImplementation] in use.
  CatalogImplementation get catalog => _catalog;

  bool _cancelled = false;

  /// Whether a request is currently being generated.
  bool get isGenerating => _isGenerating;

  /// Stops / cancels the in-flight generation stream or tool execution loop.
  void cancelGeneration() {
    if (!_isGenerating) return;
    _cancelled = true;
    _isGenerating = false;
    _playgroundController?.cancelGeneration();
    notifyListeners();
  }

  /// The chat transcript entries (user + assistant text).
  List<GenuiChatEntry> get entries => List.unmodifiable(_entries);

  /// The IDs of the currently active GenUI surfaces, in the order they were
  /// created.
  Iterable<String> get activeSurfaceIds =>
      _processor.model.allSurfaces.map((surface) => surface.id);

  /// Returns the surface with [surfaceId], to render with an [A2uiSurface], or
  /// null if there is none.
  a2ui_core.SurfaceModel<ComponentImplementation>? contextFor(
    String surfaceId,
  ) => _processor.model.getSurface(surfaceId);

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

    unawaited(_handleSend((text: entryText, action: null)));
  }

  /// Sends an action on a surface to the model.
  void _handleAction(a2ui_core.A2uiRendererAction action) {
    final context =
        jsonDecode(jsonEncode(action.context)) as Map<String, dynamic>;
    unawaited(
      _handleSend((text: '', action: (name: action.name, context: context))),
    );
  }

  Future<void> _handleSend(_Turn message) async {
    if (_isGenerating) return;
    _isGenerating = true;
    _cancelled = false;
    notifyListeners();

    final atts = _pendingAttachments;
    _pendingAttachments = null;

    final prompt = _messageToPrompt(message);
    if (prompt.trim().isEmpty && (atts == null || atts.isEmpty)) {
      _isGenerating = false;
      notifyListeners();
      return;
    }

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

    final actionInfo = message.action;
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
        if (_cancelled) break;
        mp.LLMResponse? finalResponse;
        final mcpTools = <mp.MCPTool>[
          ..._tools.map((t) => t.toMCPTool()),
          for (final func in _catalog.functions.values)
            mp.MCPTool(
              name: func.name,
              description: func.description,
              inputSchema: mp.LLMService.sanitizeSchemaForLlm(
                Map<String, dynamic>.from(func.argumentSchema.value),
              ),
            ),
        ];
        final iterationBuffer = StringBuffer();
        final iterationEntryId = _newId();
        final reply = _ReplyReader(
          _agent.openContinuingStream(),
          (message) => _processor.processMessages(
            a2ui_core.AgentToRendererMessagePayload.of(message),
          ),
        );

        await for (final chunk in mp.LLMService.generateStream(
          config: llmConfig,
          messages: List.unmodifiable(_history),
          tools: mcpTools,
          systemPrompt: _effectiveSystemPrompt,
        )) {
          if (_cancelled) break;
          if (chunk.textDelta.isNotEmpty) {
            iterationBuffer.write(chunk.textDelta);
            reply.feed(chunk.textDelta);
            _syncSurfaces();
            final cleanText = _sanitizeAssistantText(reply.text);
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

        if (_cancelled) break;

        reply.close();
        final rawIterationText = iterationBuffer.toString();
        // A2UI JSON the model wrote outside the A2UI blocks.
        _parseAndApplyA2uiBlocks(reply.text);
        _syncSurfaces();
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

        final cleanText = _sanitizeAssistantText(reply.text);
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
        if (toolCalls.isEmpty || _cancelled) break;

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
          if (_cancelled) break;
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
      if (!_cancelled) {
        _entries.add(
          GenuiChatEntry(
            id: _newId(),
            kind: GenuiChatEntryKind.error,
            text: 'Generation error: $error',
          ),
        );
      }
    } finally {
      _isGenerating = false;
      _cancelled = false;
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

    for (final func in _catalog.functions.values) {
      final matchesName = func.name == call.name ||
          func.name.toLowerCase() ==
              call.name.toLowerCase().replaceAll('_', '');
      if (matchesName) {
        try {
          final surfaces = _processor.model.allSurfaces;
          final dataModel = surfaces.isNotEmpty
              ? surfaces.first.dataModel
              : a2ui_core.DataModel();
          final context = a2ui_core.DataContext(dataModel, _catalog.invoke, '/');

          var result = func.execute(call.arguments, context);
          if (result is Future) result = await result;
          if (result is a2ui_core.ReadonlySignal) result = result.value;

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

    // Handle GenUI / A2UI operations if the model invokes them as tools
    const a2uiOpMap = {
      'createsurface': 'createSurface',
      'updatecomponents': 'updateComponents',
      'updatedatamodel': 'updateDataModel',
      'deletesurface': 'deleteSurface',
      'beginrendering': 'beginRendering',
      'finishrendering': 'finishRendering',
    };
    final normalizedOp =
        a2uiOpMap[call.name.toLowerCase().replaceAll('_', '')];
    if (normalizedOp != null) {
      try {
        Map<String, dynamic> a2uiPayload;
        if (call.arguments.containsKey('version') &&
            call.arguments.containsKey(normalizedOp)) {
          // LLM passed full A2UI message as arguments: {"version": "v0.9", "createSurface": {...}}
          a2uiPayload = Map<String, dynamic>.from(call.arguments);
        } else if (call.arguments.containsKey(normalizedOp)) {
          // LLM passed {"createSurface": {...}}
          a2uiPayload = {
            'version': 'v0.9',
            ...call.arguments,
          };
        } else {
          // LLM passed direct parameters: {"surfaceId": "...", "catalogId": "..."}
          final argsCopy = Map<String, dynamic>.from(call.arguments);
          argsCopy.remove('version');
          a2uiPayload = {
            'version': 'v0.9',
            normalizedOp: argsCopy,
          };
        }
        if (normalizedOp == 'createSurface') {
          final body = a2uiPayload['createSurface'] as Map<String, dynamic>?;
          if (body != null && !body.containsKey('catalogId')) {
            body['catalogId'] = _catalog.id;
          }
        }
        try {
          _processor.processMessages(a2uiPayload);
        } catch (_) {}
        _syncSurfaces();
        return mp.MCPToolResult(
          content: [
            mp.MCPContent(
              type: 'text',
              text: jsonEncode({
                'status': 'success',
                'operation': normalizedOp,
                'message': 'Surface operation executed successfully',
              }),
            ),
          ],
        );
      } catch (error) {
        return mp.MCPToolResult(
          content: [
            mp.MCPContent(
              type: 'text',
              text: 'GenUI operation error: $error',
            ),
          ],
          isError: true,
        );
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
      [..._chatInstructions(_catalog.id), _agent.promptSnippet].join('\n\n'),
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
      for (final func in _catalog.functions.values)
        mp.MCPTool(
          name: func.name,
          description: func.description,
          inputSchema:
              Map<String, dynamic>.from(func.argumentSchema.value),
        ),
    ];
    if (allTools.isNotEmpty && !llmConfig.useNativeToolCall) {
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
    r'```(?:json)?\s*[\s\S]*?```|\{\s*"version"\s*:\s*"v0\.9"[\s\S]*\}|,\s*\{\s*"id"\s*:[\s\S]*\}|\{\s*"id"\s*:[\s\S]*?"component"[\s\S]*?\}|\{\s*"component"\s*:[\s\S]*?\}',
    caseSensitive: false,
  );

  /// Strips A2UI JSON code blocks so they are not displayed in the chat view.
  static String _sanitizeAssistantText(String raw) {
    String cleaned = raw;
    // Strip in-progress code blocks during streaming
    final unclosedCodeBlock =
        RegExp(r'```(?:json)?\s*\{?[\s\S]*$', caseSensitive: false);
    cleaned = cleaned.replaceAll(unclosedCodeBlock, '');
    // Strip closed A2UI and component JSON blocks
    cleaned = cleaned.replaceAll(_a2uiJsonBlockRegex, '');
    // Strip trailing/dangling JSON fragments like ", { ... " or indented JSON
    final danglingJson = RegExp(
      r',?\s*\{\s*"(?:id|component|title|version)"[\s\S]*$',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(danglingJson, '');
    return cleaned.trim();
  }

  /// Converts an outgoing [_Turn] into a prompt string for the LLM.
  String _messageToPrompt(_Turn message) {
    final buffer = StringBuffer();
    if (message.text.trim().isNotEmpty) {
      buffer.writeln(message.text);
    }

    final action = message.action;
    if (action != null) {
      final context = action.context;
      final explicitMsg = context['message']?.toString() ??
          context['prompt']?.toString() ??
          context['query']?.toString();

      final cleanParams = Map<String, dynamic>.from(context)
        ..remove('message')
        ..remove('prompt')
        ..remove('query')
        ..remove('userSummary')
        ..remove('summary');

      if (cleanParams.isNotEmpty) {
        buffer.writeln(
          'UI Action "${action.name}" submitted with context: ${jsonEncode(cleanParams)}',
        );
      }
      if (explicitMsg != null && explicitMsg.trim().isNotEmpty) {
        buffer.writeln(explicitMsg.trim());
      } else if (cleanParams.isEmpty) {
        buffer.writeln('The user triggered UI action "${action.name}".');
      }
    }

    final prompt = buffer.toString().trim();
    return prompt.isEmpty ? message.text : prompt;
  }

  /// Extracts structured summary for displaying form/action parameters in the user chat bubble.
  String _messageToDisplayJson(_Turn message) {
    if (message.text.trim().isNotEmpty) {
      return message.text.trim();
    }
    final action = message.action;
    if (action != null) {
      final context = action.context;
      final userSummary = context['userSummary']?.toString() ??
          context['summary']?.toString() ??
          context['message']?.toString();
      if (userSummary != null && userSummary.isNotEmpty) {
        return userSummary;
      }
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
    for (final subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    _processor.dispose();
    super.dispose();
  }
}

/// A user turn the controller sends to the model: the text the user wrote, or
/// an action on a surface with its resolved context.
typedef _Turn = ({
  String text,
  ({String name, Map<String, dynamic> context})? action,
});

/// What genui's `PromptBuilder.chat` told the model besides the A2UI format,
/// which `package:a2ui_agent`'s prompt snippet now describes.
List<String> _chatInstructions(String catalogId) => [
  'The active catalog ID is: "$catalogId". '
      'You must use this catalog ID when creating surfaces.',
  'IMPORTANT: DO NOT update or modify surfaces created in previous turns. '
      'If the UI needs to change, you MUST create a NEW surface with a new '
      'unique `surfaceId`. You may only use `updateComponents` to populate '
      'the components of a freshly created surface.',
];

/// Reads one streamed reply of the model: renders the A2UI messages in its
/// A2UI blocks as they arrive, and keeps the text outside them.
class _ReplyReader {
  _ReplyReader(this._stream, this._render);

  final a2ui_agent.ContinuingResponseStream _stream;
  final void Function(a2ui_core.AgentToRendererMessage message) _render;
  final StringBuffer _text = StringBuffer();
  bool _ended = false;
  bool _afterBlock = false;

  /// The text of the reply so far, outside its A2UI blocks. The text on the
  /// two sides of a block is separated by a blank line.
  String get text => _text.toString();

  /// Reads the next [chunk] of the reply.
  void feed(String chunk) => _read(() => _stream.feed(chunk));

  /// Reads what the reply held back after its last chunk.
  void close() => _read(_stream.close);

  void _read(List<a2ui_agent.StreamPart> Function() read) {
    if (_ended) return;
    List<a2ui_agent.StreamPart> parts;
    try {
      parts = read();
    } on a2ui_core.A2uiError catch (error) {
      // The rest of the reply cannot be read; keep what came before the error.
      _ended = true;
      parts = error.partialResults;
    }
    for (final part in parts) {
      switch (part) {
        case a2ui_agent.TextPart(:final text):
          if (_afterBlock && _text.isNotEmpty) _text.write('\n\n');
          _afterBlock = false;
          _text.write(text);
        case a2ui_agent.A2uiPart(:final a2ui):
          _afterBlock = true;
          a2ui.forEach(_render);
        case a2ui_agent.ErrorPart():
          // A block that cannot be read or that the catalog rejects. It is
          // dropped, as genui dropped such blocks.
          _afterBlock = true;
      }
    }
  }
}
