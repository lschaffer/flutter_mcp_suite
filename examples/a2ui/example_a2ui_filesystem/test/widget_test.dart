import 'package:flutter_test/flutter_test.dart';
import 'package:example_a2ui_filesystem/main.dart';

void main() {
  testWidgets('A2uiFilesystemExampleApp builds cleanly', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const A2uiFilesystemExampleApp());
      await Future.delayed(const Duration(milliseconds: 300));
    });
    expect(find.byType(A2uiFilesystemScreen), findsOneWidget);
  });
}
