import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';

void main() {
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
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
  });
}

