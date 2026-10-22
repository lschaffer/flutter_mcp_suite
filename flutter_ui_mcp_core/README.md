# flutter_ui_mcp_core

Shared UI components, dialogs, drawers, controllers, and services for **Flutter MCP Suite** packages: [`flutter_ui_mcp`](https://pub.dev/packages/flutter_ui_mcp) and [`flutter_genui_mcp`](https://pub.dev/packages/flutter_genui_mcp).

---

## ✨ Features

- **Episodic Memory Archive & Retrieval (`MemoryArchiveDialog`)** – Inspect, search, and navigate compressed episodic memory summaries and full-turn histories. Includes automatic background compression and built-in `retrieve_memory` tool integration in `PlaygroundController`.
- **Dynamic Model Pricing & Context Limits (`ModelPricingService`)** – Real-time dynamic token pricing and context window resolution without hardcoded static tables (queries host `/models` catalogs, OpenRouter live API, DeepInfra, and local endpoints). Includes interactive banner with USD ($) and EUR (€) rates.
- **Autonomous Sub-Agent Delegation (`SubAgentExecution`)** – Full observability and autonomous multi-turn tool execution loop for child sub-agents spawned via `DelegateTaskTool`. Shows task hierarchy, depth, live logs, status, and specialized execution cards inside `ChatBubble`.
- **Dynamic Skill Activation Dock (`DynamicSkillDock`)** – Interactive chips dock allowing users and agents (`ActivateSkillsTool`/`DeactivateSkillsTool`) to activate/deactivate specialized skills at runtime without restarting the session.
- **Multimodal Chat & Lightbox Preview** – Native support for typed `ChatContentPart`s (`ImagePart`, `DocumentPart`, `AudioPart`). Provides inline previews, interactive full-screen image lightboxes, document chips, and audio pills.
- **Evaluation Benchmark Runner (`EvalController`, `EvalBenchmarkDialog`)** – Run automated LLM and agent evaluations directly within Flutter applications. Features pass rate telemetry, latency tracking, custom test suites, and detailed grading rationales.
- **Decoupled On-Device & Embedded AI (`EmbeddedLlmDriver`, `EmbeddedLlmRegistry`)** – Pluggable driver interface allowing local on-device `.gguf` execution without forcing heavy native C++ dependencies onto cloud-only users. On-device GGUF execution is powered by companion package [`flutter_ui_mcp_embedded`](../flutter_ui_mcp_embedded).
- **Standalone Modular Composer (`McpChatInputBar`)** – Reusable prompt text field, attachment preview chips, clipboard paste, and send triggers for custom host applications and custom layout grids.
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
  flutter_ui_mcp_core: ^1.3.0
  dart_mcp_core: ^1.3.0
```

---

## 📂 Examples

- [`example/lib/main.dart`](example/lib/main.dart) – Standalone runnable example showcasing configuring LLMs, managing MCP servers, and inspecting tool execution.
- [**Embedded On-Device LLM Showcase**](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/flutter/example_embedded) – Local on-device LLM runner via llamadart with zero cloud dependencies.
- [**GenUI Dynamic Weather**](https://github.com/lschaffer/flutter_mcp_suite/tree/main/examples/genui/example_genui_weather) – Dynamic generative UI weather dashboard powered by Open-Meteo tools and on-device/cloud LLMs.
