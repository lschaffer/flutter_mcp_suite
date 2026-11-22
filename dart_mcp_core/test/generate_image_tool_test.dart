import 'dart:convert';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    GenerateImageTool.embeddedImageHandler = null;
    GenerateImageTool.imageGenConfigProvider = null;
    GenerateImageTool.activeConfigProvider = null;
    GenerateImageTool.configuredProfilesProvider = null;
  });

  group('GenerateImageTool', () {
    test('exposes generate_image MCP schema with required prompt', () {
      final tool = GenerateImageTool();
      final mcpTool = tool.toMCPTool();

      expect(mcpTool.name, 'generate_image');
      expect(mcpTool.inputSchema?['required'], contains('prompt'));
      expect(
        (mcpTool.inputSchema?['properties'] as Map<String, dynamic>).keys,
        containsAll(['prompt', 'size', 'quality']),
      );
    });

    test('returns error when prompt is missing or blank', () async {
      final tool = GenerateImageTool();

      final res1 = await tool.execute({});
      expect(res1.isError, isTrue);

      final res2 = await tool.execute({'prompt': '   '});
      expect(res2.isError, isTrue);
    });

    test('routes to customHandler and returns MCPToolResult.image', () async {
      final fakePngBase64 = base64Encode([0x89, 0x50, 0x4E, 0x47]);
      String? receivedPrompt;
      String? receivedSize;

      final tool = GenerateImageTool(
        stopAfterGeneration: true,
        customHandler: ({
          required String prompt,
          String? size,
          String? quality,
          String? model,
        }) async {
          receivedPrompt = prompt;
          receivedSize = size;
          return GeneratedImagePayload(
            base64Data: fakePngBase64,
            mimeType: 'image/png',
            revisedPrompt: 'A fluffy orange cat by a sunny window',
          );
        },
      );

      final result = await tool.execute({
        'prompt': 'a cat',
        'size': '1024x1024',
      });

      expect(receivedPrompt, 'a cat');
      expect(receivedSize, '1024x1024');
      expect(result.isError, isFalse);
      expect(result.requestStop, isTrue);
      expect(result.content, hasLength(1));
      expect(result.content.first.type, 'image');
      expect(result.content.first.data, fakePngBase64);
      expect(result.content.first.mimeType, 'image/png');
      expect(result.metadata?['backend'], 'custom');
      expect(result.metadata?['revisedPrompt'], 'A fluffy orange cat by a sunny window');
    });

    test('routes to static embeddedImageHandler when embedded provider is active', () async {
      final fakePngBase64 = base64Encode([1, 2, 3, 4]);
      GenerateImageTool.embeddedImageHandler = ({
        required String prompt,
        String? size,
        String? quality,
        String? model,
      }) async {
        return GeneratedImagePayload(
          base64Data: fakePngBase64,
          mimeType: 'image/png',
        );
      };

      final tool = GenerateImageTool(
        llmConfigProvider: () => const LlmConfig(
          provider: LlmProvider.embedded,
          apiKey: '',
          model: 'sd-v1-5',
        ),
      );

      final result = await tool.execute({'prompt': 'a mountain sunrise'});

      expect(result.isError, isFalse);
      expect(result.content.first.type, 'image');
      expect(result.content.first.data, fakePngBase64);
      expect(result.metadata?['backend'], 'embedded');
    });

    test('returns clear error when provider does not support native image generation', () async {
      final tool = GenerateImageTool(
        llmConfig: const LlmConfig(
          provider: LlmProvider.claude,
          apiKey: 'sk-ant-test',
          model: 'claude-sonnet-4-5',
        ),
      );

      final result = await tool.execute({'prompt': 'a cat'});

      expect(result.isError, isTrue);
      expect(result.text, contains('does not support native image generation'));
    });

    test('McpCallToolTool forwards fallbackLlmConfig to GenerateImageTool in progressive mode', () async {
      final manager = MultiMCPManager();
      final callTool = McpCallToolTool(
        mcpManager: manager,
        localTools: [GenerateImageTool()],
        fallbackLlmConfig: const LlmConfig(
          provider: LlmProvider.claude,
          apiKey: 'sk-ant-test',
          model: 'claude-sonnet-4-5',
        ),
      );

      final result = await callTool.execute({
        'tool_name': 'generate_image',
        'arguments': {'prompt': 'a cat'},
      });

      expect(result.isError, isTrue);
      // Proves fallbackLlmConfig was forwarded (reports Claude provider rather than "No configured...")
      expect(result.text, contains('Claude'));
    });

    test('ImageGenConfig serializes roundtrip and reports missing API key clearly', () async {
      final cfg = ImageGenConfig.deepInfraFlux(apiKey: 'di-test-key');
      final roundtrip = ImageGenConfig.fromJson(cfg.toJson());
      expect(roundtrip.preset, 'deepinfra_flux');
      expect(roundtrip.model, 'black-forest-labs/FLUX-1-schnell');
      expect(roundtrip.baseUrl, 'https://api.deepinfra.com/v1/openai');
      expect(roundtrip.apiKey, 'di-test-key');

      GenerateImageTool.imageGenConfigProvider = () => ImageGenConfig.geminiNanoBanana();
      final tool = GenerateImageTool();
      final result = await tool.execute({'prompt': 'a cat'});
      expect(result.isError, isTrue);
      expect(result.text, contains('requires an API key'));
    });
  });
}
