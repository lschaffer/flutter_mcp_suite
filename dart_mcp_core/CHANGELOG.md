## 1.5.1

- **Tool Parameter Schema Sanitization (`LLMService.sanitizeSchemaForLlm`)**:
  - Recursively resolves and inlines `$ref` pointers from `$defs` / `definitions`.
  - Strips unsupported JSON schema properties (`$schema`, `default` on Gemini) to eliminate HTTP 400 schema validation errors on strict LLM providers such as Gemini 3.7 Flash and strict OpenAI-compatible endpoints.

## 1.5.0

- **Multi-LLM Profiles & Configuration Schema (`LlmConfig`)**:
  - Added profile identification attributes: `id`, `name`, `displayName`, and `profileId`.
  - Added `clone({String? newId, String? newName})` for profile duplication and migration.
  - Added execution and turn limits: `maxToolCalls`, `maxTurns`, and `turnLimit`.
  - Changed default `maxToolIterations` / `maxToolCalls` from 400 to **30** for safe guardrails against runaway tool loops.
  - Added resilient JSON parsing supporting snake_case (`max_tool_calls`, `max_turns`, `turn_limit`, `api_key`, `base_url`).
- **Infinite Tool Loop Protection (`ToolLoopGuard`, `LoopEvaluation`, `LoopAction`)**:
  - Canonicalized argument hashing to detect repetitive tool calls.
  - Injects loop warnings upon 3 consecutive identical calls or alternating patterns (A-B-A-B-A-B).
  - Automatically blocks tool execution at 4+ identical calls, preventing runaway token consumption.
- **Execution Limits & Session Auto-Rotation (`McpExecutionLimits`, `SessionRotator`)**:
  - Added `McpExecutionLimits` for turn thresholds (`maxTurns`, `turnLimit`, `maxToolCalls`).
  - Added `SessionRotator` for automatic rotation of session log files when turn thresholds or file size limits are exceeded.
- **Bulk Serialization for `EpisodicMemoryStore`**:
  - Added `loadEntries(List<EpisodicMemoryEntry> entries, {bool replace = false})` and `loadFromJsonList(List<dynamic> jsonList)`.
  - Added bulk `toJson()` and `toJsonList()` for persisting conversation archives.
  - Added `EpisodicMemoryStore.fromJson(Map<String, dynamic> json)` factory constructor.
- **Dynamic Model Override in Sub-Agent Delegation (`DelegateTaskTool`)**:
  - Added optional `model` / `modelOverride` support to automatically apply model overrides to child agent's `llmConfig`.
- **Shared Workflow Blackboard Memory (`WorkflowMemoryStore`, `StoreMemoryTool`, `RecallMemoryTool`)**:
  - In-memory key-value scratchpad for passing structured state across multi-agent workflows and sub-agents.
  - Automatically injected tools (`store_memory`, `recall_memory`) when `workflowMemoryStore` is provided to `Agent` or `McpAgentEngine`.

## 1.4.0

- **Suite-Wide Architecture Synchronization**:
  - Aligned package versioning with companion engine extraction (`flutter_ui_mcp_embedded`).
  - Strengthened pluggable `LLMService.embeddedHandler` and `LLMService.embeddedStreamHandler` interface stability.
- **Shared Workflow Blackboard / Scratchpad Memory (`WorkflowMemoryStore`, `StoreMemoryTool`, `RecallMemoryTool`)**:
  - In-memory key-value scratchpad store for passing structured state across multi-agent workflows and sub-agents.
  - Automatically injected tools (`store_memory`, `recall_memory`) when a `workflowMemoryStore` is provided to `Agent` or `McpAgentEngine`.
  - Sub-agent clones and targets inherit the parent's workflow memory store automatically.
  - Emits `AgentWorkflowMemoryEvent` on storage and retrieval operations.
- **Dynamic Model Override in Sub-Agent Delegation (`DelegateTaskTool`)**:
  - Added optional `model` / `modelOverride` parameter to `delegate_task` tool schema.
  - Automatically applies model override to child agent's `llmConfig` (`copyWith(model: model)`) for specialized sub-tasks without requiring pre-registered agent configurations.
- **Bulk Serialization for `EpisodicMemoryStore`**:
  - Added `loadEntries(List<EpisodicMemoryEntry> entries, {bool replace = false})` and `loadFromJsonList(List<dynamic> jsonList)`.
  - Added bulk `toJson()` and `toJsonList()` for persisting conversation archives to DuckDB or disk.
  - Added `EpisodicMemoryStore.fromJson(Map<String, dynamic> json)` factory constructor.

## 1.3.0

- **Typed Multimodal Parts (`ChatContentPart`)**:
  - Introduced `ChatContentPart` hierarchy (`TextPart`, `ImagePart`, `DocumentPart`, `AudioPart`) for rich multimodal message representations.
  - Native base64/URL/bytes image payload forwarding across OpenAI (`ContentPart.imageUrl`), Anthropic Claude (`InputContentBlock.image`), Google Gemini (`Part.inlineData`), and Ollama (`images`).
  - Added ergonomic factories: `ChatMessage.user()`, `ChatMessage.assistant()`, and `ChatMessage.system()`.
- **Episodic Memory Store & Recall (`EpisodicMemoryStore`, `RetrieveMemoryTool`)**:
  - Prevents permanent information loss during context window auto-compression by stashing raw turn history in an indexed episodic archive before summarization.
  - Injects `retrieve_memory` tool so the model can inspect exact past code snippets, hashes, and tool outputs on demand.
  - Emits `AgentMemoryRetrievedEvent` when the model recalls archived turns.
- **Sub-Agent Delegation (`DelegateTaskTool`)**:
  - Native task delegation enabling primary agents to delegate focused sub-tasks to specialized sub-agents or clean agent clones (`assignee: 'clone'`).
  - Multi-level recursion guards (`isSubAgent`, `delegationDepth`) preventing infinite delegation loops.
  - Real-time delegation event lifecycle: `AgentSubAgentStartedEvent`, `AgentSubAgentProgressEvent`, and `AgentSubAgentCompletedEvent`.
- **Dynamic Runtime Skill Activation (`SkillDefinition`, `ActivateSkillsTool`, `DeactivateSkillsTool`)**:
  - Allows grouping system prompts and tools into modular `SkillDefinition` units.
  - Non-active skills only publish concise one-line descriptions in the system prompt, keeping token footprints minimal.
  - Injects `activate_skills` and `deactivate_skills` tools for the model to toggle toolsets on-the-fly. Emits `AgentSkillsChangedEvent`.
- **Agent Evaluation Harness (`EvalTask`, `EvalGrader`, `EvalRunner`, `TrajectoryRecorder`)**:
  - Added end-to-end evaluation framework for agent accuracy, regression testing, and model benchmarking.
  - Included standard evaluators: `ExactMatchGrader`, `RegexGrader`, and `ToolCallGrader`.
  - Added `TrajectoryRecorder` to serialize full multi-turn conversation trajectories to and from JSON.

## 1.2.0

- **Agent Lifecycle Hooks (`AgentHook`)**:
  - Added lifecycle interceptors: `beforeToolCall`, `afterToolCall`, `beforeModelCall`, and `afterModelCall`.
  - Added `ToolCallDecision` (`proceed`, `deny`, `modify`) for security guardrails, parameter sanitization, and enterprise compliance.
- **Structured Agent Planning (`PlanState`, `PlanStep`, `WriteTodosTool`)**:
  - Native multi-step agent planning and tracking.
  - `AgentPlanEvent` stream emitted through `McpAgentEngine.agentEvents` for reactive UI progress visualization.
  - Optional `enablePlanning` flag on `Agent` automatically injecting the `write_todos` planning tool.
- **Enhanced `MCPToolResult`**:
  - Added `requestStop` flag to gracefully terminate execution loops upon task completion.
  - Added `metadata` map for rich telemetry, timestamps, and custom tool payloads.
  - Added ergonomic factories: `MCPToolResult.text`, `MCPToolResult.error`, `MCPToolResult.stop`, and `MCPToolResult.image`.
- **Context Window Auto-Compression (`ContextCompressor`)**:
  - Pure Dart token estimation and auto-compression utility designed for SLMs and long-running sessions.
  - Automatically summarizes earlier conversation turns via the LLM when approaching context limits while preserving recent turns and system instructions.
  - Emits `AgentContextCompressedEvent` with token reduction metrics (`originalTokens`, `compressedTokens`, `compressedTurnCount`).
  - Pluggable via `McpAgentEngine(contextCompressor: ...)` or `Agent(contextCompressor: ...)`.
- **Progressive MCP Tool Discovery**:
  - Added `McpListToolsTool` and `McpCallToolTool` to support workspaces with hundreds of MCP tools without blowing LLM context windows.

## 1.1.6

- **OpenAI-Compatible & Mistral HTTP Response Patching**:
  - Introduced `_OpenAiCompatiblePatchClient` to patch HTTP responses and SSE streams (`text/event-stream`) for OpenAI-compatible endpoints (such as OpenRouter, vLLM, local LLMs) and Mistral.
  - Sanitizes `usage.prompt_tokens_details` and `usage.completion_tokens_details` by stripping `null` and non-integer values, preventing `FormatException` / `ParseException` in `openai_dart`'s `requireJsonInt` (such as on `cache_write_tokens`).
  - Automatically injects missing `type: "function"` into tool calls.
  - Coerces empty list `content: []` to `null` in streaming delta and completion messages.

## 1.1.5

- **Robust Multi-Encoding File Support (`fs_read_file`, `fs_replace_text`)**:
  - Implemented automatic encoding fallback (UTF-8 -> Latin-1 / ISO-8859-1 / Windows-1252 -> UTF-8 with `allowMalformed: true`) in `BaseCodingTool`, `FsReadFileTool`, and `FsReplaceTextTool`.
  - Fixes crash (`FileSystemException: Failed to decode data using encoding 'utf-8'`) when reading or editing legacy embedded C/C++ source code, header files, or non-UTF-8 workspace documents.

## 1.1.4

- **Web & WASM Platform Abstraction for Coding Tools**:
  - Added conditional export for coding tools with `coding_tools_stub.dart`, allowing `dart_mcp_core` to compile seamlessly in Web and WASM environments where `dart:io` is unavailable.
- **Multimodal Image & Attachment Support**:
  - Added multimodal image attachment handling across LLM providers:
    - OpenAI: `ContentPart.imageUrl` with base64 data URI format.
    - Anthropic: `InputContentBlock.image` base64 blocks with media type detection (`image/png`, `image/webp`, `image/gif`, `image/jpeg`).
    - Google Gemini: `Part.bytes` for image attachments.
- **Model Reasoning & Commentary Preservation**:
  - In `McpAgentEngine`, preserved model reasoning and commentary text in conversation history alongside tool calls to prevent repeating thought loops on reasoning models (e.g., DeepSeek).
- **Tool Iteration Limit Increase**:
  - Increased default `maxToolIterations` from 100 to 400 in `McpAgentEngine` and `LlmConfig`.
- **Dependency Upgrades**:
  - Upgraded `openai_dart` to `^11.0.1`.

## 1.1.3

- **Upgraded AI SDK Dependencies**:
  - Upgraded `googleai_dart` to `^13.0.0` (Dart SDK `>=3.12.0`).
  - Upgraded `openai_dart` to `^10.0.0` (GPT Image 2.5 support, extensible `ImageSize` value class).
  - Upgraded `anthropic_sdk_dart` to `^9.0.0` (Dart SDK `>=3.12.0`).
  - Upgraded `ollama_dart` to `^4.0.0` (extended thinking union support).

## 1.1.2

- **Conversation Session Resumption & Trajectory Preservation**:
  - Added `initialMessages` property to `Agent` definition and JSON serialization (`toJson` / `fromJson`), allowing multi-turn REPL and CLI agents to save, restore, and continue session transcripts seamlessly.
  - Enhanced `AgentFinalResultEvent` to carry the full `List<ChatMessage> messages` trajectory generated across all tool calls and responses during execution.
- **Configurable Tool Iteration Limit (`maxToolIterations`)**:
  - Added configurable `maxToolIterations` (default: 100, up from 10) to `LlmConfig`, `Agent`, and `McpAgentEngine`.
  - Added graceful final response synthesis when the tool iteration limit is reached instead of halting execution abruptly.
  - Added automatic recovery prompting if an LLM finishes tool calling with an empty text response.
- **Token Usage Reporting & Metric Events**:
  - Added `AgentUsageEvent` stream event to `McpAgentEngine` providing `promptTokens`, `completionTokens`, and `totalTokens` emitted after each LLM call.
  - Added `LLMUsage` model attached to `LLMResponse` capturing usage returned by LLM providers or calculated via fallback token estimation.
- **Enhanced Coding Tools**:
  - Included full 10-tool autonomous engineering tool suite in `CodingTools.createAll()`: `fs_find`, `fs_list_dir`, `fs_read_file`, `fs_write_file`, `fs_replace_text`, `fs_create_dir`, `fs_move`, `fs_delete`, `terminal_exec`, and `fetch_web`.
  - Improved `FsReadFileTool` with intelligent pagination and safe 800-line chunk truncation, providing clear range hints for large files.
- **Bug Fixes**:
  - Cleaned up nullable type assertions in OpenAI provider usage mapping.

## 1.1.0

- **New Native Coding Tools & Engine Helpers**:
  - Added `FsFindTool` (`fs_find`) for discovering files and directories across workspaces with `.gitignore` awareness.
  - Added `FsReadFileTool` (`fs_read_file`) for line-numbered and paginated file inspection.
  - Added `FsWriteFileTool` (`fs_write_file`) for creating and overwriting files with automatic directory resolution.
  - Added `FsReplaceTextTool` (`fs_replace_text`) for surgical, unique search-and-replace edits.
  - Added `TerminalExecTool` (`terminal_exec`) for cross-platform workspace command execution (e.g. `dotnet build`, `dart test`, `git status`).
  - Added `CodingTools.createAll()` factory helper to bundle coding tools for CLI, Desktop, and Server environments.

## 1.0.2

- Updated package documentation and branding references to `flutter_mcp_suite`.

## 1.0.1

- Expanded LLM SDK dependency version constraints to support `anthropic_sdk_dart` 9.x, `googleai_dart` 13.x, `openai_dart` 9.x, and `ollama_dart` 3.x.

## 1.0.0

- **Initial stable production release** under the `flutter_mcp_suite` ecosystem.
- Rebranded and modernized from `mcp_playground_dart`.
- Production-ready Model Context Protocol (MCP) client transports (HTTP/SSE & stdio subprocesses).
- LLM service adapters for OpenAI, Anthropic, Gemini, and Ollama.
- Agent execution loop and tool orchestration engine.

## 0.3.2

- Upgraded AI SDK dependencies:
  - `anthropic_sdk_dart` to `^8.0.0`
  - `googleai_dart` to `^12.0.1`
  - `openai_dart` to `^8.1.0`
  - `ollama_dart` to `^2.6.1`
  - `yaml` to `^3.1.4`
  - `test` to `^1.32.0`
- **New Pure Dart Examples & Skills**:
  - **Git Staged Diff Reviewer & PR Generator** (`examples/dart/git_review_skill`): Automated git inspection workflow that reads staged diffs, runs static analysis, and produces structured pull request markdown reviews (`PR_REVIEW.md`).
  - **API Endpoint Health & Schema Prober** (`examples/dart/api_tester_skill`): REST health-checking agent benchmarking endpoint latency, validating JSON schema payloads, and generating diagnostic audit reports (`API_DIAGNOSTICS.md`).
  - **SQLite Database Analyst & Executive Reporter** (`examples/dart/sqlite_analyst_skill`): Autonomous database exploration agent that introspects relational schemas, executes aggregation queries, and exports business intelligence summaries (`DATABASE_REPORT.md`).

## 0.3.1

- Fixed `repository` URL in `pubspec.yaml` to point to GitHub `main` branch.

## 0.3.0

- **Windows Stdio MCP Server Execution**: Switched Windows NPX server launching to direct `node.exe` execution with `npx-cli.js`, eliminating `cmd.exe` stdin pipe stalls during MCP `initialize` handshakes.
- **Mistral Streaming**: Fixed `_MistralPatchClient` buffering live SSE event streams, enabling real-time chunk streaming.
- Added `LocalMcpRuntime.findNpxCli` and `_resolveWindowsExe` helpers for robust tool detection on Windows.
- Unified 0.3.0 release across the MCP Playground ecosystem.

## 0.2.2

- Added `SkillImporter.collectNeededTools()` — collects all tool names referenced by a skill manifest (declared tools + per-step enabledToolNames).
- Added `SkillImporter.buildUnresolvableToolsWarning()` — builds a human-readable warning listing missing tools with capability/install/registry details.
- `McpAgentEngine.registerAgentFromManifest()` now tracks resolved capability tools and emits an `AgentLogEvent` warning when unresolvable tools are detected.

## 0.2.1

- Added `McpAgentEngine.registerAgentFromManifest()` — builds and registers an `Agent` directly from a parsed `SkillManifest`, handling tool-declaration → `McpServerConfig` mapping and prompt-step conversion. Accepts optional `dartTools`, `workingDir`, and `serverOverrides`.
- Updated `SkillExporter.toSkillMd()` compatibility tag from `mcp_playground` to `"Universal"` to match agentskills.io TealKit standard.
- Added `dartTools` parameter to `registerAgentFromManifest()` for Dart-native local tool injection (weather, charts, SSH).

## 0.2.0

- **BREAKING**: SKILL.md export/import format changed to agentskills.io TealKit-compatible standard (`compatibility:`, `metadata:`, `workflow:`, `agents:`). Legacy custom format (`system_prompt:`, `prompts:`, `tools:`) is deprecated.
- Added `SkillManifest`, `SkillPromptStep`, `SkillToolDeclaration` models with 3-tier portability (`capability`, `local`, `external`).
- Added `SkillExporter` — converts `SavedPlaygroundSetup`/conversation → SKILL.md YAML frontmatter.
- Added `SkillImporter` — parses SKILL.md (both TealKit and legacy formats) → `SavedPlaygroundSetup` with multi-prompt step conversion.
- Added `SkillStorageAdapter` abstract interface with `StoredSkillInfo` for pluggable skill ZIP persistence.
- Added `yaml` dependency for robust YAML parsing.

## 0.1.4

- Upgraded dependencies: `anthropic_sdk_dart` to `^6.0.0`, `googleai_dart` to `^9.0.0`, `ollama_dart` to `^2.4.0`, `http` to `^1.6.0`.

## 0.1.3

- Refactored streaming support for Small Language Models (SLMs) and embedded models.
- Added dynamic static delegates `embeddedHandler` and `embeddedStreamHandler` to plug on-device inference engines without hard code dependencies.
- Added a new headless CLI example `embedded_example` demonstrating on-device Hugging Face GGUF model downloading, offline inference, local weather tool execution, and token-by-token terminal stream outputs.

## 0.1.2

- Expose `agentEvents` stream in `McpAgentEngine` and return a reactive event stream from `runAsync` for asynchronous streaming execution.
- Add support for loading `LlmConfig` hyperparameters (`temperature`, `maxTokens`, `topP`, `topK`, `repeatPenalty`) inside provider clients.
- Isolate local stdio client dependencies from web/wasm builds via default stub conditional imports.
- Protocol and logging compliance updates.

## 0.1.1

- Fixed WASM and Web compilation by integrating `universal_io` for subprocess/file wrappers.
- Added pure Dart `McpChangeNotifier` to core clients to remove Flutter dependencies.
- Added comprehensive self-contained package example for pub.dev.

## 0.1.0

- Initial release of the pure-Dart core package.
- Built-in multi-LLM SDK adapters (OpenAI, Claude, Gemini, Ollama, Mistral).
- HTTP/SSE stateful Model Context Protocol (MCP) clients with authentication and health-monitoring reconnection.
- Desktop stdio process execution client for Node.js and Python MCP servers.
- Core `McpAgentEngine` supporting sub-prompt orchestration pipelines, iterative tool loops, and loop-protection.
