# flutter_ui_mcp

An interactive AI Agent chat and execution widget for Flutter — connect to any LLM provider, register **local Dart-native tools** and **remote HTTP MCP servers**, and run agentic workflows in a conversational UI.

> [!TIP]
> A full working multiplatform app **Tealkit** based on the features of this suite is available in Play Store, App Store, and Windows Store. See [github.com/lschaffer/tealkit](https://github.com/lschaffer/tealkit).

---

## ✨ Features

- **Multi-LLM support** – OpenAI, Anthropic Claude, Google Gemini, Ollama (local), Mistral AI, and any OpenAI-compatible endpoint.
- **Embedded on-device models** – Run local GGUF models via `llamadart` without external network dependencies.
- **HTTP MCP Server registry** – Browse [PulseMCP](https://pulsemcp.com) and [Smithery](https://smithery.ai) catalogs or add custom remote MCP servers.
- **Local MCP subprocesses** – Install, configure, and launch local stdio MCP servers (Node.js, Python) directly within the application (supported in desktop mode).
- **Dart-native local tools** – Extend with custom Dart-native tools (e.g., Weather, SSH, Chart-generation tools; see the [example](example) implementation).
- **Agentic tool loop** – Automatic iterative tool calling with duplicate-call detection, iteration limits, and safety guards.
- **Save/Load configurations** – Persist LLM settings, tool selections, system prompts, and server lists via `SharedPreferences` or a custom `McpPlaygroundStorageDelegate`.
- **Agent Inspector** – Side-by-side conversation + internal state inspector for debugging agent behavior (can be toggled or disabled via `showAgentInspector`).
- **Cross-platform** – Works on Android, iOS, Web, macOS, Windows, and Linux.

> [!NOTE]
> For dynamic generative UI rendering via Google's GenUI (`A2UI`) protocol, see the dedicated [`flutter_genui_mcp`](https://pub.dev/packages/flutter_genui_mcp) package.

---

## 🎥 Demo

Watch the AI Agent widget in action using an embedded model to call local dart tools:

![Flutter UI MCP Demo](https://raw.githubusercontent.com/lschaffer/flutter_mcp_suite/main/screenshots/video/mcp_playground_embedded_test.gif)

---

## 🚀 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_ui_mcp: ^1.0.2
```

Then import:

```dart
import 'package:flutter_ui_mcp/flutter_ui_mcp.dart';
```

---

## 📦 Widget API

### [`FlutterUiMcp`](lib/flutter_ui_mcp_widget.dart) (or `McpPlayground`)

The main widget. Drop it into your app to get a full AI agent interface.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `initialLlmConfig` | `LlmConfig?` | `null` | Default LLM provider, model, API key, and hyperparameters. Falls back to persisted settings. |
| `initialServers` | `List<McpServerConfig>?` | `null` | Pre-configured list of HTTP MCP servers to connect to on startup. |
| `initialLocalMcpServers` | `List<LocalMcpServerSetup>?` | `null` | Pre-configured list of local Node.js or Python MCP servers to auto-initialize/install. |
| `storageDelegate` | `McpPlaygroundStorageDelegate?` | `null` | Custom persistence layer for settings. Uses `SharedPreferences` if omitted. |
| `customLocalTools` | `List<McpLocalTool>?` | `null` | Custom Dart-native tool implementations. |
| `showAgentInspector` | `bool` | `true` | Show/hide the Agent Inspector panel and toolbar toggle button. |
| `disableConfigDialog` | `bool` | `false` | Disable opening the settings dialog when LLM is not configured. |
| `messageContentBuilder` | `Widget? Function(BuildContext, ChatMessage)?` | `null` | Optional builder callback to intercept message layouts and render custom widgets (e.g., interactive charts). |
| `locale` | `String?` | `null` | Optional explicit locale override ('en' or 'de'). Defaults to system language. |

#### Basic usage

```dart
FlutterUiMcp()
```

#### With Pre-configured LLM

```dart
FlutterUiMcp(
  initialLlmConfig: const LlmConfig(
    provider: LlmProvider.openai,
    model: 'gpt-4o',
    apiKey: 'sk-...',
  ),
)
```

---

## 📂 Example Projects

Explore the runnable showcases in this repository:
- **[`flutter_ui_mcp/example`](example)** – Complete showcase app demonstrating custom SSH, Open-Meteo weather, and `fl_chart` tool integrations.
- **[`examples/flutter/example_device_diagnostics`](../examples/flutter/example_device_diagnostics)** – Telemetry monitor with custom chat cards for battery, memory, CPU load, and latency.
- **[`examples/flutter/example_audio_notes`](../examples/flutter/example_audio_notes)** – Meeting notes processor with action item checklist cards.
- **[`examples/flutter/example_github_triage`](../examples/flutter/example_github_triage)** – GitHub issue triage assistant with inline PR code reviews.
- **[`examples/flutter/example_embedded`](../examples/flutter/example_embedded)** – Local on-device embedded LLM (`llamadart`) with zero external network dependencies.
