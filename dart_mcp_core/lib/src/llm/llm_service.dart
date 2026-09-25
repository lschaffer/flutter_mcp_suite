import 'dart:async';
import 'dart:convert';
import 'package:googleai_dart/googleai_dart.dart' as gemini;
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:ollama_dart/ollama_dart.dart' as ollama;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'llm_response.dart';

const _uuid = Uuid();

/// Service provider class wrapping client integrations for various LLM SDKs.
class LLMService {
  static final Map<String, dynamic> _clientCache = {};

  /// Pluggable delegate to handle embedded (on-device) models execution.
  static Future<LLMResponse> Function({
    required LlmConfig config,
    required List<ChatMessage> messages,
    required List<MCPTool> tools,
    String? systemPrompt,
  })? embeddedHandler;

  /// Pluggable delegate to handle streaming embedded (on-device) models execution.
  static Stream<LLMStreamChunk> Function({
    required LlmConfig config,
    required List<ChatMessage> messages,
    required List<MCPTool> tools,
    String? systemPrompt,
  })? embeddedStreamHandler;

  static T _getOrCreateClient<T>({
    required String key,
    required T Function() create,
  }) {
    if (_clientCache.containsKey(key)) {
      return _clientCache[key] as T;
    }
    final client = create();
    _clientCache[key] = client;
    return client;
  }

  /// Clears cached LLM clients and closes any GoogleAIClient instances.
  static void clearCache() {
    for (final client in _clientCache.values) {
      if (client is gemini.GoogleAIClient) {
        try {
          client.close();
        } catch (_) {}
      }
    }
    _clientCache.clear();
  }

  /// Generate completion using direct SDK adapters.
  static Future<LLMResponse> generate({
    required LlmConfig config,
    required List<ChatMessage> messages,
    required List<MCPTool> tools,
    String? systemPrompt,
  }) async {
    switch (config.provider) {
      case LlmProvider.openai:
      case LlmProvider.openaiCompatible:
        return await _generateOpenAI(config, messages, tools, systemPrompt);
      case LlmProvider.mistral:
        return await _generateMistral(config, messages, tools, systemPrompt);
      case LlmProvider.claude:
        return await _generateAnthropic(config, messages, tools, systemPrompt);
      case LlmProvider.gemini:
        return await _generateGemini(config, messages, tools, systemPrompt);
      case LlmProvider.ollama:
        return await _generateOllama(config, messages, tools, systemPrompt);
      case LlmProvider.embedded:
        final handler = embeddedHandler;
        if (handler == null) {
          throw Exception('Embedded model handler not registered on LLMService.');
        }
        return await handler(
          config: config,
          messages: messages,
          tools: tools,
          systemPrompt: systemPrompt,
        );
      default:
        throw Exception(
          'LLM provider not configured or unsupported: ${config.provider}',
        );
    }
  }

  /// Generate completion stream using direct SDK adapters.
  static Stream<LLMStreamChunk> generateStream({
    required LlmConfig config,
    required List<ChatMessage> messages,
    required List<MCPTool> tools,
    String? systemPrompt,
  }) async* {
    switch (config.provider) {
      case LlmProvider.openai:
      case LlmProvider.openaiCompatible:
        yield* _streamOpenAI(config, messages, tools, systemPrompt);
      case LlmProvider.mistral:
        yield* _streamMistral(config, messages, tools, systemPrompt);
      case LlmProvider.claude:
        yield* _streamAnthropic(config, messages, tools, systemPrompt);
      case LlmProvider.gemini:
        yield* _streamGemini(config, messages, tools, systemPrompt);
      case LlmProvider.ollama:
        yield* _streamOllama(config, messages, tools, systemPrompt);
      case LlmProvider.embedded:
        final streamHandler = embeddedStreamHandler;
        if (streamHandler == null) {
          throw Exception('Embedded model stream handler not registered on LLMService.');
        }
        yield* streamHandler(
          config: config,
          messages: messages,
          tools: tools,
          systemPrompt: systemPrompt,
        );
      default:
        throw Exception(
          'LLM provider not configured or unsupported for streaming: ${config.provider}',
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. OpenAI Adapter
  // ═══════════════════════════════════════════════════════════════
  static List<openai.ChatMessage> _buildOpenAiChatMessages(
    List<ChatMessage> messages,
    String? systemPrompt,
  ) {
    final List<openai.ChatMessage> openAiMsgs = [];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      openAiMsgs.add(openai.ChatMessage.system(systemPrompt));
    }

    int i = 0;
    while (i < messages.length) {
      final msg = messages[i];
      if (msg.role == ChatRole.system) {
        if (msg.content.isNotEmpty) {
          openAiMsgs.add(openai.ChatMessage.system(msg.content));
        }
        i++;
      } else if (msg.role == ChatRole.user) {
        openAiMsgs.add(openai.ChatMessage.user(msg.content));
        i++;
      } else if (msg.role == ChatRole.tool) {
        openAiMsgs.add(
          openai.ChatMessage.tool(toolCallId: msg.id, content: msg.content),
        );
        i++;
      } else if (msg.role == ChatRole.assistant) {
        final textParts = <String>[];
        final toolCalls = <openai.ToolCall>[];

        while (i < messages.length && messages[i].role == ChatRole.assistant) {
          final aMsg = messages[i];
          if (aMsg.type == MessageType.toolCall && aMsg.toolName != null) {
            toolCalls.add(
              openai.ToolCall.functionCall(
                id: aMsg.id,
                call: openai.FunctionCall.fromMap(
                  name: aMsg.toolName!,
                  arguments: aMsg.toolArguments ?? {},
                ),
              ),
            );
          } else if (aMsg.content.isNotEmpty) {
            textParts.add(aMsg.content);
          }
          i++;
        }

        final combinedText = textParts.join('\n');
        if (toolCalls.isNotEmpty) {
          openAiMsgs.add(
            openai.ChatMessage.assistant(
              content: combinedText.isNotEmpty ? combinedText : null,
              toolCalls: toolCalls,
            ),
          );
        } else if (combinedText.isNotEmpty) {
          openAiMsgs.add(openai.ChatMessage.assistant(content: combinedText));
        }
      } else {
        i++;
      }
    }

    return openAiMsgs;
  }

  static Future<LLMResponse> _generateOpenAIWithClient(
    openai.OpenAIClient client,
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async {
    final openAiMsgs = _buildOpenAiChatMessages(messages, systemPrompt);

    final List<openai.Tool> openAiTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      for (final t in tools) {
        openAiTools.add(
          openai.Tool.function(
            name: t.name,
            description: t.description ?? '',
            parameters: t.inputSchema ?? {'type': 'object', 'properties': {}},
          ),
        );
      }
    }

    final response = await client.chat.completions.create(
      openai.ChatCompletionCreateRequest(
        model: config.model.trim().isNotEmpty ? config.model : 'gpt-4o-mini',
        messages: openAiMsgs,
        tools: openAiTools.isNotEmpty ? openAiTools : null,
        temperature: config.temperature,
        maxTokens: config.maxTokens > 0 ? config.maxTokens : null,
        topP: config.topP,
        seed: config.seed,
      ),
    );

    final choice = response.choices.first;
    final answer = choice.message.content ?? '';
    final toolCalls = <LLMToolCall>[];

    if (choice.message.toolCalls != null) {
      for (final tc in choice.message.toolCalls!) {
        if (tc.type == 'function') {
          Map<String, dynamic> args = {};
          try {
            args = jsonDecode(tc.function.arguments) as Map<String, dynamic>;
          } catch (_) {}
          toolCalls.add(
            LLMToolCall(id: tc.id, name: tc.function.name, arguments: args),
          );
        }
      }
    }

    final rawUsage = response.usage;
    final usage = rawUsage != null
        ? LLMUsage(
            promptTokens: rawUsage.promptTokens ?? 0,
            completionTokens: rawUsage.completionTokens ?? 0,
            totalTokens: rawUsage.totalTokens ?? 0,
          )
        : null;

    return LLMResponse(text: answer, toolCalls: toolCalls, usage: usage);
  }

  static Future<LLMResponse> _generateOpenAI(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async {
    final baseUrl = config.baseUrl.trim().isNotEmpty
        ? config.baseUrl
        : 'https://api.openai.com/v1';
    final cacheKey = 'openai_${config.apiKey}_$baseUrl';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => openai.OpenAIClient(
        config: openai.OpenAIConfig(
          authProvider: openai.ApiKeyProvider(config.apiKey),
          baseUrl: baseUrl,
        ),
      ),
    );
    return await _generateOpenAIWithClient(
      client,
      config,
      messages,
      tools,
      systemPrompt,
    );
  }

  static Future<LLMResponse> _generateMistral(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async {
    final baseUrl = config.baseUrl.trim().isNotEmpty
        ? config.baseUrl
        : 'https://api.mistral.ai/v1';
    final cacheKey = 'mistral_${config.apiKey}_$baseUrl';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => openai.OpenAIClient(
        config: openai.OpenAIConfig(
          authProvider: openai.ApiKeyProvider(config.apiKey),
          baseUrl: baseUrl,
        ),
        httpClient: _MistralPatchClient(http.Client()),
      ),
    );
    return await _generateOpenAIWithClient(
      client,
      config,
      messages,
      tools,
      systemPrompt,
    );
  }

  static Stream<LLMStreamChunk> _streamOpenAI(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) {
    final baseUrl = config.baseUrl.trim().isNotEmpty
        ? config.baseUrl
        : 'https://api.openai.com/v1';
    final cacheKey = 'openai_${config.apiKey}_$baseUrl';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => openai.OpenAIClient(
        config: openai.OpenAIConfig(
          authProvider: openai.ApiKeyProvider(config.apiKey),
          baseUrl: baseUrl,
        ),
      ),
    );
    return _streamOpenAIWithClient(client, config, messages, tools, systemPrompt);
  }

  static Stream<LLMStreamChunk> _streamMistral(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) {
    final baseUrl = config.baseUrl.trim().isNotEmpty
        ? config.baseUrl
        : 'https://api.mistral.ai/v1';
    final cacheKey = 'mistral_${config.apiKey}_$baseUrl';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => openai.OpenAIClient(
        config: openai.OpenAIConfig(
          authProvider: openai.ApiKeyProvider(config.apiKey),
          baseUrl: baseUrl,
        ),
        httpClient: _MistralPatchClient(http.Client()),
      ),
    );
    return _streamOpenAIWithClient(client, config, messages, tools, systemPrompt);
  }

  static Stream<LLMStreamChunk> _streamOpenAIWithClient(
    openai.OpenAIClient client,
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async* {
    final openAiMsgs = _buildOpenAiChatMessages(messages, systemPrompt);

    final List<openai.Tool> openAiTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      for (final t in tools) {
        openAiTools.add(
          openai.Tool.function(
            name: t.name,
            description: t.description ?? '',
            parameters: t.inputSchema ?? {'type': 'object', 'properties': {}},
          ),
        );
      }
    }

    final stream = client.chat.completions.createStream(
      openai.ChatCompletionCreateRequest(
        model: config.model.trim().isNotEmpty ? config.model : 'gpt-4o-mini',
        messages: openAiMsgs,
        tools: openAiTools.isNotEmpty ? openAiTools : null,
        temperature: config.temperature,
        maxTokens: config.maxTokens > 0 ? config.maxTokens : null,
        topP: config.topP,
        seed: config.seed,
      ),
    );

    final textBuffer = StringBuffer();
    final Map<int, Map<String, dynamic>> toolCallAccumulators = {};

    await for (final event in stream) {
      final choice = event.choices?.firstOrNull;
      if (choice != null) {
        final content = choice.delta.content;
        if (content != null && content.isNotEmpty) {
          textBuffer.write(content);
          yield LLMStreamChunk(textDelta: content);
        }

        final deltas = choice.delta.toolCalls;
        if (deltas != null) {
          for (final d in deltas) {
            final idx = d.index;
            final acc = toolCallAccumulators.putIfAbsent(idx, () => <String, dynamic>{
              'id': '',
              'name': '',
              'arguments': StringBuffer(),
            });
            if (d.id != null) acc['id'] = d.id;
            if (d.function?.name != null) acc['name'] = d.function!.name;
            if (d.function?.arguments != null) {
              (acc['arguments'] as StringBuffer).write(d.function!.arguments);
            }
          }
        }
      }
    }

    final toolCalls = <LLMToolCall>[];
    for (final acc in toolCallAccumulators.values) {
      final id = acc['id'] as String;
      final name = acc['name'] as String;
      final argsStr = (acc['arguments'] as StringBuffer).toString();
      Map<String, dynamic> args = {};
      try {
        args = jsonDecode(argsStr) as Map<String, dynamic>;
      } catch (_) {}
      if (name.isNotEmpty) {
        toolCalls.add(
          LLMToolCall(
            id: id.isNotEmpty ? id : 'call_${name}_${_uuid.v4()}',
            name: name,
            arguments: args,
          ),
        );
      }
    }

    yield LLMStreamChunk(
      textDelta: '',
      isDone: true,
      finalResponse: LLMResponse(text: textBuffer.toString(), toolCalls: toolCalls),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. Anthropic Claude Adapter
  // ═══════════════════════════════════════════════════════════════
  static Future<LLMResponse> _generateAnthropic(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async {
    final cacheKey = 'anthropic_${config.apiKey}';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => anthropic.AnthropicClient(
        config: anthropic.AnthropicConfig(
          authProvider: anthropic.ApiKeyProvider(config.apiKey),
        ),
      ),
    );

    final List<
      MapEntry<anthropic.MessageRole, List<anthropic.InputContentBlock>>
    >
    grouped = [];

    for (final msg in messages) {
      if (msg.role == ChatRole.system) continue;

      final isAssistant = (msg.role == ChatRole.assistant);
      final anthropicRole = isAssistant
          ? anthropic.MessageRole.assistant
          : anthropic.MessageRole.user;

      final List<anthropic.InputContentBlock> blocks = [];
      if (msg.role == ChatRole.user) {
        if (msg.content.isNotEmpty) {
          blocks.add(anthropic.InputContentBlock.text(msg.content));
        }
      } else if (msg.role == ChatRole.assistant) {
        if (msg.type == MessageType.toolCall) {
          blocks.add(
            anthropic.InputContentBlock.toolUse(
              id: msg.id,
              name: msg.toolName ?? '',
              input: msg.toolArguments ?? {},
            ),
          );
        } else {
          if (msg.content.isNotEmpty) {
            blocks.add(anthropic.InputContentBlock.text(msg.content));
          }
        }
      } else if (msg.role == ChatRole.tool) {
        blocks.add(
          anthropic.InputContentBlock.toolResultText(
            toolUseId: msg.id,
            text: msg.content,
          ),
        );
      }

      if (blocks.isEmpty) continue;

      if (grouped.isNotEmpty && grouped.last.key == anthropicRole) {
        grouped.last.value.addAll(blocks);
      } else {
        grouped.add(MapEntry(anthropicRole, blocks));
      }
    }

    final List<anthropic.InputMessage> anthropicMsgs = [];
    for (final entry in grouped) {
      if (entry.key == anthropic.MessageRole.assistant) {
        anthropicMsgs.add(anthropic.InputMessage.assistantBlocks(entry.value));
      } else {
        anthropicMsgs.add(anthropic.InputMessage.userBlocks(entry.value));
      }
    }

    final List<anthropic.ToolDefinition> anthropicTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      for (final t in tools) {
        anthropicTools.add(
          anthropic.ToolDefinition.custom(
            anthropic.Tool(
              name: t.name,
              description: t.description ?? '',
              inputSchema: anthropic.InputSchema.fromJson(
                t.inputSchema ?? {'type': 'object', 'properties': {}},
              ),
            ),
          ),
        );
      }
    }

    final response = await client.messages.create(
      anthropic.MessageCreateRequest(
        model: config.model.trim().isNotEmpty
            ? config.model
            : 'claude-3-5-sonnet-latest',
        messages: anthropicMsgs,
        system: systemPrompt != null && systemPrompt.trim().isNotEmpty
            ? anthropic.SystemPrompt.text(systemPrompt)
            : null,
        tools: anthropicTools.isNotEmpty ? anthropicTools : null,
        temperature: config.temperature,
        maxTokens: config.maxTokens > 0 ? config.maxTokens : 4096,
        topP: config.topP,
        topK: config.topK,
      ),
    );

    final textBuffer = StringBuffer();
    final toolCalls = <LLMToolCall>[];

    for (final block in response.content) {
      if (block is anthropic.TextBlock) {
        textBuffer.write(block.text);
      } else if (block is anthropic.ToolUseBlock) {
        toolCalls.add(
          LLMToolCall(id: block.id, name: block.name, arguments: block.input),
        );
      }
    }

    return LLMResponse(text: textBuffer.toString(), toolCalls: toolCalls);
  }

  static Stream<LLMStreamChunk> _streamAnthropic(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async* {
    final cacheKey = 'anthropic_${config.apiKey}';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => anthropic.AnthropicClient(
        config: anthropic.AnthropicConfig(
          authProvider: anthropic.ApiKeyProvider(config.apiKey),
        ),
      ),
    );

    final List<MapEntry<anthropic.MessageRole, List<anthropic.InputContentBlock>>> grouped = [];

    for (final msg in messages) {
      if (msg.role == ChatRole.system) continue;

      final isAssistant = (msg.role == ChatRole.assistant);
      final anthropicRole = isAssistant
          ? anthropic.MessageRole.assistant
          : anthropic.MessageRole.user;

      final List<anthropic.InputContentBlock> blocks = [];
      if (msg.role == ChatRole.user) {
        if (msg.content.isNotEmpty) {
          blocks.add(anthropic.InputContentBlock.text(msg.content));
        }
      } else if (msg.role == ChatRole.assistant) {
        if (msg.type == MessageType.toolCall) {
          blocks.add(
            anthropic.InputContentBlock.toolUse(
              id: msg.id,
              name: msg.toolName ?? '',
              input: msg.toolArguments ?? {},
            ),
          );
        } else {
          if (msg.content.isNotEmpty) {
            blocks.add(anthropic.InputContentBlock.text(msg.content));
          }
        }
      } else if (msg.role == ChatRole.tool) {
        blocks.add(
          anthropic.InputContentBlock.toolResultText(
            toolUseId: msg.id,
            text: msg.content,
          ),
        );
      }

      if (blocks.isEmpty) continue;

      if (grouped.isNotEmpty && grouped.last.key == anthropicRole) {
        grouped.last.value.addAll(blocks);
      } else {
        grouped.add(MapEntry(anthropicRole, blocks));
      }
    }

    final List<anthropic.InputMessage> anthropicMsgs = [];
    for (final entry in grouped) {
      if (entry.key == anthropic.MessageRole.assistant) {
        anthropicMsgs.add(anthropic.InputMessage.assistantBlocks(entry.value));
      } else {
        anthropicMsgs.add(anthropic.InputMessage.userBlocks(entry.value));
      }
    }

    final List<anthropic.ToolDefinition> anthropicTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      for (final t in tools) {
        anthropicTools.add(
          anthropic.ToolDefinition.custom(
            anthropic.Tool(
              name: t.name,
              description: t.description ?? '',
              inputSchema: anthropic.InputSchema.fromJson(
                t.inputSchema ?? {'type': 'object', 'properties': {}},
              ),
            ),
          ),
        );
      }
    }

    final stream = client.messages.createStream(
      anthropic.MessageCreateRequest(
        model: config.model.trim().isNotEmpty
            ? config.model
            : 'claude-3-5-sonnet-latest',
        messages: anthropicMsgs,
        system: systemPrompt != null && systemPrompt.trim().isNotEmpty
            ? anthropic.SystemPrompt.text(systemPrompt)
            : null,
        tools: anthropicTools.isNotEmpty ? anthropicTools : null,
        temperature: config.temperature,
        maxTokens: config.maxTokens > 0 ? config.maxTokens : 4096,
        topP: config.topP,
        topK: config.topK,
      ),
    );

    final textBuffer = StringBuffer();
    final Map<int, Map<String, dynamic>> toolCallAccumulators = {};

    await for (final event in stream) {
      if (event is anthropic.ContentBlockStartEvent) {
        final block = event.contentBlock;
        if (block is anthropic.ToolUseBlock) {
          toolCallAccumulators[event.index] = {
            'id': block.id,
            'name': block.name,
            'arguments': StringBuffer(),
          };
        }
      } else if (event is anthropic.ContentBlockDeltaEvent) {
        final delta = event.delta;
        if (delta is anthropic.TextDelta) {
          textBuffer.write(delta.text);
          yield LLMStreamChunk(textDelta: delta.text);
        } else if (delta is anthropic.InputJsonDelta) {
          final acc = toolCallAccumulators[event.index];
          if (acc != null) {
            (acc['arguments'] as StringBuffer).write(delta.partialJson);
          }
        }
      }
    }

    final toolCalls = <LLMToolCall>[];
    for (final acc in toolCallAccumulators.values) {
      final id = acc['id'] as String;
      final name = acc['name'] as String;
      final argsStr = (acc['arguments'] as StringBuffer).toString();
      Map<String, dynamic> args = {};
      try {
        args = jsonDecode(argsStr) as Map<String, dynamic>;
      } catch (_) {}
      if (name.isNotEmpty) {
        toolCalls.add(LLMToolCall(id: id, name: name, arguments: args));
      }
    }

    yield LLMStreamChunk(
      textDelta: '',
      isDone: true,
      finalResponse: LLMResponse(text: textBuffer.toString(), toolCalls: toolCalls),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. Gemini Adapter
  // ═══════════════════════════════════════════════════════════════
  static Future<LLMResponse> _generateGemini(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async {
    final cacheKey = 'gemini_${config.apiKey}';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => gemini.GoogleAIClient(
        config: gemini.GoogleAIConfig.googleAI(
          authProvider: gemini.ApiKeyProvider(config.apiKey),
        ),
      ),
    );

    final List<gemini.Tool> geminiTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      final declarations = <gemini.FunctionDeclaration>[];
      for (final t in tools) {
        declarations.add(
          gemini.FunctionDeclaration(
            name: t.name,
            description: t.description ?? '',
            parameters: _sanitizeGeminiSchema(t.inputSchema),
          ),
        );
      }
      geminiTools.add(gemini.Tool(functionDeclarations: declarations));
    }

    final List<MapEntry<String, List<gemini.Part>>> grouped = [];

    for (final msg in messages) {
      if (msg.role == ChatRole.system) continue;

      final String geminiRole;
      final List<gemini.Part> parts = [];

      switch (msg.role) {
        case ChatRole.user:
          geminiRole = 'user';
          if (msg.content.isNotEmpty) {
            parts.add(gemini.Part.text(msg.content));
          }
        case ChatRole.assistant:
          geminiRole = 'model';
          if (msg.type == MessageType.toolCall) {
            parts.add(
              gemini.Part.functionCall(
                msg.toolName ?? '',
                args: msg.toolArguments,
              ),
            );
          } else {
            if (msg.content.isNotEmpty) {
              parts.add(gemini.Part.text(msg.content));
            }
          }
        case ChatRole.tool:
          geminiRole = 'function';
          parts.add(
            gemini.Part.functionResponse(msg.toolName ?? '', {
              'content': msg.content,
            }),
          );
        default:
          continue;
      }

      if (parts.isEmpty) continue;

      if (grouped.isNotEmpty && grouped.last.key == geminiRole) {
        grouped.last.value.addAll(parts);
      } else {
        grouped.add(MapEntry(geminiRole, parts));
      }
    }

    final List<gemini.Content> contentList = [];
    for (final entry in grouped) {
      contentList.add(gemini.Content(role: entry.key, parts: entry.value));
    }

    final response = await client.models.generateContent(
      model: config.model.trim().isNotEmpty ? config.model : 'gemini-2.5-flash',
      request: gemini.GenerateContentRequest(
        contents: contentList,
        tools: geminiTools.isNotEmpty ? geminiTools : null,
        systemInstruction:
            systemPrompt != null && systemPrompt.trim().isNotEmpty
            ? gemini.Content(parts: [gemini.Part.text(systemPrompt)])
            : null,
        generationConfig: gemini.GenerationConfig(
          temperature: config.temperature,
          maxOutputTokens: config.maxTokens > 0 ? config.maxTokens : null,
          topP: config.topP,
          topK: config.topK,
          candidateCount: 1,
        ),
      ),
    );

    final text = response.text ?? '';
    final toolCalls = <LLMToolCall>[];

    final functionCalls = response.functionCalls;
    if (functionCalls.isNotEmpty) {
      for (final fc in functionCalls) {
        final args = Map<String, dynamic>.from(fc.args ?? {});
        toolCalls.add(
          LLMToolCall(
            id: 'call_${fc.name}_${_uuid.v4()}',
            name: fc.name,
            arguments: args,
          ),
        );
      }
    }

    return LLMResponse(text: text, toolCalls: toolCalls);
  }

  static gemini.Schema _sanitizeGeminiSchema(Map<String, dynamic>? schema) {
    if (schema == null) {
      return const gemini.Schema(type: gemini.SchemaType.string);
    }
    final typeStr = (schema['type'] ?? 'string').toString().toLowerCase();

    final desc = schema['description'] as String?;
    final properties = schema['properties'] as Map?;
    final requiredProps = (schema['required'] as List?)?.cast<String>() ?? [];

    switch (typeStr) {
      case 'object':
        final propsMap = <String, gemini.Schema>{};
        if (properties != null) {
          for (final entry in properties.entries) {
            if (entry.value is Map) {
              propsMap[entry.key.toString()] = _sanitizeGeminiSchema(
                Map<String, dynamic>.from(entry.value as Map),
              );
            }
          }
        }
        return gemini.Schema(
          type: gemini.SchemaType.object,
          description: desc,
          properties: propsMap,
          required: requiredProps,
        );
      case 'array':
        final items = schema['items'];
        final itemsSchema = items is Map
            ? _sanitizeGeminiSchema(Map<String, dynamic>.from(items))
            : const gemini.Schema(type: gemini.SchemaType.string);
        return gemini.Schema(
          type: gemini.SchemaType.array,
          description: desc,
          items: itemsSchema,
        );
      case 'integer':
        return gemini.Schema(
          type: gemini.SchemaType.integer,
          description: desc,
        );
      case 'number':
        return gemini.Schema(type: gemini.SchemaType.number, description: desc);
      case 'boolean':
        return gemini.Schema(
          type: gemini.SchemaType.boolean,
          description: desc,
        );
      default:
        return gemini.Schema(type: gemini.SchemaType.string, description: desc);
    }
  }

  static Stream<LLMStreamChunk> _streamGemini(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async* {
    final cacheKey = 'gemini_${config.apiKey}';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => gemini.GoogleAIClient(
        config: gemini.GoogleAIConfig.googleAI(
          authProvider: gemini.ApiKeyProvider(config.apiKey),
        ),
      ),
    );

    final List<gemini.Tool> geminiTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      final declarations = <gemini.FunctionDeclaration>[];
      for (final t in tools) {
        declarations.add(
          gemini.FunctionDeclaration(
            name: t.name,
            description: t.description ?? '',
            parameters: _sanitizeGeminiSchema(t.inputSchema),
          ),
        );
      }
      geminiTools.add(gemini.Tool(functionDeclarations: declarations));
    }

    final List<MapEntry<String, List<gemini.Part>>> grouped = [];

    for (final msg in messages) {
      if (msg.role == ChatRole.system) continue;

      final String geminiRole;
      final List<gemini.Part> parts = [];

      switch (msg.role) {
        case ChatRole.user:
          geminiRole = 'user';
          if (msg.content.isNotEmpty) {
            parts.add(gemini.Part.text(msg.content));
          }
        case ChatRole.assistant:
          geminiRole = 'model';
          if (msg.type == MessageType.toolCall) {
            parts.add(
              gemini.Part.functionCall(
                msg.toolName ?? '',
                args: msg.toolArguments,
              ),
            );
          } else {
            if (msg.content.isNotEmpty) {
              parts.add(gemini.Part.text(msg.content));
            }
          }
        case ChatRole.tool:
          geminiRole = 'function';
          parts.add(
            gemini.Part.functionResponse(msg.toolName ?? '', {
              'content': msg.content,
            }),
          );
        default:
          continue;
      }

      if (parts.isEmpty) continue;

      if (grouped.isNotEmpty && grouped.last.key == geminiRole) {
        grouped.last.value.addAll(parts);
      } else {
        grouped.add(MapEntry(geminiRole, parts));
      }
    }

    final List<gemini.Content> contentList = [];
    for (final entry in grouped) {
      contentList.add(gemini.Content(role: entry.key, parts: entry.value));
    }

    final stream = client.models.streamGenerateContent(
      model: config.model.trim().isNotEmpty ? config.model : 'gemini-2.5-flash',
      request: gemini.GenerateContentRequest(
        contents: contentList,
        tools: geminiTools.isNotEmpty ? geminiTools : null,
        systemInstruction:
            systemPrompt != null && systemPrompt.trim().isNotEmpty
            ? gemini.Content(parts: [gemini.Part.text(systemPrompt)])
            : null,
        generationConfig: gemini.GenerationConfig(
          temperature: config.temperature,
          maxOutputTokens: config.maxTokens > 0 ? config.maxTokens : null,
          topP: config.topP,
          topK: config.topK,
          candidateCount: 1,
        ),
      ),
    );

    final textBuffer = StringBuffer();
    final toolCalls = <LLMToolCall>[];

    await for (final response in stream) {
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        textBuffer.write(text);
        yield LLMStreamChunk(textDelta: text);
      }

      final functionCalls = response.functionCalls;
      if (functionCalls.isNotEmpty) {
        for (final fc in functionCalls) {
          final args = Map<String, dynamic>.from(fc.args ?? {});
          toolCalls.add(
            LLMToolCall(
              id: 'call_${fc.name}_${_uuid.v4()}',
              name: fc.name,
              arguments: args,
            ),
          );
        }
      }
    }

    yield LLMStreamChunk(
      textDelta: '',
      isDone: true,
      finalResponse: LLMResponse(text: textBuffer.toString(), toolCalls: toolCalls),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. Ollama Adapter
  // ═══════════════════════════════════════════════════════════════
  static List<ollama.ChatMessage> _buildOllamaChatMessages(
    List<ChatMessage> messages,
    String? systemPrompt,
  ) {
    final List<ollama.ChatMessage> ollamaMsgs = [];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      ollamaMsgs.add(
        ollama.ChatMessage(
          role: ollama.MessageRole.system,
          content: systemPrompt,
        ),
      );
    }

    int i = 0;
    while (i < messages.length) {
      final msg = messages[i];
      if (msg.role == ChatRole.system) {
        if (msg.content.isNotEmpty) {
          ollamaMsgs.add(
            ollama.ChatMessage(
              role: ollama.MessageRole.system,
              content: msg.content,
            ),
          );
        }
        i++;
      } else if (msg.role == ChatRole.user) {
        ollamaMsgs.add(
          ollama.ChatMessage(
            role: ollama.MessageRole.user,
            content: msg.content,
          ),
        );
        i++;
      } else if (msg.role == ChatRole.tool) {
        ollamaMsgs.add(
          ollama.ChatMessage(
            role: ollama.MessageRole.tool,
            content: msg.content,
          ),
        );
        i++;
      } else if (msg.role == ChatRole.assistant) {
        final textParts = <String>[];
        final toolCalls = <ollama.ToolCall>[];

        while (i < messages.length && messages[i].role == ChatRole.assistant) {
          final aMsg = messages[i];
          if (aMsg.type == MessageType.toolCall && aMsg.toolName != null) {
            toolCalls.add(
              ollama.ToolCall(
                function: ollama.ToolCallFunction(
                  name: aMsg.toolName!,
                  arguments: aMsg.toolArguments ?? {},
                ),
              ),
            );
          } else if (aMsg.content.isNotEmpty) {
            textParts.add(aMsg.content);
          }
          i++;
        }

        final combinedText = textParts.join('\n');
        ollamaMsgs.add(
          ollama.ChatMessage(
            role: ollama.MessageRole.assistant,
            content: combinedText,
            toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
          ),
        );
      } else {
        i++;
      }
    }

    return ollamaMsgs;
  }

  static Future<LLMResponse> _generateOllama(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async {
    final headers = <String, String>{};
    if (config.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey.trim()}';
    }
    final baseUrl = config.baseUrl.trim().isNotEmpty
        ? config.baseUrl
        : 'http://localhost:11434/api';
    final cacheKey = 'ollama_${config.apiKey}_$baseUrl';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => ollama.OllamaClient(
        config: ollama.OllamaConfig(baseUrl: baseUrl, defaultHeaders: headers),
      ),
    );

    final ollamaMsgs = _buildOllamaChatMessages(messages, systemPrompt);

    final List<ollama.ToolDefinition> ollamaTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      for (final t in tools) {
        ollamaTools.add(
          ollama.ToolDefinition(
            function: ollama.ToolFunction(
              name: t.name,
              description: t.description ?? '',
              parameters: t.inputSchema ?? {'type': 'object', 'properties': {}},
            ),
          ),
        );
      }
    }

    final response = await client.chat.create(
      request: ollama.ChatRequest(
        model: config.model,
        messages: ollamaMsgs,
        tools: ollamaTools.isNotEmpty ? ollamaTools : null,
        options: ollama.ModelOptions(
          temperature: config.temperature,
          numPredict: config.maxTokens > 0 ? config.maxTokens : null,
          seed: config.seed,
          topP: config.topP,
          topK: config.topK,
          repeatPenalty: config.repeatPenalty,
        ),
      ),
    );

    final answer = response.message?.content ?? '';
    final toolCalls = <LLMToolCall>[];

    if (response.message?.toolCalls != null &&
        response.message!.toolCalls!.isNotEmpty) {
      for (final tc in response.message!.toolCalls!) {
        final name = tc.function?.name ?? '';
        final args = tc.function?.arguments ?? {};
        toolCalls.add(
          LLMToolCall(
            id: 'call_${name}_${_uuid.v4()}',
            name: name,
            arguments: args,
          ),
        );
      }
    }

    return LLMResponse(text: answer, toolCalls: toolCalls);
  }

  static Stream<LLMStreamChunk> _streamOllama(
    LlmConfig config,
    List<ChatMessage> messages,
    List<MCPTool> tools,
    String? systemPrompt,
  ) async* {
    final headers = <String, String>{};
    if (config.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey.trim()}';
    }
    final baseUrl = config.baseUrl.trim().isNotEmpty
        ? config.baseUrl
        : 'http://localhost:11434/api';
    final cacheKey = 'ollama_${config.apiKey}_$baseUrl';
    final client = _getOrCreateClient(
      key: cacheKey,
      create: () => ollama.OllamaClient(
        config: ollama.OllamaConfig(baseUrl: baseUrl, defaultHeaders: headers),
      ),
    );

    final ollamaMsgs = _buildOllamaChatMessages(messages, systemPrompt);

    final List<ollama.ToolDefinition> ollamaTools = [];
    if (tools.isNotEmpty && config.useNativeToolCall) {
      for (final t in tools) {
        ollamaTools.add(
          ollama.ToolDefinition(
            function: ollama.ToolFunction(
              name: t.name,
              description: t.description ?? '',
              parameters: t.inputSchema ?? {'type': 'object', 'properties': {}},
            ),
          ),
        );
      }
    }

    final stream = client.chat.createStream(
      request: ollama.ChatRequest(
        model: config.model,
        messages: ollamaMsgs,
        tools: ollamaTools.isNotEmpty ? ollamaTools : null,
        options: ollama.ModelOptions(
          temperature: config.temperature,
          numPredict: config.maxTokens > 0 ? config.maxTokens : null,
          seed: config.seed,
          topP: config.topP,
          topK: config.topK,
          repeatPenalty: config.repeatPenalty,
        ),
      ),
    );

    final textBuffer = StringBuffer();
    final toolCalls = <LLMToolCall>[];

    await for (final event in stream) {
      final content = event.message?.content;
      if (content != null && content.isNotEmpty) {
        textBuffer.write(content);
        yield LLMStreamChunk(textDelta: content);
      }

      final calls = event.message?.toolCalls;
      if (calls != null) {
        for (final tc in calls) {
          final fn = tc.function;
          if (fn != null) {
            final name = fn.name;
            final args = fn.arguments != null ? Map<String, dynamic>.from(fn.arguments!) : const <String, dynamic>{};
            toolCalls.add(
              LLMToolCall(
                id: 'call_${name}_${_uuid.v4()}',
                name: name,
                arguments: args,
              ),
            );
          }
        }
      }
    }

    yield LLMStreamChunk(
      textDelta: '',
      isDone: true,
      finalResponse: LLMResponse(text: textBuffer.toString(), toolCalls: toolCalls),
    );
  }
}

/// HTTP client wrapper that patches requests/responses for Mistral
/// compatibility (tool_call type field, tool messages, image_url format).
class _MistralPatchClient extends http.BaseClient {
  _MistralPatchClient(this._inner);
  final http.Client _inner;

  Map<String, dynamic> _sanitizeMistralChatRequest(
    Map<String, dynamic> payload,
  ) {
    final rawMessages = payload['messages'];
    if (rawMessages is! List) return payload;

    final sanitized = <dynamic>[];
    bool changed = false;

    for (final item in rawMessages) {
      if (item is! Map) {
        sanitized.add(item);
        continue;
      }

      final msg = Map<String, dynamic>.from(item);
      final role = (msg['role'] ?? '').toString();

      if (role == 'user') {
        final content = msg['content'];
        if (content is List) {
          final patchedContent = content.map((part) {
            if (part is! Map) return part;
            final partMap = Map<String, dynamic>.from(part);
            if (partMap['type'] == 'image_url') {
              final imageUrl = partMap['image_url'];
              if (imageUrl is Map) {
                final url = imageUrl['url'];
                if (url is String) {
                  partMap['image_url'] = url;
                  changed = true;
                }
              }
            }
            return partMap;
          }).toList();
          msg['content'] = patchedContent;
        }
      }

      if (role == 'tool') {
        final toolCallId = (msg['tool_call_id'] ?? '').toString().trim();
        Map<String, dynamic>? lastAssistant;
        for (int k = sanitized.length - 1; k >= 0; k--) {
          final s = sanitized[k];
          if (s is Map && s['role']?.toString() == 'assistant') {
            lastAssistant = s as Map<String, dynamic>;
            break;
          }
          if (s is Map && s['role']?.toString() != 'tool') {
            break;
          }
        }

        bool hasMatchingAssistantToolCall = false;
        if (lastAssistant != null) {
          final toolCalls = lastAssistant['tool_calls'];
          if (toolCalls is List) {
            hasMatchingAssistantToolCall = toolCalls.any((tc) {
              if (tc is! Map) return false;
              final tcMap = Map<String, dynamic>.from(tc);
              return (tcMap['id'] ?? '').toString().trim() == toolCallId;
            });
          }
        }

        if (!hasMatchingAssistantToolCall && toolCallId.isNotEmpty) {
          if (lastAssistant != null) {
            final existingCalls = (lastAssistant['tool_calls'] as List?) ?? [];
            lastAssistant['tool_calls'] = [
              ...existingCalls,
              {
                'id': toolCallId,
                'type': 'function',
                'function': {'name': 'tool_$toolCallId', 'arguments': '{}'},
              },
            ];
          } else {
            sanitized.add({
              'role': 'assistant',
              'content': null,
              'tool_calls': [
                {
                  'id': toolCallId,
                  'type': 'function',
                  'function': {'name': 'tool_$toolCallId', 'arguments': '{}'},
                },
              ],
            });
          }
          changed = true;
        }
      }

      sanitized.add(msg);
    }

    if (changed) {
      payload['messages'] = sanitized;
    }
    return payload;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    http.BaseRequest requestToSend = request;

    if (request.method.toUpperCase() == 'POST' &&
        request.url.path.contains('chat/completions') &&
        request is http.Request) {
      try {
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) {
          final patchedPayload = _sanitizeMistralChatRequest(decoded);
          final cleanHeaders = Map<String, String>.from(request.headers);
          cleanHeaders.removeWhere(
            (key, _) => key.toLowerCase() == 'content-length',
          );
          requestToSend = http.Request(request.method, request.url)
            ..headers.addAll(cleanHeaders)
            ..body = jsonEncode(patchedPayload);
        }
      } catch (_) {}
    }

    final streamed = await _inner.send(requestToSend);

    final bool isStreaming = (requestToSend is http.Request &&
            requestToSend.body.contains('"stream":true')) ||
        (requestToSend.headers['accept']?.contains('text/event-stream') ?? false);

    if (!request.url.path.contains('chat/completions') || isStreaming) {
      return streamed;
    }

    final bodyBytes = await streamed.stream.toBytes();
    final bodyStr = utf8.decode(bodyBytes);

    String patched = bodyStr;
    try {
      final dynamic decoded = jsonDecode(bodyStr);
      if (decoded is Map<String, dynamic>) {
        bool changed = false;
        final choices = decoded['choices'];
        if (choices is List) {
          for (final choice in choices) {
            if (choice is! Map<String, dynamic>) continue;
            final msg = choice['message'];
            if (msg is! Map<String, dynamic>) continue;
            final toolCalls = msg['tool_calls'];
            if (toolCalls is! List) continue;
            for (final tc in toolCalls) {
              if (tc is Map<String, dynamic> && !tc.containsKey('type')) {
                tc['type'] = 'function';
                changed = true;
              }
            }
          }
        }
        if (changed) {
          patched = jsonEncode(decoded);
        }
      }
    } catch (_) {}

    final patchedBytes = utf8.encode(patched);
    return http.StreamedResponse(
      http.ByteStream.fromBytes(patchedBytes),
      streamed.statusCode,
      contentLength: patchedBytes.length,
      headers: streamed.headers,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
      reasonPhrase: streamed.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
