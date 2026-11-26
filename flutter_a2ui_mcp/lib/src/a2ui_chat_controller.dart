import 'dart:async';
import 'dart:convert';

import 'package:a2ui_agent/a2ui_agent.dart' as a2ui_agent;
import 'package:a2ui_core/a2ui_core.dart' hide Action;
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
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
    this.useExpressFormat = true,
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
    _expressParser = a2ui_agent.ExpressParser([_catalog]);

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

    _errorSubscription = _processor.model.onError.subscribe((error) {
      _playgroundController?.addMessage(
        mp.ChatMessage(
          id: _newId(),
          content: '[A2UI Validation/Render Error] ${error.code}: ${error.message}',
          role: mp.ChatRole.system,
          timestamp: DateTime.now(),
          type: mp.MessageType.log,
        ),
      );
    });
  }

  static Set<String>? _cachedBasicComponentNames;
  static Set<String> get _basicComponentNames =>
      _cachedBasicComponentNames ??= basicCatalog().components.keys.toSet();

  final PlaygroundController? _playgroundController;
  mp.LlmConfig _llmConfig;
  List<mp.McpLocalTool> _tools;
  final String? _systemPrompt;
  final int maxToolIterations;

  /// Whether to use the compact **A2UI 1.0 Express** format (`<a2ui>...</a2ui>`)
  /// from `a2ui_agent` by default (~50% fewer tokens than raw JSON) with local
  /// catalog compilation and automatic JSON fallback.
  final bool useExpressFormat;

  final CatalogImplementation _catalog;
  late final MessageProcessor<ComponentImplementation> _processor;
  late final a2ui_agent.ExpressParser _expressParser;

  Subscription? _actionSubscription;
  Subscription? _surfaceCreatedSubscription;
  Subscription? _surfaceDeletedSubscription;
  Subscription? _errorSubscription;

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
  set llmConfig(mp.LlmConfig config) {
    if (_llmConfig != config) {
      updateLlmConfig(config);
    }
  }

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
          config: llmConfig,
          messages: _conversationHistory,
          tools: effectiveTools,
          systemPrompt: effectiveSystemPrompt,
        );

        await for (final chunk in stream) {
          if (_cancelled) break;

          if (chunk.textDelta.isNotEmpty) {
            responseBuffer.write(chunk.textDelta);
            final cleanText = _sanitizeAssistantText(responseBuffer.toString());
            final idx = _entries.indexWhere((e) => e.id == assistantEntryId);
            if (idx != -1) {
              _entries[idx] = A2uiChatEntry(
                id: assistantEntryId,
                kind: A2uiChatEntryKind.assistant,
                text: cleanText,
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
      final cleanText = _sanitizeAssistantText(fullResponse);

      final initialSurfaceCount = _knownSurfaces.length;

      // Parse and process any A2UI JSON payload in the response
      _parseAndProcessA2uiPayloads(fullResponse);

      final hasNewSurface = _knownSurfaces.length > initialSurfaceCount;

      if (fullResponse.trim().isNotEmpty) {
        final assistantTextMsg = mp.ChatMessage(
          id: assistantMsgId,
          content: fullResponse,
          role: mp.ChatRole.assistant,
          timestamp: DateTime.now(),
          type: mp.MessageType.text,
        );
        _conversationHistory.add(assistantTextMsg);
        _playgroundController?.addMessage(assistantTextMsg);

        final idx = _entries.indexWhere((e) => e.id == assistantEntryId);
        if (cleanText.isNotEmpty) {
          if (idx != -1) {
            _entries[idx] = A2uiChatEntry(
              id: assistantEntryId,
              kind: A2uiChatEntryKind.assistant,
              text: cleanText,
            );
          }
        } else if (idx != -1) {
          if (hasNewSurface) {
            _entries.removeAt(idx);
          } else {
            _entries[idx] = A2uiChatEntry(
              id: assistantEntryId,
              kind: A2uiChatEntryKind.assistant,
              text: fullResponse.trim(),
            );
          }
        }
      } else {
        // No text produced (e.g. model emitted only tool calls)
        _entries.removeWhere((e) => e.id == assistantEntryId);
      }
      notifyListeners();

      if (_cancelled || requestedToolCalls.isEmpty) {
        break;
      }

      // Record tool call assistant messages with matching IDs
      for (final tc in requestedToolCalls) {
        final callId = tc.id.isNotEmpty ? tc.id : 'call_${tc.name}_${_newId()}';
        final toolCallMsg = mp.ChatMessage(
          id: callId,
          content: '',
          role: mp.ChatRole.assistant,
          timestamp: DateTime.now(),
          type: mp.MessageType.toolCall,
          toolName: tc.name,
          toolArguments: tc.arguments,
        );
        _conversationHistory.add(toolCallMsg);
        _playgroundController?.addMessage(toolCallMsg);
      }

      // Execute tool calls and record tool response messages with matching IDs
      for (final tc in requestedToolCalls) {
        if (_cancelled) break;

        final callId = tc.id.isNotEmpty ? tc.id : 'call_${tc.name}_${_newId()}';
        final toolResult = await _executeTool(tc);
        final toolMsg = mp.ChatMessage(
          id: callId,
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

  /// Extracts top-level JSON objects from text by tracking balanced braces.
  static List<Map<String, dynamic>> extractJsonObjects(String text) {
    final results = <Map<String, dynamic>>[];
    int depth = 0;
    int startIndex = -1;
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (escape) {
        escape = false;
        continue;
      }
      if (char == '\\' && inString) {
        escape = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (!inString) {
        if (char == '{') {
          if (depth == 0) {
            startIndex = i;
          }
          depth++;
        } else if (char == '}') {
          depth--;
          if (depth == 0 && startIndex != -1) {
            final jsonSub = text.substring(startIndex, i + 1);
            try {
              final decoded = jsonDecode(jsonSub);
              if (decoded is Map<String, dynamic>) {
                results.add(decoded);
              }
            } catch (_) {}
            startIndex = -1;
          }
        }
      }
    }
    return results;
  }

  /// Parses and applies any A2UI Express (`<a2ui>`) or JSON payloads in [text].
  /// Exposed for testing and external response integration.
  void processModelOutput(String text) => _parseAndProcessA2uiPayloads(text);

  void _parseAndProcessA2uiPayloads(String text) {
    bool processedAny = false;

    // 0. Compile A2UI Express blocks (<a2ui>...</a2ui>) via a2ui_agent ExpressParser
    if (_expressParser.hasFormatContent(text, complete: true)) {
      final parts = _expressParser.unwrap(text);
      for (final part in parts) {
        if (part is a2ui_agent.RawA2uiPart && part.a2uiRaw.trim().isNotEmpty) {
          try {
            final messages = _expressParser.compile(part.a2uiRaw);
            for (final msg in messages) {
              _processDecodedPayload(Map<String, dynamic>.from(msg.toJson()));
              processedAny = true;
            }
          } catch (e) {
            _playgroundController?.addMessage(
              mp.ChatMessage(
                id: _newId(),
                content: '[A2UI Express Compile Error] $e',
                role: mp.ChatRole.system,
                timestamp: DateTime.now(),
                type: mp.MessageType.log,
              ),
            );
            // Fall back to JSON extraction if the model put raw JSON inside <a2ui>
            final fallbackObjs = extractJsonObjects(part.a2uiRaw);
            for (final obj in fallbackObjs) {
              _processDecodedPayload(obj);
              processedAny = true;
            }
          }
        }
      }
    }

    if (processedAny) return;

    // 1. Check code fences and <a2ui-json> tags
    final fenceRegex = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```|<a2ui-json>([\s\S]*?)</a2ui-json>',
      caseSensitive: false,
    );
    final rawBlocks = <String>[];
    for (final m in fenceRegex.allMatches(text)) {
      final s = (m.group(1) ?? m.group(2))?.trim();
      if (s != null && s.isNotEmpty) rawBlocks.add(s);
    }

    for (final block in rawBlocks) {
      try {
        final decoded = jsonDecode(block);
        if (decoded is Map<String, dynamic>) {
          _processDecodedPayload(decoded);
          processedAny = true;
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _processDecodedPayload(item);
              processedAny = true;
            }
          }
        }
      } catch (_) {
        // Block might contain concatenated JSON objects
        final objects = extractJsonObjects(block);
        for (final obj in objects) {
          _processDecodedPayload(obj);
          processedAny = true;
        }
      }
    }

    // 2. If no valid JSON found in code fences/tags, scan the entire text for JSON objects
    if (!processedAny) {
      final objects = extractJsonObjects(text);
      for (final obj in objects) {
        _processDecodedPayload(obj);
      }
    }
  }

  void _processDecodedPayload(Map<String, dynamic> payload) {
    try {
      // Normalize wire protocol version (A2UI wire version requires '1.0', rejecting 'v1.0')
      final rawVersion = payload['version']?.toString().trim();
      if (rawVersion == null ||
          rawVersion == 'v1.0' ||
          rawVersion == '1.0.0' ||
          rawVersion == '1' ||
          rawVersion == '1.0') {
        payload['version'] = '1.0';
      } else if (rawVersion == '0.9' ||
          rawVersion == '0.9.0' ||
          rawVersion == 'v0.9') {
        payload['version'] = 'v0.9';
      } else if (rawVersion == '0.9.1' || rawVersion == 'v0.9.1') {
        payload['version'] = 'v0.9.1';
      }

      // Infer component name if missing from model JSON output
      if (!payload.containsKey('component') &&
          !payload.containsKey('createSurface') &&
          !payload.containsKey('updateComponents')) {
        if (payload.containsKey('items') ||
            payload.containsKey('accommodations') ||
            (payload.containsKey('title') &&
                payload['title'].toString().toLowerCase().contains('stay'))) {
          payload['component'] = 'AccommodationGrid';
        } else if (payload.containsKey('days') ||
            payload.containsKey('itinerary') ||
            (payload.containsKey('title') &&
                payload['title']
                    .toString()
                    .toLowerCase()
                    .contains('itinerary'))) {
          payload['component'] = 'TravelItineraryCard';
        } else if (payload.containsKey('defaultDestination') ||
            (payload.containsKey('title') &&
                payload['title']
                    .toString()
                    .toLowerCase()
                    .contains('finder'))) {
          payload['component'] = 'TravelSearchForm';
        } else if (payload.containsKey('times') &&
            payload.containsKey('channels')) {
          payload['component'] = 'WeatherChart';
        } else if ((payload.containsKey('title') &&
                payload['title']
                    .toString()
                    .toLowerCase()
                    .contains('forecast duration')) ||
            (payload.containsKey('duration') &&
                payload.containsKey('channels'))) {
          payload['component'] = 'WeatherForm';
        } else if (payload.containsKey('current_temp') ||
            payload.containsKey('target_temp') ||
            payload.containsKey('room')) {
          payload['component'] = 'ThermostatCard';
        } else if (payload.containsKey('devices')) {
          payload['component'] = 'DeviceGrid';
        } else if (payload.containsKey('total_kwh') ||
            payload.containsKey('breakdown')) {
          payload['component'] = 'EnergyChart';
        } else if (payload.containsKey('agents') &&
            payload['agents'] is List) {
          payload['component'] = 'AgentSwarmTimeline';
        } else if (payload.containsKey('action_name') &&
            payload.containsKey('risk_level')) {
          payload['component'] = 'ApprovalGateWidget';
        } else if (payload.containsKey('objective') &&
            payload.containsKey('findings')) {
          payload['component'] = 'SubagentCard';
        }
      }

      if (payload.containsKey('createSurface') ||
          payload.containsKey('updateComponents') ||
          payload.containsKey('updateDataModel') ||
          payload.containsKey('deleteSurface')) {
        if (payload.containsKey('createSurface')) {
          final cs = payload['createSurface'];
          if (cs is Map<String, dynamic>) {
            final cid = cs['catalogId']?.toString().trim();
            if (cid == null || cid.isEmpty || cid != _catalog.id) {
              cs['catalogId'] = _catalog.id;
            }
          }
        }
        if (payload.containsKey('updateComponents')) {
          final uc = payload['updateComponents'];
          if (uc is Map<String, dynamic> && uc['components'] is List) {
            for (final item in uc['components'] as List) {
              if (item is Map<String, dynamic>) {
                _sanitizeV1ComponentEnvelope(item, activeCatalogId: _catalog.id);
              }
            }
          }
        }
        _processor.processMessages(payload);
      } else if (payload.containsKey('component')) {
        _applyDirectComponent(payload);
      }
    } catch (_) {}
  }

  /// Sanitizes component envelope keys for `a2ui_core` 0.8.0+ v1.0 validation:
  /// - Removes `null` `@catalogId` / `catalogId` (rejected in 0.8.0) and aligns
  ///   unknown catalog IDs with [activeCatalogId] when provided.
  /// - Deduplicates mixins when both `@`-prefixed and bare forms are emitted.
  static void _sanitizeV1ComponentEnvelope(
    Map<String, dynamic> comp, {
    String? activeCatalogId,
  }) {
    if (comp.containsKey('@catalogId') && comp['@catalogId'] == null) {
      comp.remove('@catalogId');
    }
    if (comp.containsKey('catalogId') && comp['catalogId'] == null) {
      comp.remove('catalogId');
    }
    const mixinPairs = [
      ('@catalogId', 'catalogId'),
      ('@metadata', 'metadata'),
      ('@accessibility', 'accessibility'),
      ('@checks', 'checks'),
    ];
    for (final (atKey, bareKey) in mixinPairs) {
      if (comp.containsKey(atKey) && comp.containsKey(bareKey)) {
        comp.remove(bareKey);
      }
    }
    if (activeCatalogId != null) {
      if (comp.containsKey('@catalogId') &&
          comp['@catalogId']?.toString() != activeCatalogId) {
        comp['@catalogId'] = activeCatalogId;
      } else if (comp.containsKey('catalogId') &&
          comp['catalogId']?.toString() != activeCatalogId) {
        comp['catalogId'] = activeCatalogId;
      }
    }
  }

  void _applyDirectComponent(Map<String, dynamic> comp) {
    final compName = comp['component']?.toString() ?? '';
    if (compName.isEmpty) return;

    final surfaceId =
        'surface_${compName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}_${_newId().substring(0, 4)}';
    final compProps = Map<String, dynamic>.from(comp);
    compProps.remove('id');
    compProps.remove('component');
    compProps.remove('version');
    _sanitizeV1ComponentEnvelope(compProps, activeCatalogId: _catalog.id);

    try {
      _processor.processMessages([
        {
          'version': '1.0',
          'createSurface': {
            'surfaceId': surfaceId,
            'catalogId': _catalog.id,
          },
        },
        {
          'version': '1.0',
          'updateComponents': {
            'surfaceId': surfaceId,
            'components': [
              {
                'id': 'root',
                'component': compName,
                ...compProps,
              },
            ],
          },
        },
      ]);
    } catch (_) {}
  }

  static final RegExp _a2uiJsonBlockRegex = RegExp(
    r'<a2ui(?:\s[^>]*)?>[\s\S]*?</a2ui\s*>|```(?:json|a2ui)?\s*[\s\S]*?```|<a2ui-json>[\s\S]*?</a2ui-json>|\{\s*"version"\s*:\s*"v?[0-9\.]+"[\s\S]*\}|,\s*\{\s*"id"\s*:[\s\S]*\}|\{\s*"id"\s*:[\s\S]*?"component"[\s\S]*?\}|\{\s*"component"\s*:[\s\S]*?\}',
    caseSensitive: false,
  );

  /// Strips A2UI Express (`<a2ui>`) and JSON code blocks so they are not displayed in the chat view.
  static String sanitizeAssistantText(String raw) => _sanitizeAssistantText(raw);

  static String _sanitizeAssistantText(String raw) {
    String cleaned = raw;
    // Strip closed A2UI Express and JSON blocks first
    cleaned = cleaned.replaceAll(_a2uiJsonBlockRegex, '');
    // Strip in-progress code blocks and tags during streaming
    final unclosedExpressTag =
        RegExp(r'<a2ui(?:\s[^>]*)?>[\s\S]*$', caseSensitive: false);
    cleaned = cleaned.replaceAll(unclosedExpressTag, '');
    final unclosedCodeBlock =
        RegExp(r'```(?:json|a2ui)?\s*[\s\S]*$', caseSensitive: false);
    cleaned = cleaned.replaceAll(unclosedCodeBlock, '');
    final unclosedTag = RegExp(r'<a2ui-json>[\s\S]*$', caseSensitive: false);
    cleaned = cleaned.replaceAll(unclosedTag, '');
    // Strip trailing/dangling JSON fragments like ", { ... " or indented JSON
    final danglingJson = RegExp(
      r',?\s*\{\s*"(?:id|component|title|version|createSurface)"[\s\S]*$',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(danglingJson, '');
    return cleaned.trim();
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

    // 3. Handle A2UI operations if invoked as tools
    const a2uiOpMap = {
      'createsurface': 'createSurface',
      'updatecomponents': 'updateComponents',
      'updatedatamodel': 'updateDataModel',
      'deletesurface': 'deleteSurface',
    };
    final normalizedOp = a2uiOpMap[tc.name.toLowerCase().replaceAll('_', '')];
    if (normalizedOp != null) {
      try {
        final payload = <String, dynamic>{
          'version': '1.0',
          normalizedOp: tc.arguments,
        };
        _processDecodedPayload(payload);
        return mp.MCPToolResult.text(
          'Surface operation $normalizedOp executed successfully',
        );
      } catch (e) {
        return mp.MCPToolResult.text('A2UI tool error: $e');
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

    if (useExpressFormat) {
      try {
        final expressSnippet = a2ui_agent.ExpressPromptGenerator(
          [_catalog],
        ).generate();
        buffer.writeln('### Agent-to-User Interface (A2UI 1.0 Express) Instructions');
        buffer.writeln(expressSnippet.trim());
        final customNames = _catalog.components.values
            .where((c) => !_basicComponentNames.contains(c.name) && c.name != 'ChatMessage')
            .map((c) => c.name)
            .toList();
        if (customNames.isNotEmpty) {
          buffer.writeln();
          buffer.writeln(
            'Prefer these custom domain components whenever applicable: ${customNames.join(', ')}.',
          );
        }
        return buffer.toString();
      } catch (_) {
        // Fall through to raw JSON prompt if ExpressPromptGenerator cannot describe the catalog
      }
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
    final customComps = <ComponentImplementation>[];
    final basicNames = <String>[];
    for (final comp in _catalog.components.values) {
      if (_basicComponentNames.contains(comp.name) || comp.name == 'ChatMessage') {
        basicNames.add(comp.name);
      } else {
        customComps.add(comp);
      }
    }
    if (customComps.isNotEmpty) {
      buffer.writeln('Custom domain components (PREFERRED — follow these exact JSON schemas):');
      for (final comp in customComps) {
        buffer.writeln('- **${comp.name}**: `${jsonEncode(comp.schema.value)}`');
      }
    }
    if (basicNames.isNotEmpty) {
      buffer.writeln('Standard layout/basic components: ${basicNames.join(', ')}');
    }
    buffer.writeln();
    buffer.writeln(
      'Standard protocol messages:\n'
      '1. Direct shorthand (RECOMMENDED — emit one JSON object per widget): {"component": "ComponentName", ...requiredPropertiesFromSchema}\n'
      '2. Standard A2UI batch: [{"version": "1.0", "createSurface": {"surfaceId": "...", "catalogId": "${_catalog.id}"}}, {"version": "1.0", "updateComponents": {"surfaceId": "...", "components": [{"id": "root", "component": "ComponentName", ...}]}}]\n'
      'Always include "component": "<ComponentName>" and all required properties from the component schema.',
    );

    return buffer.toString();
  }

  /// Exposes the generated A2UI system prompt (visible for testing).
  String buildEffectiveSystemPrompt() => _buildSystemPrompt();

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
    if (_llmConfig != config) {
      _llmConfig = config;
      notifyListeners();
    }
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
    _errorSubscription?.unsubscribe();
    super.dispose();
  }
}
