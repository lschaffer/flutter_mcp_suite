# MCP Playground Monorepo

> [!NOTE]
> This project was created and is actively maintained using agentic coding tools. The core monorepo and its packages were built with **Google Antigravity IDE** (primarily powered by **Gemini 3.5 Flash**), and specific components (such as some examples) were developed using the **ZooCode** plugin with **DeepSeek-V4**. It stands as a real-world demonstration of building production-ready Dart packages and interactive Flutter libraries using agentic workflows.

Welcome to the **MCP Playground** monorepo! This project is modularized into dedicated packages spanning headless pure-Dart execution, shared UI widgets, classic AI agent playground interfaces, and dynamic generative UI rendering via Google GenUI (`A2UI`).

---

## 📦 Packages

| Package | Description | Directory |
|---------|-------------|-----------|
| **[`mcp_playground_dart`](mcp_playground_dart)** | Pure Dart core engine. Handles agent orchestration, LLM service adapters, MCP client transport (HTTP/SSE/stdio subprocesses), and loop execution — **no Flutter dependencies**. | [`/mcp_playground_dart`](mcp_playground_dart) |
| **[`mcp_playground_ui`](mcp_playground_ui)** | Shared Flutter UI library containing reusable controllers, LLM forms, MCP server manager tabs, settings drawers, embedded model discoverers, and the side-by-side **Agent Inspector** panel. | [`/mcp_playground_ui`](mcp_playground_ui) |
| **[`mcp_playground_flutter`](mcp_playground_flutter)** | Classic AI Agent Playground for Flutter. Drop-in interactive chat widget with markdown rendering, tool call execution, attachment support, and live inspector debugging. | [`/mcp_playground_flutter`](mcp_playground_flutter) |
| **[`genui_mcp_playground`](genui_mcp_playground)** | Standalone dynamic GenUI (`A2UI`) Playground. Enables LLMs to emit structured UI components and render rich, interactive Flutter widgets directly in the conversation flow. | [`/genui_mcp_playground`](genui_mcp_playground) |

---

## 🚀 Examples

We provide several runnable example applications across Flutter, GenUI, and headless Dart:

### 🎨 GenUI (Generative UI) Examples
* **[Dynamic Weather Generator](genui_mcp_playground/example)**: Interactive weather generator demonstrating model-generated input forms, live chart visualizations, and native Dart tool integrations via `GenuiMcpPlayground`.
* **[Filesystem Explorer](examples/genui/example_genui_filesystem)**: Interactive GenUI filesystem explorer showcasing folder tree navigation and file content inspection surfaces.

### 📱 Flutter (Classic UI) Examples
* **[Primary Showcase App](mcp_playground_flutter/example)**: A comprehensive Flutter application demonstrating the `McpPlayground` UI widget with custom SSH, Open-Meteo weather, and fl_chart tool integrations.
* **[Embedded LLM Showcase](examples/flutter/example_embedded)**: A Flutter application pre-configured to run with a local on-device embedded LLM (`llamadart`) with zero external network dependencies.

### 💻 Dart (Headless) Examples
* **[Skill Importer Example](examples/dart/skill_example)**: Demonstrates importing an agentskills.io-compatible [`skill.md`](examples/dart/skill_example/skill.md) with multi-turn prompts, executing a web search + HTML chart generation workflow via `McpAgentEngine`.
* **[Local Filesystem Inspector](examples/dart/local_filesystem_example)**: A headless agent configured to install and run the official `@modelcontextprotocol/server-filesystem` Node.js server via NPX to inspect and sort local files.
  
  ![Local Filesystem Inspector Screenshot](./screenshots/example_dart/local_filsystem_test.png)

* **[Interactive CLI Chat Agent](examples/dart/cli_example)**: An interactive command-line interface loaded dynamically via configurations, allowing you to have a multi-turn chat conversation with LLMs using local Node/Python subprocess MCP tools.

  ![Interactive CLI Chat Agent Screenshot](./screenshots/example_dart/cli_filesystem_test.png)

* **[Embedded Model Runner](examples/dart/embedded_example)**: A pure Dart console example that downloads a `Qwen2.5-3B` GGUF model directly from Hugging Face with real-time download progress, initializes `llamadart`, registers native weather tools, and runs an offline agent with real-time token-by-token streaming.

---

## 🎥 Demo Video & Visuals

Watch the Flutter UI Playground executing terminal SSH tasks and charting stats:

![SSH MCP Demo](./screenshots/video/mcp_playground_ssh_chart_test.gif)
