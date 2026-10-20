import 'package:flutter_test/flutter_test.dart';
import 'package:example_genui_benchmark_lab/main.dart';

void main() {
  testWidgets('GenuiBenchmarkLabApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GenuiBenchmarkLabApp());
    expect(find.text('GenUI Model & Prompt Benchmark Lab'), findsOneWidget);
  });
}
