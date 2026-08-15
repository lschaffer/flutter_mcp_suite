# MCP CLI Chat Agent (`cli_example`)

An interactive command-line interface demonstrating headless multi-turn agent execution with the [`mcp_playground_dart`](https://pub.dev/packages/mcp_playground_dart) core library and external MCP servers (Node.js / Python subprocesses).

---

## ✨ Features

- **Interactive Multi-Turn Terminal Agent**: Clean REPL chat interface supporting multi-line input and streaming completions.
- **YAML Configuration with `${ENV_VAR}` Interpolation**:
  - `llm.yaml`: Configure LLM provider (OpenAI, Claude, Gemini, Ollama, Mistral), model name, API keys, and custom system prompt.
  - `extern_mcp_tools.yaml`: Define stdio MCP server subprocesses (e.g. `@modelcontextprotocol/server-filesystem`).
- **Interactive Slash Commands**:
  - `/tools`: List all active and registered MCP tools.
  - `/system`: Display the active system prompt.
  - `/clear`: Clear conversation history.
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
