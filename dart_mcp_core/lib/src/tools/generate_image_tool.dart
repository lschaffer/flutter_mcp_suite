import 'dart:convert';
import 'package:googleai_dart/googleai_dart.dart' as gemini;
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart' as openai;
import '../mcp/local_tools.dart';
import '../models/models.dart';

/// Configuration for [GenerateImageTool], allowing users to choose a preset
/// image generator (DeepInfra FLUX, Gemini Nano Banana, OpenAI GPT Image) or a
/// custom model/endpoint with an optional dedicated API key.
class ImageGenConfig {
  /// Preset identifier: `'auto'`, `'deepinfra_flux'`, `'gemini_nano_banana'`,
  /// `'openai_gpt_image'`, or `'custom'`.
  final String preset;

  /// Target provider (`LlmProvider.openaiCompatible`, `LlmProvider.gemini`,
  /// `LlmProvider.openai`, or `LlmProvider.none` for auto).
  final LlmProvider provider;

  /// Base endpoint URL (used for OpenAI / DeepInfra / custom OpenAI-compatible).
  final String baseUrl;

  /// Image generation model ID (e.g. `black-forest-labs/FLUX-1-schnell`,
  /// `gemini-2.5-flash-image`, `gpt-image-1`).
  final String model;

  /// Optional dedicated API key. If blank, [GenerateImageTool] automatically
  /// reuses the API key from the matching active or saved LLM profile.
  final String apiKey;

  const ImageGenConfig({
    this.preset = 'auto',
    this.provider = LlmProvider.none,
    this.baseUrl = '',
    this.model = '',
    this.apiKey = '',
  });

  bool get isAuto => preset == 'auto' || preset.isEmpty;

  factory ImageGenConfig.deepInfraFlux({String apiKey = ''}) => ImageGenConfig(
        preset: 'deepinfra_flux',
        provider: LlmProvider.openaiCompatible,
        baseUrl: 'https://api.deepinfra.com/v1/openai',
        model: 'black-forest-labs/FLUX-1-schnell',
        apiKey: apiKey,
      );

  factory ImageGenConfig.geminiNanoBanana({String apiKey = ''}) => ImageGenConfig(
        preset: 'gemini_nano_banana',
        provider: LlmProvider.gemini,
        baseUrl: '',
        model: 'gemini-2.5-flash-image',
        apiKey: apiKey,
      );

  factory ImageGenConfig.openAiGptImage({String apiKey = ''}) => ImageGenConfig(
        preset: 'openai_gpt_image',
        provider: LlmProvider.openai,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-image-1',
        apiKey: apiKey,
      );

  String get displayLabel {
    if (isAuto) return 'Auto';
    if (model.trim().isNotEmpty) return model.trim();
    return preset;
  }

  ImageGenConfig copyWith({
    String? preset,
    LlmProvider? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
  }) {
    return ImageGenConfig(
      preset: preset ?? this.preset,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset,
        'provider': provider.configKey,
        'baseUrl': baseUrl,
        'model': model,
        'apiKey': apiKey,
      };

  factory ImageGenConfig.fromJson(Map<String, dynamic> json) {
    return ImageGenConfig(
      preset: json['preset'] as String? ?? 'auto',
      provider: LlmProvider.fromConfigKey(json['provider'] as String? ?? 'none'),
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
    );
  }
}

/// Result returned by a custom or embedded image generation handler.
class GeneratedImagePayload {
  /// Base64-encoded image bytes (without `data:image/...;base64,` prefix).
  final String base64Data;

  /// MIME type of the generated image (e.g. `image/png`, `image/jpeg`, `image/webp`).
  final String mimeType;

  /// Optional revised or expanded prompt returned by the backend.
  final String? revisedPrompt;

  const GeneratedImagePayload({
    required this.base64Data,
    this.mimeType = 'image/png',
    this.revisedPrompt,
  });
}

/// Pluggable delegate signature for custom or on-device image generation
/// (e.g. `llamadart` Stable Diffusion `ImageGenerationEngine`).
typedef ImageGenerationHandler = Future<GeneratedImagePayload> Function({
  required String prompt,
  String? size,
  String? quality,
  String? model,
});

/// Dart-native MCP local tool that generates images from text prompts and
/// returns them as [MCPToolResult.image] so chat UIs render them inline.
///
/// Supports:
/// - **OpenAI / OpenAI-compatible** (`openai_dart` `images.generate`, default `gpt-image-1`)
/// - **Google Gemini** (`googleai_dart` `generateContent` with `ResponseModality.image`, default `gemini-2.5-flash-image`)
/// - **Embedded / Custom backends** via [customHandler] or static [embeddedImageHandler]
///   (e.g. `llamadart` Stable Diffusion without importing native FFI binaries in `dart_mcp_core`).
class GenerateImageTool extends McpLocalTool {
  /// Optional static delegate for on-device image generation (e.g. `llamadart`
  /// Stable Diffusion), mirroring `LLMService.embeddedHandler`.
  static ImageGenerationHandler? embeddedImageHandler;

  /// Optional static provider returning the user-configured [ImageGenConfig]
  /// (wired automatically by `PlaygroundController`). When set to a non-auto
  /// preset (e.g. DeepInfra FLUX, Gemini Nano Banana, OpenAI, or Custom), it
  /// takes precedence over automatic provider detection.
  static ImageGenConfig? Function()? imageGenConfigProvider;

  /// Optional static provider returning the currently active LLM config
  /// (wired automatically by `PlaygroundController`).
  static LlmConfig? Function()? activeConfigProvider;

  /// Optional static provider returning all saved LLM profiles (wired
  /// automatically by `PlaygroundController`). When the active chat model
  /// (e.g. DeepSeek, Claude, Ollama) cannot generate images natively,
  /// [GenerateImageTool] checks this list for a configured OpenAI or Gemini
  /// profile so users don't have to switch their primary chat model.
  static List<LlmConfig> Function()? configuredProfilesProvider;

  /// Static LLM configuration (used if [llmConfigProvider] is not supplied).
  final LlmConfig? llmConfig;

  /// Dynamic LLM configuration callback (e.g. `() => controller.activeLlmConfig`).
  final LlmConfig? Function()? llmConfigProvider;

  /// Optional custom handler that overrides provider routing when set.
  final ImageGenerationHandler? customHandler;

  /// Default OpenAI image generation model.
  final String openaiImageModel;

  /// Default DeepInfra OpenAI-compatible image generation model
  /// (used automatically when `baseUrl` points to `deepinfra.com`).
  final String deepInfraImageModel;

  /// Default Gemini image generation model.
  final String geminiImageModel;

  /// If `true`, sets `requestStop: true` on the returned [MCPToolResult.image]
  /// so the agent finishes immediately after displaying the generated image.
  final bool stopAfterGeneration;

  /// Optional HTTP client used when downloading URL-based image responses.
  final http.Client? httpClient;

  GenerateImageTool({
    this.llmConfig,
    this.llmConfigProvider,
    this.customHandler,
    this.openaiImageModel = 'gpt-image-1',
    this.deepInfraImageModel = 'black-forest-labs/FLUX-1-schnell',
    this.geminiImageModel = 'gemini-2.5-flash-image',
    this.stopAfterGeneration = false,
    this.httpClient,
  });

  @override
  String get name => 'generate_image';

  @override
  String get description =>
      'Generates an image from a detailed text description and displays it '
      'directly in the chat output. Use this whenever the user asks to create, '
      'draw, paint, illustrate, or generate a picture or image.';

  @override
  ToolRiskLevel get riskLevel => ToolRiskLevel.network;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'prompt': {
            'type': 'string',
            'description':
                'Detailed visual description of the image to generate (subject, style, lighting, composition).',
          },
          'size': {
            'type': 'string',
            'description':
                'Optional target dimensions such as "1024x1024", "1536x1024" (landscape), or "1024x1536" (portrait).',
          },
          'quality': {
            'type': 'string',
            'description': 'Optional quality preset: "low", "medium", "high", or "auto".',
          },
          'model': {
            'type': 'string',
            'description':
                'Optional image model override (e.g. "gpt-image-1", "black-forest-labs/FLUX-1-schnell", "black-forest-labs/FLUX-1-dev").',
          },
        },
        'required': ['prompt'],
      };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) =>
      executeWithFallbackConfig(arguments, null);

  /// Executes image generation, falling back to [fallbackConfig] (such as the
  /// active agent's [LlmConfig]) when neither [llmConfigProvider] nor
  /// [llmConfig] was explicitly configured on this tool instance.
  Future<MCPToolResult> executeWithFallbackConfig(
    Map<String, dynamic> arguments,
    LlmConfig? fallbackConfig,
  ) async {
    final prompt = (arguments['prompt'] as String?)?.trim() ?? '';
    if (prompt.isEmpty) {
      return MCPToolResult.error('Missing required parameter: "prompt".');
    }

    final size = (arguments['size'] as String?)?.trim();
    final quality = (arguments['quality'] as String?)?.trim();
    final modelOverride = (arguments['model'] as String?)?.trim();

    try {
      // 1. Per-instance custom handler always takes precedence.
      if (customHandler != null) {
        final result = await customHandler!(
          prompt: prompt,
          size: size,
          quality: quality,
          model: modelOverride,
        );
        return _toToolResult(result, prompt: prompt, backend: 'custom');
      }

      final config = llmConfigProvider?.call() ??
          llmConfig ??
          fallbackConfig ??
          activeConfigProvider?.call();
      final savedProfiles = configuredProfilesProvider?.call() ?? const [];

      // 1b. Dedicated user-configured ImageGenConfig (preset or custom)
      final imgCfg = imageGenConfigProvider?.call();
      if (imgCfg != null && !imgCfg.isAuto) {
        final effectiveApiKey = _resolveApiKeyForImageConfig(
          imgCfg,
          activeConfig: config,
          savedProfiles: savedProfiles,
        );
        if (effectiveApiKey.isEmpty) {
          return MCPToolResult.error(
            'Image generator "${imgCfg.displayLabel}" requires an API key. '
            'Enter an API key in the generate_image tool settings (Agent & Tools tab) '
            'or add a matching provider profile in LLM Settings.',
          );
        }

        final effectiveConfig = LlmConfig(
          provider: imgCfg.provider == LlmProvider.none
              ? LlmProvider.openaiCompatible
              : imgCfg.provider,
          apiKey: effectiveApiKey,
          baseUrl: imgCfg.baseUrl,
          model: imgCfg.model,
        );

        final effectiveModel = (modelOverride != null && modelOverride.isNotEmpty)
            ? modelOverride
            : (imgCfg.model.trim().isNotEmpty ? imgCfg.model.trim() : null);

        if (effectiveConfig.provider == LlmProvider.gemini) {
          final result = await _generateWithGemini(
            config: effectiveConfig,
            prompt: prompt,
            modelOverride: effectiveModel,
          );
          return _toToolResult(result, prompt: prompt, backend: 'gemini');
        } else {
          final isDeepInfra =
              effectiveConfig.baseUrl.toLowerCase().contains('deepinfra.com');
          final result = await _generateWithOpenAI(
            config: effectiveConfig,
            prompt: prompt,
            size: size,
            quality: quality,
            modelOverride: effectiveModel,
          );
          return _toToolResult(
            result,
            prompt: prompt,
            backend: isDeepInfra
                ? 'deepinfra'
                : (effectiveConfig.provider == LlmProvider.openai
                    ? 'openai'
                    : 'custom_endpoint'),
          );
        }
      }

      // 2. If active config is OpenAI or Gemini, use it directly.
      if (config != null && config.isConfigured) {
        if (config.provider == LlmProvider.openai) {
          final result = await _generateWithOpenAI(
            config: config,
            prompt: prompt,
            size: size,
            quality: quality,
            modelOverride: modelOverride,
          );
          return _toToolResult(result, prompt: prompt, backend: 'openai');
        }
        if (config.provider == LlmProvider.gemini) {
          final result = await _generateWithGemini(
            config: config,
            prompt: prompt,
            modelOverride: modelOverride,
          );
          return _toToolResult(result, prompt: prompt, backend: 'gemini');
        }
      }

      // 3. If embedded provider is active (or no cloud config is set) and an
      //    embedded image handler is registered, route to it.
      if ((config == null || config.provider == LlmProvider.embedded) &&
          embeddedImageHandler != null) {
        final result = await embeddedImageHandler!(
          prompt: prompt,
          size: size,
          quality: quality,
          model: modelOverride ?? config?.model,
        );
        return _toToolResult(result, prompt: prompt, backend: 'embedded');
      }

      // 4. Search saved LLM profiles for a configured OpenAI or Gemini profile
      //    so image generation works seamlessly even while chatting with
      //    DeepSeek, Claude, Ollama, or Embedded models.
      for (final profile in savedProfiles) {
        if (!profile.isConfigured) continue;
        if (profile.provider == LlmProvider.openai) {
          final result = await _generateWithOpenAI(
            config: profile,
            prompt: prompt,
            size: size,
            quality: quality,
            modelOverride: modelOverride,
          );
          return _toToolResult(result, prompt: prompt, backend: 'openai');
        }
        if (profile.provider == LlmProvider.gemini) {
          final result = await _generateWithGemini(
            config: profile,
            prompt: prompt,
            modelOverride: modelOverride,
          );
          return _toToolResult(result, prompt: prompt, backend: 'gemini');
        }
      }

      // 5. If active config is a custom OpenAI-compatible endpoint (e.g. DeepInfra
      //    hosting FLUX.1-schnell at /v1/openai/images/generations), try it directly.
      if (config != null &&
          config.isConfigured &&
          config.provider == LlmProvider.openaiCompatible) {
        final isDeepInfra = config.baseUrl.toLowerCase().contains('deepinfra.com');
        final result = await _generateWithOpenAI(
          config: config,
          prompt: prompt,
          size: size,
          quality: quality,
          modelOverride: modelOverride,
        );
        return _toToolResult(
          result,
          prompt: prompt,
          backend: isDeepInfra ? 'deepinfra' : 'openai_compatible',
        );
      }

      // 5b. Also check saved profiles for a configured DeepInfra profile.
      for (final profile in savedProfiles) {
        if (profile.isConfigured &&
            profile.provider == LlmProvider.openaiCompatible &&
            profile.baseUrl.toLowerCase().contains('deepinfra.com')) {
          final result = await _generateWithOpenAI(
            config: profile,
            prompt: prompt,
            size: size,
            quality: quality,
            modelOverride: modelOverride,
          );
          return _toToolResult(result, prompt: prompt, backend: 'deepinfra');
        }
      }

      // 6. Final fallback to embeddedImageHandler if registered.
      if (embeddedImageHandler != null) {
        final result = await embeddedImageHandler!(
          prompt: prompt,
          size: size,
          quality: quality,
        );
        return _toToolResult(result, prompt: prompt, backend: 'embedded');
      }

      if (config == null || !config.isConfigured) {
        return MCPToolResult.error(
          'No configured image generation provider available. '
          'Add an OpenAI or Gemini profile in LLM Settings (its API key will be used automatically), '
          'or register GenerateImageTool.embeddedImageHandler.',
        );
      }

      return MCPToolResult.error(
        'Active provider "${config.provider.displayName}" does not support native image generation. '
        'Add an OpenAI or Gemini profile in LLM Settings (no need to make it active), '
        'or register GenerateImageTool.embeddedImageHandler.',
      );
    } catch (e) {
      return MCPToolResult.error('Image generation failed: $e');
    }
  }

  MCPToolResult _toToolResult(
    GeneratedImagePayload payload, {
    required String prompt,
    required String backend,
  }) {
    if (payload.base64Data.isEmpty) {
      return MCPToolResult.error('Image generation backend ($backend) returned empty image data.');
    }
    return MCPToolResult.image(
      payload.base64Data,
      mimeType: payload.mimeType,
      requestStop: stopAfterGeneration,
      metadata: {
        'backend': backend,
        'prompt': prompt,
        if (payload.revisedPrompt != null) 'revisedPrompt': payload.revisedPrompt,
      },
    );
  }

  Future<GeneratedImagePayload> _generateWithOpenAI({
    required LlmConfig config,
    required String prompt,
    String? size,
    String? quality,
    String? modelOverride,
  }) async {
    final baseUrl = config.baseUrl.trim().isNotEmpty
        ? config.baseUrl.trim()
        : 'https://api.openai.com/v1';
    final isDeepInfra = baseUrl.toLowerCase().contains('deepinfra.com');

    final client = openai.OpenAIClient(
      config: openai.OpenAIConfig(
        authProvider: openai.ApiKeyProvider(config.apiKey),
        baseUrl: baseUrl,
        timeout: config.timeout,
      ),
    );

    try {
      final model = (modelOverride != null && modelOverride.isNotEmpty)
          ? modelOverride
          : (isDeepInfra ? deepInfraImageModel : openaiImageModel);
      final isGptImage = model.toLowerCase().startsWith('gpt-image');

      final request = openai.ImageGenerationRequest(
        prompt: prompt,
        model: model,
        n: 1,
        size: _parseOpenAiSize(size),
        quality: isDeepInfra ? null : _parseOpenAiQuality(quality),
        // gpt-image-* always returns b64_json and rejects response_format;
        // DALL-E & DeepInfra FLUX accept b64_json.
        responseFormat: isGptImage ? null : openai.ImageResponseFormat.b64Json,
      );

      final response = await client.images.generate(request);
      if (response.data.isEmpty) {
        throw StateError('OpenAI returned no generated images.');
      }

      final first = response.data.first;
      String? b64 = first.b64Json;
      if ((b64 == null || b64.isEmpty) && first.url != null && first.url!.isNotEmpty) {
        final downloader = httpClient ?? http.Client();
        try {
          final imgRes = await downloader.get(Uri.parse(first.url!));
          if (imgRes.statusCode >= 200 && imgRes.statusCode < 300) {
            b64 = base64Encode(imgRes.bodyBytes);
          } else {
            throw StateError('Failed to download generated image URL (HTTP ${imgRes.statusCode}).');
          }
        } finally {
          if (httpClient == null) downloader.close();
        }
      }

      if (b64 == null || b64.isEmpty) {
        throw StateError('OpenAI image response contained neither b64_json nor url.');
      }

      final mimeType = switch (response.outputFormat) {
        openai.ImageOutputFormat.jpeg => 'image/jpeg',
        openai.ImageOutputFormat.webp => 'image/webp',
        _ => 'image/png',
      };

      return GeneratedImagePayload(
        base64Data: b64,
        mimeType: mimeType,
        revisedPrompt: first.revisedPrompt,
      );
    } finally {
      client.close();
    }
  }

  Future<GeneratedImagePayload> _generateWithGemini({
    required LlmConfig config,
    required String prompt,
    String? modelOverride,
  }) async {
    final client = gemini.GoogleAIClient(
      config: gemini.GoogleAIConfig.googleAI(
        authProvider: gemini.ApiKeyProvider(config.apiKey),
        timeout: config.timeout,
      ),
    );

    try {
      final model = (modelOverride != null && modelOverride.isNotEmpty)
          ? modelOverride
          : geminiImageModel;
      final response = await client.models.generateContent(
        model: model,
        request: gemini.GenerateContentRequest(
          contents: [gemini.Content.text(prompt)],
          generationConfig: const gemini.GenerationConfig(
            responseModalities: [
              gemini.ResponseModality.text,
              gemini.ResponseModality.image,
            ],
          ),
        ),
      );

      String? caption;
      final candidates = response.candidates ?? const [];
      for (final candidate in candidates) {
        final parts = candidate.content?.parts ?? const [];
        for (final part in parts) {
          if (part is gemini.TextPart && part.text.trim().isNotEmpty) {
            caption = part.text.trim();
          } else if (part is gemini.InlineDataPart && part.inlineData.data.isNotEmpty) {
            return GeneratedImagePayload(
              base64Data: part.inlineData.data,
              mimeType: part.inlineData.mimeType.isNotEmpty
                  ? part.inlineData.mimeType
                  : 'image/png',
              revisedPrompt: caption,
            );
          }
        }
      }

      throw StateError(
        caption != null
            ? 'Gemini returned text without an image: $caption'
            : 'Gemini returned no image content.',
      );
    } finally {
      client.close();
    }
  }

  static String _resolveApiKeyForImageConfig(
    ImageGenConfig imgCfg, {
    required LlmConfig? activeConfig,
    required List<LlmConfig> savedProfiles,
  }) {
    if (imgCfg.apiKey.trim().isNotEmpty) return imgCfg.apiKey.trim();

    final candidates = <LlmConfig>[
      ?activeConfig,
      ...savedProfiles,
    ];
    final targetHost = Uri.tryParse(imgCfg.baseUrl.trim())?.host.toLowerCase() ?? '';

    // 1. Exact host match (e.g. api.deepinfra.com)
    if (targetHost.isNotEmpty) {
      for (final c in candidates) {
        final host = Uri.tryParse(c.baseUrl.trim())?.host.toLowerCase() ?? '';
        if (host == targetHost && c.apiKey.trim().isNotEmpty) {
          return c.apiKey.trim();
        }
      }
    }

    // 2. Same provider match (e.g. gemini or openai)
    for (final c in candidates) {
      if (c.provider == imgCfg.provider && c.apiKey.trim().isNotEmpty) {
        return c.apiKey.trim();
      }
    }

    return '';
  }

  static openai.ImageSize? _parseOpenAiSize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw.toLowerCase()) {
      '256x256' => openai.ImageSize.size256x256,
      '512x512' => openai.ImageSize.size512x512,
      '1024x1024' => openai.ImageSize.size1024x1024,
      '1536x1024' => openai.ImageSize.size1536x1024,
      '1024x1536' => openai.ImageSize.size1024x1536,
      '1792x1024' => openai.ImageSize.size1792x1024,
      '1024x1792' => openai.ImageSize.size1024x1792,
      'auto' => openai.ImageSize.auto,
      _ => openai.ImageSize.custom(raw),
    };
  }

  static openai.ImageQuality? _parseOpenAiQuality(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return switch (raw.toLowerCase()) {
      'low' => openai.ImageQuality.low,
      'medium' => openai.ImageQuality.medium,
      'high' => openai.ImageQuality.high,
      'standard' => openai.ImageQuality.standard,
      'hd' => openai.ImageQuality.hd,
      'auto' => openai.ImageQuality.auto,
      _ => null,
    };
  }
}
