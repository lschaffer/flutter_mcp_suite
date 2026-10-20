import 'package:flutter_test/flutter_test.dart';
import 'package:example_genui_file_etl/main.dart';

void main() {
  testWidgets('GenuiFileEtlApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GenuiFileEtlApp());
    expect(find.text('GenUI File ETL & Data Transformation Studio'), findsOneWidget);
  });
}
