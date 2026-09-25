## 1.1.1

- **Conversation Session Resumption**:
  - Added `initialMessages` property to `Agent` definition and JSON serialization (`toJson` / `fromJson`), allowing multi-turn REPL and CLI agents to save, restore, and continue session transcripts seamlessly.
- **Token Usage Reporting & Metric Events**:
  - Added `AgentUsageEvent` stream event to `McpAgentEngine` providing `promptTokens`, `completionTokens`, and `totalTokens` emitted after each LLM call.
  - Added `LLMUsage` model attached to `LLMResponse` capturing usage returned by LLM providers or calculated via fallback token estimation.
- **Enhanced Coding Tools**:
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
