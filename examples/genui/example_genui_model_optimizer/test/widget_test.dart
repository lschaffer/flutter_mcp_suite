import 'package:flutter_test/flutter_test.dart';
import 'package:example_genui_model_optimizer/main.dart';

void main() {
  testWidgets('GenuiModelOptimizerApp builds successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GenuiModelOptimizerApp());
    expect(find.text('GenUI Model Cost & Architecture Optimizer'), findsOneWidget);
  });
}
