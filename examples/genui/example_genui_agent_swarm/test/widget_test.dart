import 'package:flutter_test/flutter_test.dart';
import 'package:example_genui_agent_swarm/main.dart';

void main() {
  testWidgets('GenuiAgentSwarmApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GenuiAgentSwarmApp());
    expect(find.text('GenUI Autonomous Multi-Agent Mission Control'), findsOneWidget);
  });
}
