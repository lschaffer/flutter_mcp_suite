# mcp_playground_ui

Shared UI components, dialogs, drawers, controllers, and services for **MCP Playground** (`mcp_playground_flutter`) and **GenUI Playground** (`genui_mcp_playground`).

---

## ✨ Features

- **`PlaygroundController`** – Full lifecycle and state manager for agent conversations, tool execution, MCP server sync, and inspector tracing.
- **LLM Configuration & Settings** – `LlmConfigForm`, `SettingsDrawer`, `SubPromptListEditor`.
- **MCP Server & Tool Management** – `McpServerRegistryTab`, `EditMcpDialog`, `RemoteMcpDialog`, `RegisteredToolsDialog`, `ServerToolsDialog`.
- **On-Device Embedded LLMs** – `EmbeddedModelManager`, `EmbeddedModelPickerWidget`, `HfDiscoverDialog`, `AddGgufDialog`.
- **Skills System** – `SkillSaveDialog`, `SkillLoadDialog`, `SkillStorageAdapter`, ZIP import/export.
- **Inspector Panel** – `AgentInspector` side pane for real-time observability of tool executions and system prompts.
- **Localization** – English & German strings via `McpPlaygroundLocalizations` (`McpLocalizations`).

---

## 🎥 Demo

Watch the AI Agent Playground in action using embedded model to call local dart tools:

![Genui MCP Demo ](https://raw.githubusercontent.com/lschaffer/mcp_playground/main/screenshots/video/genui_weather_example.gif)

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mcp_playground_ui: ^0.1.0
  mcp_playground_dart: ^0.2.2
```
