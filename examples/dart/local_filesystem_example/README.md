# Local Filesystem MCP Agent Example (`local_filesystem_example`)

A headless Dart console example demonstrating how to run the official `@modelcontextprotocol/server-filesystem` Node.js server via NPX and orchestrate multi-step file inspection and sorting tasks with `mcp_playground_dart`.

---

## ✨ Features

- **Automated Node.js MCP Subprocess Execution**: Spawns `@modelcontextprotocol/server-filesystem` using `npx` with automatic Windows path resolution.
- **Autonomous Tool Loops**: Uses filesystem tools (`list_directory`, `read_file`, `write_file`) to inspect, organize, and sort files.
- **Headless LLM Integration**: Connects with any configured LLM provider in `.env`.

---

## 🚀 How to Run

Ensure Node.js is installed and your `.env` contains your LLM credentials:

```bash
cd examples/dart/local_filesystem_example
dart pub get
dart run main.dart
```
