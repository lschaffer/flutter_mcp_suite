import 'package:flutter_test/flutter_test.dart';
import 'package:a2ui_mcp_playground_example/main.dart';

void main() {
  testWidgets('A2uiExampleApp renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const A2uiExampleApp());
    expect(find.byType(A2uiExampleApp), findsOneWidget);
  });
}
