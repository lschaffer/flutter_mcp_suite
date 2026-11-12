import 'package:flutter_test/flutter_test.dart';
import 'package:example_a2ui_model_optimizer/main.dart';

void main() {
  testWidgets('A2uiModelOptimizerApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const A2uiModelOptimizerApp());
    expect(find.text('A2UI Model Cost & Architecture Optimizer'), findsOneWidget);
  });
}
