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
        runner: ({required String assignee, required String task, List<String>? enabledTools, String? model}) async {
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

  group('6. Workflow Scratchpad Memory (WorkflowMemoryStore, StoreMemoryTool, RecallMemoryTool)', () {
    test('WorkflowMemoryStore set, get, remove, listKeys, and json roundtrip', () {
      final store = WorkflowMemoryStore();
      store.set('auth_vulnerabilities', 'Found SQL injection on line 42');
      store.set('port_count', 8080);
      store.set('tags', ['security', 'audit']);

      expect(store.has('auth_vulnerabilities'), isTrue);
      expect(store.get('auth_vulnerabilities'), equals('Found SQL injection on line 42'));
      expect(store.getTyped<int>('port_count'), equals(8080));
      expect(store.listKeys(), containsAll(['auth_vulnerabilities', 'port_count', 'tags']));

      final json = store.toJson();
      final restored = WorkflowMemoryStore.fromJson(json);
      expect(restored.get('auth_vulnerabilities'), equals('Found SQL injection on line 42'));
      expect(restored.get('port_count'), equals(8080));

      store.remove('port_count');
      expect(store.has('port_count'), isFalse);
    });

    test('StoreMemoryTool and RecallMemoryTool interact with WorkflowMemoryStore', () async {
      final store = WorkflowMemoryStore();
      final storeTool = StoreMemoryTool(store: store);
      final recallTool = RecallMemoryTool(store: store);

      // Initially empty
      final emptyRecall = await recallTool.execute({});
      expect(emptyRecall.text, contains('currently empty'));

      // Store memory
      final storeResult = await storeTool.execute({
        'key': 'api_endpoint',
        'value': 'https://api.example.com/v1',
      });
      expect(storeResult.isError, isFalse);
      expect(store.get('api_endpoint'), equals('https://api.example.com/v1'));

      // Recall by key
      final recallResult = await recallTool.execute({'key': 'api_endpoint'});
      expect(recallResult.isError, isFalse);
      expect(recallResult.text, equals('https://api.example.com/v1'));

      // List keys
      final listResult = await recallTool.execute({'key': '*'});
      expect(listResult.text, contains('api_endpoint'));

      // Missing key returns error with suggestion
      final missingResult = await recallTool.execute({'key': 'missing_key'});
      expect(missingResult.isError, isTrue);
      expect(missingResult.text, contains('Key "missing_key" not found'));
    });
  });

  group('7. Dynamic model parameter in DelegateTaskTool', () {
    test('DelegateTaskTool passes model override to runner', () async {
      String? executedModel;
      final tool = DelegateTaskTool(
        availableAssignees: ['clone', 'qwen_sub'],
        runner: ({
          required String assignee,
          required String task,
          List<String>? enabledTools,
          String? model,
        }) async {
          executedModel = model;
          return 'Completed with model $model';
        },
      );

      final result = await tool.execute({
        'assignee': 'clone',
        'task': 'Optimize query',
        'model': 'qwen2.5-coder:32b',
      });

      expect(result.isError, isFalse);
      expect(executedModel, equals('qwen2.5-coder:32b'));
    });

    test('DelegateTaskTool accepts modelOverride as alternative parameter name', () async {
      String? executedModel;
      final tool = DelegateTaskTool(
        availableAssignees: ['clone'],
        runner: ({
          required String assignee,
          required String task,
          List<String>? enabledTools,
          String? model,
        }) async {
          executedModel = model;
          return 'Done';
        },
      );

      await tool.execute({
        'assignee': 'clone',
        'task': 'Check types',
        'modelOverride': 'fast-mini',
      });

      expect(executedModel, equals('fast-mini'));
    });
  });

  group('8. Bulk Serialization for EpisodicMemoryStore', () {
    test('EpisodicMemoryStore bulk toJson, toJsonList, and loadEntries roundtrip', () {
      final store = EpisodicMemoryStore();
      final entry1 = EpisodicMemoryEntry(
        archiveId: 'mem_1',
        startTurnIndex: 0,
        endTurnIndex: 3,
        timestamp: DateTime.parse('2026-10-27T10:00:00Z'),
        rawMessages: [ChatMessage.user('Turn 1'), ChatMessage.assistant('Response 1')],
        summary: 'First discussion about architecture',
      );
      final entry2 = EpisodicMemoryEntry(
        archiveId: 'mem_2',
        startTurnIndex: 4,
        endTurnIndex: 7,
        timestamp: DateTime.parse('2026-10-27T11:00:00Z'),
        rawMessages: [ChatMessage.user('Turn 2'), ChatMessage.assistant('Response 2')],
        summary: 'Second discussion about database',
      );

      store.addEntry(entry1);
      store.addEntry(entry2);

      // Serialize
      final json = store.toJson();
      expect(json['entries'], isA<List>());
      expect((json['entries'] as List).length, equals(2));

      // Restore via factory
      final restored = EpisodicMemoryStore.fromJson(json);
      expect(restored.entries.length, equals(2));
      expect(restored.getById('mem_1')?.summary, equals('First discussion about architecture'));
      expect(restored.getById('mem_2')?.rawMessages.first.content, equals('Turn 2'));

      // Test loadEntries with replace: false vs replace: true
      final store3 = EpisodicMemoryStore();
      store3.loadEntries([entry1]);
      expect(store3.entries.length, equals(1));
      store3.loadEntries([entry2], replace: false);
      expect(store3.entries.length, equals(2));
      store3.loadEntries([entry1], replace: true);
      expect(store3.entries.length, equals(1));
    });

    test('9. Multi-Profile LlmConfig (id, name, clone, roundtrip)', () {
      const config1 = LlmConfig(
        id: 'llm_mistral_1',
        name: 'Fast Assistant',
        provider: LlmProvider.mistral,
        model: 'mistral-medium-latest',
        apiKey: 'key_123',
        baseUrl: 'https://api.mistral.ai/v1',
      );

      expect(config1.displayName, equals('Fast Assistant'));
      expect(config1.profileId, equals('llm_mistral_1'));

      // Test clone
      final cloned = config1.clone();
      expect(cloned.id, contains('llm_mistral_1_copy_'));
      expect(cloned.name, equals('Fast Assistant (Copy)'));
      expect(cloned.model, equals('mistral-medium-latest'));
      expect(cloned.apiKey, equals('key_123'));

      // Test custom clone
      final customClone = config1.clone(newId: 'llm_custom', newName: 'Custom Name');
      expect(customClone.id, equals('llm_custom'));
      expect(customClone.name, equals('Custom Name'));

      // Test JSON roundtrip
      final json = config1.toJson();
      expect(json['id'], equals('llm_mistral_1'));
      expect(json['name'], equals('Fast Assistant'));

      final restored = LlmConfig.fromJson(json);
      expect(restored.id, equals('llm_mistral_1'));
      expect(restored.name, equals('Fast Assistant'));
      expect(restored.provider, equals(LlmProvider.mistral));
      expect(restored.model, equals('mistral-medium-latest'));
      expect(restored.apiKey, equals('key_123'));

      // Test fallback display name and profile ID when id/name omitted
      const anonConfig = LlmConfig(
        provider: LlmProvider.gemini,
        model: 'gemini-3.7-flash',
        apiKey: 'key_gemini',
      );
      expect(anonConfig.displayName, equals('gemini-3.7-flash'));
      expect(anonConfig.profileId, equals('llm_gemini_gemini_3_7_flash'));
    });
  });
}

