import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_mcp_playground_example/main.dart';

void main() {
  testWidgets('GenUI app smoke test', (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = [
      const Locale('de', 'AT'),
      const Locale('de', 'DE'),
    ];
    await tester.pumpWidget(const GenuiShowcaseApp());
    await tester.pumpAndSettle();
    expect(find.byType(GenuiShowcaseApp), findsOneWidget);
  });
}
