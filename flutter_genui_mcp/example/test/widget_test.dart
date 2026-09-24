import 'package:flutter_test/flutter_test.dart';
import 'package:genui_mcp_playground_example/main.dart';

void main() {
  testWidgets('GenUI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GenuiTravelExampleApp());
    expect(find.byType(GenuiTravelExampleApp), findsOneWidget);
  });
}
