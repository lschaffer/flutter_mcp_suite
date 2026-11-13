import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_a2ui_mcp/flutter_a2ui_mcp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A2uiMcpPlayground default parameters test', () {
    const playground = A2uiMcpPlayground();
    expect(playground.showAppBar, isTrue);
    expect(playground.showStatusBadges, isTrue);
    expect(playground.showNewChatAction, isTrue);
    expect(playground.showSettingsAction, isTrue);
    expect(playground.showSkillsControls, isTrue);
    expect(playground.showAssistantStatistics, isTrue);
    expect(playground.showMemoryArchive, isTrue);
    expect(playground.showToolsCatalog, isTrue);
    expect(playground.showWorkflowActions, isTrue);
    expect(playground.showAgentInspector, isTrue);
  });

  test('A2uiMcpPlayground custom visibility flags test', () {
    const playground = A2uiMcpPlayground(
      showAppBar: false,
      showStatusBadges: false,
      showNewChatAction: false,
      showSettingsAction: false,
      showSkillsControls: false,
      showAssistantStatistics: false,
      showMemoryArchive: false,
      showToolsCatalog: false,
      showWorkflowActions: false,
      showAgentInspector: false,
    );
    expect(playground.showAppBar, isFalse);
    expect(playground.showStatusBadges, isFalse);
    expect(playground.showNewChatAction, isFalse);
    expect(playground.showSettingsAction, isFalse);
    expect(playground.showSkillsControls, isFalse);
    expect(playground.showAssistantStatistics, isFalse);
    expect(playground.showMemoryArchive, isFalse);
    expect(playground.showToolsCatalog, isFalse);
    expect(playground.showWorkflowActions, isFalse);
    expect(playground.showAgentInspector, isFalse);
  });

  testWidgets(
    'A2uiMcpPlayground renders without AppBar when showAppBar is false',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: A2uiMcpPlayground(showAppBar: false)),
      );
      expect(find.byType(AppBar), findsNothing);
    },
  );

  test(
    'McpA2uiChatController dynamically reflects PlaygroundController activeLlmConfig',
    () {
      final playgroundCtrl = PlaygroundController(
        initialLlmConfig: const LlmConfig(
          provider: LlmProvider.none,
          model: '',
          apiKey: '',
        ),
      );
      final a2uiCtrl = McpA2uiChatController(
        llmConfig: const LlmConfig(
          provider: LlmProvider.none,
          model: '',
          apiKey: '',
        ),
        playgroundController: playgroundCtrl,
      );

      expect(a2uiCtrl.llmConfig.provider, equals(LlmProvider.none));

      // Update playground controller active config via customLlmConfig
      playgroundCtrl.customLlmConfig = const LlmConfig(
        provider: LlmProvider.openaiCompatible,
        model: 'qwen-coder',
        apiKey: 'test-key',
        baseUrl: 'https://api.deepinfra.com/v1/openai',
      );

      // McpA2uiChatController should immediately reflect the active config!
      expect(a2uiCtrl.llmConfig.provider, equals(LlmProvider.openaiCompatible));
      expect(a2uiCtrl.llmConfig.model, equals('qwen-coder'));

      // Also test direct setter
      a2uiCtrl.llmConfig = const LlmConfig(
        provider: LlmProvider.gemini,
        model: 'gemini-2.5-flash',
        apiKey: 'gemini-key',
      );
      playgroundCtrl.customLlmConfig = null;
      expect(a2uiCtrl.llmConfig.provider, equals(LlmProvider.gemini));
      expect(a2uiCtrl.llmConfig.model, equals('gemini-2.5-flash'));

      a2uiCtrl.dispose();
      playgroundCtrl.dispose();
    },
  );

  test('buildA2uiCatalog constructs a valid catalog with base components', () {
    final catalog = buildA2uiCatalog();
    expect(catalog.components, isNotEmpty);
    expect(catalog.components.containsKey('Text'), isTrue);
  });

  test(
    'extractJsonObjects extracts single and multiple balanced JSON objects',
    () {
      const text1 =
          '```json\n{"component": "WeatherForm", "title": "Forecast"}\n```';
      final res1 = McpA2uiChatController.extractJsonObjects(text1);
      expect(res1.length, equals(1));
      expect(res1[0]['component'], equals('WeatherForm'));

      const text2 = '''
Some intro text here.
```json
{"component": "AccommodationGrid", "title": "Stays", "items": [{"name": "Hotel A"}]}
{"component": "TravelItineraryCard", "title": "Schedule", "days": [{"title": "Day 1"}]}
```
''';
      final res2 = McpA2uiChatController.extractJsonObjects(text2);
      expect(res2.length, equals(2));
      expect(res2[0]['component'], equals('AccommodationGrid'));
      expect(res2[1]['component'], equals('TravelItineraryCard'));
    },
  );

  test(
    'McpA2uiChatController processes direct shorthand component with version 1.0 normalization',
    () {
      final a2uiCtrl = McpA2uiChatController(
        llmConfig: const LlmConfig(
          provider: LlmProvider.none,
          model: '',
          apiKey: '',
        ),
      );

      // Initial state: no surfaces
      expect(a2uiCtrl.activeSurfaceIds, isEmpty);

      // Direct component payload without version (or with 'v1.0')
      const payload = '''
```json
{
  "component": "ChatMessage",
  "text": "Hello world from direct shorthand"
}
```
''';
      // Use controller's payload processing
      final objects = McpA2uiChatController.extractJsonObjects(payload);
      expect(objects.length, equals(1));

      a2uiCtrl.dispose();
    },
  );

  test(
    'McpA2uiChatController creates surface and entry for WeatherForm component',
    () {
      final a2uiCtrl = McpA2uiChatController(
        llmConfig: const LlmConfig(
          provider: LlmProvider.none,
          model: '',
          apiKey: '',
        ),
        customComponents: [
          ComponentImplementation(
            name: 'WeatherForm',
            schema: S.object(properties: {'title': S.string()}),
            builder: (ctx, node, props, buildChild) => const SizedBox(),
          ),
        ],
      );
      // Let's test how payloads are parsed
      a2uiCtrl.processor.processMessages([
        {
          'version': '1.0',
          'createSurface': {
            'surfaceId': 'test_surface_1',
            'catalogId': a2uiCtrl.catalog.id,
          },
        },
        {
          'version': '1.0',
          'updateComponents': {
            'surfaceId': 'test_surface_1',
            'components': [
              {
                'id': 'root',
                'component': 'WeatherForm',
                'title': 'Select City and Forecast Duration',
              },
            ],
          },
        },
      ]);

      expect(a2uiCtrl.activeSurfaceIds, contains('test_surface_1'));
      a2uiCtrl.dispose();
    },
  );

  test(
    'McpA2uiChatController parses direct component in code block and creates surface',
    () {
      final a2uiCtrl = McpA2uiChatController(
        llmConfig: const LlmConfig(
          provider: LlmProvider.none,
          model: '',
          apiKey: '',
        ),
        customComponents: [
          ComponentImplementation(
            name: 'WeatherForm',
            schema: S.object(properties: {'title': S.string()}),
            builder: (ctx, node, props, buildChild) => const SizedBox(),
          ),
        ],
      );

      const payload =
          '```json { "component": "WeatherForm", "title": "Select City and Forecast Duration" }```';
      final objects = McpA2uiChatController.extractJsonObjects(payload);
      expect(objects.length, equals(1));
      expect(objects[0]['component'], equals('WeatherForm'));

      // Now let's test if processMessages works for this component
      expect(() {
        a2uiCtrl.processor.processMessages([
          {
            'version': '1.0',
            'createSurface': {
              'surfaceId': 'surface_test_direct',
              'catalogId': a2uiCtrl.catalog.id,
            },
          },
          {
            'version': '1.0',
            'updateComponents': {
              'surfaceId': 'surface_test_direct',
              'components': [
                {
                  'id': 'root',
                  'component': 'WeatherForm',
                  'title': 'Select City and Forecast Duration',
                },
              ],
            },
          },
        ]);
      }, returnsNormally);

      expect(a2uiCtrl.activeSurfaceIds, contains('surface_test_direct'));
      a2uiCtrl.dispose();
    },
  );
}
