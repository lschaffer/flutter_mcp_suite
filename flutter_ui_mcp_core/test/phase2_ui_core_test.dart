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

    testWidgets('LlmConfigForm excludes LlmProvider.embedded when driver is not registered', (tester) async {
      // Ensure driver is unregistered
      EmbeddedLlmRegistry.unregister();
      expect(EmbeddedLlmRegistry.isAvailable, isFalse);

      final modelCtrl = TextEditingController();
      final apiKeyCtrl = TextEditingController();
      final baseUrlCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LlmConfigForm(
                provider: LlmProvider.none,
                onProviderChanged: (_) {},
                modelCtrl: modelCtrl,
                apiKeyCtrl: apiKeyCtrl,
                baseUrlCtrl: baseUrlCtrl,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
      await tester.pumpAndSettle();

      // Verify Embedded provider is NOT shown in dropdown items
      expect(find.text(LlmProvider.embedded.displayName), findsNothing);
      expect(find.text(LlmProvider.gemini.displayName), findsWidgets);
    });

    test('PlaygroundController sanitizes embedded provider to none when driver is not registered', () {
      EmbeddedLlmRegistry.unregister();
      expect(EmbeddedLlmRegistry.isAvailable, isFalse);

      final controller = PlaygroundController(
        initialLlmConfig: const LlmConfig(
          provider: LlmProvider.embedded,
          model: 'qwen2.5.gguf',
          apiKey: '',
        ),
      );

      expect(controller.llmConfig.provider, equals(LlmProvider.none));
    });
  });

  group('SystemPromptTemplate Tests', () {
    test('default templates contain expected entries', () {
      expect(kDefaultSystemPromptTemplates.length, equals(3));
      expect(kDefaultSystemPromptTemplates.any((t) => t.label == 'Coding Expert'), isTrue);
      expect(kDefaultSystemPromptTemplates.any((t) => t.label == 'Vision Analyst'), isTrue);
      expect(kDefaultSystemPromptTemplates.any((t) => t.label == 'Data & Tools Agent'), isTrue);
    });

    testWidgets('SettingsPanel renders custom templates and updates systemPrompt on tap', (tester) async {
      final controller = PlaygroundController();
      const customTemplates = [
        SystemPromptTemplate(
          label: 'Customer Support',
          prompt: 'You are a friendly customer support representative.',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsPanel(
              controller: controller,
              initialTabIndex: 0,
              systemPromptTemplates: customTemplates,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Persona Templates:'), findsOneWidget);
      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.text('Coding Expert'), findsNothing);

      // Tap on the chip
      await tester.tap(find.text('Customer Support'));
      await tester.pumpAndSettle();

      expect(controller.systemPrompt, 'You are a friendly customer support representative.');
    });

    testWidgets('SettingsPanel hides templates when showSystemPromptTemplates is false', (tester) async {
      final controller = PlaygroundController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsPanel(
              controller: controller,
              initialTabIndex: 0,
              showSystemPromptTemplates: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Persona Templates:'), findsNothing);
      expect(find.text('Coding Expert'), findsNothing);
    });

    testWidgets('LlmProfilesTab renders multi-profiles, strategy panel, and hides embedded when unavailable', (tester) async {
      final initialConfigs = [
        const LlmConfig(
          id: 'llm_mistral_1',
          name: 'Mistral Primary',
          provider: LlmProvider.mistral,
          model: 'mistral-medium-latest',
          apiKey: 'key1',
        ),
        const LlmConfig(
          id: 'llm_mistral_2',
          name: 'Mistral Codestral',
          provider: LlmProvider.mistral,
          model: 'codestral-latest',
          apiKey: 'key2',
        ),
      ];

      final controller = PlaygroundController(
        initialLlmConfigs: initialConfigs,
      );

      expect(controller.llmConfigs.length, equals(2));
      expect(controller.selectedLlmId, equals('llm_mistral_1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LlmProfilesTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Heading and Add LLM button
      expect(find.text('Configured LLMs'), findsOneWidget);
      expect(find.text('Add LLM'), findsOneWidget);

      // Both profile cards rendered
      expect(find.text('Mistral Primary'), findsOneWidget);
      expect(find.text('Mistral Codestral'), findsOneWidget);
      expect(find.text('Active / Primary'), findsOneWidget);

      // Embedded tab should NOT be present when EmbeddedLlmRegistry is not available
      expect(find.text('Embedded'), findsNothing);

      // Global Tool Rules & Strategy card
      expect(find.text('Global Tool Rules & Strategy'), findsOneWidget);

      // Tap to expand strategy
      await tester.tap(find.text('Global Tool Rules & Strategy'));
      await tester.pumpAndSettle();

      expect(find.text('Inject Tool Calling Rules'), findsOneWidget);
      expect(find.text('Tool Delivery Strategy'), findsWidgets);

      // Collapse strategy to bring cards into viewport
      await tester.tap(find.text('Global Tool Rules & Strategy'));
      await tester.pumpAndSettle();

      // Tap Set Active on second profile
      await tester.tap(find.text('Set Active'));
      await tester.pumpAndSettle();

      expect(controller.selectedLlmId, equals('llm_mistral_2'));
    });
  });

  group('WorkflowSaveDialog & Progressive Tool Selection Tests', () {
    testWidgets('WorkflowSaveDialog saves only last prompt turn and displays omitted turns hint', (tester) async {
      final controller = PlaygroundController();

      final now = DateTime.now();
      // Add conversation history with 3 turns
      final messages = [
        ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: 'Old Turn 1: Analyze codebase',
          type: MessageType.text,
          timestamp: now,
        ),
        ChatMessage(
          id: 'msg-2',
          role: ChatRole.assistant,
          content: 'Analysis complete.',
          type: MessageType.text,
          timestamp: now,
        ),
        ChatMessage(
          id: 'msg-3',
          role: ChatRole.user,
          content: 'Old Turn 2: Run linter',
          type: MessageType.text,
          timestamp: now,
        ),
        ChatMessage(
          id: 'msg-4',
          role: ChatRole.assistant,
          content: 'Linting clean.',
          type: MessageType.text,
          timestamp: now,
        ),
        ChatMessage(
          id: 'msg-5',
          role: ChatRole.user,
          content: 'Latest Step 1: Run unit tests\n++#++\nLatest Step 2: Deploy staging',
          type: MessageType.text,
          timestamp: now,
        ),
        ChatMessage(
          id: 'msg-6',
          role: ChatRole.assistant,
          content: 'Tests passed.',
          type: MessageType.text,
          timestamp: now,
        ),
      ];
      for (final m in messages) {
        controller.addMessage(m);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkflowSaveDialog(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check hint about omitted earlier turns
      expect(
        find.text('Saving the most recent prompt turn (2 earlier turn(s) omitted from workflow).'),
        findsOneWidget,
      );

      // Check subprompt badge and steps
      expect(find.text('2 subprompts'), findsOneWidget);
      expect(find.text('Subprompt 1:'), findsOneWidget);
      expect(find.text('Latest Step 1: Run unit tests'), findsOneWidget);
      expect(find.text('Subprompt 2:'), findsOneWidget);
      expect(find.text('Latest Step 2: Deploy staging'), findsOneWidget);

      // Ensure older turns are not in the prompt preview
      expect(find.text('Old Turn 1: Analyze codebase'), findsNothing);
      expect(find.text('Old Turn 2: Run linter'), findsNothing);
    });

    testWidgets('WorkflowSaveDialog prioritizes unsentInput over chat history', (tester) async {
      final controller = PlaygroundController();

      controller.addMessage(
        ChatMessage(
          id: 'msg-prev',
          role: ChatRole.user,
          content: 'Previous Turn Prompt',
          type: MessageType.text,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkflowSaveDialog(
              controller: controller,
              unsentInput: 'Draft Prompt: Check Kubernetes cluster',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Saving the current uncommitted prompt (1 earlier conversation turn(s) omitted).'),
        findsOneWidget,
      );
      expect(find.text('Draft Prompt: Check Kubernetes cluster'), findsOneWidget);
      expect(find.text('Previous Turn Prompt'), findsNothing);
    });

    test('Progressive discovery sanitizes meta-tools and enables catalog tools', () async {
      final catalogTools = [
        _SampleTool('tool_alpha'),
        _SampleTool('tool_beta'),
      ];

      final storage = _TestStorageDelegate();
      // Simulate stale storage with meta tools
      await storage.saveEnabledTools({'mcp_list_tools', 'mcp_call_tool'});

      final controller = PlaygroundController(
        storageDelegate: storage,
        progressiveMcpDiscovery: true,
        customLocalTools: catalogTools,
      );

      // Await initialization post-load
      await Future.delayed(const Duration(milliseconds: 50));

      // Meta-tools should have been stripped and catalog tools equipped
      expect(controller.enabledToolNames.contains('mcp_list_tools'), isFalse);
      expect(controller.enabledToolNames.contains('mcp_call_tool'), isFalse);
      expect(controller.enabledToolNames.contains('tool_alpha'), isTrue);
      expect(controller.enabledToolNames.contains('tool_beta'), isTrue);
    });
  });
}

class _TestStorageDelegate extends McpPlaygroundStorageDelegate {
  Set<String> _tools = {};

  @override
  Future<void> saveLlmConfig(LlmConfig config) async {}
  @override
  Future<LlmConfig?> loadLlmConfig() async => null;
  @override
  Future<void> saveServers(List<McpServerConfig> servers) async {}
  @override
  Future<List<McpServerConfig>> loadServers() async => [];
  @override
  Future<void> saveSetups(List<SavedPlaygroundSetup> setups) async {}
  @override
  Future<List<SavedPlaygroundSetup>> loadSetups() async => [];

  @override
  Future<Set<String>> loadEnabledTools() async => _tools;

  @override
  Future<void> saveEnabledTools(Set<String> tools) async {
    _tools = tools;
  }
}

class _SampleTool extends McpLocalTool {
  @override
  final String name;
  @override
  final String description;
  @override
  final Map<String, dynamic> inputSchema;

  _SampleTool(this.name)
      : description = 'Tool $name',
        inputSchema = const {'type': 'object'};

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async =>
      MCPToolResult(content: [MCPContent(type: 'text', text: name)]);
}

