import 'package:test/test.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:ollama_dart/ollama_dart.dart' as ollama;

void main() {
  group('LLMService System Message Normalization', () {
    test('merges systemPrompt and leading ChatRole.system (compressed summary) into single index 0 message for OpenAI', () {
      final messages = [
        ChatMessage(
          id: 'summary_1',
          content: '[Prior Conversation Summary] (Archive ID: mem_1234):\n- User asked about pricing\n- Assistant provided calculation',
          role: ChatRole.system,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'user_1',
          content: 'Continue with step 2',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final openAiMsgs = LLMService.buildOpenAiChatMessages(
        messages,
        'You are a helpful coding agent.',
      );

      // Must produce exactly 2 messages: index 0 (system), index 1 (user)
      expect(openAiMsgs.length, equals(2));

      // Index 0 must be the single merged system message
      expect(openAiMsgs[0], isA<openai.SystemMessage>());
      final sysMsg = openAiMsgs[0] as openai.SystemMessage;
      expect(sysMsg.content, contains('You are a helpful coding agent.'));
      expect(sysMsg.content, contains('[Prior Conversation Summary]'));

      // Index 1 must be the user message
      expect(openAiMsgs[1], isA<openai.UserMessage>());

      // Ensure NO system message exists at index > 0 (strictly Jinja loop.first compliant)
      for (int i = 1; i < openAiMsgs.length; i++) {
        expect(openAiMsgs[i], isNot(isA<openai.SystemMessage>()),
            reason: 'Message at index $i must not have system role');
      }
    });

    test('merges multiple leading system messages with systemPrompt', () {
      final messages = [
        ChatMessage(
          id: 'sys_1',
          content: 'Rule 1: Always write tests.',
          role: ChatRole.system,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'sys_2',
          content: 'Rule 2: Keep functions small.',
          role: ChatRole.system,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'user_1',
          content: 'Refactor this code',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final openAiMsgs = LLMService.buildOpenAiChatMessages(
        messages,
        'Base Instructions.',
      );

      expect(openAiMsgs.length, equals(2));
      expect(openAiMsgs[0], isA<openai.SystemMessage>());
      final sysMsg = openAiMsgs[0] as openai.SystemMessage;
      expect(sysMsg.content, contains('Base Instructions.'));
      expect(sysMsg.content, contains('Rule 1: Always write tests.'));
      expect(sysMsg.content, contains('Rule 2: Keep functions small.'));
    });

    test('safely converts mid-conversation ChatRole.system messages to user notices', () {
      final messages = [
        ChatMessage(
          id: 'user_1',
          content: 'Hello',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'asst_1',
          content: 'Hi there! How can I help?',
          role: ChatRole.assistant,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'sys_mid',
          content: 'Context injection: User switched project directory to /src/app',
          role: ChatRole.system,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'user_2',
          content: 'List files here',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final openAiMsgs = LLMService.buildOpenAiChatMessages(
        messages,
        'Main system prompt.',
      );

      // Index 0 is the initial system prompt
      expect(openAiMsgs[0], isA<openai.SystemMessage>());

      // All remaining messages must NOT have system role
      for (int i = 1; i < openAiMsgs.length; i++) {
        expect(openAiMsgs[i], isNot(isA<openai.SystemMessage>()),
            reason: 'Message at index $i must never have system role');
      }

      // The mid-conversation system message was converted to user notice
      final hasMidNotice = openAiMsgs.whereType<openai.UserMessage>().any(
            (m) => m.toJson().toString().contains('[System Notice]: Context injection'),
          );
      expect(hasMidNotice, isTrue);
    });

    test('handles null systemPrompt when leading ChatRole.system is present', () {
      final messages = [
        ChatMessage(
          id: 'sys_1',
          content: 'Standalone leading system directive',
          role: ChatRole.system,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'user_1',
          content: 'What is my directive?',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
      ];

      final openAiMsgs = LLMService.buildOpenAiChatMessages(messages, null);
      expect(openAiMsgs.length, equals(2));
      expect(openAiMsgs[0], isA<openai.SystemMessage>());
      expect((openAiMsgs[0] as openai.SystemMessage).content,
          equals('Standalone leading system directive'));
    });

    test('Ollama adapter also enforces single system message at index 0', () {
      final messages = [
        ChatMessage(
          id: 'summary_1',
          content: '[Prior Conversation Summary] 15 turns compressed',
          role: ChatRole.system,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'user_1',
          content: 'Summarize again',
          role: ChatRole.user,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'sys_mid',
          content: 'Mid stream update',
          role: ChatRole.system,
          timestamp: DateTime.now(),
        ),
      ];

      final ollamaMsgs = LLMService.buildOllamaChatMessages(
        messages,
        'Ollama base system prompt.',
      );

      expect(ollamaMsgs.length, equals(3));
      // Index 0: merged system prompt
      expect(ollamaMsgs[0].role, equals(ollama.MessageRole.system));
      expect(ollamaMsgs[0].content, contains('Ollama base system prompt.'));
      expect(ollamaMsgs[0].content, contains('[Prior Conversation Summary]'));

      // Index 1: user message
      expect(ollamaMsgs[1].role, equals(ollama.MessageRole.user));

      // Index 2: mid-conversation converted to user notice
      expect(ollamaMsgs[2].role, equals(ollama.MessageRole.user));
      expect(ollamaMsgs[2].content, contains('[System Notice]: Mid stream update'));

      // Strictly verify no system role at index > 0
      for (int i = 1; i < ollamaMsgs.length; i++) {
        expect(ollamaMsgs[i].role, isNot(equals(ollama.MessageRole.system)));
      }
    });
  });
}
