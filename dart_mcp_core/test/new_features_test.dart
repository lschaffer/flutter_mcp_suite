import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() {
  group('1. Multimodal Content Parts (ChatMessage & ChatContentPart)', () {
    test('TextPart serialization and deserialization', () {
      const part = TextPart('Hello world');
      final json = part.toJson();
      expect(json['type'], equals('text'));
      expect(json['text'], equals('Hello world'));

      final fromJson = ChatContentPart.fromJson(json);
      expect(fromJson, isA<TextPart>());
      expect((fromJson as TextPart).text, equals('Hello world'));
    });

    test('ImagePart serialization and deserialization with url and base64', () {
      final imgBytes = Uint8List.fromList([1, 2, 3, 4]);
      final base64Str = base64Encode(imgBytes);

      final imgPart = ImagePart.fromBase64(base64Str, mimeType: 'image/jpeg');
      final json = imgPart.toJson();
      expect(json['type'], equals('image'));
      expect(json['base64'], equals(base64Str));
      expect(json['mimeType'], equals('image/jpeg'));

      final fromJson = ChatContentPart.fromJson(json) as ImagePart;
      expect(fromJson.base64, equals(base64Str));
      expect(fromJson.mimeType, equals('image/jpeg'));
    });

    test('ChatMessage supports parts and helper factories', () {
      final msg = ChatMessage.user(
        'Check this screenshot',
        parts: [
          const TextPart('Check this screenshot'),
          ImagePart.fromUrl('https://example.com/screenshot.png'),
        ],
      );

      expect(msg.role, equals(ChatRole.user));
      expect(msg.content, equals('Check this screenshot'));
      expect(msg.parts, isNotNull);
      expect(msg.parts!.length, equals(2));

      final json = msg.toJson();
      expect(json['parts'], isA<List>());

      final restored = ChatMessage.fromJson(json);
      expect(restored.parts, isNotNull);
      expect(restored.parts!.length, equals(2));
      expect(restored.parts![0], isA<TextPart>());
      expect(restored.parts![1], isA<ImagePart>());
    });
  });

  group('2. Episodic Memory Store & RetrieveMemoryTool', () {
    test('EpisodicMemoryStore adds and searches archived memories', () {
      final store = EpisodicMemoryStore();
      final entry = EpisodicMemoryEntry(
        archiveId: 'mem_test1',
        startTurnIndex: 0,
        endTurnIndex: 2,
        timestamp: DateTime.now(),
        rawMessages: [
          ChatMessage.user('My secret code is ALPHA-999'),
          ChatMessage.assistant('Understood, code noted.'),
        ],
        summary: 'User shared code ALPHA-999.',
      );

      store.addEntry(entry);
      expect(store.entries.length, equals(1));

      // Query matching
      final matches = store.search('ALPHA');
      expect(matches.length, equals(1));
      expect(matches.first.archiveId, equals('mem_test1'));

      // Query non-matching
      final noMatches = store.search('BETA');
      expect(noMatches.isEmpty, isTrue);

      // Lookup by ID
      final byId = store.getById('mem_test1');
      expect(byId, isNotNull);
      expect(byId!.rawMessages.length, equals(2));
    });

    test('RetrieveMemoryTool executes and recalls memories', () async {
      final store = EpisodicMemoryStore();
      final entry = EpisodicMemoryEntry(
        archiveId: 'mem_auth',
        startTurnIndex: 0,
        endTurnIndex: 2,
        timestamp: DateTime.now(),
        rawMessages: [
          ChatMessage.user('Auth token is xyz123'),
          ChatMessage.assistant('Saved token.'),
        ],
        summary: 'Saved user auth token.',
      );
      store.addEntry(entry);

      String? retrievedArchiveId;
      int? retrievedTurns;
      final tool = RetrieveMemoryTool(
        memoryStore: store,
        onMemoryRetrieved: (id, count, query) {
          retrievedArchiveId = id;
          retrievedTurns = count;
        },
      );

      final result = await tool.execute({'query': 'xyz123'});
      expect(result.isError, isFalse);
      expect(result.text, contains('ARCHIVE [mem_auth]'));
      expect(result.text, contains('Auth token is xyz123'));
      expect(retrievedArchiveId, equals('mem_auth'));
      expect(retrievedTurns, equals(2));
    });
  });

  group('3. Dynamic Skills (SkillDefinition & Tools)', () {
    test('ActivateSkillsTool and DeactivateSkillsTool trigger callbacks', () async {
      final activated = <String>[];
      final deactivated = <String>[];

      final activateTool = ActivateSkillsTool(
        availableSkills: ['git_review', 'sqlite_analyst'],
        onActivate: (skills) async {
          activated.addAll(skills);
          return 'Activated ${skills.join(", ")}';
        },
      );

      final deactivateTool = DeactivateSkillsTool(
        onDeactivate: (skills) async {
          deactivated.addAll(skills);
          return 'Deactivated ${skills.join(", ")}';
        },
      );

      final actResult = await activateTool.execute({'skills': ['git_review']});
      expect(actResult.text, contains('Activated git_review'));
      expect(activated, contains('git_review'));

      final deactResult = await deactivateTool.execute({'skills': ['git_review']});
      expect(deactResult.text, contains('Deactivated git_review'));
      expect(deactivated, contains('git_review'));
    });
  });

  group('4. Sub-Agent Delegation (DelegateTaskTool)', () {
    test('DelegateTaskTool dispatches sub-task to runner', () async {
      String? delegatedAssignee;
      String? delegatedTask;

      final tool = DelegateTaskTool(
        availableAssignees: ['clone', 'researcher'],
        runner: ({required String assignee, required String task, List<String>? enabledTools}) async {
          delegatedAssignee = assignee;
          delegatedTask = task;
          return 'Sub-agent completed task: Found 3 articles.';
        },
      );

      final result = await tool.execute({
        'assignee': 'researcher',
        'task': 'Find recent Flutter news',
      });

      expect(result.isError, isFalse);
      expect(result.text, contains('Found 3 articles'));
      expect(delegatedAssignee, equals('researcher'));
      expect(delegatedTask, equals('Find recent Flutter news'));
    });
  });

  group('5. Evaluation Harness (EvalTask, Graders, TrajectoryRecorder)', () {
    test('ExactMatchGrader grades correctly', () async {
      const task = EvalTask(
        id: 'task_1',
        name: 'Greeting task',
        prompt: 'Say hello',
        expectedOutput: 'Hello, World!',
      );

      const grader = ExactMatchGrader();
      final passResult = await grader.grade(
        task: task,
        actualOutput: 'The answer is Hello, World! Have a nice day.',
        trajectory: [],
      );
      expect(passResult.isSuccess, isTrue);

      final failResult = await grader.grade(
        task: task,
        actualOutput: 'Goodbye!',
        trajectory: [],
      );
      expect(failResult.isSuccess, isFalse);
    });

    test('ToolCallGrader verifies required tool invocations', () async {
      const task = EvalTask(
        id: 'task_tool',
        name: 'Tool call task',
        prompt: 'Look up weather',
        expectedTools: ['get_weather'],
      );

      const grader = ToolCallGrader();
      final passResult = await grader.grade(
        task: task,
        actualOutput: 'Sunny 25C',
        trajectory: [
          ChatMessage(
            id: 'm1',
            content: '',
            role: ChatRole.assistant,
            timestamp: DateTime.now(),
            toolName: 'get_weather',
          ),
        ],
      );
      expect(passResult.isSuccess, isTrue);

      final failResult = await grader.grade(
        task: task,
        actualOutput: 'Sunny 25C',
        trajectory: [],
      );
      expect(failResult.isSuccess, isFalse);
    });

    test('TrajectoryRecorder exports and imports JSON trajectories', () {
      final original = [
        ChatMessage.user('Hello'),
        ChatMessage.assistant('Hi there!'),
      ];

      final jsonStr = TrajectoryRecorder.exportToJson(original);
      expect(jsonStr, contains('Hello'));
      expect(jsonStr, contains('Hi there!'));

      final restored = TrajectoryRecorder.importFromJson(jsonStr);
      expect(restored.length, equals(2));
      expect(restored[0].content, equals('Hello'));
      expect(restored[1].content, equals('Hi there!'));
    });
  });
}
