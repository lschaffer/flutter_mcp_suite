import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubAgentExecution Model Tests', () {
    test('initializes with running status and tracks progress', () {
      final sub = SubAgentExecution(
        id: 'sub-1',
        task: 'Scrape documentation',
        depth: 1,
        startedAt: DateTime.now(),
      );

      expect(sub.id, 'sub-1');
      expect(sub.task, 'Scrape documentation');
      expect(sub.depth, 1);
      expect(sub.isRunning, isTrue);
      expect(sub.isCompleted, isFalse);

      sub.addProgress('Fetched page 1');
      expect(sub.progressUpdates, contains('Fetched page 1'));

      sub.complete('Synthesized 5 pages');
      expect(sub.isRunning, isFalse);
      expect(sub.isCompleted, isTrue);
      expect(sub.result, 'Synthesized 5 pages');
      expect(sub.completedAt, isNotNull);
    });

    test('toJson and fromJson roundtrip correctly', () {
      final sub = SubAgentExecution(
        id: 'sub-2',
        task: 'Unit testing',
        depth: 2,
        startedAt: DateTime.now(),
      );
      sub.addProgress('Running test suite');
      sub.complete('All tests passed');

      final json = sub.toJson();
      final restored = SubAgentExecution.fromJson(json);

      expect(restored.id, sub.id);
      expect(restored.task, sub.task);
      expect(restored.depth, sub.depth);
      expect(restored.result, sub.result);
      expect(restored.progressUpdates, sub.progressUpdates);
    });
  });

  group('EvalController Tests', () {
    test('initializes with default tasks and allows add/remove', () {
      final ctrl = EvalController();
      expect(ctrl.tasks.length, greaterThanOrEqualTo(3));

      ctrl.addTask(
        const EvalTask(
          id: 'custom-task',
          name: 'Custom Evaluation',
          prompt: 'Echo TEST_PASS',
          expectedOutput: 'TEST_PASS',
        ),
      );
      expect(ctrl.tasks.any((t) => t.id == 'custom-task'), isTrue);

      ctrl.removeTask('custom-task');
      expect(ctrl.tasks.any((t) => t.id == 'custom-task'), isFalse);

      ctrl.clearTasks();
      expect(ctrl.tasks, isEmpty);

      ctrl.resetTasksToDefault();
      expect(ctrl.tasks.length, greaterThanOrEqualTo(3));
    });
  });

  group('PlaygroundController Phase 2 State Extensions', () {
    late PlaygroundController controller;

    setUp(() {
      controller = PlaygroundController(
        initialLlmConfig: const LlmConfig(
          provider: LlmProvider.openai,
          apiKey: 'mock-key',
          model: 'gpt-4o',
        ),
      );
    });

    test('Episodic memory store and memory archive reactive getters', () {
      expect(controller.enableEpisodicMemory, isTrue);
      expect(controller.memoryArchive, isEmpty);

      controller.episodicMemoryStore.addEntry(
        EpisodicMemoryEntry(
          archiveId: 'mem_1',
          startTurnIndex: 1,
          endTurnIndex: 3,
          timestamp: DateTime.now(),
          rawMessages: [
            ChatMessage.user('What is the weather in Berlin?'),
            ChatMessage.assistant('It is 22 degrees.'),
          ],
          summary: 'User asked about weather in Berlin; assistant replied 22C.',
        ),
      );

      expect(controller.memoryArchive.length, 1);
      expect(controller.memoryArchive.first.archiveId, 'mem_1');

      controller.clearMemoryArchive();
      expect(controller.memoryArchive, isEmpty);
    });

    test('Dynamic skills registration and toggle', () {
      expect(controller.dynamicSkills, isEmpty);
      expect(controller.activeSkillNames, isEmpty);

      final skill = const SkillDefinition(
        name: 'sqlite_expert',
        description: 'Enables querying SQLite databases',
        systemPrompt: 'You are an SQLite expert.',
      );

      controller.registerDynamicSkill(skill);
      expect(controller.dynamicSkills.length, 1);
      expect(controller.dynamicSkills.first.name, 'sqlite_expert');

      controller.toggleDynamicSkill('sqlite_expert');
      expect(controller.activeSkillNames, contains('sqlite_expert'));

      controller.toggleDynamicSkill('sqlite_expert');
      expect(controller.activeSkillNames, isNot(contains('sqlite_expert')));

      controller.activateSkills(['sqlite_expert']);
      expect(controller.activeSkillNames, contains('sqlite_expert'));

      controller.deactivateSkills(['sqlite_expert']);
      expect(controller.activeSkillNames, isEmpty);
    });

    test('Pending multimodal parts staging and clearing', () {
      expect(controller.pendingParts, isEmpty);

      final docPart = DocumentPart(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'data.csv',
        mimeType: 'text/csv',
      );

      controller.addPendingPart(docPart);
      expect(controller.pendingParts.length, 1);
      expect(controller.pendingParts.first, isA<DocumentPart>());

      controller.removePendingPart(0);
      expect(controller.pendingParts, isEmpty);

      controller.addPendingPart(docPart);
      controller.clearPendingParts();
      expect(controller.pendingParts, isEmpty);
    });

    test('Agent Inspector visibility state and toggle', () {
      expect(controller.isInspectorVisible, isTrue);
      controller.toggleInspector();
      expect(controller.isInspectorVisible, isFalse);
      controller.isInspectorVisible = true;
      expect(controller.isInspectorVisible, isTrue);
    });
  });

  group('Widget Tests for Phase 2 UI Dialogs & Components', () {
    testWidgets('DynamicSkillDock renders active and inactive skill chips',
        (tester) async {
      final controller = PlaygroundController(
        initialLlmConfig: const LlmConfig(
          provider: LlmProvider.openai,
          apiKey: 'mock-key',
          model: 'gpt-4o',
        ),
      );

      controller.registerDynamicSkill(
        const SkillDefinition(
          name: 'git_reviewer',
          description: 'Reviews git diffs',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicSkillDock(controller: controller),
          ),
        ),
      );

      expect(find.text('git_reviewer'), findsOneWidget);

      await tester.tap(find.text('git_reviewer'));
      await tester.pump();

      expect(controller.activeSkillNames, contains('git_reviewer'));
    });

    testWidgets('MemoryArchiveDialog renders empty state and search',
        (tester) async {
      final controller = PlaygroundController(
        initialLlmConfig: const LlmConfig(
          provider: LlmProvider.openai,
          apiKey: 'mock-key',
          model: 'gpt-4o',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 700,
              child: MemoryArchiveDialog(controller: controller),
            ),
          ),
        ),
      );

      expect(find.text('Episodic Memory Archive'), findsOneWidget);
      expect(find.textContaining('Search archived turns'), findsOneWidget);
      expect(find.textContaining('No memories archived yet'), findsOneWidget);
    });

    test('ClipboardPayload image and document media properties', () {
      final imgPayload = ClipboardPayload(
        type: ClipboardContentType.image,
        name: 'screenshot.png',
        mimeType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(imgPayload.isMedia, isTrue);

      final docPayload = ClipboardPayload(
        type: ClipboardContentType.document,
        name: 'spec.md',
        mimeType: 'text/markdown',
        text: '# Title',
      );
      expect(docPayload.isMedia, isTrue);

      final textPayload = const ClipboardPayload(
        type: ClipboardContentType.text,
        name: 'text',
        mimeType: 'text/plain',
        text: 'hello',
      );
      expect(textPayload.isMedia, isFalse);
    });
  });

  group('ModelPricingService Tests', () {
    test('isLocalOrFree accurately detects free/local models and endpoints', () {
      expect(
        ModelPricingService.isLocalOrFree(
          const LlmConfig(
            provider: LlmProvider.ollama,
            model: 'llama3:8b',
            apiKey: '',
          ),
        ),
        isTrue,
      );

      expect(
        ModelPricingService.isLocalOrFree(
          const LlmConfig(
            provider: LlmProvider.embedded,
            model: 'model.gguf',
            apiKey: '',
          ),
        ),
        isTrue,
      );

      expect(
        ModelPricingService.isLocalOrFree(
          const LlmConfig(
            provider: LlmProvider.openaiCompatible,
            model: 'qwen',
            baseUrl: 'http://localhost:11434/v1',
            apiKey: '',
          ),
        ),
        isTrue,
      );

      expect(
        ModelPricingService.isLocalOrFree(
          const LlmConfig(
            provider: LlmProvider.openaiCompatible,
            model: 'deepseek-v3',
            baseUrl: 'http://127.0.0.1:8000/v1',
            apiKey: '',
          ),
        ),
        isTrue,
      );

      expect(
        ModelPricingService.isLocalOrFree(
          const LlmConfig(
            provider: LlmProvider.openaiCompatible,
            model: 'deepseek-ai/DeepSeek-V3',
            baseUrl: 'https://api.deepinfra.com/v1/openai',
            apiKey: 'key',
          ),
        ),
        isFalse,
      );
    });

    test('fetchPrice returns free \$0 for local or ollama endpoints', () async {
      final price = await ModelPricingService.fetchPrice(
        const LlmConfig(
          provider: LlmProvider.ollama,
          model: 'qwen2.5:7b',
          baseUrl: 'http://localhost:11434',
          apiKey: '',
        ),
      );

      expect(price.isFree, isTrue);
      expect(price.hasPricing, isTrue);
      expect(price.inputPer1MUsd, 0.0);
      expect(price.outputPer1MUsd, 0.0);
      expect(price.rateDescription, contains('Local'));
    });

    test('fetchPrice returns unknown for empty or unreachable configuration without hardcoded values', () async {
      final price = await ModelPricingService.fetchPrice(
        const LlmConfig(
          provider: LlmProvider.openaiCompatible,
          model: 'non-existent-synthetic-model-99999',
          baseUrl: 'http://invalid-fake-host-999.xyz',
          apiKey: '',
        ),
      );

      expect(price.hasPricing, isFalse);
      expect(price.rateDescription, 'Price: Unknown');
    });

    test('ModelPriceInfo formattedContextWindow and toEur conversions', () {
      const info1M = ModelPriceInfo(
        inputPer1MUsd: 1.0,
        outputPer1MUsd: 2.0,
        contextWindow: 1000000,
        rateDescription: 'test',
      );
      expect(info1M.formattedContextWindow, '1M');

      const info128k = ModelPriceInfo(
        inputPer1MUsd: 1.0,
        outputPer1MUsd: 2.0,
        contextWindow: 128000,
        rateDescription: 'test',
      );
      expect(info128k.formattedContextWindow, '128k');

      const infoNone = ModelPriceInfo(
        inputPer1MUsd: 1.0,
        outputPer1MUsd: 2.0,
        contextWindow: null,
        rateDescription: 'test',
      );
      expect(infoNone.formattedContextWindow, isNull);

      expect(ModelPricingService.toEur(1.0), closeTo(0.92, 0.001));
    });

    testWidgets('LlmConfigForm renders model pricing and context banner for local model', (tester) async {
      final modelCtrl = TextEditingController(text: 'llama3:8b');
      final apiKeyCtrl = TextEditingController();
      final baseUrlCtrl = TextEditingController(text: 'http://localhost:11434');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LlmConfigForm(
                provider: LlmProvider.ollama,
                onProviderChanged: (_) {},
                modelCtrl: modelCtrl,
                apiKeyCtrl: apiKeyCtrl,
                baseUrlCtrl: baseUrlCtrl,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LlmConfigForm), findsOneWidget);
      expect(find.textContaining('Free / Local Model'), findsOneWidget);
      expect(find.textContaining('131k'), findsOneWidget);
    });
  });
}

