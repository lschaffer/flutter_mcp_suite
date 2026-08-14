# Modularization Plan: Clean Architecture for MCP Playground & GenUI Playground

## 1. Overview & Goal

Currently, `mcp_playground_flutter` contains standard chat rendering, embedded LLM management, MCP registry tabs, skill managers, and the newly added GenUI components. Blending both standard chat and GenUI in a single package has increased complexity and created maintenance overhead.

This plan separates the code into a clean, modular 4-package architecture:

```
                      ┌───────────────────────────┐
                      │    mcp_playground_dart    │  (Pure Dart engine - unchanged)
                      └─────────────┬─────────────┘
                                    │
                                    ▼
                      ┌───────────────────────────┐
                      │     mcp_playground_ui     │  (Shared UI, dialogs, drawers,
                      └──────┬─────────────┬──────┘   inspector, skills, localization)
                             │             │
              ┌──────────────┘             └──────────────┐
              ▼                                           ▼
┌───────────────────────────┐               ┌───────────────────────────┐
│   mcp_playground_flutter  │               │   genui_mcp_playground   │
│ (Standard Markdown/Chat   │               │ (Interactive GenUI Chat   │
│  Playground UI package)   │               │  & Catalog UI package)    │
└───────────────────────────┘               └───────────────────────────┘
```

---

## 2. Package Breakdown & Responsibilities

### A. `mcp_playground_dart` (Base Engine)
* **Status**: Unchanged (pub.dev package).
* **Contents**: Agent execution engine, LLM adapters, MCP clients, tool orchestration, no Flutter dependencies.

---

### B. `mcp_playground_ui` (New Shared UI Library)
* **Path**: `mcp_playground_ui/`
* **Role**: Provides reusable Flutter widgets, settings dialogs, registry tabs, and management panels.
* **Dependencies**: `flutter`, `mcp_playground_dart`, `shared_preferences`, `file_picker`, `universal_io`, `path`, `path_provider`, `archive`, `flutter_markdown_plus`, etc.
* **Key Components**:
  1. **LLM Configuration**: `LlmConfigForm`, provider selectors (OpenAI, Anthropic, Ollama, Google AI, Gemini, Custom, Embedded Llama), settings dialogs.
  2. **MCP Management**: `McpServerRegistryTab`, `EditMcpDialog`, `RemoteMcpDialog`, `ServerToolsDialog`, `RegisteredToolsDialog`, `InitialMcpInstallProgressDialog`.
  3. **Local MCP Runtime**: `LocalMcpClient` (subprocess wrapper for Node.js / Python / Dart).
  4. **Skill & Prompt Management**: `SkillSaveDialog`, `SubPromptListEditor`, `SkillZipImporter`, `SkillZipExporter`, file & web storage adapters.
  5. **Agent Inspector**: `AgentInspector` panel (execution steps, tool calls, raw tool payloads, system prompts, skill views).
  6. **Settings Drawer**: `SettingsDrawer` uniting LLM settings, skill management, and server registry.
  7. **Embedded LLM**: Downloader, storage manager, and UI widgets for local GGUF models.
  8. **Localization & Utilities**: `McpLocalizations` (EN/DE), `mime_utils.dart`.
  9. **Base Controllers & Models**: Shared state abstractions (inspector log events, server connections, tool registry state).

---

### C. `mcp_playground_flutter` (Classic / Standard Chat Playground)
* **Path**: `mcp_playground_flutter/`
* **Role**: The standard, production-ready AI Agent Playground widget using Markdown and rich code blocks.
* **Dependencies**: `flutter`, `mcp_playground_dart`, `mcp_playground_ui`.
* **Changes**:
  - Remove direct `genui`, `genai_primitives`, and `json_schema_builder` dependencies.
  - Simplify `McpPlayground` and `PlaygroundController` by referencing `mcp_playground_ui`.
  - Retain `ChatBubble`, standard markdown/HTML message rendering, agent loops, and inspector integration.

---

### D. `genui_mcp_playground` (New Standalone GenUI Package)
* **Path**: `genui_mcp_playground/`
* **Role**: Attractive, generative-UI-native playground widget allowing the model to stream interactive Flutter UI widgets + execute MCP tools.
* **Dependencies**: `flutter`, `mcp_playground_dart`, `mcp_playground_ui`, `genui`, `genai_primitives`, `json_schema_builder`.
* **Key Components**:
  1. `GenuiMcpPlayground` widget (top-level widget with identical shell: app bar, inspector side-panel, settings drawer, MCP registry, skill dialogs).
  2. `genuiCatalogItems` / `Catalog` as required parameters or defaults with dynamic widget registration.
  3. `McpGenuiChatController` + `GenuiChatView` + `A2uiTransportAdapter` for streaming and rendering reactive GenUI widgets.
  4. Built-in GenUI catalog helpers and catalog item definitions.

---

## 3. Package Name Suggestions for `genui_?`

| Suggested Package Name | Description | Pros / Cons |
| :--- | :--- | :--- |
| **`genui_mcp_playground`** ⭐ *(Recommended)* | Direct GenUI counterpart to `mcp_playground` | **Pros**: Clear naming symmetry (`mcp_playground_flutter` vs `genui_mcp_playground`), highly discoverable on pub.dev. |
| **`genui_playground_flutter`** | Flutter GenUI playground | **Pros**: Emphasizes Flutter & GenUI. **Cons**: Omits "MCP" in the title. |
| **`genui_agent_playground`** | Agentic GenUI playground | **Pros**: Focuses on agentic tool calling + UI generation. |

---

## 4. Migration & Implementation Strategy

To ensure zero lost work or regressions, we will follow a phased approach:

### Phase 1: Create `mcp_playground_ui`
1. Initialize `mcp_playground_ui` package with `pubspec.yaml`.
2. Move common widgets (`settings_drawer.dart`, `agent_inspector.dart`, `llm_config_form.dart`, `mcp_server_registry_tab.dart`, `skill_save_dialog.dart`, `sub_prompt_list_editor.dart`, dialogs, embedded LLM service & widgets, localizations, mime utils) into `mcp_playground_ui/lib/`.
3. Export public API from `mcp_playground_ui/lib/mcp_playground_ui.dart`.
4. Ensure `mcp_playground_ui` passes `dart analyze`.

### Phase 2: Create `genui_mcp_playground`
1. Initialize `genui_mcp_playground` package with `pubspec.yaml` (dependencies: `mcp_playground_dart`, `mcp_playground_ui`, `genui`, `genai_primitives`, `json_schema_builder`).
2. Move GenUI controllers (`genui_chat_controller.dart`), views (`genui_chat_view.dart`), catalog builders (`genui_catalog.dart`), and create `GenuiMcpPlayground` widget wrapping the shared UI shell with the GenUI chat view and catalog items.
3. Add example app in `genui_mcp_playground/example/`.
4. Validate `dart analyze` and example build.

### Phase 3: Clean & Restore `mcp_playground_flutter`
1. Remove `genui`, `genai_primitives`, `json_schema_builder` from `mcp_playground_flutter/pubspec.yaml`.
2. Refactor `mcp_playground_flutter` to import shared components from `mcp_playground_ui`.
3. Remove GenUI-specific branching and files from `mcp_playground_flutter`.
4. Keep standard chat features, markdown rendering, tool calling, inspector, and full feature parity with v0.2.x.
5. Validate `dart analyze` on `mcp_playground_flutter`.

### Phase 4: Verification & Examples Update
1. Update `examples/flutter/example_embedded` to use standard `mcp_playground_flutter`.
2. Update `examples/flutter/example_genui_filesystem` to use `genui_mcp_playground`.
3. Verify all packages analyze cleanly with no errors.
