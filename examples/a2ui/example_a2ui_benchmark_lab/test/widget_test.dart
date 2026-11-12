import 'package:flutter_test/flutter_test.dart';
import 'package:example_a2ui_benchmark_lab/main.dart';

void main() {
  testWidgets('A2uiBenchmarkLabApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const A2uiBenchmarkLabApp());
    expect(find.text('A2UI Model & Prompt Benchmark Lab'), findsOneWidget);
  });
}
