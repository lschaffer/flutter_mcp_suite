# flutter_genui_mcp

An interactive, dynamic **GenUI & Agentic MCP Widget** for Flutter.

`flutter_genui_mcp` brings together Google's **GenUI** (`A2UI`) generative UI protocol, the **Model Context Protocol (MCP)**, and native Dart tools. It enables LLMs to emit structured UI components and render rich, interactive Flutter widgets directly in the conversation flow, while retaining full agentic tool-calling capabilities and live state inspection.

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
> **Recommended LLMs**: Rendering dynamic GenUI surfaces requires strict structured JSON output compliant with the GenUI (`A2UI`) protocol. A **medium-to-large sized model** (e.g., Gemini 2.5 Flash / Pro, GPT-4o, Mistral Medium / Large, Llama 3.3 70B+, Claude 3.5 / 3.7 Sonnet) is recommended for complex generative UI schemas.
> 
> If your primary use case requires small embedded or offline on-device models (e.g. GGUF via `llamadart`) with standard chat and markdown rendering, consider using [`flutter_ui_mcp`](https://pub.dev/packages/flutter_ui_mcp).

---

## 🧠 Model Size & Compatibility Matrix

Different examples and workflows require different LLM reasoning and structured JSON output capabilities:

| Example Showcase | Min. Model Size | Recommended Models | GenUI / A2UI Compatibility | Notes |
|:---|:---|:---|:---:|:---|
| **[Travel & Stay Planner](example)** | **14B+** | Mistral Medium/Large, Gemini 2.5 Flash/Pro, GPT-4o, Claude 3.7 Sonnet, Qwen 2.5 32B | 🟢 Full Support | Multi-step tool calls + date pickers + SerpAPI parsing + rich itinerary cards. |
| **[Custom PC Rig Builder & Store](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_pc_builder)** | **14B+** | Mistral Small/Medium, GPT-4o, Gemini 2.5 Flash, Qwen 2.5 14B/32B | 🟢 Full Support | Platform socket compatibility (AM5 vs LGA1700), dynamic product catalog grids, and order invoicing. |
| **[Dynamic Weather Generator](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_weather)** | **7B – 8B** | Ministral 8B, Qwen 2.5 7B, Mistral 7B, Llama 3.1 8B | 🟢 Full Support | Single/dual tool calls with Open-Meteo and chart component emission. |
| **[Finance & Budget Planner](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_finance)** | **7B – 8B** | Qwen 2.5 7B, Mistral NeMo 12B, GPT-4o-mini, Gemini 2.5 Flash | 🟢 Full Support | Budget calculations, interactive savings sliders, and compound interest curve charts. |
| **[Smart Home Studio](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_smarthome)** | **7B – 8B** | Ministral 8B, Qwen 2.5 7B, Mistral 7B, Gemma 2 9B | 🟢 Full Support | Interactive climate sliders, toggle switches, and energy bar charts. |
| **[Data Visualizer Studio](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_data_studio)** | **14B+** | Mistral Small/Medium, Qwen 2.5 14B/32B, Gemini 2.5 Flash, GPT-4o | 🟢 Full Support | Tabular schema synthesis, KPI metric grids, and dynamic trend charts. |
| **[Filesystem Explorer](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_filesystem)** | **7B – 8B** | Qwen 2.5 7B, Ministral 8B, Llama 3.1 8B | 🟢 Full Support | Directory tree navigation and file preview cards. |
| **Small Models (2B – 3B)** *(Gemma 2 2B, Ministral 3B, Qwen 2.5 3B)* | *2B – 3B* | Local GGUF via llamadart or Ollama | 🟡 Basic / Limited | Can handle simple tools and direct chat, but may struggle with strict GenUI JSON schema generation. Use standard [`flutter_ui_mcp`](https://pub.dev/packages/flutter_ui_mcp) for best small model experience. |

---

## 🎥 Demo

Watch dynamic GenUI in action rendering interactive surfaces:

### 🏖️ GenUI Travel & Stay Planner
![GenUI MCP Travel Demo](https://raw.githubusercontent.com/lschaffer/flutter_mcp_suite/main/screenshots/video/genui_mcp_travel_example.gif)

### ⛅ GenUI Weather Generator
![GenUI MCP Weather Demo](https://raw.githubusercontent.com/lschaffer/flutter_mcp_suite/main/screenshots/video/genui_weather_example.gif)

### 📈 GenUI Finance & Budget Planner
![GenUI MCP Finance Demo](https://raw.githubusercontent.com/lschaffer/flutter_mcp_suite/main/screenshots/video/genui_finance_example.gif)

---

## 🚀 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_genui_mcp: ^1.0.2
  genui: ^0.10.3
```

Then import:

```dart
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
```

---

## 📦 Widget API

### `FlutterGenUiMcp` (or `GenuiMcpPlayground`)

The primary widget providing a full-featured generative UI and agent interface.

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
import 'package:material_ui/material_ui.dart';
import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';

class MyGenuiApp extends StatelessWidget {
  const MyGenuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterGenUiMcp(
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
- **[`flutter_genui_mcp/example`](example)** – Primary showcase: **Travel & Accommodation Planner** with SerpAPI Google search, date pickers, stay grids (hotels, apartments, camping), day-by-day itineraries, and JPG export.
- **[`examples/genui/example_genui_weather`](../examples/genui/example_genui_weather)** – Dynamic weather generator with interactive form selectors, `fl_chart` visualizations, and JPG export.
- **[`examples/genui/example_genui_filesystem`](../examples/genui/example_genui_filesystem)** – Interactive filesystem explorer with folder tree navigation and file viewer surfaces.
