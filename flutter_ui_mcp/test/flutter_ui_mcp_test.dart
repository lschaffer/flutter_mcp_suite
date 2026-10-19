import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';

void main() {
  test('LlmConfig default values test', () {
    const config = LlmConfig(
      provider: LlmProvider.none,
      model: '',
      apiKey: '',
    );
    expect(config.temperature, equals(0.2));
    expect(config.thinking, isFalse);
    expect(config.isConfigured, isFalse);
  });

  test('McpServerConfig json serialization test', () {
    const config = McpServerConfig(
      id: 'test-id',
      name: 'Test Server',
      url: 'https://test.mcp.io',
      isOnline: true,
      description: 'A test server description',
    );

    final json = config.toJson();
    expect(json['id'], equals('test-id'));
    expect(json['name'], equals('Test Server'));
    expect(json['url'], equals('https://test.mcp.io'));
    expect(json['isOnline'], isTrue);
    expect(json['description'], equals('A test server description'));

    final deserialized = McpServerConfig.fromJson(json);
    expect(deserialized.id, equals('test-id'));
    expect(deserialized.name, equals('Test Server'));
    expect(deserialized.url, equals('https://test.mcp.io'));
    expect(deserialized.isOnline, isTrue);
    expect(deserialized.description, equals('A test server description'));
  });

  test('McpPlayground default visibility parameters test', () {
    const playground = McpPlayground();
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

  test('McpPlayground custom visibility parameters test', () {
    const playground = McpPlayground(
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

  testWidgets('McpPlayground renders without AppBar when showAppBar is false',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: McpPlayground(
          showAppBar: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
  });
}
