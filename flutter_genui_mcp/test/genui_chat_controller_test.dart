import 'dart:convert';
import 'dart:math';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart' as mp;
import 'package:flutter/material.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart'
    show GenuiChatEntryKind, McpGenuiChatController;
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart'
    hide ValidationResult;

/// A model that answers each request with the next of [replies], streamed in
/// small chunks, and records the requests.
class _FakeModel {
  _FakeModel(this.replies);

  final List<mp.LLMResponse> replies;
  final List<({List<mp.ChatMessage> messages, String? systemPrompt})> requests =
      [];

  Stream<mp.LLMStreamChunk> call({
    required mp.LlmConfig config,
    required List<mp.ChatMessage> messages,
    required List<mp.MCPTool> tools,
    String? systemPrompt,
  }) async* {
    requests.add((messages: messages, systemPrompt: systemPrompt));
    final reply = replies[requests.length - 1];
    for (var i = 0; i < reply.text.length; i += 16) {
      yield mp.LLMStreamChunk(
        textDelta: reply.text.substring(i, min(i + 16, reply.text.length)),
      );
    }
    yield mp.LLMStreamChunk(textDelta: '', isDone: true, finalResponse: reply);
  }
}

/// A controller that talks to [model], with the errors its renderer reports
/// collected in [errors].
McpGenuiChatController _controller(
  _FakeModel model,
  List<A2uiRendererError> errors, {
  List<FunctionImplementation>? clientFunctions,
}) {
  mp.LLMService.embeddedStreamHandler = model.call;
  addTearDown(() => mp.LLMService.embeddedStreamHandler = null);
  final controller = McpGenuiChatController(
    llmConfig: const mp.LlmConfig(
      provider: mp.LlmProvider.embedded,
      model: 'fake',
      apiKey: '',
    ),
    clientFunctions: clientFunctions,
  );
  addTearDown(controller.dispose);
  controller.processor.model.onError.subscribe(errors.add);
  return controller;
}

const String _catalogId = BasicCatalog.v0_9Id;

/// Messages that create the surface `form` with a Submit button.
final List<Map<String, Object?>> _formMessages = [
  {
    'version': 'v0.9',
    'createSurface': {'surfaceId': 'form', 'catalogId': _catalogId},
  },
  {
    'version': 'v0.9',
    'updateComponents': {
      'surfaceId': 'form',
      'components': [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['title', 'submit'],
        },
        {'id': 'title', 'component': 'Text', 'text': 'Pick one'},
        {'id': 'label', 'component': 'Text', 'text': 'Submit'},
        {
          'id': 'submit',
          'component': 'Button',
          'child': 'label',
          'action': {
            'event': {
              'name': 'submit',
              'context': {'choice': 'b'},
            },
          },
        },
      ],
    },
  },
];

final String _formReply =
    'Here is a form.\n<a2ui-json>\n${jsonEncode(_formMessages)}\n'
    '</a2ui-json>\nFill it in.';

class _AddFunction extends FunctionImplementation {
  _AddFunction()
    : super(
        name: 'add',
        description: 'Adds two numbers.',
        returnType: A2uiReturnType.number,
        argumentSchema: Schema.object(
          properties: {'a': Schema.number(), 'b': Schema.number()},
          required: ['a', 'b'],
        ),
      );

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) => (args['a'] as num) + (args['b'] as num);
}

void main() {
  testWidgets('renders the A2UI blocks of a reply and shows the text around '
      'them', (tester) async {
    final model = _FakeModel([mp.LLMResponse(text: _formReply)]);
    final errors = <A2uiRendererError>[];
    final controller = _controller(model, errors);

    controller.sendMessage('Show a form');
    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(controller.activeSurfaceIds, ['form']);
    expect(
      [for (final entry in controller.entries) (entry.kind, entry.text)],
      [
        (GenuiChatEntryKind.user, 'Show a form'),
        (GenuiChatEntryKind.assistant, 'Here is a form.\n\nFill it in.'),
        (GenuiChatEntryKind.surface, ''),
      ],
    );
    final systemPrompt = model.requests.single.systemPrompt!;
    expect(systemPrompt, contains('<a2ui-json>'));
    expect(systemPrompt, contains('The active catalog ID is: "$_catalogId"'));
  });

  testWidgets('sends an action on a surface to the model', (tester) async {
    final model = _FakeModel([
      mp.LLMResponse(text: _formReply),
      const mp.LLMResponse(text: 'Thanks!'),
    ]);
    final errors = <A2uiRendererError>[];
    final controller = _controller(model, errors);
    controller.sendMessage('Show a form');
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: A2uiSurface(surface: controller.contextFor('form')!),
        ),
      ),
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(model.requests, hasLength(2));
    expect(
      model.requests.last.messages.last.content,
      'UI Action "submit" submitted with context: {"choice":"b"}',
    );
    expect(controller.entries.last.text, 'Thanks!');
  });

  testWidgets('applies fenced A2UI JSON written outside the A2UI blocks once', (
    tester,
  ) async {
    final reply = [
      for (final message in _formMessages)
        '```json\n${jsonEncode(message)}\n```',
    ].join('\n');
    final model = _FakeModel([mp.LLMResponse(text: reply)]);
    final errors = <A2uiRendererError>[];
    final controller = _controller(model, errors);

    controller.sendMessage('Show a form');
    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(controller.activeSurfaceIds, ['form']);
    expect(
      controller.entries.map((entry) => entry.kind),
      isNot(contains(GenuiChatEntryKind.assistant)),
    );
  });

  testWidgets('applies the A2UI operations the model calls as tools once', (
    tester,
  ) async {
    final model = _FakeModel([
      mp.LLMResponse(
        text: '',
        toolCalls: [
          for (final (index, message) in _formMessages.indexed)
            mp.LLMToolCall(
              id: 'call_$index',
              name: message.keys.last,
              arguments: message,
            ),
        ],
      ),
      const mp.LLMResponse(text: 'Done.'),
    ]);
    final errors = <A2uiRendererError>[];
    final controller = _controller(model, errors);

    controller.sendMessage('Show a form');
    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(controller.activeSurfaceIds, ['form']);
    expect(
      controller.contextFor('form')!.componentsModel.get('submit'),
      isNotNull,
    );
  });

  testWidgets('runs a client function the model calls as a tool', (
    tester,
  ) async {
    final model = _FakeModel([
      const mp.LLMResponse(
        text: '',
        toolCalls: [
          mp.LLMToolCall(
            id: 'call_add',
            name: 'add',
            arguments: {'a': 2, 'b': 3},
          ),
        ],
      ),
      const mp.LLMResponse(text: 'It is 5.'),
    ]);
    final errors = <A2uiRendererError>[];
    final controller = _controller(
      model,
      errors,
      clientFunctions: [_AddFunction()],
    );

    controller.sendMessage('Add 2 and 3');
    await tester.pumpAndSettle();

    final toolResponse = model.requests.last.messages.last;
    expect(toolResponse.type, mp.MessageType.toolResponse);
    expect(toolResponse.content, '5');
    expect(controller.entries.last.text, 'It is 5.');
  });
}
