# flutter_ui_mcp_core

Shared UI components, dialogs, drawers, controllers, and services for **Flutter MCP Suite** packages: [`flutter_ui_mcp`](https://pub.dev/packages/flutter_ui_mcp) and [`flutter_genui_mcp`](https://pub.dev/packages/flutter_genui_mcp).

---

## ✨ Features

- **OS-Native Local AI (`LocalAiAdapter`)** – Bridges on-device system models (Google Gemini Nano via Android AICore on Samsung Galaxy S25 / Pixel 8+, Apple FoundationModels on iOS 18.1+, Windows AI Foundry, Chrome Prompt API) with zero cloud latency and zero external keys.
- **Multimodal Image Optimization (`ImageOptimizer`)** – Automatically scales large camera photos down to optimal dimensions (max 768px) with native hardware decoders to prevent mobile NPU memory bottlenecks and out-of-memory errors.
- **`PlaygroundController`** – Full lifecycle and state manager for agent conversations, tool execution, MCP server synchronization, and inspector tracing.
- **Workflow Automation & Execution** – Define, save, load, and run multi-step agent workflows (`WorkflowDef`, `WorkflowSaveDialog`, `WorkflowLoadDialog`, `WorkflowStep`, sub-prompt pipelines).
- **Skills System & Skill Wizard** – Comprehensive skill authoring and discovery (`SkillsManagerDialog`, `SkillWizardDialog`, `SkillDetailsDialog`, `ActiveSkillBanner`, `SkillStorageAdapter`, ZIP import/export).
- **LLM Configuration & Settings** – `LlmConfigForm`, `SettingsDrawer`, `SubPromptListEditor`.
- **MCP Server & Tool Management** – `McpServerRegistryTab`, `EditMcpDialog`, `RemoteMcpDialog`, `RegisteredToolsDialog`, `ServerToolsDialog`.
- **On-Device Embedded LLMs** – `EmbeddedModelManager`, `EmbeddedModelPickerWidget`, `HfDiscoverDialog`, `AddGgufDialog`.
- **Inspector Panel** – `AgentInspector` side pane for real-time observability of tool executions, raw JSON payloads, and system prompts.
- **Localization** – Full English & German strings via `McpLocalizations`.

---

## 🎥 Demo

Watch shared components in action executing tasks with local tools and embedded models:

![Flutter UI MCP Core Demo](https://raw.githubusercontent.com/lschaffer/flutter_mcp_suite/main/screenshots/video/genui_weather_example.gif)

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_ui_mcp_core: ^1.2.0
  dart_mcp_core: ^1.2.0
```

---

## 📂 Examples

- [`example/lib/main.dart`](example/lib/main.dart) – Standalone runnable example showcasing configuring LLMs, managing MCP servers, and inspecting tool execution.
- [**On-Device Gemini Nano Copilot**](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/flutter/example_local_ai_nano) – Native mobile copilot on Samsung Galaxy S25 / Android AICore with hardware battery, telemetry, and multimodal image inspection.
- [**GenUI Weather with Local AI**](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_weather_local_ai_nano) – Dynamic generative UI weather dashboard powered by on-device Gemini Nano and Open-Meteo tools.
