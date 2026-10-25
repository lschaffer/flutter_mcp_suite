import 'package:flutter/material.dart';
import 'package:flutter_ui_mcp_embedded/flutter_ui_mcp_embedded.dart';
import 'package:flutter_ui_mcp_core/flutter_ui_mcp_core.dart'
    show EmbeddedLlmRegistry;
import 'package:dart_mcp_core/dart_mcp_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Register the embedded engine driver with the Flutter MCP Suite registry.
  FlutterUiMcpEmbedded.register();
  runApp(const EmbeddedLlmExampleApp());
}

/// Example application showcasing on-device embedded LLM execution with [FlutterUiMcpEmbedded].
class EmbeddedLlmExampleApp extends StatelessWidget {
  const EmbeddedLlmExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter UI MCP Embedded Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const EmbeddedLlmDemoPage(),
    );
  }
}

class EmbeddedLlmDemoPage extends StatefulWidget {
  const EmbeddedLlmDemoPage({super.key});

  @override
  State<EmbeddedLlmDemoPage> createState() => _EmbeddedLlmDemoPageState();
}

class _EmbeddedLlmDemoPageState extends State<EmbeddedLlmDemoPage> {
  final TextEditingController _modelPathController = TextEditingController(
    text: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
  );
  final TextEditingController _promptController = TextEditingController(
    text: 'What are the advantages of running on-device SLMs with MCP?',
  );

  bool _isGpuSupported = false;
  int _totalVram = 0;
  int _freeVram = 0;
  bool _isLoading = false;
  double _loadProgress = 0.0;
  String _statusMessage = 'Driver registered. Ready to initialize.';
  String _generatedOutput = '';

  @override
  void initState() {
    super.initState();
    _checkHardwareCapabilities();
  }

  @override
  void dispose() {
    _modelPathController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _checkHardwareCapabilities() async {
    final adapter = EmbeddedLlmAdapter.instance;
    final gpuSupported = await adapter.isGpuSupported();
    final vram = await adapter.getVramInfo();

    if (mounted) {
      setState(() {
        _isGpuSupported = gpuSupported;
        _totalVram = vram.total;
        _freeVram = vram.free;
      });
    }
  }

  Future<void> _loadModel() async {
    final path = _modelPathController.text.trim();
    if (path.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadProgress = 0.0;
      _statusMessage = 'Loading model: $path...';
    });

    try {
      await EmbeddedLlmAdapter.instance.initialize(
        path,
        gpuLayers: _isGpuSupported ? 99 : 0,
        contextSize: 2048,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _loadProgress = progress;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _statusMessage = 'Model loaded successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Model load failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runInference() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    if (!EmbeddedLlmAdapter.instance.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load a GGUF model first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedOutput = '';
      _statusMessage = 'Generating response...';
    });

    try {
      final messages = [
        ChatMessage(
          id: 'user-1',
          role: ChatRole.user,
          content: prompt,
          timestamp: DateTime.now(),
        ),
      ];

      final response = await EmbeddedLlmAdapter.instance.generateResponse(
        messages: messages,
        temperature: 0.7,
        maxTokens: 512,
        onStreamChunk: (chunk) {
          if (mounted) {
            setState(() {
              _generatedOutput += chunk;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _generatedOutput = response.text;
          _statusMessage = 'Inference complete.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Inference error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adapter = EmbeddedLlmAdapter.instance;
    final isRegistered = EmbeddedLlmRegistry.isAvailable;
    final isLoaded = adapter.isLoaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter UI MCP Embedded Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recheck GPU info',
            onPressed: _checkHardwareCapabilities,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver & Hardware Status Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isRegistered ? Icons.check_circle : Icons.error,
                          color: isRegistered ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRegistered
                              ? 'EmbeddedLlmDriver Registered'
                              : 'No Driver Registered',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Model Status: ${isLoaded ? "Loaded (${adapter.loadedModelPath})" : "Not Loaded"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'GPU Acceleration: ${_isGpuSupported ? "Supported" : "CPU only"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_totalVram > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'VRAM: ${(_freeVram / (1024 * 1024)).toStringAsFixed(0)} MB free / '
                        '${(_totalVram / (1024 * 1024)).toStringAsFixed(0)} MB total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Model Loading Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Model Management',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _modelPathController,
                      decoration: const InputDecoration(
                        labelText: 'Model Path or GGUF URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_open),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading && _loadProgress > 0) ...[
                      LinearProgressIndicator(value: _loadProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: ${(_loadProgress * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _loadModel,
                            icon: const Icon(Icons.download),
                            label: const Text('Load GGUF Model'),
                          ),
                        ),
                        if (isLoaded) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    await adapter.dispose();
                                    setState(() {
                                      _statusMessage = 'Model unloaded.';
                                    });
                                  },
                            icon: const Icon(Icons.eject),
                            label: const Text('Unload'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prompt & Inference Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Inference Playground',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Prompt',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _runInference,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run On-Device Inference'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status & Output Section
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Output & Status',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (_generatedOutput.isNotEmpty) ...[
                      const Divider(height: 24),
                      SelectableText(
                        _generatedOutput,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
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
