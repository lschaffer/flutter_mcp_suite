import 'package:test/test.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() {
  group('ContextCompressor', () {
    test('estimateTokens calculates reasonable token approximation', () {
      const compressor = ContextCompressor();
      final messages = [
        ChatMessage(
          id: '1',
          content: 'Hello world, this is a short test message.',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          content: 'Response from assistant with some details.',
          role: ChatRole.assistant,
          timestamp: DateTime.now(),
        ),
      ];

      final tokens = compressor.estimateTokens(messages, systemPrompt: 'System instructions');
      expect(tokens, greaterThan(15));
      expect(tokens, lessThan(100));
    });

    test('shouldCompress returns false when under threshold or too few messages', () {
      const compressor = ContextCompressor(tokenThreshold: 1000, preserveRecentCount: 4);
      final messages = [
        ChatMessage(
          id: '1',
          content: 'Short message 1',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          content: 'Short message 2',
          role: ChatRole.assistant,
          timestamp: DateTime.now(),
        ),
      ];

      // Too few messages (<= preserveRecentCount + 1)
      expect(compressor.shouldCompress(messages), isFalse);

      // Enough messages but under token threshold
      final manyShort = List.generate(
        8,
        (i) => ChatMessage(
          id: '$i',
          content: 'Turn $i: short content',
          role: i % 2 == 0 ? ChatRole.user : ChatRole.assistant,
          timestamp: DateTime.now(),
        ),
      );
      expect(compressor.shouldCompress(manyShort), isFalse);
    });

    test('shouldCompress returns true when token count exceeds threshold with sufficient messages', () {
      const compressor = ContextCompressor(tokenThreshold: 50, preserveRecentCount: 2);
      final messages = List.generate(
        6,
        (i) => ChatMessage(
          id: '$i',
          content: 'Turn $i: This is a longer message that contains multiple words to exceed 50 tokens rapidly when combined.',
          role: i % 2 == 0 ? ChatRole.user : ChatRole.assistant,
          timestamp: DateTime.now(),
        ),
      );

      expect(compressor.shouldCompress(messages), isTrue);
    });

    test('compress preserves recent turns and creates summary message', () async {
      const compressor = ContextCompressor(tokenThreshold: 50, preserveRecentCount: 2);
      final messages = List.generate(
        6,
        (i) => ChatMessage(
          id: '$i',
          content:
              'Conversation turn $i: ${'detailed information and context for task step number $i. ' * 10}',
          role: i % 2 == 0 ? ChatRole.user : ChatRole.assistant,
          timestamp: DateTime.now(),
        ),
      );

      const llmConfig = LlmConfig(
        provider: LlmProvider.openaiCompatible,
        model: 'test-model',
        apiKey: 'test',
        baseUrl: 'http://localhost:99999/v1',
      );

      // Will trigger fallback summarization because dummy endpoint is unreachable
      final result = await compressor.compress(
        messages: messages,
        llmConfig: llmConfig,
      );

      expect(result.compressedTurnCount, equals(4)); // 6 - 2 = 4
      expect(result.compressedMessages.length, equals(3)); // 1 summary + 2 preserved
      expect(result.compressedMessages.first.role, equals(ChatRole.system));
      expect(result.compressedMessages.first.content, contains('[Prior Conversation Summary]'));
      expect(result.compressedMessages[1].id, equals('4'));
      expect(result.compressedMessages[2].id, equals('5'));
      expect(result.originalTokens, greaterThan(result.compressedTokens));
    });

    test('Agent copyWith supports contextCompressor', () {
      final agent = Agent(
        key: 'test_agent',
        name: 'Test Agent',
        llmConfig: const LlmConfig(
          provider: LlmProvider.openai,
          model: 'gpt-4o',
          apiKey: 'key',
        ),
      );
      expect(agent.contextCompressor, isNull);

      final updated = agent.copyWith(
        contextCompressor: const ContextCompressor(tokenThreshold: 2000),
      );
      expect(updated.contextCompressor, isNotNull);
      expect(updated.contextCompressor!.tokenThreshold, equals(2000));
    });
  });
}
