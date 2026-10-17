# MCP CLI Chat Agent (`cli_example`)

An interactive command-line interface demonstrating headless multi-turn agent execution with the [`mcp_playground_dart`](https://pub.dev/packages/mcp_playground_dart) core library and external MCP servers (Node.js / Python subprocesses).

---

## ✨ Features

- **Interactive Multi-Turn Terminal Agent**: Clean REPL chat interface supporting multi-line input and streaming completions with `McpAgentEngine`.
- **Autonomous Task Planning & Step Tracking (`AgentPlanEvent`)**:
  - Structured multi-step task decomposition before/during execution.
  - Live terminal rendering of step progression (`[pending]`, `[in_progress]`, `[completed]`, `[failed]`).
  ```text
  ┌─ TASK PLAN ──────────────────────────────
  │ [in_progress] step_1: Search for project dependencies
  │ [pending    ] step_2: Analyze breaking changes
  │ [pending    ] step_3: Output migration report
  └──────────────────────────────────────────
  ```
- **Live Tool Call & Result Inspection (`AgentToolResultEvent`)**:
  - Real-time logging of tool invocations, parameters, and formatted results.
- **Dynamic Context Compression (`AgentContextCompressedEvent`)**:
  - Automatic summarization and token optimization when context limits are reached.
- **YAML Configuration with `${ENV_VAR}` Interpolation**:
  - `llm.yaml`: Configure LLM provider (OpenAI, Claude, Gemini, Ollama, Mistral, Embedded), model name, API keys, and custom system prompt.
  - `extern_mcp_tools.yaml`: Define stdio MCP server subprocesses (e.g. `@modelcontextprotocol/server-filesystem`).
- **Interactive Slash Commands**:
  - `/tools`: List all active and registered MCP tools.
  - `/system`: Display the active system prompt.
  - `/clear`: Clear conversation history.
  - `/help`, `/?`: Show available commands.
  - `/exit`, `/bye`: Quit the CLI.

---

## 🚀 How to Run

```bash
cd examples/dart/cli_example
dart pub get
dart run main.dart
```

Optional CLI flags:
```bash
dart run main.dart --llm llm.yaml --tools extern_mcp_tools.yaml
```

