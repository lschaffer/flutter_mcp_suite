import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_playground_flutter_example/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Playground widget smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(const McpPlaygroundExampleApp());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    // Verify that the playground widget compiles and builds.
    expect(find.byType(McpPlaygroundExampleApp), findsOneWidget);
  });
}
