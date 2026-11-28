import 'dart:async';
import 'package:test/test.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() {
  tearDown(() {
    LLMService.embeddedHandler = null;
    LLMService.embeddedStreamHandler = null;
    LLMService.clearCache();
  });

  group('LlmConfig timeout defaults', () {
    test('defaults timeoutSeconds to 180 and remains configurable', () {
      const defaultConfig = LlmConfig(
        provider: LlmProvider.openai,
        model: 'gpt-4o-mini',
        apiKey: 'sk-test',
      );
      expect(defaultConfig.timeoutSeconds, 180);
      expect(defaultConfig.timeout, const Duration(seconds: 180));

      final fromEmptyJson = LlmConfig.fromJson(const {});
      expect(fromEmptyJson.timeoutSeconds, 180);
      expect(fromEmptyJson.timeout, const Duration(seconds: 180));

      const customConfig = LlmConfig(
        provider: LlmProvider.openai,
        model: 'gpt-4o-mini',
        apiKey: 'sk-test',
        timeoutSeconds: 45,
      );
      expect(customConfig.timeoutSeconds, 45);
      expect(customConfig.timeout, const Duration(seconds: 45));

      final restored = LlmConfig.fromJson(customConfig.toJson());
      expect(restored.timeoutSeconds, 45);
    });
  });

  group('McpAgentEngine stream resilience & retry', () {
    test(
      'retries on stalled socket / TimeoutException and succeeds on attempt 2',
      () async {
        int attempts = 0;
        LLMService.embeddedStreamHandler = ({
          required config,
          required messages,
          required tools,
          systemPrompt,
        }) async* {
          attempts++;
          if (attempts == 1) {
            // Simulate a stalled stream that exceeds the 1s timeout with 0 bytes.
            await Future<void>.delayed(const Duration(seconds: 3));
            yield const LLMStreamChunk(textDelta: 'too late');
          } else {
            yield const LLMStreamChunk(textDelta: 'Recovered ');
            yield const LLMStreamChunk(textDelta: 'answer');
            yield const LLMStreamChunk(
              textDelta: '',
              isDone: true,
              finalResponse: LLMResponse(text: 'Recovered answer'),
            );
          }
        };

        final engine = McpAgentEngine(
          maxLlmRetries: 2,
          llmRetryBaseDelay: Duration.zero,
        );

        engine.setAgents([
          Agent(
            key: 'retry_timeout_agent',
            name: 'Retry Timeout Agent',
            llmConfig: const LlmConfig(
              provider: LlmProvider.embedded,
              model: 'mock-model',
              apiKey: '',
              useStreaming: true,
              timeoutSeconds: 1,
            ),
            prompts: [const SubPromptStep(text: 'Hello')],
          ),
        ]);

        final events = await engine.runAsync('retry_timeout_agent').toList();

        expect(attempts, 2);
        final finalEvent = events.whereType<AgentFinalResultEvent>().single;
        expect(finalEvent.response, 'Recovered answer');
        expect(
          events.whereType<AgentLogEvent>().any(
            (e) => e.message.contains('retrying (attempt 2/3)'),
          ),
          isTrue,
        );
      },
    );

    test(
      'retries instead of returning truncated fragment when SSE stream drops mid-flight',
      () async {
        int attempts = 0;
        LLMService.embeddedStreamHandler = ({
          required config,
          required messages,
          required tools,
          systemPrompt,
        }) async* {
          attempts++;
          if (attempts == 1) {
            // Emit a 1-word fragment and end abruptly without isDone: true.
            yield const LLMStreamChunk(textDelta: 'One');
            return;
          }
          yield const LLMStreamChunk(textDelta: 'Complete full response.');
          yield const LLMStreamChunk(
            textDelta: '',
            isDone: true,
            finalResponse: LLMResponse(text: 'Complete full response.'),
          );
        };

        final engine = McpAgentEngine(
          maxLlmRetries: 2,
          llmRetryBaseDelay: Duration.zero,
        );

        engine.setAgents([
          Agent(
            key: 'truncated_stream_agent',
            name: 'Truncated Stream Agent',
            llmConfig: const LlmConfig(
              provider: LlmProvider.embedded,
              model: 'mock-model',
              apiKey: '',
              useStreaming: true,
            ),
            prompts: [const SubPromptStep(text: 'Explain')],
          ),
        ]);

        final events = await engine.runAsync('truncated_stream_agent').toList();

        expect(attempts, 2);
        final finalEvent = events.whereType<AgentFinalResultEvent>().single;
        expect(finalEvent.response, 'Complete full response.');
        expect(
          events.whereType<AgentLogEvent>().any(
            (e) => e.message.contains('retrying (attempt 2/3)'),
          ),
          isTrue,
        );
      },
    );

    test(
      'surfaces error after retries are exhausted on persistent incomplete streams',
      () async {
        int attempts = 0;
        LLMService.embeddedStreamHandler = ({
          required config,
          required messages,
          required tools,
          systemPrompt,
        }) async* {
          attempts++;
          yield const LLMStreamChunk(textDelta: 'One');
          // Abrupt EOF without isDone: true on every attempt.
        };

        final engine = McpAgentEngine(
          maxLlmRetries: 1,
          llmRetryBaseDelay: Duration.zero,
        );

        engine.setAgents([
          Agent(
            key: 'exhausted_stream_agent',
            name: 'Exhausted Stream Agent',
            llmConfig: const LlmConfig(
              provider: LlmProvider.embedded,
              model: 'mock-model',
              apiKey: '',
              useStreaming: true,
            ),
            prompts: [const SubPromptStep(text: 'Explain')],
          ),
        ]);

        final events = <AgentEvent>[];
        Object? streamError;
        try {
          await for (final event in engine.runAsync('exhausted_stream_agent')) {
            events.add(event);
          }
        } catch (e) {
          streamError = e;
        }

        expect(attempts, 2);
        expect(streamError, isA<IncompleteStreamException>());
        final errorEvents = events.whereType<AgentErrorEvent>().toList();
        expect(errorEvents, isNotEmpty);
        expect(errorEvents.first.error, isA<IncompleteStreamException>());
        expect(events.whereType<AgentFinalResultEvent>(), isEmpty);
      },
    );

    test(
      'forwards heartbeat / reasoning statusMessage chunks as AgentLogEvent',
      () async {
        LLMService.embeddedStreamHandler = ({
          required config,
          required messages,
          required tools,
          systemPrompt,
        }) async* {
          yield const LLMStreamChunk(
            textDelta: '',
            statusMessage: 'Model reasoning...',
          );
          yield const LLMStreamChunk(
            textDelta: '',
            statusMessage: 'Preparing tool call...',
          );
          yield const LLMStreamChunk(textDelta: 'Done!');
          yield const LLMStreamChunk(
            textDelta: '',
            isDone: true,
            finalResponse: LLMResponse(text: 'Done!'),
          );
        };

        final engine = McpAgentEngine(llmRetryBaseDelay: Duration.zero);

        engine.setAgents([
          Agent(
            key: 'heartbeat_agent',
            name: 'Heartbeat Agent',
            llmConfig: const LlmConfig(
              provider: LlmProvider.embedded,
              model: 'mock-model',
              apiKey: '',
              useStreaming: true,
            ),
            prompts: [const SubPromptStep(text: 'Think')],
          ),
        ]);

        final events = await engine.runAsync('heartbeat_agent').toList();

        final finalEvent = events.whereType<AgentFinalResultEvent>().single;
        expect(finalEvent.response, 'Done!');
        final logMessages = events
            .whereType<AgentLogEvent>()
            .map((e) => e.message)
            .toList();
        expect(logMessages, contains('Model reasoning...'));
        expect(logMessages, contains('Preparing tool call...'));
      },
    );

    test(
      'retries non-streaming calls on transient 503 error and succeeds',
      () async {
        int attempts = 0;
        LLMService.embeddedHandler = ({
          required config,
          required messages,
          required tools,
          systemPrompt,
        }) async {
          attempts++;
          if (attempts == 1) {
            throw Exception('HTTP 503 Service Unavailable');
          }
          return const LLMResponse(text: 'Non-stream success');
        };

        final engine = McpAgentEngine(
          maxLlmRetries: 2,
          llmRetryBaseDelay: Duration.zero,
        );

        engine.setAgents([
          Agent(
            key: 'non_stream_retry_agent',
            name: 'Non-stream Retry Agent',
            llmConfig: const LlmConfig(
              provider: LlmProvider.embedded,
              model: 'mock-model',
              apiKey: '',
              useStreaming: false,
            ),
            prompts: [const SubPromptStep(text: 'Ping')],
          ),
        ]);

        final events = await engine.runAsync('non_stream_retry_agent').toList();
        expect(attempts, 2);
        final finalEvent = events.whereType<AgentFinalResultEvent>().single;
        expect(finalEvent.response, 'Non-stream success');
      },
    );
  });
}
