## 1.5.0

* **Multi-LLM Configuration Profiles & Manager (`LlmProfilesTab`)**:
  * Create, switch, rename, duplicate (`clone()`), and delete named LLM configuration profiles.
  * Profile fallback strategies and default profile resolution.
  * Reorganized `LlmConfigForm` with execution limits (max tool calls, max turns, turn limit) and collapsible parameter sections.
* **Safe Build-Phase State Dispatching (`_safeNotifyListeners`)**:
  * Fixed `setState() or markNeedsBuild() called during build` assertion when `fetchActiveModelPrice()` or configuration changes occur during the widget tree build phase.
  * Automatically defers notifications to `SchedulerPhase.postFrameCallbacks` when called during `persistentCallbacks`.
* **Synchronous Rebuild Prevention in `AgentInspector`**:
  * Guarded `fetchActiveModelPrice()` in `initState()` and `didUpdateWidget()` with post-frame callbacks.
* **Workflow Scratchpad Memory & Progressive Discovery Integration**:
  * Integrated `WorkflowMemoryStore` in `PlaygroundController` with dynamic blackboard tools (`store_memory`, `recall_memory`).
  * Improved `WorkflowSaveDialog`: persists single most recent turn prompt and subprompts with clear omit warning banner.
  * Fixed tool selector in settings drawer: accurately displays active tool counts and selected tools across primary and subagent scopes.

## 1.4.2

* **Responsive Full-Screen Dialogs on Mobile**:
  * All assistant management dialogs now automatically render as `Dialog.fullscreen(child: Scaffold(...))` on mobile screen widths:
    * `SettingsPanel` (Config, LLM, MCP servers via `showMcpSettingsDialog` with `useSafeArea: false`).
    * `SkillsManagerDialog`, `SkillWizardDialog` (including tool selector modal), `SkillDetailsDialog`, `SkillSaveDialog`, and `SkillLoadDialog`.
    * `WorkflowLoadDialog` and `WorkflowSaveDialog`.
    * `MemoryArchiveDialog` (Episodic Memory Archive & Search).
    * `EvalBenchmarkDialog` (Evaluation & Benchmarking suite).
    * `EditMcpDialog`, `ServerToolsDialog`, and `RegisteredToolsDialog`.
* **Mobile Layout & Overflow Fixes**:
  * `SettingsPanel`: wrapped active tools status indicator in `Expanded` and compacted button padding to prevent horizontal text overflow on narrow displays.
  * `SettingsPanel`: wrapped Persona / System Prompt title in `Expanded` to prevent overflow when long custom names are displayed.
  * `McpChatInputBar`: stacked the paste-from-clipboard action directly below the attachment (paperclip) icon in a compact vertical `Column`.
  * `WorkflowSaveDialog`: modernized option selector using Flutter 3.32+ `RadioGroup` and `RadioListTile` with compact zero-padding.

## 1.4.1

* **Web & WASM Compatibility**:
  * Decoupled native clipboard file and PowerShell reading behind conditional imports (`clipboard_native_reader_stub.dart` on Web/WASM, `clipboard_native_reader_io.dart` on native desktop).
  * Removed unconditional `dart:io` import from `ClipboardContentService` using `platform_file` abstraction.
  * Added dedicated `embedded_llm.dart` lightweight entrypoint exporting `EmbeddedLlmDriver` and `EmbeddedLlmRegistry` without pulling UI widgets or clipboard services.

## 1.4.0

* **⚠️ BREAKING CHANGES & MIGRATION (Embedded LLM Decoupling)**:
  * **Removed `llamadart` from `flutter_ui_mcp_core`**: The base core library no longer compiles or bundles native C++, FFI, WebGPU, or WASM dependencies.
  * **Migration for On-Device GGUF users**:
    1. Add `flutter_ui_mcp_embedded: ^1.4.0` to your `pubspec.yaml`.
    2. Register the driver via `FlutterUiMcpEmbedded.register()` during app startup.
    3. If the companion driver is omitted, `LlmProvider.embedded` is safely suppressed from UI dropdowns and stored preferences fall back to `LlmProvider.none`.
  * **Contract Extracted**: Core now provides abstract interfaces `EmbeddedLlmDriver` and global registry `EmbeddedLlmRegistry`.
* **Standalone Prompt Composer (`McpChatInputBar`)**:
  * Added `McpChatInputBar` widget for host applications needing only the prompt textfield, attachment chips, clipboard paste, and send triggers.
* **Configurable System Prompt Templates (`SystemPromptTemplate`)**:
  * Added `SystemPromptTemplate` model and `kDefaultSystemPromptTemplates`.
  * Added `systemPromptTemplates` and `showSystemPromptTemplates` options to `SettingsPanel`, `SettingsDrawer`, `showMcpSettingsDialog()`, and `PlaygroundController` to allow providing custom persona templates or hiding the quick persona chips altogether.
* **Cancel / Stop Generation Support**:
  * Added `stopGeneration()` alias and interactive stop button in `McpChatInputBar`.
  * Added `onCancel` callback support falling back directly to `PlaygroundController.cancelGeneration()`.
* **Mobile Fullscreen Inspector & Dialog Polish**:
  * Updated `showMcpInspectorDialog()` to open in full screen on mobile screens (`< 900` px) using `Dialog.fullscreen` with zero double/duplicate title headers.
* **Local Model Directory Discovery**:
  * `EmbeddedModelManager` now automatically discovers `.gguf` weights in `~/.models` as well as application documents.
* **Runtime Local Tool Registration**:
  * Added `controller.addLocalTools(tools)` for batch registration of native Dart tools.

## 1.3.0

* **Episodic Memory Archive & Retrieval UI**:
  * Added `MemoryArchiveDialog` for searching, inspecting, and navigating compressed episodic memory summaries and raw interaction histories.
  * Added reactive `memoryArchive` store and `retrieve_memory` tool integration in `PlaygroundController`.
* **Autonomous Sub-Agent Execution Tracking**:
  * Added `SubAgentExecution` model tracking child sub-agent workflows, hierarchy/depth, status, execution logs, and completed results.
  * Integrated autonomous `DelegateTaskTool` runner into `PlaygroundController` with dynamic tool cascading.
  * Added specialized visual execution cards in `ChatBubble` for sub-agent runs, episodic memory lookups, and skill activations.
* **Dynamic Skill Activation Dock**:
  * Added `DynamicSkillDock` widget allowing users to toggle dynamic skill availability on the fly.
  * Integrated agent-driven skill activation via `ActivateSkillsTool` and `DeactivateSkillsTool`.
* **Multimodal Chat Content Staging**:
  * Added `pendingParts` staging in `PlaygroundController` for multimodal input.
  * Enhanced `ChatBubble` with rich rendering for images (with full-resolution lightbox viewer), documents, and audio clips.
* **Evaluation Benchmark Runner**:
  * Added `EvalController` and `EvalBenchmarkDialog` enabling automated LLM/agent benchmarking directly in Flutter apps with real-time pass/fail metrics, scoring, and output inspection.
* **Dynamic Model Pricing & Context Limits (`ModelPricingService`)**:
  * Real-time dynamic token pricing and context window resolution without hardcoded static tables (queries host `/models` catalogs, OpenRouter live API, DeepInfra, and local endpoints).
  * Rich model autocomplete suggestions with multimodal indicator badges, context length tags, and real-time input/output rates.
  * Interactive model pricing and context banner beneath the model selector in `LlmConfigForm` with USD ($) and EUR (€) rate conversions and live freshness tracking.
* **Autonomous Multi-Turn Sub-Agent Execution Loop**:
  * Enhanced `delegate_task` runner in `PlaygroundController` into a full autonomous multi-turn loop supporting up to 5 iterative tool turns.
  * Real-time progress updates streamed to `SubAgentExecution` and rendered in `ChatBubble` cards as child tools run.
* **Markdown Dark Mode Styling**:
  * High-contrast markdown text and syntax styles (`darkMarkdownStyleSheet`) ensuring crystal-clear codeblock, table, and list readability in dark theme mode.
* **Attachment Resilience & Inspector Metrics**:
  * Added `allowMalformed: true` to attachment UTF-8 decoding to protect against non-UTF8/ISO-8859-1 character crashes.
  * `AgentInspector` sent characters and token usage metrics now accurately account for staged file attachments.
* **Dependencies**:
  * Upgraded dependency to `dart_mcp_core: ^1.3.0`.

## 1.2.0

* **Embedded On-Device LLM Standardization (`.gguf` via `llamadart`)**:
  * Standardized the embedded on-device engine exclusively on `.gguf` via `llamadart` (`llama.cpp`) across all platforms (Android, iOS, Windows, macOS, Linux, Web), ensuring crash-safe execution and access to the extensive open-weights community catalog.
  * Enhanced HuggingFace discovery (`HfDiscoverDialog`) and direct URL import (`AddGgufDialog`) tailored to quantized GGUF models with automatic CPU size safety filtering.
  * Added hardware-specific acceleration guidance in `EmbeddedModelPickerWidget` (Apple Metal GPU, Android ARM NEON, Desktop shaders, WebGPU).
* **Multimodal Image Optimization (`ImageOptimizer`)**:
  * Added `ImageOptimizer.shrinkToOptimalSize` using Flutter native hardware decoders to automatically downscale large photos (e.g. 200MP mobile camera shots) to optimal 768px dimensions for on-device SLMs and multimodal APIs without memory bloat.
* **Mobile UX Enhancements**:
  * Optimized LLM configuration and settings modal sheets for mobile screens, rendering as full-screen views on devices under 600px width for optimal readability.
* **Zero-Cost Telemetry**:
  * Configured `AgentInspector` token cost tracking to recognize `LlmProvider.embedded` as zero-cost on-device execution.
* **Dependencies**:
  * Upgraded dependency to `dart_mcp_core: ^1.2.0`.

## 1.1.7

* **Dependencies**:
  * Upgraded dependency to `dart_mcp_core: ^1.1.6` for OpenAI-compatible endpoint token detail sanitization, tool call schema patching, and SSE stream handling.
  * Synchronized version 1.1.7 across the Flutter MCP Suite ecosystem.

## 1.1.6

* **Platform Support & WASM Compatibility**:
  * Migrated from `flutter_widget_from_html` to `flutter_widget_from_html_core`, restoring full WASM runtime compatibility and clean platform support across Android, iOS, Windows, macOS, Linux, and Web.
* **Static Analysis & Deprecation Fixes**:
  * Updated `EmbeddedLlmAdapter` to use `LlamaLogging.configure` instead of deprecated `LlamaEngine.configureLogging`.
  * Updated model loading to use `LlamaEngine.setModel` with `LlamaModel` instead of deprecated `loadModel` and `loadModelFromUrl`.
  * Resolved all linter deprecation warnings.
* **Dependencies**:
  * Synchronized version 1.1.6 across the Flutter MCP Suite ecosystem.

## 1.1.5

* Synchronized release across the Flutter MCP Suite ecosystem.
* Added support for embedded model discovery and dynamic tool registration.

## 1.1.4

- Upgraded dependencies:
  - `openai_dart: ^11.0.1`
  - `material_ui: ^1.6.0`
- Upgraded dependency on `dart_mcp_core: ^1.1.4`.
- Synchronized release across the Flutter MCP Suite ecosystem.

## 1.1.3

- Upgraded AI SDK dependencies:
  - `googleai_dart: ^13.0.0`
  - `openai_dart: ^10.0.0`
  - `anthropic_sdk_dart: ^9.0.0`
  - `ollama_dart: ^4.0.0`
- Upgraded dependency on `dart_mcp_core: ^1.1.3`.
- Synchronized release across the Flutter MCP Suite ecosystem.

## 1.1.2

- Upgraded dependency on `dart_mcp_core: ^1.1.2`.
- Synchronized release across the Flutter MCP Suite ecosystem.

## 1.1.1

- Upgraded dependency on `dart_mcp_core: ^1.1.1`.
- Synchronized release across the Flutter MCP Suite ecosystem.

## 1.1.0

- Modernized UI text across widgets: updated defaults to "Chat", "AI Agent Studio", and clean action labels.
- Added support for sub-prompt and workflow prompt templates with improved styling.
- Model Size & Capability Matrix added to documentation.
- Upgraded dependency on `dart_mcp_core: ^1.1.0`.

## 1.0.2

- Updated README and documentation to reference `flutter_mcp_suite` ecosystem.
- Depends on `dart_mcp_core: ^1.0.2`.

## 1.0.1

- Upgraded dependencies: `material_ui` to `^1.4.0`, `file_picker` to `^13.1.0`, `archive` to `^4.3.0`, `llamadart` to `^0.8.24`.
- Expanded version constraints for `anthropic_sdk_dart`, `googleai_dart`, `openai_dart`, and `ollama_dart`.
- Added standalone showcase example package in `example/`.

## 1.0.0

- **Initial stable production release** under the `flutter_mcp_suite` ecosystem.
- Rebranded and modernized from `mcp_playground_ui`.
- Shared UI controllers, inspector drawer, embedded GGUF model discoverers, and MCP server registry components.
- Depends on `dart_mcp_core: ^1.0.0`.

## 0.4.0

- **BREAKING CHANGE - Decoupled Material UI**:
  - Migrated from legacy `package:flutter/material.dart` to standalone `package:material_ui/material_ui.dart` using the official Flutter migration tool (`dart fix --apply --code=migrate_design_widgets`).
  - Added dependency on `material_ui: ^1.3.0`.
  - Re-exported `package:material_ui/material_ui.dart` in `mcp_playground_ui.dart` for backwards and downstream compatibility.
- Upgraded `file_picker` to `^13.0.0`.
- Fixed markdown style sheet text colors in dark mode to guarantee legible `onSurface` contrast for headings and body text.

## 0.3.4

- Tightened `file_picker` dependency constraint to `^12.0.0` and removed redundant null checks to ensure seamless `pub downgrade` analysis.
- Fixed dartdoc parameter references in `SkillStorageAdapter` implementations.

## 0.3.3

- Enabled WebAssembly (WASM) runtime support:
  - Replaced direct `dart:io` and `path_provider` imports with conditional exports and platform-agnostic helpers.
  - Added conditional stubs for `EmbeddedModelManager`, `LocalMCPClient`, and `FileSystemSkillStorageAdapter` for Web/WASM runtimes.
  - Decoupled HTML preview in chat bubbles via conditional launcher.
  - Removed `universal_io` dependency.
  - Replaced platform checks with `defaultTargetPlatform`.

## 0.3.2

- Upgraded AI and core dependencies:
  - `mcp_playground_dart` to `^0.3.2`
  - `anthropic_sdk_dart` to `^8.0.0`
  - `googleai_dart` to `^12.0.1`
  - `openai_dart` to `^8.1.0`
  - `ollama_dart` to `^2.6.1`
  - `llamadart` to `^0.8.23`
  - `archive` to `^4.2.0`
  - `flutter_widget_from_html` to `^0.17.4`

## 0.3.1

- Declared supported platforms explicitly in `pubspec.yaml` (Android, iOS, Linux, macOS, Web, Windows).
- Fixed `repository` URL in `pubspec.yaml` to point to GitHub `main` branch.
- Broadened `file_picker` dependency constraint to `'>=11.0.3 <13.0.0'` to support `file_picker` 12.0.0+.

## 0.3.0

- Updated `WorkflowSaveDialog` to use Flutter 3.32+ `RadioGroup<bool>` ancestor, resolving deprecated `groupValue` warnings.
- Added auto-sync to `PlaygroundController.connectServer()` for newly registered or unsynced clients.
- Added copy button and clipboard feedback for user prompts and assistant message bubbles.
- Upgraded `mcp_playground_dart` to `^0.3.0`.

## 0.1.0

* Initial release of `mcp_playground_ui` extracting common Flutter components, dialogs, drawers, and controllers into a shared library.
