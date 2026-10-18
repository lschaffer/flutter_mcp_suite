# dart_mcp_core

Pure Dart core for the **Flutter MCP Suite**. Contains the agent execution engine, LLM SDK adapters, Model Context Protocol (MCP) clients, and tool orchestration — with zero Flutter dependencies.

Ideal for building pure Dart CLI applications, background workers, backend services, or scripting agents using the Model Context Protocol.

---

## ✨ Features

- **Multi-LLM Provider Support** — Unified SDK wrappers for:
  - **Embedded GGUF Models** (on-device execution via `llamadart`)
  - **OpenAI** (`openai_dart`)
  - **Anthropic Claude** (`anthropic_sdk_dart`)
  - **Google Gemini** (`googleai_dart`)
  - **Ollama** (Local models via `ollama_dart`)
  - **Mistral AI** (OpenAI-compatible client with tool call/assistant formatting patches)
  - **OpenAI-Compatible** (vLLM, LiteLLM, or custom local endpoints)
- **Typed Multimodal Messages (`ChatContentPart`)** — First-class support for `TextPart`, `ImagePart` (bytes, base64, URL), `DocumentPart`, and `AudioPart` natively mapped to OpenAI, Gemini, Claude, and Ollama formats.
- **Context Window Auto-Compression & Episodic Memory Recall** — Automatically summarizes older conversation turns when token thresholds are exceeded, preserving raw turns in an indexed `EpisodicMemoryStore`. Injects `retrieve_memory` tool so the model can inspect exact historical code snippets, hashes, and tool outputs on demand.
- **Autonomous Sub-Agent Delegation (`DelegateTaskTool`)** — Primary agents can delegate focused tasks to specialized sub-agents or clean agent clones (`assignee: 'clone'`) with isolated context windows and multi-level recursion guards (`isSubAgent`, `delegationDepth`).
- **Dynamic Runtime Skill Activation (`SkillDefinition`)** — Group system prompts and tools into modular skill units. Non-active skills only publish concise one-line descriptions in the system prompt until the model activates them via `activate_skills` and `deactivate_skills`, keeping token footprints minimal.
- **Agent Evaluation Harness (`evals`)** — Anthropic-aligned evaluation suite with `EvalTask`, `EvalGrader` (`ExactMatchGrader`, `RegexGrader`, `ToolCallGrader`), `EvalRunner`, and `TrajectoryRecorder` for regression testing, pass@k metrics, and offline trajectory replay.
- **Structured Agent Planning (`PlanState`, `PlanStep`, `WriteTodosTool`)** — Native task checklist planning and live progress tracking with reactive `AgentPlanEvent` streams.
- **Agent Lifecycle Hooks (`AgentHook`)** — Security interceptors (`beforeToolCall`, `afterToolCall`, `beforeModelCall`, `afterModelCall`) with `ToolCallDecision` (`proceed`, `deny`, `modify`).
- **Progressive MCP Tool Discovery (`McpListToolsTool`, `McpCallToolTool`)** — On-demand schema loading to support hundreds of tools without exhausting context windows.
- **Model Context Protocol (MCP) Clients**
  - **Remote HTTP/SSE Transport** — Connection checking, Basic/Bearer authentication, automatic health monitoring, and reconnect loops.
  - **Local Stdio Transport** — Desktop-only (macOS, Windows, Linux) stdio subprocess client that automatically launches and interacts with local Node.js (`npx`/`npm`) or Python (`uvx`/`pip`) MCP servers.
- **Local Tools Framework** — Clean abstract class `McpLocalTool` to register any custom Dart-native functions as LLM-executable tools with enhanced `MCPToolResult.text`, `MCPToolResult.stop`, and `MCPToolResult.image`.
- **McpAgentEngine**
  - Iterative agentic tool execution loop with reactive `AgentEvent` streams.
  - Multi-step sub-prompt chaining with output substitution placeholders (`${tool_result}`, `${task_result}`).
  - Built-in duplicate call loop protection and cancellation tokens.
  - Interactive callbacks for real-time console logging, tool execution, and assistant thoughts.

---

## 🧠 Model Size & Embedded Compatibility Matrix

`dart_mcp_core` provides headless orchestration across local and cloud LLMs:

| Model Tier | Representative Models | Tool Calling Support | Suitable Headless Workflows |
|:---|:---|:---:|:---|
| **Compact SLMs (2B – 3.8B)** | **Gemma 2 2B**, **Ministral 3B**, **Qwen 2.5 3B / 3.8B** | 🟢 Native Tools & Simple JSON | Offline Dart CLI scripts (`embedded_example`), single-step tool execution, local file parsing, and quick summaries. |
| **Mid-Size SLMs (7B – 9B)** | **Qwen 2.5 7B**, **Ministral 8B**, **Mistral 7B**, **Llama 3.1 8B**, **Gemma 2 9B** | 🟢 Multi-Step Tool Chaining | Subprocess MCP servers (e.g. `@modelcontextprotocol/server-filesystem`), SQLite queries (`sqlite_analyst_skill`), and REST API probing (`api_tester_skill`). |
| **Workhorse Models (14B – 24B)** | **Qwen 2.5 14B**, **Mistral Small 24B** | 🟢 Complex Reasoning | Full multi-turn automated code reviews (`git_review_skill`), complex schema introspections, and high reliability. |
| **Frontier Cloud Models (32B – 70B+)** | **Gemini 2.5 Flash / Pro**, **GPT-4o**, **Claude 3.7 Sonnet**, **Qwen 2.5 32B+** | 🟢 Complex Agent Loops | Deep multi-agent sub-prompt workflows with unlimited tool iterations. |

---

## 🚀 Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  dart_mcp_core: ^1.3.0
```

### Basic Example (Pure Dart CLI)

```dart
import 'dart:convert';
import 'dart:io';
import 'package:dart_mcp_core/dart_mcp_core.dart';

Future<void> main() async {
  // 1. Configure the LLM
  final llmConfig = LlmConfig(
    provider: LlmProvider.openai,
    model: 'gpt-4o-mini',
    apiKey: 'your-openai-api-key',
  );

  // 2. Define your Dart-native tools
  final tools = <McpLocalTool>[
    GeocodeWeatherCityTool(),
    GetHourlyForecastTool(),
  ];

  // 3. Create the Agent configuration
  final agent = Agent(
    key: 'weather_agent',
    name: 'Weather Expert',
    llmConfig: llmConfig,
    systemPrompt: 'You are a weather assistant. Always geocode the city name first.',
    prompts: [
      const SubPromptStep(
        text: 'Find coordinates of Rome, Italy using geocode_weather_city.',
        enabledToolNames: ['geocode_weather_city'],
      ),
      const SubPromptStep(
        text: 'Fetch the 24-hour forecast using get_hourly_forecast for those coordinates.\n\nCoordinates:\n\${tool_result}',
      ),
    ],
    dartTools: tools,
  );

  // 4. Create the execution engine and run the Agent
  final engine = McpAgentEngine();
  engine.setAgents([agent]);

  try {
    await engine.run(
      agent.key,
      onLog: (msg) => print('[LOG] $msg'),
      onToolResult: (name, params, result) => print('Tool $name returned: $result'),
      onAssistantResult: (prompt, response) => print('Assistant: $response'),
      onFinalResult: (response) {
        print('\n=== FINAL RESPONSE ===');
        print(response);
      },
    );
  } finally {
    await engine.dispose();
  }
}
```

---

## 🖼️ Multimodal Content Parts (`ChatContentPart`)

`dart_mcp_core` supports structured multimodal messages across OpenAI, Anthropic Claude, Google Gemini, and Ollama.

```dart
final userMessage = ChatMessage.user(
  'Analyze this architecture diagram and explain the data flow:',
  parts: [
    const TextPart('Analyze this architecture diagram and explain the data flow:'),
    ImagePart.fromUrl('https://example.com/architecture.png'),
    // Or from local bytes:
    // ImagePart.fromBytes(imageBytes, mimeType: 'image/png'),
  ],
);
```

---

## 🧠 Context Window Auto-Compression with Episodic Recall

Standard LLM summarization often permanently discards exact parameters, hashes, or code snippets from older turns. `dart_mcp_core` pairs `ContextCompressor` with an `EpisodicMemoryStore`:

1. When tokens exceed `tokenThreshold`, older turns are summarized into a compact overview.
2. The verbatim turns are saved into `EpisodicMemoryStore` with an archive ID (e.g. `mem_7f99efd7`).
3. The engine automatically injects the `retrieve_memory` tool so the model can recall past raw turns whenever needed.

```dart
final memoryStore = EpisodicMemoryStore();

final compressor = ContextCompressor(
  tokenThreshold: 4000,
  preserveRecentCount: 4,
  memoryStore: memoryStore,
);

final agent = Agent(
  key: 'researcher',
  name: 'Research Assistant',
  llmConfig: llmConfig,
  contextCompressor: compressor,
);

// Listen to recall events
engine.agentEvents.listen((event) {
  if (event is AgentMemoryRetrievedEvent) {
    print('🧠 Model recalled ${event.recalledTurnCount} turns from archive ${event.archiveId}');
  }
});
```

---

## 🤖 Sub-Agent Delegation (`delegate_task` & `clone`)

Avoid context pollution by delegating specialized work to isolated child agents.

- **`assignee: 'clone'`** creates a child worker agent with identical tools and LLM configuration, but with a fresh, clean context window.
- **`assignee: '<key>'`** invokes another registered sub-agent by key.
- Built-in `isSubAgent` and `delegationDepth` guards prevent infinite recursive delegation.

```dart
final agent = Agent(
  key: 'manager',
  name: 'Project Manager',
  llmConfig: llmConfig,
  enableDelegation: true,
  subAgentKeys: ['researcher', 'coder'],
);

// Listen to sub-agent lifecycle in real-time
engine.agentEvents.listen((event) {
  if (event is AgentSubAgentStartedEvent) {
    print('🚀 [Sub-Agent Started] Assignee: ${event.subAgentKey} - Task: ${event.task}');
  } else if (event is AgentSubAgentCompletedEvent) {
    print('✅ [Sub-Agent Finished] Output: ${event.result}');
  }
});
```

---

## ⚡ Dynamic Runtime Skill Activation (`SkillDefinition`)

Instead of registering 50+ tool schemas and bloating prompt context windows upfront, package related capabilities into modular `SkillDefinition`s.

- Non-active skills only publish a single-line summary in the system prompt.
- The model activates skills on-demand using `activate_skills` when relevant, and unloads them with `deactivate_skills` when finished.

```dart
final gitSkill = SkillDefinition(
  name: 'git_reviewer',
  description: 'Inspects git diffs, commits, and performs automated pull request code reviews.',
  systemPrompt: 'You are an expert code reviewer checking for logic errors and security vulnerabilities.',
  tools: [GitDiffTool(), GitLogTool()],
  isAlwaysOn: false, // Inactive by default; activated on demand by the agent
);

final agent = Agent(
  key: 'lead_dev',
  name: 'Lead Developer',
  llmConfig: llmConfig,
  skills: [gitSkill],
);

// Listen for dynamic skill transitions
engine.agentEvents.listen((event) {
  if (event is AgentSkillsChangedEvent) {
    print('⚡ Active Skills: ${event.activeSkills.join(', ')}');
  }
});
```

---

## 🎯 Agent Evaluation & Trajectory Replay Harness (`evals`)

Benchmark agent reliability and run deterministic regression tests without live API calls.

```dart
// 1. Define an evaluation task
final task = EvalTask(
  id: 'weather_tokyo',
  name: 'Tokyo Weather Inquiry',
  prompt: 'What is the current temperature in Tokyo?',
  expectedTools: ['get_weather'],
  expectedOutput: 'Tokyo',
);

// 2. Select graders
final runner = EvalRunner(
  defaultGrader: ExactMatchGrader(),
);

// 3. Run the evaluation suite
final report = await runner.runSuite(
  suiteName: 'Weather Capabilities Verification',
  tasks: [task],
  engine: engine,
  agentKey: 'weather_agent',
);

print('Pass Rate: ${(report.passRate * 100).toStringAsFixed(1)}%');
print('Passed: ${report.passedTasks} / ${report.totalTasks}');
print('Total Tokens Used: ${report.totalTokens}');

// 4. Save trajectories for offline test replay
final jsonTranscript = TrajectoryRecorder.exportToJson(report.results.first.trajectory);
```

---

## 💻 Native Coding Tools (`CodingTools`)

`dart_mcp_core` provides 10 built-in autonomous software engineering tools matching Claude Code / Roo Code style capabilities:

- `CodingTools.createAll({String? workingDirectory})` — Instantiates:
  - `fs_find` — Recursive glob / wildcard workspace search matching patterns (e.g. `*.dart`, `*.csproj`) with `.gitignore` and default build folder exclusions.
  - `fs_list_dir` — Structured directory inspection with file sizes and type tags (`[DIR]`, `[FILE]`).
  - `fs_read_file` — Line-numbered file reading with pagination protection (capped to 800 lines max per read to safeguard LLM context windows).
  - `fs_write_file` — Atomic file creation and full overwrite with automatic parent directory generation.
  - `fs_replace_text` — Exact, unique search-and-replace block edits (ideal for small/open models).
  - `fs_create_dir` — Recursive directory creation.
  - `fs_move` — File and folder rename or move operations.
  - `fs_delete` — File and recursive directory deletion (with workspace root protection).
  - `terminal_exec` — Subprocess shell execution with timeout and output capture.
  - `fetch_web` — Direct HTTP GET tool for querying web pages, pub.dev API, and documentation.

---

## 📊 Token Usage Metrics & Multi-Turn Sessions

- **`Agent.initialMessages` & Trajectory Preservation**: Pass previous conversation history (`List<ChatMessage>`) to the `Agent` for stateful multi-turn execution without losing context. `AgentFinalResultEvent` returns the full turn trajectory (all tool calls, tool results, and responses) to save or continue sessions.
- **Configurable Tool Iteration Limit (`maxToolIterations`)**: Configurable exploration budget (defaults to 100 iterations) in `LlmConfig`, `Agent`, and `McpAgentEngine`. When the limit is reached, the engine automatically prompts the model to synthesize all findings and deliver its final response rather than halting abruptly.
- **`AgentUsageEvent`**: Emits real-time token counts (`promptTokens`, `completionTokens`, `totalTokens`) after each LLM call for precise cost accounting.

---

## 🛠️ Real-World Reference Implementation: TealKit CLI

For a complete production CLI application utilizing `dart_mcp_core` for autonomous coding agent workflows, multi-LLM configuration switching, session persistence (JSON/Markdown), and MCP server management, check out:
- [**TealKit CLI (`tealkit_cli`)**](https://github.com/lschaffer/tealkit/tree/master/cli)
