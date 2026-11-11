import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' hide Action;
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart' as mp;
import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';
import 'package:uuid/uuid.dart';

import 'a2ui_catalog.dart';

/// The kind of an entry in the A2UI chat transcript.
enum A2uiChatEntryKind {
  /// A message written by the user.
  user,

  /// A message produced by the model (streamed text).
  assistant,

  /// An error produced while handling a request.
  error,

  /// An active A2UI surface widget.
  surface,
}

/// A single entry in the A2UI chat transcript.
class A2uiChatEntry {
  /// Creates an [A2uiChatEntry].
  const A2uiChatEntry({
    required this.id,
    required this.kind,
    required this.text,
    this.surfaceId,
    this.attachments,
  });

  /// Stable unique identifier.
  final String id;

  /// The kind of the entry.
  final A2uiChatEntryKind kind;

  /// The text content of the entry.
  final String text;

  /// The surface ID if this is a surface entry.
  final String? surfaceId;

  /// Optional attachments attached to this message.
  final List<mp.MessageAttachment>? attachments;
}

/// A [ChangeNotifier] that bridges `dart_mcp_core`'s [mp.LLMService]
/// to an A2UI conversation pipeline.
///
/// It coordinates an A2UI [MessageProcessor], streaming model execution,
/// local tool calling (including MCP server tools), and dynamic UI rendering.
class McpA2uiChatController extends ChangeNotifier {
  /// Creates an [McpA2uiChatController].
  McpA2uiChatController({
    required mp.LlmConfig llmConfig,
    List<mp.McpLocalTool> tools = const [],
    CatalogImplementation? catalog,
    List<A2uiCatalogItemDefinition>? catalogItems,
    String? catalogJson,
    List<ComponentImplementation>? customComponents,
    List<FunctionImplementation>? customFunctions,
    String? systemPrompt,
    this.maxToolIterations = 10,
    PlaygroundController? playgroundController,
  })  : _llmConfig = llmConfig,
        _tools = List.unmodifiable(tools),
        _systemPrompt = systemPrompt,
        _playgroundController = playgroundController,
        _catalog = catalog ??
            buildA2uiCatalog(
              catalogJson: catalogJson,
              catalogItems: catalogItems,
              customComponents: customComponents,
              customFunctions: customFunctions,
            ) {
    _processor = MessageProcessor<ComponentImplementation>(
      catalogs: [_catalog],
    );

    _actionSubscription = _processor.model.onAction.subscribe((action) {
      _handleAction(action);
    });

    _surfaceCreatedSubscription =
        _processor.model.onSurfaceCreated.subscribe((surface) {
      _onSurfaceCreated(surface.id);
    });

    _surfaceDeletedSubscription =
        _processor.model.onSurfaceDeleted.subscribe((surfaceId) {
      _onSurfaceDeleted(surfaceId);
    });
  }

  final PlaygroundController? _playgroundController;
  mp.LlmConfig _llmConfig;
  List<mp.McpLocalTool> _tools;
  final String? _systemPrompt;
  final int maxToolIterations;

  final CatalogImplementation _catalog;
  late final MessageProcessor<ComponentImplementation> _processor;

  Subscription? _actionSubscription;
  Subscription? _surfaceCreatedSubscription;
  Subscription? _surfaceDeletedSubscription;

  final List<A2uiChatEntry> _entries = [];
  final List<mp.ChatMessage> _conversationHistory = [];
  final Set<String> _knownSurfaces = {};

  bool _isGenerating = false;
  bool _cancelled = false;
  List<mp.MessageAttachment>? _pendingAttachments;

  /// The active A2UI [MessageProcessor].
  MessageProcessor<ComponentImplementation> get processor => _processor;

  /// The active A2UI catalog.
  CatalogImplementation get catalog => _catalog;

  /// The transcript of chat entries (messages and surfaces).
  List<A2uiChatEntry> get entries => List.unmodifiable(_entries);

  /// Whether the assistant is currently generating.
  bool get isGenerating => _isGenerating;

  /// Whether the current generation was cancelled.
  bool get isCancelled => _cancelled;

  /// Returns the active LLM configuration, prioritizing the live config
  /// from the attached [PlaygroundController] if configured.
  mp.LlmConfig get llmConfig {
    final live = _playgroundController?.activeLlmConfig;
    if (live != null && live.isConfigured) {
      return live;
    }
    return _llmConfig;
  }

  /// Sets the LLM configuration.
  set llmConfig(mp.LlmConfig config) => updateLlmConfig(config);

  /// Active surface IDs currently available in the processor.
  Iterable<String> get activeSurfaceIds =>
      _processor.model.allSurfaces.map((s) => s.id);

  /// Retrieves the [SurfaceModel] for a given [surfaceId].
  SurfaceModel<ComponentImplementation>? surfaceFor(String surfaceId) =>
      _processor.model.getSurface(surfaceId);

  void _onSurfaceCreated(String surfaceId) {
    if (_knownSurfaces.add(surfaceId)) {
      _entries.add(
        A2uiChatEntry(
          id: 'surface_$surfaceId',
          kind: A2uiChatEntryKind.surface,
          text: '',
          surfaceId: surfaceId,
        ),
      );
      notifyListeners();
    }
  }

  void _onSurfaceDeleted(String surfaceId) {
    _knownSurfaces.remove(surfaceId);
    _entries.removeWhere((e) => e.surfaceId == surfaceId);
    notifyListeners();
  }

  void _handleAction(A2uiRendererAction action) {
    final buffer = StringBuffer();
    if (action.userMessage != null && action.userMessage!.trim().isNotEmpty) {
      buffer.write(action.userMessage!.trim());
    } else {
      buffer.write('Action "${action.name}" triggered on surface ${action.surfaceId}');
      if (action.context.isNotEmpty) {
        buffer.write(' with context: ${jsonEncode(action.context)}');
      }
    }
    sendMessage(buffer.toString());
  }

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
      A2uiChatEntry(
        id: _newId(),
        kind: A2uiChatEntryKind.user,
        text: entryText,
        attachments: attachments != null ? List.unmodifiable(attachments) : null,
      ),
    );
    notifyListeners();

    _runGeneration(entryText);
  }

  Future<void> _runGeneration(String userText) async {
    if (_isGenerating) return;
    _isGenerating = true;
    _cancelled = false;
    notifyListeners();

    final atts = _pendingAttachments;
    _pendingAttachments = null;

    // Process attachments
    String effectivePrompt = userText;
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
      content: effectivePrompt,
      role: mp.ChatRole.user,
      timestamp: DateTime.now(),
      attachments: visionAttachments.isNotEmpty ? visionAttachments : null,
    );
    _conversationHistory.add(userMsg);
    _playgroundController?.addMessage(userMsg);

    final effectiveSystemPrompt = _buildSystemPrompt();
    final effectiveTools = _gatherEffectiveTools();

    int toolIteration = 0;
    while (!_cancelled && toolIteration <= maxToolIterations) {
      toolIteration++;
      final assistantEntryId = _newId();
      final assistantMsgId = _newId();

      final currentAssistantEntry = A2uiChatEntry(
        id: assistantEntryId,
        kind: A2uiChatEntryKind.assistant,
        text: '',
      );
      _entries.add(currentAssistantEntry);
      notifyListeners();

      final responseBuffer = StringBuffer();
      final List<mp.LLMToolCall> requestedToolCalls = [];

      try {
        final stream = mp.LLMService.generateStream(
          config: _llmConfig,
          messages: _conversationHistory,
          tools: effectiveTools,
          systemPrompt: effectiveSystemPrompt,
        );

        await for (final chunk in stream) {
          if (_cancelled) break;

          if (chunk.textDelta.isNotEmpty) {
            responseBuffer.write(chunk.textDelta);
            final idx = _entries.indexWhere((e) => e.id == assistantEntryId);
            if (idx != -1) {
              _entries[idx] = A2uiChatEntry(
                id: assistantEntryId,
                kind: A2uiChatEntryKind.assistant,
                text: responseBuffer.toString(),
              );
              notifyListeners();
            }
          }

          if (chunk.isDone && chunk.finalResponse != null) {
            requestedToolCalls.addAll(chunk.finalResponse!.toolCalls);
          }
        }
      } catch (e) {
        if (!_cancelled) {
          _entries.add(
            A2uiChatEntry(
              id: _newId(),
              kind: A2uiChatEntryKind.error,
              text: 'LLM Generation Error: $e',
            ),
          );
          notifyListeners();
        }
        break;
      }

      final fullResponse = responseBuffer.toString();
      final assistantMsg = mp.ChatMessage(
        id: assistantMsgId,
        content: fullResponse,
        role: mp.ChatRole.assistant,
        timestamp: DateTime.now(),
        type: requestedToolCalls.isNotEmpty
            ? mp.MessageType.toolCall
            : mp.MessageType.text,
        toolName: requestedToolCalls.isNotEmpty
            ? requestedToolCalls.first.name
            : null,
        toolArguments: requestedToolCalls.isNotEmpty
            ? requestedToolCalls.first.arguments
            : null,
      );
      _conversationHistory.add(assistantMsg);
      _playgroundController?.addMessage(assistantMsg);

      // Parse and process any A2UI JSON payload in the response
      _parseAndProcessA2uiPayloads(fullResponse);

      if (_cancelled || requestedToolCalls.isEmpty) {
        break;
      }

      // Execute tool calls
      for (final tc in requestedToolCalls) {
        if (_cancelled) break;

        final toolResult = await _executeTool(tc);
        final toolMsg = mp.ChatMessage(
          id: _newId(),
          content: toolResult.text,
          role: mp.ChatRole.tool,
          timestamp: DateTime.now(),
          type: mp.MessageType.toolResponse,
          toolName: tc.name,
          toolResult: toolResult,
        );
        _conversationHistory.add(toolMsg);
        _playgroundController?.addMessage(toolMsg);
      }
    }

    _isGenerating = false;
    notifyListeners();
  }

  void _parseAndProcessA2uiPayloads(String text) {
    final candidates = <String>[];

    // Look for <a2ui-json>...</a2ui-json>
    final tagRegex = RegExp(r'<a2ui-json>([\s\S]*?)</a2ui-json>', caseSensitive: false);
    for (final m in tagRegex.allMatches(text)) {
      final s = m.group(1)?.trim();
      if (s != null && s.isNotEmpty) candidates.add(s);
    }

    // Look for ```json ... ``` code fences
    final fenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    for (final m in fenceRegex.allMatches(text)) {
      final s = m.group(1)?.trim();
      if (s != null && s.isNotEmpty) candidates.add(s);
    }

    // Look for un-fenced JSON objects with "component" or "createSurface"
    if (candidates.isEmpty) {
      final objRegex = RegExp(
        r'\{[\s\S]*?(?:"component"|"createSurface")\s*:[\s\S]*?\}',
        caseSensitive: false,
      );
      for (final m in objRegex.allMatches(text)) {
        final s = m.group(0)?.trim();
        if (s != null && s.isNotEmpty) candidates.add(s);
      }
    }

    for (final jsonStr in candidates) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          _processDecodedPayload(decoded);
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _processDecodedPayload(item);
            }
          }
        }
      } catch (_) {}
    }
  }

  void _processDecodedPayload(Map<String, dynamic> payload) {
    try {
      if (payload.containsKey('createSurface') ||
          payload.containsKey('updateComponents') ||
          payload.containsKey('updateDataModel') ||
          payload.containsKey('deleteSurface')) {
        if (!payload.containsKey('version')) {
          payload['version'] = 'v1.0';
        }
        if (payload.containsKey('createSurface')) {
          final cs = payload['createSurface'];
          if (cs is Map<String, dynamic> && !cs.containsKey('catalogId')) {
            cs['catalogId'] = _catalog.id;
          }
        }
        _processor.processMessages(payload);
      } else if (payload.containsKey('component')) {
        _applyDirectComponent(payload);
      }
    } catch (_) {}
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
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': surfaceId,
          'catalogId': _catalog.id,
        },
      });

      _processor.processMessages({
        'version': 'v1.0',
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

  Future<mp.MCPToolResult> _executeTool(mp.LLMToolCall tc) async {
    // 1. Check local tools
    for (final t in _tools) {
      if (t.name == tc.name) {
        try {
          return await t.execute(tc.arguments);
        } catch (e) {
          return mp.MCPToolResult.text('Tool error: $e');
        }
      }
    }

    // 2. Check MCP Manager if available
    if (_playgroundController != null) {
      try {
        return await _playgroundController.mcpManager.callTool(
          tc.name,
          tc.arguments,
        );
      } catch (e) {
        return mp.MCPToolResult.text('MCP tool execution error: $e');
      }
    }

    return mp.MCPToolResult.text('Unknown tool: ${tc.name}');
  }

  List<mp.MCPTool> _gatherEffectiveTools() {
    final List<mp.MCPTool> list = [];
    final seen = <String>{};

    for (final t in _tools) {
      if (seen.add(t.name)) {
        list.add(t.toMCPTool());
      }
    }

    if (_playgroundController != null) {
      for (final t in _playgroundController.mcpManager.availableTools) {
        if (seen.add(t.name)) {
          list.add(t);
        }
      }
    }

    return list;
  }

  String _buildSystemPrompt() {
    final buffer = StringBuffer();
    final sysPrompt = _systemPrompt;
    if (sysPrompt != null && sysPrompt.trim().isNotEmpty) {
      buffer.writeln(sysPrompt.trim());
      buffer.writeln();
    }

    buffer.writeln('### Agent-to-User Interface (A2UI) Instructions');
    buffer.writeln(
      'You can render rich, interactive user interface surfaces using the A2UI standard.',
    );
    buffer.writeln(
      'To display a UI surface, emit valid A2UI JSON either in `<a2ui-json>...</a2ui-json>` tags or a ```json code block.',
    );
    buffer.writeln();
    buffer.writeln('Available components in catalog "${_catalog.id}":');
    for (final comp in _catalog.components.values) {
      buffer.writeln('- **${comp.name}**');
    }
    buffer.writeln();
    buffer.writeln(
      'Standard protocol messages:\n'
      '1. createSurface: {"version": "v1.0", "createSurface": {"surfaceId": "...", "catalogId": "${_catalog.id}"}}\n'
      '2. updateComponents: {"version": "v1.0", "updateComponents": {"surfaceId": "...", "components": [{"id": "root", "component": "...", ...}]}}\n'
      '3. Direct shorthand: {"component": "ComponentName", ...}\n',
    );

    return buffer.toString();
  }

  /// Cancels any active generation in progress.
  void stopGeneration() {
    _cancelled = true;
    _isGenerating = false;
    notifyListeners();
  }

  /// Alias for [stopGeneration].
  void cancelGeneration() => stopGeneration();

  /// Clears the chat conversation and all active surfaces.
  void clearChat() {
    _entries.clear();
    _conversationHistory.clear();
    _knownSurfaces.clear();
    notifyListeners();
  }

  /// Updates the LLM configuration.
  void updateLlmConfig(mp.LlmConfig config) {
    _llmConfig = config;
    notifyListeners();
  }

  /// Updates the active local tools.
  void updateTools(List<mp.McpLocalTool> tools) {
    _tools = List.unmodifiable(tools);
    notifyListeners();
  }

  String _newId() => const Uuid().v4();

  @override
  void dispose() {
    _actionSubscription?.unsubscribe();
    _surfaceCreatedSubscription?.unsubscribe();
    _surfaceDeletedSubscription?.unsubscribe();
    super.dispose();
  }
}
