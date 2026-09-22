import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart';
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() {
  runApp(const ExampleCoreApp());
}

/// Standalone showcase for the `flutter_ui_mcp_core` shared components.
class ExampleCoreApp extends StatelessWidget {
  const ExampleCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter UI MCP Core Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CoreShowcasePage(),
    );
  }
}

class CoreShowcasePage extends StatefulWidget {
  const CoreShowcasePage({super.key});

  @override
  State<CoreShowcasePage> createState() => _CoreShowcasePageState();
}

class _CoreShowcasePageState extends State<CoreShowcasePage> {
  LlmProvider _selectedProvider = LlmProvider.openai;
  final TextEditingController _modelCtrl = TextEditingController(text: 'gpt-4o');
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _baseUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter UI MCP Core Components'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LlmConfigForm Component',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    LlmConfigForm(
                      provider: _selectedProvider,
                      onProviderChanged: (newProvider) {
                        setState(() => _selectedProvider = newProvider);
                      },
                      modelCtrl: _modelCtrl,
                      apiKeyCtrl: _apiKeyCtrl,
                      baseUrlCtrl: _baseUrlCtrl,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
