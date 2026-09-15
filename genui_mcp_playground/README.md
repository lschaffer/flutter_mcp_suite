# genui_mcp_playground

An interactive, dynamic **GenUI & Agentic MCP Playground** for Flutter.

`genui_mcp_playground` brings together Google's **GenUI** (`A2UI`) generative UI protocol, the **Model Context Protocol (MCP)**, and native Dart tools. It enables LLMs to emit structured UI components and render rich, interactive Flutter widgets directly in the conversation flow, while retaining full agentic tool-calling capabilities and live state inspection.

---

## ✨ Features

- **Dynamic GenUI Surface Rendering** – Render model-generated interactive forms, charts, tables, and custom widgets directly inline in the chat transcript.
- **Pluggable GenUI Catalog** – Define custom components using JSON schemas (`GenuiCatalogItemDefinition`) or Dart builders with `Catalog` and `BasicCatalogItems`.
- **Multi-LLM Support** – OpenAI, Anthropic Claude, Google Gemini, Ollama (local), Mistral AI, and custom OpenAI-compatible endpoints.
- **Embedded On-Device LLMs** – Run GGUF models locally with `llamadart` without network dependencies.
- **MCP & Local Tool Calling** – Connect remote HTTP/SSE MCP servers, local subprocess servers, and Dart-native tools.
- **Interactive Agent Inspector** – Side-by-side live inspection of system prompts, tool calls, JSON payloads, and execution traces.
- **Cross-Platform** – Android, iOS, macOS, Windows, Linux, and Web.

---

> [!TIP]
> **Recommended LLMs**: Rendering dynamic GenUI surfaces requires strict structured JSON output compliant with the GenUI (`A2UI`) protocol. A **medium-to-large sized model** (e.g., Gemini 3.6 Flash / Pro, GPT-4o / latest OpenAI models, Mistral Medium / Large, Llama 3.3 70B+, Gemma 27B, Claude 3.5 / 3.7 Sonnet) is recommended for reliable generative UI generation. Small embedded/on-device SLMs (e.g. 1B–3B parameter models) might not be adequate for complex GenUI catalog schemas.
> 
> If your primary use case requires small embedded or offline on-device models (e.g. GGUF via `llamadart`), consider using the lighter standard variant [`mcp_playground_flutter`](https://pub.dev/packages/mcp_playground_flutter).

---

## 🎥 Demo

Watch the dynamic GenUI Playground in action rendering interactive surfaces:

### 🏖️ GenUI Travel & Stay Planner
![GenUI MCP Travel Demo](https://raw.githubusercontent.com/lschaffer/mcp_playground/main/screenshots/video/genui_mcp_travel_example.gif)

### ⛅ GenUI Weather Generator
![GenUI MCP Weather Demo](https://raw.githubusercontent.com/lschaffer/mcp_playground/main/screenshots/video/genui_weather_example.gif)

### 📈 GenUI Finance & Budget Planner
![GenUI MCP Finance Demo](https://raw.githubusercontent.com/lschaffer/mcp_playground/main/screenshots/video/genui_finance_example.gif)

---

## 🚀 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  genui_mcp_playground: ^0.3.1
  genui: ^0.10.2
```

Then import:

```dart
import 'package:genui_mcp_playground/genui_mcp_playground.dart';
```

---

## 📦 Widget API

### `GenuiMcpPlayground`

The primary widget providing a full-featured generative UI and agent playground.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `initialLlmConfig` | `LlmConfig?` | `null` | Default LLM provider, model, API key, and settings. |
| `initialServers` | `List<McpServerConfig>?` | `null` | Pre-configured list of HTTP MCP servers to connect to on startup. |
| `customLocalTools` | `List<McpLocalTool>?` | `null` | Custom Dart-native tool implementations. |
| `genuiCatalog` | `Catalog?` | `null` | Custom GenUI `Catalog` instance. |
| `genuiCatalogItems` | `List<GenuiCatalogItemDefinition>?` | `null` | List of JSON schema item definitions to build the catalog dynamically. |
| `genuiCatalogJson` | `String?` | `null` | Raw JSON string containing schema catalog definitions. |
| `clientFunctions` | `List<ClientFunction>?` | `null` | List of GenUI client-side functions (`ClientFunction` / `SynchronousClientFunction`) registered in the catalog. |
| `initialSystemPrompt` | `String?` | `null` | Optional initial system prompt. |
| `initialEnabledTools` | `List<String>?` | `null` | Tool names pre-selected on startup. |
| `showAgentInspector` | `bool` | `true` | Show/hide the side-by-side Agent Inspector panel. |
| `disableConfigDialog` | `bool` | `false` | Disable opening the settings dialog when LLM is not configured. |
| `storageDelegate` | `McpPlaygroundStorageDelegate?` | `null` | Custom persistence layer (defaults to `SharedPreferences`). |

---

## 💡 Usage Examples

### 1. Basic Setup with Weather Forecast Catalog

```dart
import 'package:flutter/material.dart';
import 'package:genui_mcp_playground/genui_mcp_playground.dart';

class MyGenuiApp extends StatelessWidget {
  const MyGenuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenuiMcpPlayground(
        initialLlmConfig: const LlmConfig(
          provider: LlmProvider.openai,
          model: 'gpt-4o',
          apiKey: 'sk-...',
        ),
        customLocalTools: [WeatherForecastTool()],
        initialEnabledTools: const ['get_weather_forecast'],
        genuiCatalog: myWeatherCatalog,
        showAgentInspector: true,
      ),
    );
  }
}
```

### 2. Standalone Chat & Surface View (`GenuiChatView`)

If you want to embed only the transcript and dynamic GenUI surfaces inside your own custom layout:

```dart
final controller = McpGenuiChatController(
  llmConfig: myLlmConfig,
  tools: myLocalTools,
  catalog: myCatalog,
);

// In your build method:
GenuiChatView(
  controller: controller,
  scrollController: myScrollController,
)
```

---

## 📂 Example Projects

Explore the runnable showcases in this repository:
- **[`genui_mcp_playground/example`](example)** – Primary showcase: **Travel & Accommodation Planner** with SerpAPI Google search, date pickers, stay grids (hotels, apartments, camping), day-by-day itineraries, and JPG export.
- **[`examples/genui/example_genui_weather`](../examples/genui/example_genui_weather)** – Dynamic weather generator with interactive form selectors, `fl_chart` visualizations, and JPG export.
- **[`examples/genui/example_genui_filesystem`](../examples/genui/example_genui_filesystem)** – Interactive filesystem explorer with folder tree navigation and file viewer surfaces.
