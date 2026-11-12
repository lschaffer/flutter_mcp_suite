import 'package:flutter_test/flutter_test.dart';
import 'package:example_a2ui_agent_swarm/main.dart';

void main() {
  testWidgets('A2uiAgentSwarmApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const A2uiAgentSwarmApp());
    expect(find.text('A2UI Autonomous Multi-Agent Mission Control'), findsOneWidget);
  });
}
