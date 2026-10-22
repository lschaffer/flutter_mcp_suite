# flutter_ui_mcp_embedded

Pluggable on-device embedded LLM engine for the **Flutter MCP Suite** (`flutter_ui_mcp_core` and `flutter_ui_mcp`) powered by `llamadart` (`llama.cpp` on native platforms and WebGPU / WASM on the web).

By isolating `llamadart` into this dedicated companion package, developers who only need cloud LLMs (OpenAI, Anthropic Claude, Gemini) or external local servers (Ollama, LM Studio) can keep their core Flutter apps lightweight without native C++ compilation tools or heavy binary footprints.

---

## 🚀 Quick Start

### 1. Add Dependencies

In your application's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_ui_mcp: ^1.4.0
  flutter_ui_mcp_embedded: ^1.4.0
```

### 2. Register the Driver

In your `main.dart`, register the embedded driver before launching your app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
import 'package:flutter_ui_mcp_embedded/flutter_ui_mcp_embedded.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register llamadart / llama.cpp engine with Flutter MCP Suite
  FlutterUiMcpEmbedded.register();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: McpPlayground(),
    );
  }
}
```

---

## 💡 Capabilities

- **Offline GGUF Execution**: Run quantized `.gguf` models directly on CPU / GPU.
- **Cross-Platform**: Supports Android (NDK), iOS (Metal), macOS (Metal), Windows, Linux, and Web (WebGPU).
- **Streaming & Native MCP Tools**: Fully compatible with streaming token responses and tool-calling execution loops.
