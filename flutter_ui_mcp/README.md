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

## 🧠 Model Size & Embedded Compatibility Matrix

[`flutter_ui_mcp`](https://pub.dev/packages/flutter_ui_mcp) supports the full spectrum of models, from compact on-device embedded SLMs to state-of-the-art frontier cloud models:

| Model Tier | Representative Models | Tool Calling Support | Recommended Use Cases |
|:---|:---|:---:|:---|
| **Ultra-Light SLM (2B – 3.8B)** | **Gemma 2 2B**, **Ministral 3B**, **Qwen 2.5 3B / 3.8B**, **Llama 3.2 3B** | 🟢 Native Tools & Simple APIs | On-device mobile/desktop (`llamadart` GGUF), offline devices, embedded telemetry diagnostics, meeting note summaries, and single-turn tool calling. |
| **Mid-Size SLM (7B – 9B)** | **Qwen 2.5 7B**, **Ministral 8B**, **Mistral 7B**, **Llama 3.1 8B**, **Gemma 2 9B** | 🟢 Excellent Tool Accuracy | Multi-step agent loops, structured JSON responses, GitHub issue triage, code review drafts, and multiple toolsets. |
| **Workhorse Models (12B – 24B)** | **Mistral NeMo 12B**, **Qwen 2.5 14B**, **Mistral Small 24B** | 🟢 Robust & Resilient | Complex agentic chaining, deep technical reviews, SQL schema inspection, and multi-turn workflows. |
| **Frontier Cloud / Big Models (32B – 70B+)** | **Gemini 2.5 Flash / Pro**, **GPT-4o**, **Claude 3.7 Sonnet**, **Qwen 2.5 32B / 72B**, **Llama 3.3 70B** | 🟢 Production Grade | Complex enterprise workflows, large context windows, multi-file inspection, and unrestricted tool iteration loops. |

### Compatibility across Suite Examples

| Example Application | Target Platform | Min. Recommended Model | Best Experience |
|:---|:---|:---|:---|
| **[Embedded LLM Showcase](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/flutter/example_embedded)** | Desktop / Mobile | **Qwen 2.5 3B** / **Ministral 3B** (GGUF) | Qwen 2.5 3B / 7B (Offline) |
| **[Device Diagnostics Copilot](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/flutter/example_device_diagnostics)** | Desktop / Mobile | **Gemma 2 2B** / **Qwen 2.5 3B** | Qwen 2.5 7B / Mistral 7B |
| **[Audio & Meeting Notes Assistant](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/flutter/example_audio_notes)** | Cross-platform | **Ministral 3B** / **Qwen 2.5 3B** | Ministral 8B / GPT-4o-mini |
| **[GitHub Issue Triage & PR Review](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/flutter/example_github_triage)** | Cross-platform | **Qwen 2.5 7B** / **Mistral 7B** | Mistral Small 24B / Claude 3.5 Sonnet |
| **[Primary Multi-Tool Showcase](example)** | Cross-platform | **Qwen 2.5 7B** / **Mistral 7B** | Gemini 2.5 Flash / GPT-4o |

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
