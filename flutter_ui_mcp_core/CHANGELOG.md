## 1.5.11

* **Suite Synchronization**:
  * Upgraded `dart_mcp_core` dependency to `^1.5.11` (multi-turn tool call and response ID alignment, provider compatibility fixes, and context compressor adjustments).

## 1.5.10

* **Suite Synchronization**:
  * Upgraded `dart_mcp_core` dependency to `^1.5.10` (OpenAI compatible empty content sanitization and context window auto-compression improvements).

## 1.5.9

* **Automatic MCP Server Tool Selection & Synchronization**:
  * Enabling or adding an MCP server now automatically discovers/caches tools and registers them into `enabledToolNames`, preventing the "0 Tools" state when external or custom MCP servers are toggled.
  * Disabling or removing an MCP server automatically purges its associated tools from `enabledToolNames`.
  * Server synchronization automatically triggers connections for enabled servers that have cached tools or have not yet completed tool discovery.
  * Cleans up legacy pseudo-tool IDs (e.g. `gh_mcp_*`) on startup.
* **Suite Synchronization**:
  * Upgraded `dart_mcp_core` dependency to `^1.5.9`.

## 1.5.8

* **Configurable 10-Minute HTTP Timeout for Local Models & Coding Agents**:
  * Inherited `timeoutSeconds` (default 600s / 10m) from `dart_mcp_core` across all LLM adapters.
  * Eliminates 2-minute timeouts when interacting with local models (Hypura, vLLM, LM Studio) during non-streaming tool execution turns.
* **Synchronized AI SDK Major Upgrades**:
  * Upgraded `openai_dart` to `^12.0.0`.
  * Upgraded `ollama_dart` to `^5.0.0`.
  * Upgraded `anthropic_sdk_dart` to `^10.0.0`.
  * Upgraded `googleai_dart` to `^13.1.0`.
  * Upgraded `dart_mcp_core` to `^1.5.8`.

## 1.5.7

* **Clickable Markdown & Autolinked URLs**:
  * Added `onTapLink` handler with fallback URL schemes (`http`, `https`) to launch links reliably in the external browser via `url_launcher`.
  * Configured `md.ExtensionSet.gitHubFlavored` with `markdown: ^7.3.0` so raw URLs in responses (e.g. `https://orf.at/...`) are automatically rendered as clickable hyperlinks.
* **Sanitized Choice Option Chips**:
  * Stripped code blocks (fenced and indented) and inline code spans before parsing interactive option buttons in `ChatBubble`.
  * Prevents programming arrays and code constructs (such as Angular `router.navigate(['/login'])`) from rendering as false-positive choice action buttons.
* **Session History Restoration (`PlaygroundController.loadMessages`)**:
  * Added `PlaygroundController.loadMessages(List<ChatMessage> messages, {bool clearExisting = true})` to easily restore historical conversation transcripts and persist session state across app restarts or multi-chat views.
* **Synchronized Suite Upgrades**:
  * Bumped `dart_mcp_core` dependency to `^1.5.7`.

## 1.5.6

* **Instant Generation Cancellation & Tool Loop Abortion**:
  * Aborts active tool wait immediately upon user clicking stop (`stopGeneration` / `cancelGeneration`), halting the tool execution loop without delay.
  * Automatically rejects/denies any pending tool approvals on cancellation.
  * Prevents subsequent tool iterations or further LLM turns from executing after a user stop request.
* **Workspace Directory Dynamic Rebinding**:
  * Updating `PlaygroundController.workspaceDirectory` now immediately synchronizes all active `BaseCodingTool` instances to the new workspace path.
  * Added `PlaygroundController.updateLocalTools(List<McpLocalTool> tools)` to dynamically refresh local tool collections.
* **Synchronized Suite Upgrades**:
  * Bumped `dart_mcp_core` dependency to `^1.5.6`.

## 1.5.5

* **WASM & Web Platform Compatibility**:
  * Eliminated direct `dart:io` imports across `tool_permission_service.dart` and `document_export_service.dart` by migrating to `universal_io`, restoring full Web & WASM runtime compatibility.
* **Resolved FilePicker Static Analysis Deprecations**:
  * Removed deprecated `type` and `allowedExtensions` arguments in `FilePicker.saveFile()` within `chat_bubble.dart` to prevent warnings on future file_picker releases and ensure a clean 50/50 static analysis score on pub.dev.
* **Synchronized Suite Upgrades**:
  * Bumped `dart_mcp_core` dependency to `^1.5.5` and `anthropic_sdk_dart` to `^9.0.1`.

## 1.5.3

* **Human-in-the-Loop (HITL) Tool Permissions (`ToolPermissionService`, `ToolPermissionSettings`)**:
  * Configurable auto-approval policies categorized across four risk levels: `read`, `network`, `write`, and `execute`.
  * Added `PendingToolApprovalCard` interactive UI card displaying the requested tool name, color-coded risk badge, arguments preview, and three decision actions:
    * **Accept**: Approves the single execution.
    * **Always Allow**: Auto-approves the entire risk category for the session and persists preferences to `.tealkit/permissions.yaml`.
    * **Deny**: Rejects execution and safely returns an execution refusal error to the LLM.
  * Added `ToolPermissionSettings.inferRiskLevel(...)` heuristic classifier to deduce risk categories for tools lacking explicit risk designations.
  * Added `pendingToolApproval` and `respondToToolApproval(...)` to `PlaygroundController`.
* **Coding Sub-Mode & Plan Mode Protection Guard (`checkPlanModeToolRestriction`)**:
  * Added `codingSubMode` property (`/plan`, `/code`, `/ask`, `/rag`) to `PlaygroundController`.
  * In `/plan` mode, file-writing tools (`fs_write_file`, `fs_replace_text`, `fs_delete`, etc.) are prohibited from modifying source code files (`.dart`, `.py`, `.ts`, `.cpp`, etc.), shielding production repositories from premature or unapproved edits.
  * Explicitly allows modifying documentation and planning files (`*.md`, `tasks.md`, `implementation_plan.md`, `*.json`, `*.yaml`).
* **Document Export Engine (`DocumentExportService`, `ExportDocumentDialog`)**:
  * Export structured plans, architecture documents, and technical analyses to **PDF** (`.pdf`), **Word** (`.docx`), and **Markdown** (`.md`).
  * Features intelligent plan detection (`DocumentExportService.isExportableAnalysisOrPlan`) which automatically surfaces export buttons in `ChatBubble` message cards.
  * Includes `ExportDocumentDialog` allowing interactive destination folder selection, filename customization, and format toggling with native system file-saver integration.
* **External Input Prompt Injection (`PlaygroundController`)**:
  * Added `setInputPrompt(String prompt)` and `consumePendingInputPrompt()` for programmatic injection of prompts into the chat input bar.

## 1.5.2

* **Chat View Background Customization**:
  * Added chatBackgroundDecoration (Decoration?), showEmptyChatState (ool, default 	rue), and emptyChatBuilder to PlaygroundController.
  * Added reactive setters setChatBackgroundDecoration(...), setShowEmptyChatState(...), and setEmptyChatBuilder(...) that notify listeners on change.
  * Added convenience method setChatBackgroundImage(ImageProvider image, {BoxFit fit, Alignment alignment, ColorFilter? colorFilter, double opacity, bool showEmptyText}) to allow setting an image wallpaper background with zero empty-state text.
* **Standalone McpChatView in Core**:
  * Moved and exported McpChatView directly within lutter_ui_mcp_core with full background decoration and empty state customization support.
* **Cleaned Multi-Step Tabs Controls**:
  * Removed the duplicate + Step button in SubPromptListEditor's horizontal step tabs bar; step insertion is now handled exclusively by the right-aligned + action button.

## 1.5.1

* **Desktop Dialog Ergonomics**:
  * Enlarged settings and management dialogs to 95% screen width and 95% height on desktop (`mcpDesktopDialogWidth(context)` = 0.95, `mcpDesktopDialogHeight(context)` = 0.95) for expansive multi-tab viewability.
* **Redesigned LLM Model Selector**:
  * Permanently converted the model selector into a searchable dropdown menu with an inline quick-refresh button (`Icons.refresh_rounded`).
  * Added auto-loading of remote models on form initialization when the endpoint URL is set.
  * Added loading spinner and auto-fetch trigger when opening search picker with an empty model catalog.
  * Removed obsolete "Detect Foundry" button.
* **Multi-Profile State Restoration on App Restart**:
  * Fixed multi-profile persistence: `PlaygroundController._initAndLoad()` now loads all saved profiles from storage, preventing loss of secondary profiles upon app restart or hot restart (`Shift+R`).
* **International Localization Safety**:
  * Exported `materialUiLocalizationsDelegates` and robust fallback locale resolution to guarantee zero `MaterialLocalizations` runtime errors on systems running non-English system locales.

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
