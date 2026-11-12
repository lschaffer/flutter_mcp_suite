import 'package:flutter_test/flutter_test.dart';
import 'package:example_a2ui_file_etl/main.dart';

void main() {
  testWidgets('A2uiFileEtlApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const A2uiFileEtlApp());
    expect(find.text('A2UI File ETL & Data Transformation Studio'), findsOneWidget);
  });
}
