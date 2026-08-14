import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_playground_flutter_example_genui_filesystem/main.dart';

void main() {
  testWidgets('GenuiFilesystemExampleApp builds cleanly', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const GenuiFilesystemExampleApp());
      await Future.delayed(const Duration(milliseconds: 300));
    });
    expect(find.byType(GenuiFilesystemScreen), findsOneWidget);
  });
}
