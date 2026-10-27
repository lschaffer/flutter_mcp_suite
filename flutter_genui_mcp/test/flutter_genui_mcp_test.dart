import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FlutterGenUiMcp default parameters test', () {
    const playground = FlutterGenUiMcp();
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

  test('FlutterGenUiMcp custom visibility flags test', () {
    const playground = FlutterGenUiMcp(
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

  testWidgets('FlutterGenUiMcp renders without AppBar when showAppBar is false',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlutterGenUiMcp(
          showAppBar: false,
        ),
      ),
    );
    expect(find.byType(AppBar), findsNothing);
  });

  test('McpGenuiChatController dynamically reflects PlaygroundController activeLlmConfig', () {
    final playgroundCtrl = PlaygroundController(
      initialLlmConfig: const LlmConfig(provider: LlmProvider.none, model: '', apiKey: ''),
    );
    final genuiCtrl = McpGenuiChatController(
      llmConfig: const LlmConfig(provider: LlmProvider.none, model: '', apiKey: ''),
      playgroundController: playgroundCtrl,
    );

    expect(genuiCtrl.llmConfig.provider, equals(LlmProvider.none));

    // Update playground controller active config via customLlmConfig
    playgroundCtrl.customLlmConfig = const LlmConfig(
      provider: LlmProvider.openaiCompatible,
      model: 'qwen-coder',
      apiKey: 'test-key',
      baseUrl: 'https://api.deepinfra.com/v1/openai',
    );

    // McpGenuiChatController should immediately reflect the active config!
    expect(genuiCtrl.llmConfig.provider, equals(LlmProvider.openaiCompatible));
    expect(genuiCtrl.llmConfig.model, equals('qwen-coder'));

    // Also test direct setter
    genuiCtrl.llmConfig = const LlmConfig(
      provider: LlmProvider.gemini,
      model: 'gemini-2.5-flash',
      apiKey: 'gemini-key',
    );
    playgroundCtrl.customLlmConfig = null;
    expect(genuiCtrl.llmConfig.provider, equals(LlmProvider.gemini));
    expect(genuiCtrl.llmConfig.model, equals('gemini-2.5-flash'));

    genuiCtrl.dispose();
    playgroundCtrl.dispose();
  });
}

