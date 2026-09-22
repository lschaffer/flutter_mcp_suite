# flutter_ui_mcp_core

Shared UI components, dialogs, drawers, controllers, and services for **Flutter MCP Suite** packages: [`flutter_ui_mcp`](https://pub.dev/packages/flutter_ui_mcp) and [`flutter_genui_mcp`](https://pub.dev/packages/flutter_genui_mcp).

---

## ✨ Features

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
  flutter_ui_mcp_core: ^1.0.2
  dart_mcp_core: ^1.0.2
```

---

## 📂 Example

See the standalone runnable example at [`example/lib/main.dart`](example/lib/main.dart) which showcases configuring LLMs, managing MCP servers, and inspecting tool execution.
