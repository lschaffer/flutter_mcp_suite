# dart_mcp_core

Pure Dart core for the **Flutter MCP Suite**. Contains the agent execution engine, LLM SDK adapters, Model Context Protocol (MCP) clients, and tool orchestration — with zero Flutter dependencies.

Ideal for building pure Dart CLI applications, background workers, backend services, or scripting agents using the Model Context Protocol.

---

## ✨ Features

- **Multi-LLM Provider Support** — Unified SDK wrappers for:
  - **OpenAI** (`openai_dart`)
  - **Anthropic Claude** (`anthropic_sdk_dart`)
  - **Google Gemini** (`googleai_dart`)
  - **Ollama** (Local models via `ollama_dart`)
  - **Mistral AI** (OpenAI-compatible client with tool call/assistant formatting patches)
  - **OpenAI-Compatible** (vLLM, LiteLLM, or custom local endpoints)
  - **Embedded GGUF Models** (on-device execution via `llamadart`)
- **Model Context Protocol (MCP) Clients**
  - **Remote HTTP/SSE Transport** — Connection checking, Basic/Bearer authentication, automatic health monitoring, and reconnect loops.
  - **Local Stdio Transport** — Desktop-only (macOS, Windows, Linux) stdio subprocess client that automatically launches and interacts with local Node.js (`npx`/`npm`) or Python (`uvx`/`pip`) MCP servers.
- **Local Tools Framework** — Clean abstract class `McpLocalTool` to register any custom Dart-native functions as LLM-executable tools.
- **McpAgentEngine**
  - Iterative agentic tool execution loop.
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
  dart_mcp_core: ^1.0.2
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

## 🛠️ Creating Custom Tools

To create custom tools, inherit from `McpLocalTool`:

```dart
class GetCurrentTimeTool extends McpLocalTool {
  @override
  String get name => 'get_current_time';

  @override
  String get description => 'Returns the current local time.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {},
  };

  @override
  Future<MCPToolResult> execute(Map<String, dynamic> arguments) async {
    final now = DateTime.now().toLocal().toString();
    return MCPToolResult(
      content: [MCPContent(type: 'text', text: 'Current time is $now')],
    );
  }
}
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

- **`Agent.initialMessages`**: Pass previous conversation history (`List<ChatMessage>`) to the `Agent` for stateful multi-turn execution without losing context.
- **`AgentUsageEvent`**: Emits real-time token counts (`promptTokens`, `completionTokens`, `totalTokens`) after each LLM call for precise cost accounting.

---

## 🛠️ Real-World Reference Implementation: TealKit CLI

For a complete production CLI application utilizing `dart_mcp_core` for autonomous coding agent workflows, multi-LLM configuration switching, session persistence (JSON/Markdown), and MCP server management, check out:
- [**TealKit CLI (`tealkit_cli`)**](https://github.com/lschaffer/tealkit/tree/master/cli)

