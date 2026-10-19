import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'env_loader.dart';
import 'tools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const MultimodalVisionExampleApp());
}

class MultimodalVisionExampleApp extends StatelessWidget {
  const MultimodalVisionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multimodal Vision & Media Inspector',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEC4899), // Pink
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 150, 52, 101),
          brightness: Brightness.dark,
        ),
      ),
      home: const MultimodalVisionScreen(),
    );
  }
}

class MultimodalVisionScreen extends StatefulWidget {
  const MultimodalVisionScreen({super.key});

  @override
  State<MultimodalVisionScreen> createState() => _MultimodalVisionScreenState();
}

class _MultimodalVisionScreenState extends State<MultimodalVisionScreen> {
  late final PlaygroundController _controller;

  // Valid 64x64 blue PNG icon encoded as base64
  static const String _samplePngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA'
      'B3RJTUUH6AoTEhkY7hC9jAAAAChJREFUeNrtwTEBAAAAwqD1T20ND6AAAAAAAAAAAAAAAAAAAAAA'
      '4M0AB9AAATa7UjUAAAAASUVORK5CYII=';

  static const String _systemPrompt = '''
You are a Staff QA & Mobile Accessibility Specialist.
You have the ability to inspect multimodal inputs (UI screenshots, specification documents, and audio notes).
When analyzing UI bug screenshots:
- Inspect visual alignment, contrast ratios, and tap target sizing.
- Use the `analyze_ui_wireframe` tool to formalize the defect report with severity and exact widget fixes.
- When reviewing attached markdown specifications or audio transcripts, ensure they align with the visual design.
''';

  @override
  void initState() {
    super.initState();
    _controller = PlaygroundController(
      initialLlmConfig: EnvLoader.getInitialLlmConfig(),
      customLocalTools: [AnalyzeUiWireframeTool()],
    );
    _controller.systemPrompt = _systemPrompt;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _stageScreenshot() async {
    try {
      final byteData = await rootBundle.load('assets/sample_checkout_ui.jpg');
      final bytes = byteData.buffer.asUint8List();
      _controller.addPendingPart(
        ImagePart.fromBytes(bytes, mimeType: 'image/jpeg'),
      );
    } catch (_) {
      _controller.addPendingPart(
        ImagePart.fromBase64(_samplePngBase64, mimeType: 'image/png'),
      );
    }
  }

  Future<void> _copySampleImageToClipboard() async {
    try {
      final byteData = await rootBundle.load('assets/sample_checkout_ui.jpg');
      final bytes = byteData.buffer.asUint8List();
      if (!kIsWeb && Platform.isWindows) {
        final tempFile = File('${Directory.systemTemp.path}/sample_checkout_ui.jpg');
        await tempFile.writeAsBytes(bytes);
        final script = '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
\$img = [System.Drawing.Image]::FromFile('${tempFile.path.replaceAll(r'\', r'\\')}')
[System.Windows.Forms.Clipboard]::SetImage(\$img)
''';
        final utf16le = <int>[];
        for (final b in script.codeUnits) {
          utf16le.add(b & 0xFF);
          utf16le.add((b >> 8) & 0xFF);
        }
        await Process.run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-EncodedCommand',
          base64.encode(utf16le),
        ]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sample image copied to Windows Clipboard! Press Ctrl+V in the prompt to paste it.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Error copying sample to clipboard: $e');
    }
  }

  void _stageDocument() {
    _controller.addPendingPart(
      const DocumentPart(
        fileName: 'checkout_spec_v2.md',
        mimeType: 'text/markdown',
        textContent: '''# Checkout Screen Specification (v2.4)
- Currency selector: Row with CountryFlag and PriceText
- Action button: Full-width elevated button with minimum 48dp height
- Constraints: Must not overflow on iPhone SE or compact Android screens
''',
      ),
    );
  }

  void _stageAudioNote() {
    _controller.addPendingPart(
      const AudioPart(
        base64: 'UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=',
        mimeType: 'audio/wav',
      ),
    );
  }

  void _sendPromptWithStagedParts(String text) {
    _controller.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.photo_library_outlined, size: 22),
            SizedBox(width: 8),
            Text(
              'Multimodal Media Studio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final count = _controller.pendingParts.length;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: _controller.clearPendingParts,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text('Clear Staged ($count)'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Stage Sample Media:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _stageScreenshot,
                    icon: const Icon(Icons.image_outlined, size: 14),
                    label: const Text(
                      '+ UI Screenshot',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _copySampleImageToClipboard,
                    icon: const Icon(Icons.copy_all_outlined, size: 14),
                    label: const Text(
                      'Copy Image for Ctrl+V',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _stageDocument,
                    icon: const Icon(Icons.description_outlined, size: 14),
                    label: const Text(
                      '+ Spec Doc',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _stageAudioNote,
                    icon: const Icon(Icons.mic_outlined, size: 14),
                    label: const Text(
                      '+ Voice Memo',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: () => _sendPromptWithStagedParts(
                      'Please analyze the staged screenshot and specification document. '
                      'Check for RenderFlex overflow issues and execute analyze_ui_wireframe.',
                    ),
                    child: const Text(
                      'Analyze All Staged',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: McpPlayground(
        controller: _controller,
        showAgentInspector: true,
        initialEnabledTools: const ['analyze_ui_wireframe'],
      ),
    );
  }
}
